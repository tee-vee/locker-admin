REM Teamviewer 8 Host Install Script
REM Cleanup old version and Skip Full version installs
REM also keeps current Teamviewer ID 
REM Cleans up old shortcuts from XP Vista and Windows 7 Desktops
REM Uses Corporate MSI installer
REM Deployed using SCCM 2007 R2, should work with others
REM 2012-2013 updated 2/15/2013
@echo off

REM Check for Teamviewer Full Version and Skip uninstall and install script
REM Checks against the current add/remove programs list
wmic /output:%temp%\InstallList.txt product get name,version
find /I /N "TeamViewer 8 (MSI Wrapper)" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer 8 Host" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO killTVService
find /I /N "TeamViewer 8" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer 7 (MSI Wrapper)" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer 7 Host" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO killTVService
find /I /N "TeamViewer 7" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer 6 (MSI Wrapper)" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer 6 Host" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO killTVService
find /I /N "TeamViewer 6" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer 5 (MSI Wrapper)" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer 5 (MSI)" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer 5 Host" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO killTVService
find /I /N "TeamViewer 5" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer 4 (MSI)" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram
find /I /N "TeamViewer Host 4" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO killTVService
find /I /N "TeamViewer 4" %temp%\InstallList.txt
if "%ERRORLEVEL%"=="0" GOTO endofprogram

REM Kill Teamviewer Services

:killTVService
    taskkill /f /t /im TeamViewer_Service.exe
    tasklist /FI "IMAGENAME eq TeamViewer_Service.exe" 2>NUL | find /I /N "TeamViewer_Service.exe">NUL
    if "%ERRORLEVEL%"=="0" GOTO killTVService

:killTVDesktop
    taskkill /f /t /im TeamViewer_Desktop.exe
    tasklist /FI "IMAGENAME eq TeamViewer_Desktop.exe" 2>NUL | find /I /N "TeamViewer_Desktop.exe">NUL
    if "%ERRORLEVEL%"=="0" GOTO killTVDesktop   

:killTeamViewer
    taskkill /f /t /im TeamViewer.exe
    tasklist /FI "IMAGENAME eq TeamViewer.exe" 2>NUL | find /I /N "TeamViewer.exe">NUL
    if "%ERRORLEVEL%"=="0" GOTO killTeamViewer      

:killtvw32
    taskkill /f /t /im tv_w32.exe
    tasklist /FI "IMAGENAME eq tv_w32.exe" 2>NUL | find /I /N "tv_w32.exe">NUL
    if "%ERRORLEVEL%"=="0" GOTO killtvw32       

:killtvx64
    taskkill /f /t /im tv_x64.exe
    tasklist /FI "IMAGENAME eq tv_x64.exe" 2>NUL | find /I /N "tv_x64.exe">NUL
    if "%ERRORLEVEL%"=="0" GOTO killtvx64   

REM Backup the current Teamviewer registry settings
IF EXIST "%ProgramFiles(x86)%" (
   reg export "HKLM\SOFTWARE\Wow6432Node\TeamViewer" %temp%\tv64backup.reg /y   
) ELSE (
   reg export "HKLM\SOFTWARE\TeamViewer"  %temp%\tv32backup.reg /y
)

REM Check for and remove older Teamviewer Shortcuts

REM Check and clean Vista and Win7 public desktop
    
    IF NOT EXIST C:\ProgramData\NUL GOTO NOVSPUB
    del /F /S /Q "C:\ProgramData\*Teamviewer*.lnk"

:NOVSPUB

REM Check and clean Vista and Win7 user desktops

    IF NOT EXIST c:\Users\NUL GOTO NOVSPROF
    del /F /S /Q "c:\Users\*Teamviewer*.lnk"
    GOTO NOXP

:NOVSPROF

REM cleanup XP user desktops

    del /F /S /Q "c:\Documents and Settings\*Teamviewer*.lnk"
    
:NOXP

REM Cleanup any previous versions of Teamviewer Host
REM To update Find the Product code and paste it to the top of the list and add the Remove line code
msiexec /x {EC2464BB-11A3-47D2-8A39-A184A13119D8} /qn REBOOT=ReallySuppress
msiexec /x {CA4DE7D2-24ED-4C0A-BBE7-B9FA80B518E1} /qn REBOOT=ReallySuppress
msiexec /x {A1BD6CB3-19A1-4E0E-8B19-A5B617D84E29} /qn REBOOT=ReallySuppress
msiexec /x {60396943-BCBA-44BA-AE26-657AE521A08F} /qn REBOOT=ReallySuppress
msiexec /x {F9E98720-0B97-4A9B-8B5B-C9BD3E957D4A} /qn REBOOT=ReallySuppress
msiexec /x {D0BAA8B3-B8DF-4B83-9BB5-12D0AEDE582D} /qn REBOOT=ReallySuppress
msiexec /x {13F931C0-7EBF-4A24-8787-FE2C8F46F3A7} /qn REBOOT=ReallySuppress
msiexec /x {A5811914-34F3-461E-8413-F1437B627CBB} /qn REBOOT=ReallySuppress
msiexec /x {DB34E701-663F-4E1E-8ADA-05B6348B420F} /qn REBOOT=ReallySuppress

REM Check for Manually Updated Teamviewer Host and Uninstall
wmic product where name="TeamViewer 8 Host (MSI Wrapper)" call uninstall
wmic product where name="TeamViewer 8 Host" call uninstall
wmic product where name="TeamViewer 7 Host (MSI Wrapper)" call uninstall
wmic product where name="TeamViewer 7 Host" call uninstall
wmic product where name="TeamViewer 6 Host (MSI Wrapper)" call uninstall
wmic product where name="TeamViewer 6 Host" call uninstall
wmic product where name="TeamViewer 5 Host (MSI Wrapper)" call uninstall
wmic product where name="TeamViewer 5 Host" call uninstall
wmic product where name="TeamViewer Host 4 (MSI)" call uninstall
wmic product where name="TeamViewer Host 4" call uninstall

REM Restore Teamviewer Registry Settings prior to install
IF EXIST "%ProgramFiles(x86)%" (
   reg import "%temp%\tv64backup.reg"   
) ELSE (
   reg import "%temp%\tv32backup.reg"
)

REM Silent Install Teamviewer

Start /wait msiexec.exe /qn /i TeamViewer_Host.msi REBOOT=ReallySuppress

REM Remove Desktop Shortcuts
del "%Public%\Desktop\TeamViewer 8 Host.lnk"
del "%ALLUSERSPROFILE%\Desktop\TeamViewer 8 Host.lnk"

:endofprogram

REM Return exit code to SCCM
exit /B %EXIT_CODE%
