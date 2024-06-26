# Certificate Services (AD-CS)

## Theory

> AD CS is Microsoft’s PKI implementation that provides everything from encrypting file systems, to digital signatures, to user authentication (a large focus of our research), and more. While AD CS is not installed by default for Active Directory environments, from our experience in enterprise environments it is widely deployed, and the security ramifications of misconfigured certificate service instances are enormous. ([specterops.io](https://posts.specterops.io/certified-pre-owned-d95910965cd2))

In [their research papers](https://posts.specterops.io/certified-pre-owned-d95910965cd2), [Will Schroeder](https://twitter.com/harmj0y) and [Lee Christensen](https://twitter.com/tifkin\_) shared their research on AD CS and identified multiple theft, escalation and persistence vectors.

* **Credential theft** (dubbed THEFT1 to THEFT5)
* **Account persistence** (dubbed PERSIST1 to PERSIST3)
* **Domain escalation** (dubbed ESC1 to ESC14)
  * based on [misconfigured certificate templates](certificate-templates.md)
  * based on [dangerous CA configuration](certificate-authority.md)
  * related to [access control vulnerabilities](access-controls.md)
  * based on an NTLM relay vulnerability related to the [web and RPC endpoints of AD CS](unsigned-endpoints.md)
* **Domain persistence** (dubbed DPERSIST1 to DPERSIST3)
  * by [forging certificates with a stolen CA certificates](certificate-authority.md#stolen-ca)
  * by trusting rogue CA certificates
  * by [maliciously creating vulnerable access controls](../../persistence/access-controls.md)

## Practice

### Escalation techniques

[#template-allows-san-esc1](certificate-templates.md#template-allows-san-esc1 "mention")

[#any-purpose-eku-esc2](certificate-templates.md#any-purpose-eku-esc2 "mention")

[#certificate-agent-eku-esc3](certificate-templates.md#certificate-agent-eku-esc3 "mention")

[#certificate-templates-esc4](access-controls.md#certificate-templates-esc4 "mention")

[#other-objects-esc5](access-controls.md#other-objects-esc5 "mention")

[#editf\_attributesubjectaltname2-esc6](certificate-authority.md#editf\_attributesubjectaltname2-esc6 "mention")

[#certificate-authority-esc7](access-controls.md#certificate-authority-esc7 "mention")

[#web-endpoint-esc8](unsigned-endpoints.md#web-endpoint-esc8 "mention")

[#no-security-extension-esc9](certificate-templates.md#no-security-extension-esc9 "mention")

[#weak-certificate-mapping-esc10](certificate-templates.md#weak-certificate-mapping-esc10 "mention")

[#rpc-endpoint-esc11](unsigned-endpoints.md#rpc-endpoint-esc11 "mention")

[#shell-access-to-adcs-ca-with-yubihsm-esc12](certificate-authority.md#shell-access-to-adcs-ca-with-yubihsm-esc12 "mention")

[#issuance-policiy-with-privileged-group-linked-esc13](certificate-templates.md#issuance-policiy-with-privileged-group-linked-esc13 "mention")

[#weak-explicit-mapping-esc14](certificate-templates.md#weak-explicit-mapping-esc14 "mention")&#x20;

[certifried.md](certifried.md "mention")

### Terminology

> * **PKI** (Public Key Infrastructure) — a system to manage certificates/public key encryption
> * **AD CS** (Active Directory Certificate Services) — Microsoft’s PKI implementation
> * **CA** (Certificate Authority) — PKI server that issues certificates
> * **Enterprise CA** — CA integrated with AD (as opposed to a standalone CA), offers certificate templates
> * **Certificate Template** — a collection of settings and policies that defines the contents of a certificate issued by an enterprise CA
> * **CSR** (Certificate Signing Request) — a message sent to a CA to request a signed certificate
> * **EKU** (Extended/Enhanced Key Usage) — one or more object identifiers (OIDs) that define how a certificate can be used
>
> ([specterops.io](https://posts.specterops.io/certified-pre-owned-d95910965cd2))

### Recon

While AD CS offers attackers a wide range of exploitation and persistence scenarios, this set of services is not always installed, and when it is, it is a requirement to identify its different parts in the domain.

#### Cert Publishers

An initial indicator is the "Cert Publishers" built-in group whose members usually are the servers where AD CS is installed (i.e. PKI/CA).

* From UNIX-like systems: `rpc net group members "Cert Publishers" -U "DOMAIN"/"User"%"Password" -S "DomainController"`
* From Windows systems: `net group "Cert Publishers" /domain`

#### `pKIEnrollmentService` objects

Alternatively, information like the PKI's CA and DNS names can be gathered through LDAP.

{% tabs %}
{% tab title="netexec" %}
[netexec](https://github.com/Pennyw0rth/NetExec)'s [adcs](https://github.com/Pennyw0rth/NetExec/blob/master/cme/modules/adcs.py) module (Python) can be used to find PKI enrollment services in AD.

```bash
netexec ldap 'domaincontroller' -d 'domain' -u 'user' -p 'password' -M adcs
```
{% endtab %}

{% tab title="windapsearch" %}
[windapsearch ](https://github.com/ropnop/windapsearch)(Python) can be used to manually to the LDAP query.

```bash
windapsearch -m custom --filter '(objectCategory=pKIEnrollmentService)' --base 'CN=Configuration,DC=domain,DC=local' --attrs dn,dnshostname --dc 'domaincontroller' -d 'domain.local' -u 'user' -p 'password'
```
{% endtab %}

{% tab title="ntlmrelayx" %}
With [Impacket](https://github.com/SecureAuthCorp/impacket)'s [ntlmrelayx](https://github.com/SecureAuthCorp/impacket/blob/master/examples/ntlmrelayx.py) (Python), thanks to [SAERXCIT](https://twitter.com/saerxcit) ([PR#1214](https://github.com/SecureAuthCorp/impacket/pull/1214)), it is possible to gather information regarding ADCS like the name and host of the CA, the certificate templates enrollment rights for those allowing client authentication and not requiring manager approval, etc. With ntlmrelayx, these information can be gathered through a relayed LDAP session.

```bash
ntlmrelayx -t "ldap://domaincontroller" --dump-adcs
```
{% endtab %}
{% endtabs %}

#### Attack paths

{% hint style="info" %}
[Certipy](https://github.com/ly4k/Certipy) (Python) and [Certify](https://github.com/GhostPack/Certify) (C#) can also identify the PKI enrollment services and potential attack paths.
{% endhint %}

{% tabs %}
{% tab title="UNIX-like" %}
From UNIX-like systems, the [Certipy](https://github.com/ly4k/Certipy) (Python) tool can be used to operate multiple attacks and enumeration operations.

```python
# enumerate and save text, json and bloodhound (original) outputs
certipy find -u 'user@domain.local' -p 'password' -dc-ip 'DC_IP' -old-bloodhound

# quickly spot vulnerable elements
certipy find -u 'user@domain.local' -p 'password' -dc-ip 'DC_IP' -vulnerable -stdout
```

Certipy also supports BloodHound. With the `-old-bloodhound` option, the data will be exported for the original version of [BloodHound](https://github.com/BloodHoundAD/BloodHound). With the `-bloodhound` option, the data will be exported for the modified version of BloodHound, [forked](https://github.com/ly4k/BloodHound/) by Certipy's [author](https://twitter.com/ly4k\_) (default output when no flag is set).

The tool also supports multiple output types (text, json, stdout).

{% hint style="info" %}
By default, Certipy uses LDAPS, which is not always supported by the domain controllers. The `-scheme` flag can be used to set whether to use LDAP or LDAPS.
{% endhint %}
{% endtab %}

{% tab title="Windows" %}
From Windows systems, the [Certify](https://github.com/GhostPack/Certify) (C#) tool can be used to operate multiple attacks and enumeration operations.

```batch
Certify.exe cas
```
{% endtab %}
{% endtabs %}

### Abuse

The different domain escalation scenarios are detailed in the following parts.

#### Techniques dubbed ESC1 to ESC3, ESC9, ESC10, ESC13 and ESC14

{% content-ref url="certificate-templates.md" %}
[certificate-templates.md](certificate-templates.md)
{% endcontent-ref %}

#### Techniques dubbed ESC6 and ESC12

{% content-ref url="certificate-authority.md" %}
[certificate-authority.md](certificate-authority.md)
{% endcontent-ref %}

#### Techniques dubbed ESC4, ESC5 & ESC7

{% content-ref url="access-controls.md" %}
[access-controls.md](access-controls.md)
{% endcontent-ref %}

#### Technique dubbed ESC8, ESC11

{% content-ref url="unsigned-endpoints.md" %}
[unsigned-endpoints.md](unsigned-endpoints.md)
{% endcontent-ref %}

## Resources

{% embed url="https://posts.specterops.io/certified-pre-owned-d95910965cd2" %}

{% embed url="https://www.riskinsight-wavestone.com/en/2021/06/microsoft-adcs-abusing-pki-in-active-directory-environment" %}

{% embed url="https://http418infosec.com/ad-cs-what-can-be-misconfigured" %}

{% embed url="https://http418infosec.com/ad-cs-the-certified-pre-owned-attacks" %}

{% embed url="https://research.ifcr.dk/certipy-2-0-bloodhound-new-escalations-shadow-credentials-golden-certificates-and-more-34d1c26f0dc6" %}
