# Activities

## Theory
In almost every Android application, developers expose activities without sufficient protections. Exposing activities can lead to various attacks. For example, an attacker or a malicious app installed on the same device, can call those exposed activities to invoke internal pages of the application. Calling internal pages puts the application at risk of phishing by manipulating users to enter details in the phishing app, as well as exposing a user to secret pages, such as admin panels or pages which should have been visible to paid/pro user only

Activity Manager allows to replay exposed activities (with proper action and category parameters).

## Practical
### Detect Exposed Activities
1. Drozer allows to see which activies are exposed.
```bash
dz> run app.activity.info -a com.application
Package: com.application
  com.application.appe.ActivityOne
    Permission: null
  com.application.appe.MainActivity
    Permission: null
```
2. Activities are exposed if :
* the activity component's `android:exported` value is set to `true` in the `AndroidManifest.xml` file
* or the activity component's has an `intent` section
```bash
 <activity android:configChanges="keyboardHidden|orientation" android:label="@string/app_name" android:launchMode="singleTask" android:name="com.application.appe.SplashActivity" android:screenOrientation="portrait" android:theme="@style/SplashScreenTheme">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
```
### Exploit Exposed Activites
1. Find which action and which category allows to exposed your activity (inside AndroidManifest.xml)
```bash
Action : android.intent.action.MAIN
Category : android.intent.category.LAUNCHER
```
2. Replay Activity via **Activity Manager** (AM)
```bash
#Could lead to a crash of the app, invoke NFC module on your phone, etc.
am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
```
## References
{% embed url="https://www.linkedin.com/pulse/hacking-android-apps-through-exposed-components-tal-melamed" %}


