# Magisk

## Theory

> Magisk is a suite of open source software for customizing Android, supporting devices higher than Android 6.0.\
> Some highlight features:
>
> * **MagiskSU**: Provide root access for applications
> * **Magisk Modules**: Modify read-only partitions by installing modules
> * **MagiskBoot**: The most complete tool for unpacking and repacking Android boot images
> * **Zygisk**: Run code in every Android applications' processes
>
> ([Magisk GitHub repo](https://github.com/topjohnwu/Magisk))

## Practical

### Install Magisk

1. Download latest APK release at [https://github.com/topjohnwu/Magisk/releases](https://github.com/topjohnwu/Magisk/releases)
2. Install package on the phone

```bash
adb install "Magisk-vXX.Y.apk"
```

### Install Magisk modules

1. Download ZIP module (e.g. [MagiskTrustUserCerts](https://github.com/NVISOsecurity/MagiskTrustUserCerts/releases), [MagiskHide](https://github.com/HuskyDG/MagiskHide/releases/tag/v1.10.3), ...)
2. Push the archive on the phone

```bash
adb push "module.zip" "/sdcard/Download"
```

Once the archive is on the phone's storage, the module can be installed and enabled within the Magisk app

* Magisk App --> Modules --> Install from storage --> Reboot
* After reboot, enable the package

## References

{% embed url="https://github.com/topjohnwu/Magisk" %}

{% embed url="https://github.com/NVISOsecurity/MagiskTrustUserCerts/releases" %}
