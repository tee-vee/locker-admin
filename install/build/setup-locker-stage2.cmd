:: Derek Yuen <derekyuen@locision.com>, Gilbert Zhong <gilbertzhong@locision.com>
:: setup-locker.bat
:: December 2016

@echo off

echo ====================================================
echo          Start Locker Build Process - STAGE 2
echo ====================================================
:: build.cmd debug -- build debug version.
title "LOCKER DEPLOYMENT - STAGE 2"

::  * Expects 1 parameter (REQUIRES SIM CARD ICCID)
::  * NOTE: DO NOT SCAN 2D CODE ON BOTTOM RIGHT CORNER
::  * ERROR CHECKING - IF SCAN begins with http* -> alert user to rescan

:: [] START: setup-locker.bat %1%
::     -> VALIDATE %1% AS SIMCARD ICCID
::        -> USE %1% TO DETERMINE SITENAME BY FINDING FILE OF SAME NAME IN \Dropbox\locker-admin\LOCKER\<SITENAME>\SIMCARD ICCID
::        -> GET CONFIG FROM %HOMEPATH%\Dropbox\LOCKER\*\SIMCARD ICCID
::        -> EXAMPLE RETURN: "\Dropbox\locker-admin\LOCKER\test-locker-foshan\SIMCARD ICCID"
::     IF SIMCARD ICCID IS UFO ("\Dropbox\locker-admin\LOCKER\UFO") then build machine as NON-PRODUCTION (no locker cloud registration)

:: [] FIND SITENAME (use system global variable %SIMICCID% and %SITENAME%
:: maybe use it in path ?  i.e. %HOMEPATH%\Dropbox\locker-admin\LOCKER\%SITENAME%\config\%SIMICCID% ?
cd %SYSTEMDRIVE%%HOMEPATH%\Dropbox\LOCKER
dir /b /s | findstr %1%

SET SIMICCID=%1%
FOR %%i IN ("%SIMICCID%") DO (
ECHO filedrive=%%~di
ECHO filepath=%%~pi
ECHO filename=%%~ni
ECHO fileextension=%%~xi
)
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
REM ECHO "SIM ICCID: %1%"
echo "TYPE: <standard36, standard72, standard711>"


REM ======== SETUP COMPUTER + ENVIRONMENT
REM
REM [] SET ENVIRONMENT VARIABLES
REM
REM  SET SITENAME=%1%
SET SITENAME=test-locker-hk03
SET HOME=%SYSTEMDRIVE%%HOMEPATH%
SET KIOSKHOME=C:\Users\kiosk
SET TOOLS=%HOME%\Dropbox\locker-admin\tools
SET LOCKERINSTALL=%HOME%\Dropbox\locker-admin\install
SET LOCKERDRIVERS=%LOCKERINSTALL%\_drivers
SET LOCKERADMIN=%HOME%\Dropbox\locker-admin\LOCKER\%SITENAME%
SET LOCKERCFG=locker.properties
SET TMP=C:\temp
REM just in case ...
SET LOG=E:\LOGS
SET LOGS=E:\LOGS
SET SETUPLOGS=%LOGS%\locker-setup

date /t > %SETUPLOGS%\deploy-start-time
time /t >> %SETUPLOGS%\deploy-start-time

REM [] PRE-REQ
ECHO "PRE-REQUISITES SETUP"

:: first, suppress errors
if "%suppress_errors%"=="false" (
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Windows" /v ErrorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 0 /f >nul 2>&1
) else (
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Windows" /v ErrorMode /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f >nul 2>&1
)

::start /wait %LOCKERINSTALL%\_pkg\gow.exe /S
copy %TOOLS%\nssm.exe c:\windows\system32\

REM [] WHOAMI
rem for /F "tokens=1,2" %%i in ('qwinsta /server:%COMPUTERNAME% ^| findstr "console"') do set tempVar=%%j
whoami

REM
REM GET AND SET COMPUTER NAME
REM
ECHO "SET COMPUTER NAME"

REM
REM [] GET SYSTEM SOFTWARE AND HARDWARE INVENTORY
REM
ECHO "GET COMPUTER SYSTEM AND SOFTWARE INVENTORY"


REM
REM [] GET MAC ADDRESS FOR CLOUD REGISTRATION
REM    REQUIRES: ALL NETWORK PORT MAC ADDRESS (INCLUDING WIRELESS)
REM    WARNING: MUST GET NETWORK MAC ADDRESS *BEFORE* DISABLE WIRELESS INTERFACES
REM
ECHO "GET MAC ADDRESS FOR CLOUD REGISTRATION"
cd %LOCKERADMIN%\config\
mkdir tmp
mklink getmac-copy.bat %LOCKERINSTALL%\build\getmac-copy.bat
mklink combine-locker-properties.bat %LOCKERINSTALL%\build\combine-locker-properties.bat
CALL combine-locker-properties.bat
move locker.properties.part1 tmp
move locker.properties.part2 tmp


REM [] DISABLE WIRELESS INTERFACE
ECHO "DISABLE WIRELESS INTERFACE"
netsh interface set interface name="Wireless Network Connection" admin=DISABLED
devcon disable BTH*
svchost -k bthsvcs
net stop bthserv
REG add "HKLM\SYSTEM\CurrentControlSet\services\bthserv" /v Start /t REG_DWORD /d 4 /f

REM
REM [] MAKE SOME DIRECTORIES
REM
ECHO "MAKE DIRECTORIES"
mkdir c:\temp >NUL
mkdir c:\wim >NUL
mkdir e:\logs\locker-build\ >NUL
mkdir e:\images\archive >NUL

REM
REM [] INSTALL DRIVERS
REM
ECHO "INSTALL DRIVERS"
REM [][] PRINTER
ECHO " INSTALL PRINTER DRIVERS"
REM CALL 0-setup-env.bat
REM CALL install-printer.bat
REM RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 path-to-inf\infname.inf
%LOCKERDRIVERS%\printer\Windows81Driver\RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 %LOCKERDRIVERS%\printer\Windows81Driver\POS88EN.inf
%LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--device=USB\VID_0483&PID_5720&REV_0100"

%LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--inf=%LOCKERDRIVERS%\printer\SPRT_Printer.inf"

REM [][] SCANNER
ECHO "INSTALL SCANNER DRIVER"
%LOCKERDRIVERS%\scanner\udp_and_vcom_drv211Setup\udp_and_vcom_drv.2.1.1.Setup.exe /S

ping 127.0.0.1 -n 10

REM [] APPLY ESSENTIAL UPDATES
ECHO "APPLY WINDOWS UPDATES"

REM [] INSTALL SPECIFIC UPDATES TO FIX WINDOWS UPDATE PROBLEMS
REM SEE https://www.develves.net/blogs/asd/2016-08-15-windows-7-updates-take-forever/
REM ORDER: FIRST->3020369, SECOND->3172605
REM https://support.microsoft.com/en-us/kb/3020369
REM https://support.microsoft.com/en-us/kb/3172605
:: wusa.exe %LOCKERINSTALL%\_pkg\Windows6.1-KB3020369-x86.msu /quiet /norestart
:: wusa.exe %LOCKERINSTALL%\_pkg\Windows6.1-KB3172605-x86.msu /quiet /norestart
wusa.exe %TMP%\Windows6.1-KB3020369-x86.msu /quiet /norestart
wusa.exe %TMP%\Windows6.1-KB3172605-x86.msu /quiet /norestart

REM [] LIST UPDATES
ECHO "WINDOWS INVENTORY CHECK"
wmic qfe list brief /format:texttablewsys > %LOGS%/locker-install/post-deploy-updates.txt

ping 127.0.0.1 -n 10

REM [] ADD USER
:: ECHO "ADD KIOSK USER"
:: REM %TOOLS%\hstart.exe  /elevate /uac add-kiosk-user.bat
:: start /wait net localgroup kiosk-group /add
:: start /wait net user /add kiosk locision123 /active:yes /comment:"kiosk" /fullname:"kiosk" /passwordchg:no
:: start /wait net localgroup "kiosk-group" "kiosk" /add
:: REM [] auto create user profile (super quick, super dirty!)
:: ECHO "create kiosk user profile"
:: psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir

REM [] Install JRE
ECHO "INSTALL JAVA"
start /wait %LOCKERINSTALL%\_pkg\jre-8u111-windows-i586.exe INSTALLCFG=%LOCKERINSTALL%\_pkg\jre-install.properties /L %SETUPLOGS%\jre-install.log
start /wait %TMP%\jre-8u111-windows-i586.exe INSTALLCFG=%TMP%\jre-install.properties /L %SETUPLOGS%\jre-install.log
ping -n 20 127.0.0.1
D:\Java\jre\bin\Java -version
REM setx JAVA_HOME=D:\java\jre
REM setx PATH "%PATH%;D:\java\jre\bin;%SYSTEMDRIVE%\%HOMEPATH%\Dropbox\locker-admin\tools"

REM [] INSTALL MICROSOFT .NET 4.6.2
ECHO "INSTALL DOT NET 4.6.2"
REM [][] CHECK
REG query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /t REG_DWORD /f Release
REM [][] INSTALL
:: "%LOCKERINSTALL%\_pkg\Microsoft .NET Framework 4.6.2 (Offline Installer) for Windows 7 SP1.exe" /passive /norestart
%TMP%\MicrosoftDotNETFramework462OfflineInstallerForWindows7SP1.exe /passive /norestart

ping -n 30 127.0.0.1

REM Install Microsoft Security Essentials
ECHO "INSTALL MICROSOFT SECURITY ESSENTIALS"
:: "%LOCKERINSTALL%\_pkg\MicrosoftSecurityEssentialsInstallWindows 7-32-bit-EN.exe" /s /q /o /runwgacheck
%TMP%\MicrosoftSecurityEssentialsInstallWindows7-32bit-EN.exe /s /q /o /runwgacheck
"%ProgramFiles%\Windows Defender\MpCmdRun.exe" –signatureupdate

ping -n 20 127.0.0.1

:: ---------------------------
REM [] INSTALL BLUETOOTH TOOLS
start /wait %LOCKERINSTALL%\_pkg\BluetoothCLTools.exe /silent

REM [] INSTALL POWERSHELL3
ECHO "INSTALL POWERSHELL 3"
:: start /wait wusa.exe %LOCKERINSTALL%\_pkg\_updates\Windows6.1-KB2506143-x86-WMF3.msu /quiet /norestart
start /wait wusa.exe %TMP%\Windows6.1-KB2506143-x86-WMF3.msu /quiet /norestart

ping -n 15 127.0.0.1

REM [] INSTALL POWERSHELL4
ECHO "INSTALL POWERSHELL 4"
:: start /wait wusa.exe %LOCKERINSTALL%\_pkg\_updates\Windows6.1-KB2819745-x86-MultiPkg-WMF4 /quiet /norestart
start /wait wusa.exe %TMP%\Windows6.1-KB2819745-x86-MultiPkg-WMF4 /quiet /norestart

ping -n 15 127.0.0.1

REM [] INSTALL POWERSHELL5
ECHO "INSTALL POWERSHELL 5"
:: start /wait wusa.exe %LOCKERINSTALL%\_pkg\_updates\Win7-KB3134760-x86.msu /quiet /norestart
start /wait wusa.exe %TMP%\Win7-KB3134760-x86.msu /quiet /norestart


REM [] LOCKERLIFE ENVIRONMENT SETUP
ECHO "STAGE2: LOCKERLIFE ENVIRONMENT SETUP"
mklink d:\status %LOCKERADMIN%\config\status
copy /v /Y %LOCKERINSTALL%\kioskServer d:\
copy /v /Y %LOCKERINSTALL%\Locker-Console d:\
copy /v /Y %LOCKERINSTALL%\locker-libs d:\
copy /v /Y %LOCKERINSTALL%\Locker-Slider d:\
copy /v /Y %LOCKERINSTALL%\*.jar d:\
REM mklink d:\run.bat %LOCKERINSTALL%\run.bat
mklink %KIOSKHOME%\AppData\Roaming\Microsoft\Windows\STARTM~1\Programs\Startup\run-production.bat" %LOCKERINSTALL%\run.bat

REM Fetch java dependencies, place into locker-libs
REM first fetch pkglist
REM curl ...
REM grep for URL, then fetch each file
REM curl | grep..
REM curl

REM [] LOCKDOWN KIOSK USER
ECHO "LOCKDOWN KIOSK USER"

REM [] GROUP POLICY CHECK
ECHO "GROUP POLICY"
REM    Our group policy is applied to groups, not directly to users
REM    Good to double check from perspective of user
REM    Verify the RSoP
REM    (RSoP = Resultant Set of Policy)
rem gpresult /user kiosk

REM APPLY KIOSK GROUP POLICY
rem gpupdate

REM [] Windows Firewall
ECHO "LOCAL SETUP FIREWALL"
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
choco install sysinternals -y
choco install putty -y
choco install winscp -y
choco install pswindowsupdate -y
choco install speccy -y
choco install carbon -y
choco install procdump -y
choco install teraterm -y
rem choco install handle -y

REM [] SETUP CAMERA
REM

REM []

REM [] HIDE BOOTING
REM
ECHO "BOOT HARDENING"
:: bcdedit /set quietboot on
bcdedit /set bootux disabled

REM [] SET CPU CORES USED TO BOOT SYSTEM AND CPU PARKING
bcdedit /set numproc %NUMBER_OF_PROCESSORS% 

REM [] CUT DOWN BOOT OS SELECTION TIMEOUT (default: 30 seconds!!)
REM bcdedit

REM [] SHORTEN SHUTDOWN WAIT TIME
REM WaitToKillServiceTimeout
REM REG add "HKLM\SYSTEM\CurrentControlSet\Control" /v Start /t REG_DWORD /d 4 /f

REM [] Make all boot settings permanent (see msconfig.exe -> boot tab)

REM [] DISABLE BOOTING INTO RECOVERY MODE
REM    UNDO: bcdedit /deletevalue {current} bootstatuspolicy
bcdedit /set {default} recoveryenabled No
bcdedit /set {default} bootstatuspolicy ignoreallfailures

REM [] KILL VISUAL EFFECTS
ECHO "KILL VISUAL EFFECTS"
sc stop uxsms

REM Adjust for Best Performance:
REM
REM [HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects]
REM "VisualFXSetting"=dword:00000002"

REM [] MAKE SURE COMPUTER DOES NOT SLEEP. EVER.
REM
ECHO "APPLY COMPUTER POWER SETTINGS"
powercfg -change -standby-timeout-ac 0
powercfg -h off

REM [] APPLY TOUCHSCREEN SETTINGS
ECHO "CALIBRATE TOUCHSCREEN"

REM [] DISABLE HIBERNATE
REM

REM [] DISABLE FILE SHARING
net stop lanmanserver

REM [] DISABLE WINDOWS SEARCH
REM change disabled to auto to reenable
sc config WSearch start= disabled


REM [] Set Autologon
REM
ECHO "SETUP AUTOLOGON"
autologon /accepteula kiosk \ locision123

REM [] DISABLE AERO
ECHO "DISABLE AERO"
net stop uxsms

REM [] CLASSIC THEME
ECHO "CLASSIC THEME"
sc config themes start= disabled
net stop themes
rundll32.exe %SystemRoot%\system32\shell32.dll,Control_RunDLL %SystemRoot%\system32\desk.cpl desk,@Themes /Action:OpenTheme /file:"C:\Windows\Resources\Ease of Access Themes\classic.theme"

REM [] DISABLE WINDOWS UPDATE
ECHO "DISABLE WINDOWS UPDATE"
REM
REG add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /t REG_DWORD /v NoWindowsUpdate /d 1 /f
:: powershell -executionpolicy bypass -file %LOCKERINSTALL%\build\setup-windowsupdate.ps1
powershell -executionpolicy bypass -file %TMP%\setup-windowsupdate.ps1
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
REM Disable-BingSearch
REM Disable-GameBarTips
REM Update-Help

REM Set-TaskBarOptions -Lock -Size small -Verbose

REM
REM [] REGISTER ME FOR LOCKER CLOUD!
REM    REMINDER: TRAP if not error then go next
ECHO "%~n0 REGISTER LOCKER CLOUD"
:: CALL %LOCKERINSTALL%\build\register-locker.bat
:: CALL %TMP%\register-locker.bat

echo.
ECHO "%~n0 INSTALL SERVICES"
REM ******
REM
REM [] INSTALL SCANNER.JAR AS SERVICE
:: CALL %LOCKERINSTALL%\build\new-service-scanner.bat
CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-scanner.bat

REM
REM [] INSTALL KIOSKSERVER AS SERVICE
:: CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat
CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-kioskserver.bat

REM
REM [] INSTALL DATA-COLLECTION.JAR AS SERVICE
:: CALL %LOCKERINSTALL%\build\new-service-datacollection.bat
CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-datacollection.bat

REM
REM [] INSTALL CORE.JAR AS SERVICE
:: CALL %LOCKERINSTALL%\build\new-service-core.bat
CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-core.bat

REM [] add locker-admin, tools, LOCKER, install links to favorites
REM XXMKLINK.EXE "%userprofile%\Links\locker-admin.lnk" "C:%HOMEPATH\Dropbox\locker-admin"

echo.
echo "%~n0 SET WORKGROUP NAME"
wmic computersystem where name="%computername%" call joindomainorworkgroup name=”LOCKERLIFE.HK”

ECHO "%~n0 CLEANUP"
echo.
echo "%~n0 DISABLE GUEST USER"
net user guest /active:no
echo.
echo "%~n0 SET SYSTEM TIME"
tzutil.exe /s "China Standard Time"
w32tm /config /syncfromflags:manual /manualpeerlist:"stdtime.gov.hk 0.asia.pool.ntp.org 3.asia.pool.ntp.org"
echo.
echo "%~n0 clean up desktop"
:: powershell cleanup script (also executes function-specific cmdlets)
:: powershell update-help
del /f /s /q "C:\Users\kiosk\Desktop\*.lnk"
del /f /s /q "C:%HOMEPATH%\Desktop\*.lnk"
del /f /s /q "%Public%\Desktop\*.lnk"
del /f /s /q "%ALLUSERSPROFILE%\Desktop\*.lnk"
del /f /s /q c:\temp\*

:: setup kiosk env
copy /v %USERPROFILE%\Dropbox\locker-admin\install\build\complete-locker-setup.cmd %KIOSKHOME%\Desktop

:: update boot screen
%USERPROFILE%\Dropbox\locker-admin\tools\BootUpdCmd20.exe %USERPROFILE%\Dropbox\locker-admin\install\build\lockerlife-boot-custom.bs7

pushd %LOCKERINSTALL%\build

ECHO "ALL DONE! REBOOTING"
date /t > %SETUPLOGS%\deploy-end-time
time /t >> %SETUPLOGS%\deploy-end-time
timeout 30
REM shutdown /r /t 3
