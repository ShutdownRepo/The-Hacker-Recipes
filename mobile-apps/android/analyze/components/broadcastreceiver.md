# Broadcast receivers
## Theory
Broadcast receivers are registered for specific events to occur. When the event occurs, the receiver gets invoked and performs tasks, such as showing a message to the user. What we can do with broadcast receivers is up to the creativity of the developer, as a lot of stuff can be carried out with them.

Different broadcasts :
* System Events
* Custom Broadcasts

## Practical
### Detect
* Drozer allows to detect broadcast receivers but doesn't show `action's name`:
```bash
dz> run app.broadcast.info -a com.application
Package: com.application
  io.invertase.firebase.messaging.ReactNativeFirebaseMessagingReceiver
    Permission: com.google.android.c2dm.permission.SEND
  com.google.firebase.iid.FirebaseInstanceIdReceiver
    Permission: com.google.android.c2dm.permission.SEND
  org.matomo.sdk.extra.InstallReferrerReceiver
    Permission: null
```
* AndroidManifest.xml shows everything:
```bash
<receiver android:exported="true" android:name="io.invertase.firebase.messaging.ReactNativeFirebaseMessagingReceiver" android:permission="com.google.android.c2dm.permission.SEND">
            <intent-filter>
                <action android:name="com.google.android.c2dm.intent.RECEIVE"/>
            </intent-filter>
        </receiver>
``` 
### Exploit
Run the BR on Activity Manager (AM) :
```bash
//Use your app, launch the following command : (Application is crashed in my case)

am broadcast -a com.google.android.c2dm.intent.RECEIVE                                                                                                                                                  
//Broadcasting: Intent { act=com.google.android.c2dm.intent.RECEIVE flg=0x400000 }
//Broadcast completed: result=500
```

## References
{% embed url="https://resources.infosecinstitute.com/topic/android-hacking-security-part-3-exploiting-broadcast-receivers/" %}
