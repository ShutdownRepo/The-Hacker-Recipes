# Find sensitive data in logs
## Theory
Logging data increases the risk of exposure of that data and reduces system performance. Multiple public security incidents have occurred as a result of logging sensitive user data.
* Apps or system services should not log data provided from third-party apps that might include sensitive information.
* Apps must not log any Personally Identifiable Information (PII) as part of normal operation, unless it's absolutely necessary to provide the core functionality of the app.

## Practical
1. Grab application process identifier (PID)
* Using Frida-ps
```bash
#frida-ps -Uai                                                                 
  PID  Name                     Identifier                               
-----  -----------------------  -----------------------------------------
19804  Chrome                   com.android.chrome                       
<PID>  Application              <AppIdentifier>  
```
2. Filter logs with _grep_
```bash
$ adb logcat | grep <PID>
```
3. Check logs when :
* **Logging**
    => cleartext password?
    => cleartext API that lead to an authent?
    => session cookies that could be use for authent? 
    => verbosed error?

* **Creating an element** => SQL statement appeared?

## References

{% embed url="https://source.android.com/docs/security/best-practices/privacy" %}
