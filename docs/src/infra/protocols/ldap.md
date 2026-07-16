---
authors: ShutdownRepo, Tednoob17
category: infra
---

# 🛠️ LDAP

## Theory

LDAP (Lightweight Directory Access Protocol) is a standardized network protocol primarily used for directory services — authentication and resource access in networked environments. It operates over TCP, defaulting to port `389` for plain connections and port `636` for LDAPS (LDAP over TLS).

In environments such as Active Directory, LDAP is the primary interface for querying the directory. Anonymous binds are sometimes permitted, which allows unauthenticated enumeration of naming contexts and base attributes. With valid credentials, a significant amount of information becomes accessible, including users, groups, computers, GPOs, and delegation configurations.

## Practice

### Enumeration

#### Banner grabbing

The LDAP rootDSE (Root Directory Service Entry) is often accessible without credentials. It exposes metadata such as naming contexts, supported LDAP versions, and the domain controller's DNS hostname.

:::tabs
=== Unix-like
```bash
# Retrieve naming contexts (base DN) from rootDSE
ldapsearch -x -H ldap://$TARGET -b "" -s base namingContexts

# Retrieve all rootDSE attributes
ldapsearch -x -H ldap://$TARGET -b "" -s base "(objectclass=*)"
```

=== Windows
```powershell
# Query rootDSE using ADSI
[System.DirectoryServices.DirectoryEntry]::new("LDAP://$TARGET/rootDSE").Properties
```
:::

#### Anonymous bind

If anonymous binds are permitted, directory objects can be enumerated without credentials. The extent of accessible data depends on the server's access control configuration.

:::tabs
=== Unix-like
```bash
# $DOMAIN: the domain to query, e.g. contoso.local
ldapsearch -x -H ldap://$TARGET -b "dc=$DOMAIN,dc=local"

# Filter for user objects only
ldapsearch -x -H ldap://$TARGET -b "dc=$DOMAIN,dc=local" "(objectclass=user)"

# Filter for group objects
ldapsearch -x -H ldap://$TARGET -b "dc=$DOMAIN,dc=local" "(objectclass=group)"
```

=== Windows
```powershell
# $DOMAIN: the domain to query, e.g. contoso.local
# Enumerate all objects accessible via anonymous bind
$dirEntry = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$TARGET/dc=$DOMAIN,dc=local")
$dirSearcher = [System.DirectoryServices.DirectorySearcher]::new($dirEntry)
$dirSearcher.Filter = "(objectclass=*)"
$dirSearcher.FindAll()
```
:::

#### Authenticated enumeration

With valid domain credentials, LDAP can be queried for a comprehensive set of objects and attributes.

:::tabs
=== Unix-like
```bash
# Enumerate all user objects
# $DOMAIN: the domain to query, e.g. contoso.local
ldapsearch -x -H ldap://$DC_IP \
  -D "$USER@$DOMAIN" -W \
  -b "dc=$DOMAIN,dc=local" "(objectclass=user)"

# Enumerate computer accounts
ldapsearch -x -H ldap://$DC_IP \
  -D "$USER@$DOMAIN" -W \
  -b "dc=$DOMAIN,dc=local" "(objectclass=computer)"

# windapsearch — enumerate domain users
python3 windapsearch.py --dc-ip $DC_IP -u "$USER" -p "$PASSWORD" --users

# windapsearch — enumerate domain admins
python3 windapsearch.py --dc-ip $DC_IP -u "$USER" -p "$PASSWORD" --da

# ldeep — dump all LDAP objects to a local folder
ldeep ldap -u "$USER" -p "$PASSWORD" -d "$DOMAIN" -s ldap://$DC_IP all "dump/$DOMAIN"

# NetExec — enumerate users via LDAP
nxc ldap $DC_IP -u "$USER" -p "$PASSWORD" --users
```

=== Windows
```powershell
# Using PowerView — enumerate domain users
Get-DomainUser -Server $DC_IP

# Using PowerView — enumerate domain groups
Get-DomainGroup -Server $DC_IP

# Using PowerView — enumerate domain computers
Get-DomainComputer -Server $DC_IP

# Using built-in Active Directory module
Get-ADUser -Filter * -Server $DC_IP
```
:::

#### Nmap scripts

Port discovery and LDAP service identification can be performed using Nmap NSE scripts.

:::tabs
=== Unix-like
```bash
# Discover LDAP/LDAPS ports and run enumeration scripts
nmap -p 389,636 --script=ldap-search,ldap-rootdse $TARGET

# Service version detection with LDAP scripts
nmap -p 389,636 -sV --script=ldap-search,ldap-ls $TARGET
```
:::

#### Authentication check

The identity associated with an LDAP bind can be verified using `ldapwhoami` to confirm credential validity and determine the effective bind DN.

:::tabs
=== Unix-like
```bash
# Verify identity of an authenticated bind
ldapwhoami -x -H ldap://$DC_IP -D "$USER@$DOMAIN" -W

# Verify anonymous bind (returns anonymous if allowed)
ldapwhoami -x -H ldap://$TARGET
```
:::

## Resources

[LDAP - Wikipedia](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol)
[windapsearch](https://github.com/ropnop/windapsearch)
[ldeep](https://github.com/franc-pentest/ldeep)
[ldapsearch man page](https://linux.die.net/man/1/ldapsearch)
[HackTricks - LDAP](https://book.hacktricks.xyz/network-services-pentesting/pentesting-ldap)