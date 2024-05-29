# Web endpoints

## Theory

In [their research papers](https://posts.specterops.io/certified-pre-owned-d95910965cd2), [Will Schroeder](https://twitter.com/harmj0y) and [Lee Christensen](https://twitter.com/tifkin\_) found a domain escalation vector based on web endpoints vulnerable to [NTLM relay attacks](../ntlm/relay.md). The escalation vector was dubbed [ESC8](https://posts.specterops.io/certified-pre-owned-d95910965cd2#48bd).

> AD CS supports several HTTP-based enrollment methods via additional server roles that administrators can optionally install \[(The certificate enrollment web interface, Certificate Enrollment Service (CES), Network Device Enrollment Service (NDES)).]
>
> \[...]
>
> These HTTP-based certificate enrollment interfaces are all vulnerable to NTLM relay attacks. Using NTLM relay, an attacker can impersonate an inbound-NTLM-authenticating victim user. While impersonating the victim user, an attacker could access these web interfaces and request a client authentication certificate based on the "User" or "Machine" certificate templates.
>
> ([specterops.io](https://posts.specterops.io/certified-pre-owned-d95910965cd2#5c3c))

Following this, [Sylvain Heiniger](https://twitter.com/sploutchy) from Compass Security has found a similar vulnerability on the AD CS RPC enrollment endpoint. As described in [his article](https://blog.compass-security.com/2022/11/relaying-to-ad-certificate-services-over-rpc/), each RPC interface checks the NTLM signature independently.

For certificate request purposes, the `MS-ICPR` (ICertPassage Remote Protocol) RPC interface is used. According to the [Microsoft documentation](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-icpr/0c6f150e-3ead-4006-b37f-ebbf9e2cf2e7), packet privacy is enabled if the `IF_ENFORCEENCRYPTICERTREQUEST` flag is set (default configuration), meaning that NTLM relay attacks are not possible.

These attacks, like all [NTLM relay attacks](../ntlm/relay.md), require a victim account to authenticate to an attacker-controlled machine. An attacker can coerce authentication by many means, see [MITM and coerced authentication coercion techniques](../mitm-and-coerced-authentications/). Once the incoming authentication is received by the attacker, it can be relayed to an AD CS web endpoint.

Once the relayed session is obtained, the attacker poses as the relayed account and can request a client authentication certificate. The certificate template used needs to be configured for authentication (i.e. EKUs like Client Authentication, PKINIT Client Authentication, Smart Card Logon, Any Purpose (`OID 2.5.29.37.0`), or no EKU (`SubCA`)) and allowing low-priv users to enroll can be abused to authenticate as any other user/machine/admin.

{% hint style="success" %}
The default **User** and **Machine/Computer** templates match those criteria and are very often enabled.
{% endhint %}

This allows for lateral movement, account persistence, and in some cases privilege escalation if the relayed user had powerful privileges (e.g., domain controllers or Exchange servers, domain admins etc.).

## Practice

### Discovery of Web Endpoint

Following bash line allows to find potential endpoint running AD CS web endppoint. Note that machines also responding in basic/ntlm on this endpoint will behave similarly. Nevertheless, this is a server list for possible relay attacks.

```bash
cat server_ips.txt | httpx -path "/certsrv/certfnsh.asp" -follow-redirect -match-code 401 
```

### Web endpoint (ESC8)

{% tabs %}
{% tab title="UNIX-like" %}
**1 - Setting up the relay servers** :tools:

From UNIX-like systems, [Impacket](https://github.com/SecureAuthCorp/impacket)'s [ntlmrelayx](https://github.com/SecureAuthCorp/impacket/blob/master/examples/ntlmrelayx.py) (Python) can be used to conduct the ESC8 escalation scenario.

```bash
ntlmrelayx -t http://$PKI.domain.local/certsrv/certfnsh.asp --adcs --template "Template name"
```

{% hint style="info" %}
The certificate template flag (i.e. `--template`) can either be left blank (defaults to Machine or User whether relayed account name ends with `$`) or chosen among the certificate templates that fill the requirements.

For instance, if the relayed principal is a domain controller, the `DomainController` template must be specified.
{% endhint %}

[Certipy](https://github.com/ly4k/Certipy) (Python) can be used to enumerate information regarding the certificate templates (EKUs allowing for authentication, allowing low-priv users to enroll, etc.) and identify enabled HTTP endpoint ([how to enumerate](./#attack-paths)).

```bash
# find ESC8-vulnerable CAs
certipy find -u "$USER@$DOMAIN" -p "$PASSWORD" -dc-ip "$DC_IP" -stdout | grep -B20 ESC8
# find and look through enabled templates for ones that could be used for authentication
certipy find -u "$USER@$DOMAIN" -p "$PASSWORD" -dc-ip "$DC_IP" -stdout -enabled
```

{% hint style="info" %}
By default, Certipy uses LDAPS, which is not always supported by the domain controllers. The `-scheme` flag can be used to set whether to use LDAP or LDAPS.
{% endhint %}

**2 - Authentication coercion** :chains:

Just like any other NTLM relay attack, once the relay servers are running and waiting for incoming NTLM authentications, authentication coercion techniques can be used (e.g. [PrinterBug](../mitm-and-coerced-authentications/ms-rprn.md), [PetitPotam](../mitm-and-coerced-authentications/ms-efsr.md), [PrivExchange](../exchange-services/privexchange.md)) to force accounts/machines to authenticate to the relay servers.

{% content-ref url="../mitm-and-coerced-authentications/" %}
[mitm-and-coerced-authentications](../mitm-and-coerced-authentications/)
{% endcontent-ref %}

**3 - Loot** :tada:

Once incoming NTLM authentications are relayed and authenticated sessions abused, base64-encoded PFX certificates will be obtained and usable with [Pass-the-Certificate](../kerberos/pass-the-certificate.md) to obtain a TGT and authenticate.
{% endtab %}

{% tab title="Windows" %}
From Windows systems, the [Certify](https://github.com/GhostPack/Certify) (C#) tool can be used to enumerate enabled web endpoints (both HTTP and HTTPS).

```batch
Certify.exe cas
```

{% hint style="warning" %}
If web endpoints are enabled, switch to UNIX because at the time of writing (October 20th, 2021), I don't know how to easily conduct the ESC8 abuse from Windows.
{% endhint %}
{% endtab %}
{% endtabs %}

### RPC endpoint (ESC11)

{% tabs %}
{% tab title="UNIX-like" %}
**1 - Setting up the relay servers** :tools:

From UNIX-like systems, [Impacket](https://github.com/SecureAuthCorp/impacket)'s [ntlmrelayx](https://github.com/SecureAuthCorp/impacket/blob/master/examples/ntlmrelayx.py) (Python) can be used to conduct the ESC11 escalation scenario.

```bash
ntlmrelayx -t rpc://$PKI.domain.local -rpc-mode ICPR -icpr-ca-name $CA_NAME -smb2support --template "Template name"
```

{% hint style="info" %}
The certificate template flag (i.e. `--template`) can either be left blank (defaults to Machine or User whether relayed account name ends with `$`) or chosen among the certificate templates that fill the requirements.

For instance, if the relayed principal is a domain controller, the `DomainController` template must be specified.
{% endhint %}

[Certipy](https://github.com/ly4k/Certipy) (Python) can be used to enumerate information regarding the certificate templates (EKUs allowing for authentication, allowing low-priv users to enroll, etc.) and identify a vulnerable RPC endpoint ([how to enumerate](./#attack-paths)).

```bash
# find ESC11-vulnerable CAs
certipy find -u "$USER@$DOMAIN" -p "$PASSWORD" -dc-ip "$DC_IP" -stdout | grep -B20 ESC11
# find and look through enabled templates for ones that could be used for authentication
certipy find -u "$USER@$DOMAIN" -p "$PASSWORD" -dc-ip "$DC_IP" -stdout -enabled
```

{% hint style="info" %}
By default, Certipy uses LDAPS, which is not always supported by the domain controllers. The `-scheme` flag can be used to set whether to use LDAP or LDAPS.
{% endhint %}

**2 - Authentication coercion** :chains:

Just like any other NTLM relay attack, once the relay servers are running and waiting for incoming NTLM authentications, authentication coercion techniques can be used (e.g. [PrinterBug](../mitm-and-coerced-authentications/ms-rprn.md), [PetitPotam](../mitm-and-coerced-authentications/ms-efsr.md), [PrivExchange](../exchange-services/privexchange.md)) to force accounts/machines to authenticate to the relay servers.

{% content-ref url="../mitm-and-coerced-authentications/" %}
[mitm-and-coerced-authentications](../mitm-and-coerced-authentications/)
{% endcontent-ref %}

**3 - Loot** :tada:

Once incoming NTLM authentications are relayed and authenticated sessions abused, base64-encoded PFX certificates will be obtained and usable with [Pass-the-Certificate](../kerberos/pass-the-certificate.md) to obtain a TGT and authenticate.
{% endtab %}

{% tab title="Windows" %}
From Windows systems, at the time of writing (April 24th, 2024) no tool permits to identify and exploit the ESC11 vulnerability. Look at the UNIX-like tab to perform the exploitation.

{% endtab %}
{% endtabs %}

## Resources

{% embed url="https://www.exandroid.dev/2021/06/23/ad-cs-relay-attack-practical-guide" %}

{% embed url="https://dirkjanm.io/ntlm-relaying-to-ad-certificate-services" %}

{% embed url="https://posts.specterops.io/certified-pre-owned-d95910965cd2" %}

{% embed url="https://blog.compass-security.com/2022/11/relaying-to-ad-certificate-services-over-rpc/" %}
