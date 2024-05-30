# Find sensitive data inside backup
## Theory
Backup analysis can reveal sensitive data.
It is important to compare the files present in the following steps:
* files present in the backup of the application _before_ using it
* files present in the backup of the application _after_ using it with a simple user account
* files in the backup of the application _after_ using it with a privileged account

## Practical 
### Create backups (.ab)
> Note : AppIdentifier could be found using ```frida-ps -Uia``` 

Install your app and create backup
```bash
adb backup -f vanilla.ab -shared <AppIdentifier>
//Now unlock your device and confirm the backup operation...
```
Open the app, connect to your simple user, play with it and create backup
```bash
adb backup -f backup_user.ab -shared <AppIdentifier>
//Now unlock your device and confirm the backup operation...
```
Uninstall the app, install the app again and connect with your privilege account and create backup
```bash
adb backup -f backup_admin.ab -shared <AppIdentifier>
//Now unlock your device and confirm the backup operation...
```
### Convert backups (.tar) & Extract
Convert .ab files into .tar
```bash
dd if=vanilla.ab bs=1 skip=24 | python -c "import zlib,sys;sys.stdout.write(zlib.decompress(sys.stdin.read()))" > vanilla.tar
dd if=backup_user.ab bs=1 skip=24 | python -c "import zlib,sys;sys.stdout.write(zlib.decompress(sys.stdin.read()))" > backup_user.tar
dd if=backup_admin.ab bs=1 skip=24 | python -c "import zlib,sys;sys.stdout.write(zlib.decompress(sys.stdin.read()))" > backup_admin.tar
```
Extract .tar backup
```bash
mkdir vanilla && tar xvf vanilla.tar -C vanilla
mkdir backup_user && tar xvf backup_user.tar -C backup_user
mkdir backup_admin && tar xvf backup_admin.tar -C backup_admin
```
### Compare
```bash
diff -r -q ./vanilla ./backup_user
diff -r -q ./vanilla ./backup_admin
```
Check that no sensitive information (API key, secret, etc) is present in the added files.  
