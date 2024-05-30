# Find sensitive data in cache

## Theory
When users type in input fields, the software automatically suggests data. This feature can be very useful for messaging apps. However, the keyboard cache may disclose sensitive information when the user selects an input field that takes this type of information.

The `android:inputType` field is used to evaluate the security of the cache regarding sensitive information.

A password field needs to be completed with `textPassword` or `textNoSuggestions` value.

## Practical
After unpacking application, search for android:inputType field relative to password tag.
```bash
grep -rain "android:inputType" .
```
android:inputType="**textPassword**" or "**textNoSuggestions**" protect user input.

## References
{% embed url="https://mobile-security.gitbook.io/mobile-security-testing-guide/android-testing-guide/0x05d-testing-data-storage" %}
{% embed url="https://developer.android.com/reference/android/text/InputType.html" %}
