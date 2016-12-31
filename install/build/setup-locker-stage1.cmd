:: Derek Yuen <derekyuen@locision.com>
:: December 2016

@echo off
echo "stage1"
echo "stage1"
echo "stage1"
echo "stage1"

echo ====================================================
echo          Start Locker Build Process - STAGE 1
echo ====================================================
:: build.cmd debug -- build debug version.

:: [] ADD USER
ECHO "ADD KIOSK USER"
:: %TOOLS%\hstart.exe  /elevate /uac add-kiosk-user.bat
start /wait net localgroup kiosk-group /add
start /wait net user /add kiosk locision123 /active:yes /comment:"kiosk" /fullname:"kiosk" /passwordchg:no
start /wait net localgroup "kiosk-group" "kiosk" /add
:: [] auto create user profile (super quick, super dirty!)
ECHO "create kiosk user profile"
psexec -accepteula -nobanner -u kiosk -p locision123 -i cmd /c dir
psexec -accepteula -nobanner -u kiosk -p locision123 -i cmd /c dir
psexec -accepteula -nobanner -u kiosk -p locision123 -i cmd /c dir

:: SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin
