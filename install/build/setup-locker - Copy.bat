@ECHO OFF
REM
REM setup-locker.bat
REM Derek Yuen <derekyuen@locision.com>, Gilbert Zhong <gilbertzhong@locision.com>
REM December 2016
REM
REM setup-locker.bat
REM  * Expects 1 parameter (REQUIRES SIM CARD ICCID)
REM  * NOTE: DO NOT SCAN 2D CODE ON BOTTOM RIGHT CORNER
REM  * ERROR CHECKING - IF SCAN begins with http* -> alert user to rescan

REM
REM [] START: setup-locker.bat %1%
REM     -> VALIDATE %1% AS SIMCARD ICCID
REM        -> USE %1% TO DETERMINE SITENAME BY FINDING FILE OF SAME NAME IN \Dropbox\locker-admin\LOCKER\<SITENAME>\SIMCARD ICCID
REM        -> GET CONFIG FROM %HOMEPATH%\Dropbox\LOCKER\*\SIMCARD ICCID
REM        -> EXAMPLE RETURN: "\Dropbox\locker-admin\LOCKER\test-locker-foshan\SIMCARD ICCID"
REM     IF SIMCARD ICCID IS UFO ("\Dropbox\locker-admin\LOCKER\UFO") then build machine as NON-PRODUCTION (no locker cloud registration)
REM
REM if %1 is NUL then display error msg "need to run setup-locker.bat <SCAN SIM CARD BARCODE>" and exit 1
REM IF [%1]==[] (
REM     ECHO setup-locker.bat REQUIRES 4G SIM CARD SCAN OF ICCID
REM     EXIT /B -1
REM )

REM
REM [] FIGURE OUT WHAT MACHINE WE ARE BUILDING
REM
REM   else store %1 as SIMBARCODE
REM if 'LOCKERNAME = grep %SIMBARCODE% %HOMEPATH%\Dropbox\LOCKER\_locker-site-names.txt' is null,
REM   locker-not-found
REM  else echo "building locker %LOCKERNAME%"
REM

ECHO "IT'S A BEAUTIFUL DAY TO BUILD A LOCKER, LET'S HAVE SOME FUN!"
ECHO "BUILDING LOCKER: <SITENAME>"
ECHO "SIM ICCID: %1%"
echo "TYPE: <standard36, standard72, standard711>"


REM ======== SETUP COMPUTER + ENVIRONMENT
REM
REM [] SET ENVIRONMENT VARIABLES
REM
REM  SET SITENAME=%1%
SET SITENAME=test-locker-hk03
SET HOME=%SYSTEMDRIVE%%HOMEPATH%
SET TOOLS=%HOME%\Dropbox\locker-admin\tools
SET LOCKERINSTALL=%HOME%\Dropbox\locker-admin\install
SET LOCKERDRIVERS=%LOCKERINSTALL%\_drivers
SET LOCKERADMIN=%HOME%\Dropbox\locker-admin\LOCKER\%SITENAME%
SET LOCKERCFG=locker.properties
REM just in case ...
SET LOG=E:\LOGS
SET LOGS=E:\LOGS
SET SETUPLOGS=%LOGS%\locker-setup

date /t > %SETUPLOGS%\deploy-start-time
time /t >> %SETUPLOGS%\deploy-start-time

REM [] WHOAMI
rem for /F "tokens=1,2" %%i in ('qwinsta /server:%COMPUTERNAME% ^| findstr "console"') do set tempVar=%%j
whoami

REM
REM GET AND SET COMPUTER NAME
REM

REM
REM [] GET SYSTEM SOFTWARE AND HARDWARE INVENTORY
REM


REM
REM [] GET MAC ADDRESS FOR CLOUD REGISTRATION
REM    REQUIRES: ALL NETWORK PORT MAC ADDRESS (INCLUDING WIRELESS)
REM    WARNING: MUST GET NETWORK MAC ADDRESS *BEFORE* DISABLE WIRELESS INTERFACES
REM
cd %LOCKERADMIN%\config\
mkdir tmp
mklink getmac-copy.bat %LOCKERINSTALL%\build\getmac-copy.bat
mklink combine-locker-properties.bat %LOCKERINSTALL%\build\combine-locker-properties.bat
CALL combine-locker-properties.bat
move locker.properties.part1 tmp
move locker.properties.part2 tmp


REM [] DISABLE WIRELESS INTERFACE
netsh interface set interface name="Wireless Network Connection" admin=DISABLED
devcon disable BTH*
svchost -k bthsvcs
net stop bthserv
REG add "HKLM\SYSTEM\CurrentControlSet\services\bthserv" /v Start /t REG_DWORD /d 4 /f

REM
REM [] MAKE SOME DIRECTORIES
REM
mkdir c:\temp >NUL
mkdir c:\wim >NUL
mkdir e:\logs\locker-build\ >NUL
mkdir e:\images\archive >NUL

REM
REM [] INSTALL DRIVERS
REM
REM [][] PRINTER
REM CALL 0-setup-env.bat
REM CALL install-printer.bat
REM RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 path-to-inf\infname.inf
%LOCKERDRIVERS%\printer\Windows81Driver\RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 %LOCKERDRIVERS%\printer\Windows81Driver\POS88EN.inf
%LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--device=USB\VID_0483&PID_5720&REV_0100"

%LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--inf=%LOCKERDRIVERS%\printer\SPRT_Printer.inf"

REM [][] SCANNER
%LOCKERDRIVERS%\scanner\udp_and_vcom_drv211Setup\udp_and_vcom_drv.2.1.1.Setup.exe /S

ping 127.0.0.1 -n 10

REM [] APPLY ESSENTIAL UPDATES
REM [] INSTALL SPECIFIC UPDATES TO FIX WINDOWS UPDATE PROBLEMS
REM SEE https://www.develves.net/blogs/asd/2016-08-15-windows-7-updates-take-forever/
REM ORDER: FIRST->3020369, SECOND->3172605
REM https://support.microsoft.com/en-us/kb/3020369
REM https://support.microsoft.com/en-us/kb/3172605
wusa.exe %LOCKERINSTALL%\_pkg\Windows6.1-KB3020369-x86.msu /quiet /norestart
wusa.exe %LOCKERINSTALL%\_pkg\Windows6.1-KB3172605-x86.msu /quiet /norestart

REM [] LIST UPDATES
wmic qfe list brief /format:texttablewsys > %LOGS%/locker-install/post-deploy-updates.txt

ping 127.0.0.1 -n 10 

REM [] ADD USER
REM %TOOLS%\hstart.exe  /elevate /uac add-kiosk-user.bat
start /wait net localgroup kiosk-group /add
start /wait net user /add kiosk locision123 /active:yes /comment:"kiosk" /fullname:"kiosk" /passwordchg:no
start /wait net localgroup "kiosk-group" "kiosk" /add
REM [] auto create user profile (super quick, super dirty!)
runas /user:kiosk locision123 "cmd /c dir"

REM [] Install JRE
start /wait %LOCKERINSTALL%\_pkg\jre-8u111-windows-i586.exe INSTALLCFG=%SYSTEMDRIVE%%HOMEPATH%\Dropbox\locker-admin\install\_pkg\jre-install.properties /L e:\logs\locker-setup\jre-install.log
ping -n 20 127.0.0.1
D:\Java\jre\bin\Java -version
setx JAVA_HOME=D:\java\jre
setx PATH "%PATH%;D:\java\jre\bin;%SYSTEMDRIVE%\%HOMEPATH%\Dropbox\locker-admin\tools"

REM [] INSTALL MICROSOFT .NET 4.6.2
REM [][] CHECK
rem reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /t REG_DWORD /f Release
REM [][] INSTALL
start /wait "%LOCKERINSTALL%\_pkg\Microsoft .NET Framework 4.6.2 (Offline Installer) for Windows 7 SP1.exe" /showfinalerror /norestart /passive /CEIPconsent

ping -n 20 127.0.0.1

REM Install Microsoft Security Essentials
"%LOCKERINSTALL%\_pkg\MicrosoftSecurityEssentialsInstallWindows 7-32-bit-EN.exe" /s /q /o /runwgacheck

ping -n 20 127.0.0.1


REM [] INSTALL BLUETOOTH TOOLS
start /wait %LOCKERINSTALL%\_pkg\BluetoothCLTools.exe /silent

REM [] INSTALL POWERSHELL3
start /wait wusa.exe %LOCKERINSTALL%\_pkg\_updates\Windows6.1-KB2506143-x86-WMF3.msu /quiet /norestart

ping -n 15 127.0.0.1

REM [] INSTALL POWERSHELL4
start /wait wusa.exe %LOCKERINSTALL%\_pkg\_updates\Windows6.1-KB2819745-x86-MultiPkg-WMF4 /quiet /norestart

ping -n 15 127.0.0.1

REM [] INSTALL POWERSHELL4
start /wait wusa.exe %LOCKERINSTALL%\_pkg\_updates\Win7-KB3134760-x86.msu /quiet /norestart

REM [] INSTALL CHOCOLATEY
@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"


REM [] LOCKERLIFE ENVIRONMENT SETUP
mklink d:\status %LOCKERADMIN%\config\status
xcopy /s /F /Y %LOCKERINSTALL%\kioskServer d:\
xcopy /s /F /Y %LOCKERINSTALL%\Locker-Console d:\
xcopy /s /F /Y %LOCKERINSTALL%\locker-libs d:\
xcopy /s /F /Y %LOCKERINSTALL%\Locker-Slider d:\
xcopy /s /F /Y %LOCKERINSTALL%\*.jar d:\
REM mklink d:\run.bat %LOCKERINSTALL%\run.bat
mklink "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\run-production.bat" %LOCKERINSTALL%\run.bat

REM Fetch java dependencies, place into locker-libs
REM first fetch pkglist
REM curl ...
REM grep for URL, then fetch each file
REM curl | grep..
REM curl

REM [] LOCKDOWN KIOSK USER


REM [] GROUP POLICY CHECK
REM    Our group policy is applied to groups, not directly to users
REM    Good to double check from perspective of user 
REM    Verify the RSoP 
REM    (RSoP = Resultant Set of Policy)
rem gpresult /user kiosk

REM APPLY KIOSK GROUP POLICY
rem gpupdate

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

REM [] INSTALL REQUIRED PACKAGES
choco install notepadplusplus.install -y
choco install 7zip -y
choco install sysinternals -y
choco install putty -y
choco install curl -y
choco install vim -y
choco install wget -y
choco install winscp -y
choco install nssm -y
choco install pswindowsupdate -y
choco install boxstarter.common -y
choco install boxstarter.winconfig -y
choco install speccy -y
choco install gow -y
choco install carbon -y
choco install clink -y
choco install jq -y
choco install rsync -y
choco install which -y
choco install procdump -y
choco install teraterm -y
rem choco install handle -y

REM [] SETUP CAMERA
REM

REM []

REM [] HIDE BOOTING
REM
bcdedit /set quietboot on
bcdedit /set bootux disabled

REM [] SET CPU CORES USED TO BOOT SYSTEM AND CPU PARKING
bcdedit /set numproc 2

REM [] CUT DOWN BOOT OS SELECTION TIMEOUT (default: 30 seconds!!)
REM bcdedit

REM [] Make all boot settings permanent (see msconfig.exe -> boot tab)

REM [] DISABLE BOOTING INTO RECOVERY MODE
REM    UNDO: bcdedit /deletevalue {current} bootstatuspolicy
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

REM [] APPLY TOUCHSCREEN SETTINGS

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
net stop uxsms

REM [] CLASSIC THEME
rundll32.exe %SystemRoot%\system32\shell32.dll,Control_RunDLL %SystemRoot%\system32\desk.cpl desk,@Themes /Action:OpenTheme /file:"C:\Windows\Resources\Ease of Access Themes\classic.theme"

REM [] DISABLE WINDOWS UPDATE
REM $WUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
REM $WUSettings
REM $WUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings

REM
REM NotificationLevel  :
REM     0 = Not configured;
REM     1 = Disabled;
REM     2 = Notify before download;
REM     3 = Notify before installation;
REM     4 = Scheduled installation;
REM

REM $WUSettings.NotificationLevel=1
REM $WUSettings.save()

REM [] DISABLE BINGSEARCH
Disable-BingSearch
Disable-GameBarTips
Update-Help

Set-TaskBarOptions -Lock -Size small -Verbose

REM
REM [] REGISTER ME FOR LOCKER CLOUD!
REM    REMINDER: TRAP if not error then go next
CALL %LOCKERINSTALL%\build\register-locker.bat

REM ******
REM
REM [] INSTALL SCANNER.JAR AS SERVICE
CALL %LOCKERINSTALL%\build\new-service-scanner.bat

REM
REM [] INSTALL KIOSKSERVER AS SERVICE
CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat

REM
REM [] INSTALL DATA-COLLECTION.JAR AS SERVICE
CALL %LOCKERINSTALL%\build\new-service-datacollection.bat

REM
REM [] INSTALL CORE.JAR AS SERVICE
CALL %LOCKERINSTALL%\build\new-service-core.bat

REM [] add locker-admin, tools, LOCKER, install links to favorites
REM XXMKLINK.EXE "%userprofile%\Links\locker-admin.lnk" "C:%HOMEPATH\Dropbox\locker-admin"


REM [] CLEANUP
del "%Public%\Desktop\*.lnk"
del "%ALLUSERSPROFILE%\Desktop\*.lnk"

REM %LOCKERINSTALL%\Win7BootUpdaterCmd2.exe 

REM
ECHO "ALL DONE! REBOOTING"
date /t > %SETUPLOGS%\deploy-end-time
time /t >> %SETUPLOGS%\deploy-end-time
REM shutdown /r /t 3
