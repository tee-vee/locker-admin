:: Derek Yuen <derekyuen@locision.com>
:: setenv.cmd -- call me maybe?
:: January 2017

@echo off

:: setup work environment
echo.
echo "%~n0 setup work environment ..."
setx baseurl http://lockerlife.hk/deploy
setx _tmp c:\temp

SET LOCKERCFG=locker.properties

set _tmp=C:\temp
set HOME=%USERPROFILE%
set KIOSKHOME=C:\Users\kiosk
set LOCKERBASE=%USERPROFILE%\Dropbox\locker-admin
set TOOLS=%LOCKERBASE%\tools
SET LOCKERTOOLS=%LOCKERBASE%\tools
SET LOCKERINSTALL=%LOCKERBASE%\install
SET LOCKERDRIVERS=%LOCKERINSTALL%\_drivers
SET LOCKERADMIN=%LOCKERBASE%\LOCKER\%SITENAME%
SET LOG=E:\LOGS
SET LOGS=E:\LOGS
set images=e:\images
set archiveimages=e:\images\archive

SET SETUPLOGS="%LOGS%\locker-setup"

SET DROPBOXSTATUS=

:: Set path of Reg.exe and other exe's
set REGEXE="%SystemRoot%\System32\REG.exe"
set tar="%ProgramFiles%\Gow\bin\tar.exe"
set git="%ProgramFiles%\Git\cmd\Git.exe"
set bitsadmin=%SystemRoot%\System32\bitsadmin.exe
set hstart=%SystemRoot%\System32\hstart.exe
set ps=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe


:: use dropbox if psosible
if exist "%USERPROFILE%\Dropbox\locker-admin\tools\hstart.exe" (
    set hstart=%USERPROFILE%\Dropbox\locker-admin\tools\hstart.exe
    echo "%~n0: Build environment condition = GOOD"
    set DROPBOXSTATUS="OK"
) else (
    echo.
    echo "%~n0: Downloading hstart"
    REM ## %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/hstart.exe' 'C:\temp\hstart.exe';}"
    set hstart=c:\temp\hstart.exe
    echo "using temp hstart"
    echo "%~n0: Build environment condition = POOR"

)

:: Find Start Menu
For /f "tokens=3*" %%G in ('REG QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v "Start Menu" ^|Find "REG_"') do Call Set _startmenu=%%H

Echo %_startmenu%

c:
mkdir %_tmp% c:\temp e:\logs e:\logs\locker-build e:\images e:\images\archive
c: & cd %_tmp%

echo.

set _setenv=0
echo "%~n0: Setup work environment ... done"
echo.

