:: Derek Yuen <derekyuen@locision.com>
:: 
:: December 2016

@echo off

echo ====================================================
echo          Start Locker Build Process - STAGE 1
echo ====================================================
:: build.cmd debug -- build debug version.
title "LOCKER DEPLOYMENT - STAGE 1"

:: [] ADD USER
ECHO "%~n0 ADD KIOSK USER"
REM %TOOLS%\hstart.exe /elevate /uac add-kiosk-user.bat
start /wait net localgroup kiosk-group /add
start /wait net user /add kiosk locision123 /active:yes /comment:"kiosk" /fullname:"kiosk" /passwordchg:no
start /wait net localgroup "kiosk-group" "kiosk" /add


:: [] auto create user profile (super quick, super dirty!)
ECHO "%~n0 Create kiosk user profile"
psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir
psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir

:: SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
