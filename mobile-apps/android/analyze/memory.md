# Find sensitive data in memory

## Theory
When the application manipulates data such as authentication information, it is loaded into memory. Given the criticality of this data, it must be unloaded from memory once the application has finished using it.

## Practical
1. Find **Process Name** (not Identifier)
```bash
frida-ps -Uai
 PID  Name                     Identifier                               
----  -----------------------  -----------------------------------------
2755  Google                   com.google.android.googlequicksearchbox  
5285  <Process Name>           com.application             
```
2. Launch **fridump** tool and **dump** data
```bash
# -U : USB
# -s : running strings on all files, could be long => create dump/strings.txt file

python3 fridump.py -U -s "Process Name" 

        ______    _     _
        |  ___|  (_)   | |
        | |_ _ __ _  __| |_   _ _ __ ___  _ __
        |  _| '__| |/ _` | | | | '_ ` _ \| '_ \
        | | | |  | | (_| | |_| | | | | | | |_) |
        \_| |_|  |_|\__,_|\__,_|_| |_| |_| .__/
                                         | |
                                         |_|
        
Current Directory: /opt/tools/fridump
Output directory is set to: /opt/tools/fridump/dump
Creating directory...
Starting Memory dump...
Oops, memory access violation!-------------------------------] 6.62% Complete
Oops, memory access violation!-------------------------------] 14.86% Complete
Oops, memory access violation!#------------------------------] 39.58% Complete
Progress: [##################################################] 99.38% Complete
Running strings on all files:
Progress: [##########----------------------------------------] 19.14% Complete
```
3. Search specific patterns

* Passwords / Secrets / Authentification keys / Cookies 
=> Cleartext passwords/secrets? 
=> could you reuse authentifcation methods (apikeys, cookies) ?

```bash
# cat dump/strings.txt | grep -ai "password"     
OAuth2RessourceOwnerPasswordClient
getNewTokenWithUserAndPassword
newPassword
```

### Known problems
```bash
DEBUG:unable to connect to remote frida-server: closed
```
Relaunch frida server
```bash
//connect to phone
host$ adb shell

//superuser
phone$ su

//find frida server pid
phone# ps -A | grep -i frida
shell         <PID>  8731  135800   4524 do_sys_poll         0 S frida-server

//kill server
phone# kill -9 <PID>

//Launch frida-server
phone# ./data/local/tmp/frida-server &
[1] 8907
```
