# Burp Certificate Authority

## Theory

A proxy allows auditing communication between client & server on the fly.
Android devices trust only system Certificate Authorities by default. A trick consists of installing Burp CA inside phone's store using Magisk Always Trust User Certificates.
Main steps :
1. Extract BurpSuite CA
2. Transform Certificate
3. Push Certificate on the phone
4. (Install Magisk app, Magisk TrustUserCerts)
5. Allow Certificate on phone
6. Add Burp Proxy

## Practical

1. Extract Burp Certificate Autority from your Burp Instance (on host)
```bash
Burp => Proxy => Options => Export CA certificate => Certificate in DER format
```
```bash
$file cert.der
cert.der: data
```
2. Transform Certificate
```bash 
openssl x509 -inform DER -in cert.der -out cert.pem
```
```bash
$file cert.pem
cert.pem: PEM certificate
```
3. Push certificate on the phone
```bash
$ adb push cert.pem /sdcard/Download
```
4. Install and Enable Magisk / Magisk module TrustUserCerts
5. Search your certificate in your download folder, select it, give it a name and enable it
6. Add Burp Proxy on your phone

Note: Burp Proxy instance needs to listen on all interfaces i.e. this will enable other network users to use the proxy.

On Host :
* Burp => Proxy => Options => Proxy Listeners => Add
	* Bind to: port (ex 8080)
	* Check All Interfaces (it means *:8080)
* _Check that your listener is running_

On Phone :
```bash
 Wifi => preferences => manual proxy => (your ip instance with *:port)
 ```
 ## References
 {% embed url="https://pswalia2u.medium.com/install-burpsuites-or-any-ca-certificate-to-system-store-in-android-10-and-11-38e508a5541a" %}
