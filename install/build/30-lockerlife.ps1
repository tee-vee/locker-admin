# Derek Yuen <derekyuen@locision.com>
# 
# December 2016

@echo off

echo ====================================================
echo          Start Locker Build Process - STAGE 3
echo ====================================================
# build.cmd debug -- build debug version.
title "LOCKER DEPLOYMENT - STAGE 3"

# add user
ECHO "ADD KIOSK USER"
## %TOOLS%\hstart.exe /elevate /uac add-kiosk-user.bat
& net localgroup kiosk-group /add
& net user /add kiosk locision123 /active:yes /comment:"kiosk" /fullname:"kiosk" /passwordchg:no
& net localgroup "kiosk-group" "kiosk" /add


# [] auto create user profile (super quick, super dirty!)
ECHO "%~n0 Create kiosk user profile"
psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir
psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir

# psexec -u kiosk to use bginfo to change background to black

# SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

#get locker-libs

# set autologon to kiosk user

# symlink \Users\kiosk\...\startup items\run.bat->dropbox\locker-shared\production\run.bat 
# symlink D:\run.bat->dropbox\locker-shared\production\run.bat 

# create finish-locker-setup.ps1 on kiosk\desktop, reboot

#$WUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
#$WUSettings
#$WUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
#
#REM
#REM NotificationLevel  :
#REM     0 = Not configured;
#REM     1 = Disabled;
#REM     2 = Notify before download;
#REM     3 = Notify before installation;
#REM     4 = Scheduled installation;
#REM
#
#$WUSettings.NotificationLevel=1
#$WUSettings.save()
#
#REM [] DISABLE BINGSEARCH
#Disable-BingSearch
#Disable-GameBarTips
#Update-Help

