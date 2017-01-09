REM 
REM setup-locker.bat
REM Derek Yuen <derekyuen@locision.com>
REM December 2016
REM

REM
REM setup-locker.bat expects 1 parameter (scan the fucking SIM CARD BARCODE!)
REM

REM
REM [] GET START PARAMETERS - NEED TO SCAN
REM
REM if %1 is NUL then display error msg "need to run setup-locker.bat <SCAN SIM CARD BARCODE>" and exit 1

REM
REM [] FIGURE OUT WHAT MACHINE WE ARE BUILDING
REM
REM   else store %1 as SIMBARCODE
REM if 'LOCKERNAME = grep %SIMBARCODE% %HOMEPATH%\Dropbox\LOCKER\_locker-site-names.txt' is null, 
REM   locker-not-found
REM  else echo "building locker %LOCKERNAME%"
REM

echo "IT'S A BEAUTIFUL DAY TO BUILD A LOCKER, LET'S HAVE SOME FUN!"

REM
REM [] SET ENVIRONMENT VARIABLES
REM


REM [] WHOAMI
rem for /F "tokens=1,2" %%i in ('qwinsta /server:%COMPUTERNAME% ^| findstr "console"') do set tempVar=%%j
whoami

REM
REM GET AND SET COMPUTER NAME
REM

REM
REM [] GET SYSTEM INVENTORY
REM


REM
REM [] GET MAC ADDRESS FOR CLOUD REGISTRATION
REM
getmac -v | findstr Local*
getmac -v | findstr Wireless*
getmac -v | findstr Bluetooth*

REM
REM [] MAKE SOME DIRECTORIES
REM
mkdir c:\temp
mkdir e:\logs\locker-build\
mkdir e:\images\archive

REM
REM [] INSTALL DRIVERS
REM
REM

REM [] APPLY ESSENTIAL UPDATES

REM [] ADD USER
C:\Users\locker-build-test\Dropbox\locker-admin\tools\hstart.exe  /elevate /uac add-kiosk-user.bat 
REM net user /add kiosk * /active:yes /comment:"kiosk" /fullname:"kiosk" /passwordchg:no

REM [] Install JRE
jre-8u111-windows-i586.exe INSTALLCFG=%HOMEPATH%\Dropbox\locker-admin\install\_pkg\jre-install.properties.txt /L e:\logs\locker-setup\jre-install.log
C:\Java\jre\bin\Java -version

setx JAVA_HOME=C:\java\jre
setx path "%path%;c:\java\jre\bin;%HOMEPATH%\Dropbox\locker-admin\tools"

REM [] INSTALL MICROSOFT .NET 4.6.2 
REM [][] CHECK 
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /t REG_DWORD /f Release
REM [][] INSTALL
"Microsoft .NET Framework 4.6.2 (Offline Installer) for Windows 7 SP1.exe" /showfinalerror /norestart /passive /CEIPconsent

REM[] INSTALL NOTEPAD-PLUS-PLUS
msiexec /i "npp.7.2.1.Installer.exe" /passive /norestart

REM Install Microsoft Security Essentials
MicrosoftSecurityEssentialsInstallWindows 7-32-bit-EN.exe /s /q /o /runwgacheck


REM Fetch java dependencies, place into locker-libs
REM first fetch pkglist
curl ...
REM grep for URL, then fetch each file
curl | grep..
curl 

REM [] LOCKDOWN KIOSK USER
REM APPLY KIOSK GROUP POLICY
REM [] Windows Firewall
Netsh Advfirewall show allprofiles
NetSh Advfirewall set allrprofiles state on

REM QUERY FIREWALL RULES
netsh advfirewall firewall show rule name=all

netsh advfirewall set currentprofile logging filename "e:\logs\pfirewall.log"
netsh advfirewall firewall add rule name="Allow Java" dir=in action=allow program="D:\java\jre\java.exe"
netsh advfirewall firewall add rule name="Allow Kioskserver" dir=in action=allow program="D:\kioskserver\kioskserver.exe"
netsh advfirewall firewall set rule group="Remote Desktop" new enable=Yes
netsh advfirewall firewall add rule name="Open Port 23" dir=in action=allow protocol=TCP localport=23
netsh advfirewall firewall add rule name="Open Port 8080" dir=in action=allow protocol=TCP localport=8080
netsh advfirewall firewall add rule name="Open Port 8081" dir=in action=allow protocol=TCP localport=8081
netsh advfirewall firewall add rule name="Open Port 9012" dir=in action=allow protocol=TCP localport=9012
rem netsh advfirewall firewall delete rule name="Open Server Port 8080" protocol=tcp localport=8080
rem netsh advfirewall firewall delete rule name="Open Server Port 8081" protocol=tcp localport=8081
rem netsh advfirewall firewall delete rule name="Open Server Port 23" protocol=tcp localport=23


REM [] SETUP CAMERA
REM

REM [] CLEANUP

REM [] 

REM [] HIDE BOOTING 
REM
bcdedit /set quietboot on

REM [] CUT DOWN BOOT OS SELECTION TIMEOUT (default: 30 seconds!!)
bcdedit

REM [] Make all boot settings permanent (see msconfig.exe -> boot tab)

REM [] DISABLE BOOTING INTO RECOVERY MODE
REM
bcdedit /set {default} recoveryenabled No 
bcdedit /set {default} bootstatuspolicy ignoreallfailures

REM [] KILL VISUAL EFFECTS
sc stop uxsms
REM Adjust for Best Performance:
REM 
REM [HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects]
REM "VisualFXSetting"=dword:00000002"

REM [] MAKE SURE COMPUTER DOES NOT SLEEP. EVER.
REM
powercfg -change -standby-timeout-ac 0
powercfg -h off

REM [] DISABLE HIBERNATE
REM

REM [] DISABLE FILE SHARING
net stop lanmanserver

REM [] DISABLE WINDOWS SEARCH
REM change disabled to auto to reenable
sc config WSearch start= disabled


REM [] Set Autologon
REM
autologon kiosk \ locision123

REM [] DISABLE AERO
rem net stop uxsms

REM [] DISABLE WINDOWS UPDATE (again)
REM    - Windows Update already disabled through group policy
REM    - This is a backup measure

REM
REM [] INSTALL SCANNER.JAR AS SERVICE

REM
REM [] INSTALL KIOSKSERVER AS SERVICE

REM
REM [] INSTALL DATA-COLLECTION.JAR AS SERVICE

REM
REM [] INSTALL CORE.JAR AS SERVICE

