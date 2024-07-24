# Exported Services
## Theory
An exported service in Android is a service that can be accessed and interacted with by other applications besides the one that declares it. By default, services are not exported, meaning they are private to the application that owns them. However, when a service is exported, it becomes part of the public API of the application and can be called upon by other applications installed on the device.

## Practical
### Detect
* Drozer shows exported services
```bash
dz> run app.service.info -a com.application
Package: com.application
  com.google.android.gms.auth.api.signin.RevocationBoundService
    Permission: com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION
```
* AndroidManifest.xml shows exported services
```bash
 <service android:exported="true"
 android:name="com.google.android.gms.auth.api.signin.RevocationBoundService" 
 android:permission="com.google.android.gms.auth.api.signin.permission.REVOCATION_NOTIFICATION" 
 android:visibleToInstantApps="true"/>
```
### Exploit
Drozer could abuse exported services :
```bash
run app.service.send com.complication com.google.android.gms.auth.api.signin.RevocationBoundService --msg 1 2 3
```
