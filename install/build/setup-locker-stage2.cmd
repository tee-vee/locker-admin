:: Derek Yuen <derekyuen@locision.com>, Gilbert Zhong <gilbertzhong@locision.com>
:: setup-locker.bat
:: December 2016

@echo off

echo ====================================================
echo          Start Locker Build Process - STAGE 2
echo ====================================================
:: build.cmd debug -- build debug version.
title "LOCKER DEPLOYMENT - STAGE 2"

:: --------------------------------------------------------------------------------------------
:: Setup work environment
:: --------------------------------------------------------------------------------------------
echo.
echo "%~n0 setup work environment ..."
echo.
set bitsadmin=%WINDIR%\system32\bitsadmin.exe
set _tmp=C:\temp
set baseurl=http://lockerlife.hk/deploy

:: --------------------------------------------------------------------------------------------
:: get environment variables
:: --------------------------------------------------------------------------------------------
:: call me maybe?
if not defined _setenv (
    start "BitsAdmin Service Init" %bitsadmin% /reset
    %bitsadmin% /transfer "getenv" %baseurl%/setenv.cmd %_tmp%\setenv.cmd
    cd %_tmp% & call %_tmp%\setenv.cmd

)

:: --------------------------------------------------------------------------------------------
:: SIM ICCID
:: --------------------------------------------------------------------------------------------
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
cd %LOCKERBASE%\LOCKER
dir /b /s | findstr %1%

SET SIMICCID=%1
FOR %%i IN ("%SIMICCID%") DO (
    echo.
    ECHO filedrive=%%~di
    ECHO filepath=%%~pi
    ECHO filename=%%~ni
    ECHO fileextension=%%~xi
)

REM if %1 is NUL then display error msg "need to run setup-locker.bat <SCAN SIM CARD BARCODE>" and exit 1
REM IF [%1]==[] (
REM     ECHO setup-locker.bat REQUIRES 4G SIM CARD SCAN OF ICCID
REM     EXIT /B -1
REM )

:: --------------------------------------------------------------------------------------------
REM [] FIGURE OUT WHAT MACHINE WE ARE BUILDING
:: --------------------------------------------------------------------------------------------
REM   else store %1 as SIMBARCODE
REM if 'LOCKERNAME = grep %SIMBARCODE% %HOMEPATH%\Dropbox\LOCKER\_locker-site-names.txt' is null,
REM   locker-not-found
REM  else echo "building locker %LOCKERNAME%"


:: --------------------------------------------------------------------------------------------
:: --------------------------------------------------------------------------------------------
echo.
ECHO "IT'S A BEAUTIFUL DAY TO BUILD A LOCKER, LET'S HAVE SOME FUN!"
ECHO "BUILDING LOCKER: <SITENAME>"
REM ECHO "SIM ICCID: %1"
echo "TYPE: <standard36, standard72, standard711>"


:: --------------------------------------------------------------------------------------------
REM [] SET ENVIRONMENT VARIABLES
:: --------------------------------------------------------------------------------------------
REM
REM  SET SITENAME=%1%
SET SITENAME=test-locker-hk03
REM ## SET TOOLS=%USERPROFILE%\Dropbox\locker-admin\tools
REM ## SET LOCKERINSTALL=%USERPROFILE%\Dropbox\locker-admin\install
REM ## SET LOCKERDRIVERS=%LOCKERINSTALL%\_drivers
REM ## SET LOCKERADMIN=%USERPROFILE%\Dropbox\locker-admin\LOCKER\%SITENAME%
REM ## SET LOCKERCFG=locker.properties
REM ## SET TMP=C:\temp

date /t > %SETUPLOGS%\deploy-start-time
time /t >> %SETUPLOGS%\deploy-start-time

:: --------------------------------------------------------------------------------------------
REM [] PRE-REQ
:: --------------------------------------------------------------------------------------------
ECHO "PRE-REQUISITES SETUP"

:: first, suppress errors
if "%suppress_errors%"=="false" (
    %REGEXE% add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Windows" /v ErrorMode /t REG_DWORD /d 0 /f >nul 2>&1
    %REGEXE% add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 0 /f >nul 2>&1
) else (
    %REGEXE% add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Windows" /v ErrorMode /t REG_DWORD /d 2 /f >nul 2>&1
    %REGEXE% add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f >nul 2>&1
)

:: start /wait %LOCKERINSTALL%\_pkg\gow.exe /S
copy /Y %LOCKERTOOLS%\nssm.exe %WINDIR%\System32

:: --------------------------------------------------------------------------------------------
REM [] WHOAMI
:: --------------------------------------------------------------------------------------------
rem for /F "tokens=1,2" %%i in ('qwinsta /server:%COMPUTERNAME% ^| findstr "console"') do set tempVar=%%j
whoami


:: --------------------------------------------------------------------------------------------
REM GET AND SET COMPUTER NAME
:: --------------------------------------------------------------------------------------------
REM
ECHO "SET COMPUTER NAME"

:: --------------------------------------------------------------------------------------------
REM [] GET SYSTEM SOFTWARE AND HARDWARE INVENTORY
:: --------------------------------------------------------------------------------------------
echo.
ECHO "GET COMPUTER SYSTEM AND SOFTWARE INVENTORY"

:: --------------------------------------------------------------------------------------------
:: get MAC address for cloud registration
:: --------------------------------------------------------------------------------------------
::    REQUIRES: ALL NETWORK PORT MAC ADDRESS (INCLUDING WIRELESS)
::    WARNING: MUST GET NETWORK MAC ADDRESS *BEFORE* DISABLE WIRELESS INTERFACES
echo.
echo "GET MAC ADDRESS FOR CLOUD REGISTRATION"
cd %LOCKERADMIN%\config\
mkdir %_tmp%
mklink getmac-copy.bat %LOCKERINSTALL%\build\getmac-copy.bat
mklink combine-locker-properties.bat %LOCKERINSTALL%\build\combine-locker-properties.bat
CALL combine-locker-properties.bat
move locker.properties.part1 %_tmp%
move locker.properties.part2 %_tmp%


:: --------------------------------------------------------------------------------------------
REM [] DISABLE WIRELESS INTERFACE
:: --------------------------------------------------------------------------------------------
echo.
ECHO "DISABLE WIRELESS INTERFACE"
%WINDIR%\System32\netsh.exe interface set interface name="Wireless Network Connection" admin=DISABLED
devcon disable BTH*
svchost -k bthsvcs
%WINDIR%\System32\net.exe stop bthserv
%REGEXE% add "HKLM\SYSTEM\CurrentControlSet\services\bthserv" /v Start /t REG_DWORD /d 4 /f

:: --------------------------------------------------------------------------------------------
REM [] INSTALL DRIVERS
:: --------------------------------------------------------------------------------------------
REM
ECHO "INSTALL DRIVERS"

:: --------------------------------------------------------------------------------------------
REM INSTALL PRINTER DRIVERS
:: --------------------------------------------------------------------------------------------
ECHO " INSTALL PRINTER DRIVERS"
REM CALL 0-setup-env.bat
REM CALL install-printer.bat
REM RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 path-to-inf\infname.inf
wmic printer list status
%LOCKERDRIVERS%\printer\Windows81Driver\RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 %LOCKERDRIVERS%\printer\Windows81Driver\POS88EN.inf
%LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--device=USB\VID_0483&PID_5720&REV_0100"

%LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--inf=%LOCKERDRIVERS%\printer\SPRT_Printer.inf"

:: Print a test page to one or more printers
REM ## for /f "tokens=1-4 delims=," %i in (%Printer.txt%) do cscript prnctrl.vbs -t -b \\%PrintServer%\%i

:: --------------------------------------------------------------------------------------------
REM INSTALL SCANNER DRIVER
:: --------------------------------------------------------------------------------------------
echo.
ECHO "INSTALL SCANNER DRIVER"
%hstart% /nouac /runas /wait "%LOCKERDRIVERS%\scanner\udp_and_vcom_drv211Setup\udp_and_vcom_drv.2.1.1.Setup.exe /S"

ping 127.0.0.1 -n 10

:: --------------------------------------------------------------------------------------------
REM [] APPLY ESSENTIAL UPDATES
REM     INSTALL SPECIFIC UPDATES TO FIX WINDOWS UPDATE PROBLEMS
REM     SEE https://www.develves.net/blogs/asd/2016-08-15-windows-7-updates-take-forever/
REM     ORDER: FIRST->3020369, SECOND->3172605
REM         https://support.microsoft.com/en-us/kb/3020369
REM         https://support.microsoft.com/en-us/kb/3172605
:: --------------------------------------------------------------------------------------------
echo.
ECHO "APPLY WINDOWS UPDATES"
REM ## wusa.exe %TMP%\Windows6.1-KB3020369-x86.msu /quiet /norestart
REM ## wusa.exe %TMP%\Windows6.1-KB3172605-x86.msu /quiet /norestart
%hstart% /nouac /delay=2 /runas /wait "%WINDIR%\System32\wusa.exe %LOCKERINSTALL%\Windows6.1-KB3020369-x86.msu /quiet /norestart"
%hstart% /nouac /delay=2 /runas /wait "%WINDIR%\System32\wusa.exe %LOCKERINSTALL%\_pkg\Windows6.1-KB3172605-x86.msu /quiet /norestart"
echo.

:: --------------------------------------------------------------------------------------------
REM [] LIST UPDATES
:: --------------------------------------------------------------------------------------------
echo.
ECHO "WINDOWS INVENTORY CHECK"
%hstart% /nouac /runas "%WINDIR%\System32\Wbem\wmic.exe qfe list brief /format:texttablewsys > %LOGS%\locker-install\post-deploy-updates.txt"

ping 127.0.0.1 -n 10

:: --------------------------------------------------------------------------------------------
REM [] Install JRE
:: --------------------------------------------------------------------------------------------
echo.
ECHO "INSTALL JAVA"
%hstart% /D="C:\temp" /nouac /delay=2 /runas /wait "%LOCKERINSTALL%\_pkg\jre-8u111-windows-i586.exe INSTALLCFG=%LOCKERINSTALL%\_pkg\jre-install.properties /L %SETUPLOGS%\jre-install.log"
REM ## start /wait %TMP%\jre-8u111-windows-i586.exe INSTALLCFG=%TMP%\jre-install.properties /L %SETUPLOGS%\jre-install.log
ping -n 20 127.0.0.1
D:\Java\jre\bin\Java -version
REM ## setx JAVA_HOME=D:\java\jre
REM setx PATH "%PATH%;D:\java\jre\bin;%SYSTEMDRIVE%\%HOMEPATH%\Dropbox\locker-admin\tools"

:: --------------------------------------------------------------------------------------------
:: [] INSTALL MICROSOFT .NET 4.6.2
:: --------------------------------------------------------------------------------------------
echo.
ECHO "INSTALL DOT NET 4.6.2"
:: [][] CHECK & INSTALL
%REGEXE% query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /t REG_DWORD /f Release
if Errorlevel 1 (
    :: dot Net framework not installed
    REM ## %TMP%\MicrosoftDotNETFramework462OfflineInstallerForWindows7SP1.exe /passive /norestart
    %hstart% /nouac /delay=2 /runas /wait "%LOCKERINSTALL%\_pkg\Microsoft .NET Framework 4.6.2 (Offline Installer) for Windows 7 SP1.exe /passive /norestart"
)

ping -n 15 127.0.0.1

:: --------------------------------------------------------------------------------------------
:: Install Microsoft Security Essentials
:: --------------------------------------------------------------------------------------------
echo.
ECHO "INSTALL MICROSOFT SECURITY ESSENTIALS"

cd %PROGRAMFILES% & cd "Windows Defender"
if not exist "%PROGRAMFILES%\Windows Defender\MpCmdRun.exe" (
    REM ## "%LOCKERINSTALL%\_pkg\MicrosoftSecurityEssentialsInstallWindows 7-32-bit-EN.exe" /s /q /o /runwgacheck
    REM ## %hstart% /nouac /delay=1 /runas /wait "%LOCKERINSTALL%\_pkg\MicrosoftSecurityEssentialsInstallWindows7-32bit-EN.exe /s /q /o /runwgacheck"
) else (
    %windir%\System32\sc.exe start MsMpSvc
    %hstart% /d="%PROGRAMFILES%\Windows Defender" /nouac /runas "MpCmdRun.exe –SignatureUpdate"
)

ping -n 10 127.0.0.1

:: --------------------------------------------------------------------------------------------
REM [] INSTALL BLUETOOTH TOOLS
:: --------------------------------------------------------------------------------------------
echo.
%hstart% /nouac /runas /wait "%LOCKERINSTALL%\_pkg\BluetoothCLTools.exe /silent"

:: --------------------------------------------------------------------------------------------
REM [] INSTALL POWERSHELL3
:: --------------------------------------------------------------------------------------------
echo.
ECHO "INSTALL POWERSHELL 3"
%hstart% /nouac /runas /wait "%WINDIR%\System32\wusa.exe %LOCKERINSTALL%\_pkg\Windows6.1-KB2506143-x86-WMF3.msu /quiet /norestart"
REM ## start /wait wusa.exe %TMP%\Windows6.1-KB2506143-x86-WMF3.msu /quiet /norestart

ping -n 15 127.0.0.1

:: --------------------------------------------------------------------------------------------
REM [] INSTALL POWERSHELL4
:: --------------------------------------------------------------------------------------------
echo.
ECHO "INSTALL POWERSHELL 4"
%hstart% /nouac /runas /wait "%WINDIR%\System32\wusa.exe %LOCKERINSTALL%\_pkg\Windows6.1-KB2819745-x86-MultiPkg-WMF4 /quiet /norestart"
REM ## start /wait wusa.exe %TMP%\Windows6.1-KB2819745-x86-MultiPkg-WMF4 /quiet /norestart

ping -n 15 127.0.0.1

:: --------------------------------------------------------------------------------------------
REM [] INSTALL POWERSHELL5
:: --------------------------------------------------------------------------------------------
echo.
ECHO "INSTALL POWERSHELL 5"
%hstart% /nouac /runas /wait "%WINDIR%\System32\wusa.exe %LOCKERINSTALL%\_pkg\Win7-KB3134760-x86.msu /quiet /norestart"
:: start /wait wusa.exe %TMP%\Win7-KB3134760-x86.msu /quiet /norestart


REM [] LOCKERLIFE ENVIRONMENT SETUP
ECHO "STAGE2: LOCKERLIFE ENVIRONMENT SETUP"
mklink d:\status %LOCKERADMIN%\config\status
copy /v /Y %LOCKERINSTALL%\kioskServer d:\
copy /v /Y %LOCKERINSTALL%\Locker-Console d:\
copy /v /Y %LOCKERINSTALL%\locker-libs d:\
copy /v /Y %LOCKERINSTALL%\Locker-Slider d:\
copy /v /Y %LOCKERINSTALL%\*.jar d:\
REM mklink d:\run.bat %LOCKERINSTALL%\run.bat
%hstart% /runas /nouac "cmd /c mklink %KIOSKHOME%\AppData\Roaming\Microsoft\Windows\STARTM~1\Programs\Startup\run.bat %LOCKERINSTALL%\run.bat"

REM Fetch java dependencies, place into locker-libs
REM first fetch pkglist
REM curl ...
REM grep for URL, then fetch each file
REM curl | grep..
REM curl

:: --------------------------------------------------------------------------------------------
:: [] GROUP POLICY CHECK
ECHO "GROUP POLICY"
REM    Our group policy is applied to groups, not directly to users
REM    Good to double check from perspective of user
REM    Verify the RSoP
REM    (RSoP = Resultant Set of Policy)
%windir%\System32\gpresult /r /user kiosk
%hstart% /runas "cmd /c copy %LOCKERINSTALL%\_gpo\export\production-gpo.zip %WINDIR%\System32"

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

:: --------------------------------------------------------------------------------------------
:: [] INSTALL REQUIRED PACKAGES
choco install sysinternals -y
choco install speccy -y
choco install procdump -y

:: [] SETUP CAMERA

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

:: --------------------------------------------------------------------------------------------
REM [] DISABLE BOOTING INTO RECOVERY MODE
REM    UNDO: bcdedit /deletevalue {current} bootstatuspolicy
bcdedit /set {default} recoveryenabled No
bcdedit /set {default} bootstatuspolicy ignoreallfailures

:: --------------------------------------------------------------------------------------------
REM [] KILL VISUAL EFFECTS
ECHO "KILL VISUAL EFFECTS"
sc stop uxsms

:: --------------------------------------------------------------------------------------------
REM Adjust for Best Performance:
REM
REM [HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects]
REM "VisualFXSetting"=dword:00000002"

:: --------------------------------------------------------------------------------------------
REM [] MAKE SURE COMPUTER DOES NOT SLEEP. EVER.
REM
ECHO "APPLY COMPUTER POWER SETTINGS"
powercfg -change -standby-timeout-ac 0
powercfg -h off

:: --------------------------------------------------------------------------------------------
REM [] APPLY TOUCHSCREEN SETTINGS
ECHO "CALIBRATE TOUCHSCREEN"

:: --------------------------------------------------------------------------------------------
REM [] DISABLE HIBERNATE
REM

:: --------------------------------------------------------------------------------------------
REM [] DISABLE FILE SHARING
net stop lanmanserver

:: --------------------------------------------------------------------------------------------
:: [] DISABLE WINDOWS SEARCH
:: change disabled to auto to reenable
sc config WSearch start= disabled


:: --------------------------------------------------------------------------------------------
REM [] Set Autologon
REM
ECHO "SETUP AUTOLOGON"
autologon /accepteula kiosk \ locision123

:: --------------------------------------------------------------------------------------------
REM [] DISABLE AERO
ECHO "DISABLE AERO"
net stop uxsms

:: --------------------------------------------------------------------------------------------
REM [] CLASSIC THEME
echo.
ECHO "CLASSIC THEME"
sc config themes start= disabled
net stop themes
rundll32.exe %WINDIR%\system32\shell32.dll,Control_RunDLL %WINDIR%\system32\desk.cpl desk,@Themes /Action:OpenTheme /file:"C:\Windows\Resources\Ease of Access Themes\classic.theme"

:: --------------------------------------------------------------------------------------------
REM [] DISABLE WINDOWS UPDATE
echo.
ECHO "DISABLE WINDOWS UPDATE"
%REGEXE% add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /t REG_DWORD /v NoWindowsUpdate /d 1 /f
%ps% -executionpolicy bypass -file %LOCKERINSTALL%\build\setup-windowsupdate.ps1
echo.

REM
REM [] REGISTER ME FOR LOCKER CLOUD!
REM    REMINDER: TRAP if not error then go next
REM ## ECHO "%~n0 REGISTER LOCKER CLOUD"
REM ## CALL %LOCKERINSTALL%\build\register-locker.bat
REM ## CALL %TMP%\register-locker.bat

:: --------------------------------------------------------------------------------------------
echo.
ECHO "%~n0 INSTALL SERVICES"
REM [] INSTALL SCANNER.JAR AS SERVICE
CALL %LOCKERINSTALL%\build\new-service-scanner.bat
REM ## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-scanner.bat

REM
REM [] INSTALL KIOSKSERVER AS SERVICE
CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat
REM ## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-kioskserver.bat

REM
REM [] INSTALL DATA-COLLECTION.JAR AS SERVICE
CALL %LOCKERINSTALL%\build\new-service-datacollection.bat
REM ## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-datacollection.bat

REM
REM [] INSTALL CORE.JAR AS SERVICE
CALL %LOCKERINSTALL%\build\new-service-core.bat
REM ## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-core.bat

:: --------------------------------------------------------------------------------------------
REM [] add locker-admin, tools, LOCKER, install links to favorites
XXMKLINK.EXE %userprofile%\Links\locker-admin.lnk %LOCKERBASE%
XXMKLINK.EXE %userprofile%\Links\locker-tools.lnk %LOCKERTOOLS%

:: --------------------------------------------------------------------------------------------
:: set scheduled tasks
:: Examples: https://technet.microsoft.com/en-us/library/bb490996.aspx
:: --------------------------------------------------------------------------------------------
:: To schedule a command that runs every hour at five minutes past the hour
:: The following command schedules the MyApp program to run hourly beginning at five minutes past midnight.
:: Because the /mo parameter is omitted, the command uses the default value for the hourly schedule, which is every (1) hour. 
:: If this command is issued after 12:05 A.M., the program will not run until the next day.
REM ## schtasks /create /sc hourly /st 00:05:00 /tn "My App" /tr c:\apps\myapp.exe

:: To schedule a command that runs every five hours
:: The following command schedules the MyApp program to run every five hours beginning on the first day of March 2001.
:: It uses the /mo parameter to specify the interval and the /sd parameter to specify the start date.
:: Because the command does not specify a start time, the current time is used as the start time.
REM ## schtasks /create /sc hourly /mo 5 /sd 03/01/2001 /tn "My App" /tr c:\apps\myapp.exe

:: To schedule a task that runs every day
:: The following example schedules the MyApp program to run once a day, every day, at 8:00 A.M. until December 31, 2001.
:: Because it omits the /mo parameter, the default interval of 1 is used to run the command every day.
REM ## schtasks /create /tn "My App" /tr c:\apps\myapp.exe /sc daily /st 08:00:00 /ed 12/31/2001


:: --------------------------------------------------------------------------------------------
echo.
echo "%~n0 SET WORKGROUP NAME"
%windir%\System32\Wbem\wmic computersystem where name="%computername%" call joindomainorworkgroup name=”LOCKERLIFE.HK”

:: --------------------------------------------------------------------------------------------
echo.
echo "%~n0 SET SYSTEM TIME"
%windir%\System32\tzutil.exe /s "China Standard Time"
%windir%\System32\w32tm /config /syncfromflags:manual /manualpeerlist:"stdtime.gov.hk 0.asia.pool.ntp.org 3.asia.pool.ntp.org"

echo.
echo "%~n0 clean up desktop"
:: powershell cleanup script (also executes function-specific cmdlets)
del /f /s /q "%KIOSKHOME%\Desktop\*.lnk"
del /f /s /q "%KIOSKHOME%\Desktop\desktop.ini"
del /f /s /q "%KIOSKHOME%\Recent\*.*"
del /f /s /q "%USERPROFILE%\Desktop\*.lnk"
del /f /s /q "%USERPROFILE%\Desktop\desktop.ini"
del /f /s /q "%USERPROFILE%\Recent\*.*"
del /f /s /q "%USERPROFILE%\Downloads\*.*"
rm -fr "%USERPROFILE%\Favorites\*"
del /f /s /q "%Public%\Desktop\*.lnk"
del /f /s /q "%Public%\Desktop\desktop.ini"
del /f /s /q "%Public%\Recent\*.*"
del /f /s /q "%ALLUSERSPROFILE%\Desktop\*.lnk"
del /f /s /q "%ALLUSERSPROFILE%\Desktop\desktop.ini"
del /f /s /q "%ALLUSERSPROFILE%\Recent\*.*"
start %windir%\System32\cleanmgr.exe /verylowdisk
REM ## del /f /s /q %_tmp%\

:: setup kiosk env

:: BACKUP Local Group Policy
cd %WINDIR%\System32
%tar% -cvf GroupPolicy-Backup.tar GroupPolicy
%tar% -cvf GroupPolicyUsers-Backup.tar GroupPolicyUsers
copy /V /Y %LOCKERINSTALL%\build\complete-locker-setup.cmd %KIOSKHOME%\Desktop

:: --------------------------------------------------------------------------------------------
:: update boot screen
:: --------------------------------------------------------------------------------------------
%LOCKERTOOLS%\BootUpdCmd20.exe %LOCKERINSTALL%\build\lockerlife-boot-custom.bs7

ECHO "%~n0 CLEANUP"
echo.
echo "%~n0 DISABLE GUEST USER"
%windir%\System32\net user guest /active:no
%LOCKERINSTALL%\build\disable-admin.cmd
%LOCKERINSTALL%\build\enable-UAC.cmd

:: --------------------------------------------------------------------------------------------
:: unset setenv
set _setenv=

:: --------------------------------------------------------------------------------------------
%SYSTEMROOT%\System32\WinSAT.exe -v forgethistory
%SYSTEMROOT%\System32\dism.exe /english /online /disable-feature /featurename:WindowsGadgetPlatform



:: --------------------------------------------------------------------------------------------
cd %LOCKERINSTALL%\build

ECHO "ALL DONE! REBOOTING"
date /t > %SETUPLOGS%\deploy-end-time
time /t >> %SETUPLOGS%\deploy-end-time
%windir%\System32\timeout /t 30
REM shutdown /r /t 3
