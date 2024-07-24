# Drozer
## Theory
> Drozer is the leading security testing framework for Android.
> Drozer allows you to search for security vulnerabilities in apps and devices by assuming the role of an app and > interacting with the Dalvik VM, other apps' IPC endpoints and the underlying OS.
> A Drozer server run on the host and a drozer Agent run on the phone.
> _FYI, Drozer is no longer maintained._
## Practical

### Run Drozer
**On host** launch Drozer server :
```bash
docker run -it fsecurelabs/drozer
#root
```
Add Drozer agent to your phone :
```bash
//Download last APK and install - https://github.com/WithSecureLabs/drozer/releases
adb install drozer.apk
```
**On Phone :** enable drozer agent by clicking on the app, select "YES" => _Agent on port 31415 of your phone is enable_
_Note : IPv4 of your phone is enable on Wifi => Your Network => Settings => More => IP Address_

**On host:** connect to the phone using following command line

```bash 
root@7951b36f9c40:/#drozer console connect --server <phone IP address>

Selecting <id> (Google Pixel 3a 10)

            ..                    ..:.
           ..o..                  .r..
            ..a..  . ....... .  ..nd
              ro..idsnemesisand..pr
              .otectorandroidsneme.
           .,sisandprotectorandroids+.
         ..nemesisandprotectorandroidsn:.
        .emesisandprotectorandroidsnemes..
      ..isandp,..,rotectorandro,..,idsnem.
      .isisandp..rotectorandroid..snemisis.
      ,andprotectorandroidsnemisisandprotec.
     .torandroidsnemesisandprotectorandroid.
     .snemisisandprotectorandroidsnemesisan:
     .dprotectorandroidsnemesisandprotector.

drozer Console (v2.4.4)
```

### Audit

Please go to the following links :

* Activities
* Broadcast receivers
* Content providers
* Services Exported

## References
{% embed url="https://hub.docker.com/r/fsecurelabs/drozer" %}
{% embed url="https://github.com/WithSecureLabs/drozer/wiki" %}
