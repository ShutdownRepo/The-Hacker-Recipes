# MobSF

## Theory

> Mobile-Security-Framework is a powerful automated tool which can perform penetration test for 
> (Android/iOS/Windows). It can perform static, dynamic analysis and malware analysis for the
> above mobile applications. MobSF can also provide dynamic runtime testing with a powerful 
> security scanner CapFuzz.
> [(source)](https://vxrl.medium.com/advanced-usage-of-mobsf-and-genymotion-aa0c8cde637)

## Environment
Genymotion is the preferred dynamic analysis environment that can be set up. A Genymotion Android VM must be run before starting MobSF.

## Practical
### Installation
Clone repository and setup the platform.
```bash
git clone https://github.com/MobSF/Mobile-Security-Framework-MobSF.git
cd Mobile-Security-Framework-MobSF
./setup.sh
```
### Usage

#### Static Analysis
1. Download your favorite apk on [apkpure](https://apkpure.com)
2. Launch MobSF
```bash
./run.sh 127.0.0.1:8000
```
3. Button "Upload & Analyse"
4. Start analysis

#### Dynamic Analysis
1. Download your favorite apk on [apkpure](https://apkpure.com)
2. Install Genymotion :
	1. Download [bin](https://www.genymotion.com/download/)
	2. Give permissions & launch 
	```bash
	chmod +x genymotion.bin & ./genymotion.bin
	```
	3. Add genymotion path to your path
	```bash
	PATH=$PATH:$(pwd) or PATH=$PATH:/opt/genymotion
	```
3. Launch Genymotion & create instance
	1. Create an account (use [emailinator](https://www.emailnator.com/) if you don't want to use your real email)
	2. Clic on "+" and select Android 7.0 and Above
	3. Keep setting on default
	4. Launch instance
4. Launch MobSF
	```bash
	./run.sh 127.0.0.1:8000
	```
5. Dynamic Analyzer => **MobSFy Android Runtime**
* Add IP of your Genymotion instance and port 5555 like ip:5555
* Connection should work (check run.sh outputs)
6. Dynamic Analyzer => **Start Dynamic Analyzer**

## References
{% embed url="https://mobsf.github.io/docs/#/installation" %}
{% embed url="https://vxrl.medium.com/advanced-usage-of-mobsf-and-genymotion-aa0c8cde637" %}


