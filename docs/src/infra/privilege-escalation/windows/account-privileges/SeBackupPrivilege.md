---
authors: PvUL00
category: infra
---

# SeBackupPrivilege

## Theory

[SeBackupPrivilege](https://docs.microsoft.com/en-us/windows-hardware/drivers/ifs/privileges) allows traversing any folder and listing its contents, enabling a file to be copied from a folder even when there is no access control entry (ACE) in the folder's access control list (ACL). This cannot be done with the standard copy command; the data must be copied programmatically using the [`FILE_FLAG_BACKUP_SEMANTICS`](https://docs.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-createfilea) flag.

The privilege is assigned by default to members of the **Backup Operators** and **Administrators** local groups. Because it is a token privilege, it may appear as `Disabled` in the current token and must be explicitly enabled before use.

> [!NOTE]
> The complementary write-side privilege is `SeRestorePrivilege`. The two are usually held together (e.g. by Backup Operators members) but are evaluated independently by the kernel.

## Practice

### Check & enable

If `SeBackupPrivilege` appears as `Disabled`, it can be enabled using the [SeBackupPrivilegeCmdLets](https://github.com/giuliano108/SeBackupPrivilege/tree/master/SeBackupPrivilegeCmdLets/bin/Debug) PowerShell module:

```powershell
Import-Module .\SeBackupPrivilegeUtils.dll
Import-Module .\SeBackupPrivilegeCmdLets.dll

Get-SeBackupPrivilege  # confirm current state
Set-SeBackupPrivilege  # enable it
Get-SeBackupPrivilege  # verify
```

### Copy any protected file

With the privilege enabled, `Copy-FileSeBackupPrivilege` (from [SeBackupPrivilegeCmdLets](https://github.com/giuliano108/SeBackupPrivilege)) reads any file regardless of its ACL:

```powershell
Copy-FileSeBackupPrivilege "$PATH_TO_FILE" "$OUTPUT_FILE"
```

> [!TIP]
> Interesting targets include SSH private keys, configuration files with embedded credentials, and any file protected by a restrictive DACL.

### Dump SAM & SYSTEM

`SeBackupPrivilege` allows saving the SAM and SYSTEM registry hives via `reg save`, regardless of their ACLs. Refer to [SAM & LSA secrets](../../../../ad/movement/credentials/dumping/sam-and-lsa-secrets.md) for the full methodology.

### Dump NTDS.dit

`SeBackupPrivilege` also allows reading `NTDS.dit` directly via backup semantics or after exposing it through a Volume Shadow Copy. Refer to [NTDS secrets](../../../../ad/movement/credentials/dumping/ntds.md) for the full methodology.

## Resources

[https://github.com/giuliano108/SeBackupPrivilege](https://github.com/giuliano108/SeBackupPrivilege)

[https://github.com/mpgn/BackupOperatorToDA](https://github.com/mpgn/BackupOperatorToDA)

[https://github.com/improsec/BackupOperatorToolkit](https://github.com/improsec/BackupOperatorToolkit)

[https://github.com/gtworek/Priv2Admin](https://github.com/gtworek/Priv2Admin)

[https://www.hackingarticles.in/windows-privilege-escalation-sebackupprivilege/](https://www.hackingarticles.in/windows-privilege-escalation-sebackupprivilege/)
