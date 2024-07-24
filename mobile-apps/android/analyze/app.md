# Find sensitive data in the app

## Theory
Android source code could display sensitive data which could permit a malicious user to anthenticate to the app (apikey), steal credentials (hardcoded credentials), find environment variables (production, preproduction), find sensitive backup.

## Practical
Find sensitive data
```bash
grep -ie "\([a-z0-9]\+\)\?apikey\([ ]\)*[=:]\([ ]\)*['\"]\?\([a-z0-9/=+]\)\{1,128\}['\"]\?" -r . -o
for file in $(find .); do echo "============= Strings in $file" && strings $file | grep -iE "(authtoken|token|auth|apikey|passwd|password|secret)" -w --color=auto;done
```
Use common software such as nuclei after unpacking, converting, decompiling your APK (see **APK transform** sheet)
```bash
nuclei -t /root/nuclei-templates/file/ -u $PWD/ -c 500 -o $PWD/$1.nuclei_vulns.txt
```

