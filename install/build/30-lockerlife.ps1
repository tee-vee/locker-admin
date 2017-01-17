# Derek Yuen <derekyuen@locision.com>
#
# December 2016

# @echo off

WriteInfoHighlighted ====================================================
WriteInfoHighlighted          Start Locker Build Process - STAGE 3
WriteInfoHighlighted ====================================================
# build.cmd debug -- build debug version.
#title "LOCKER DEPLOYMENT - STAGE 3"


# --------------------------------------------------------------------------------------------
Write-Host "."
WriteInfoHighlighted "install services"
WriteInfoHighlighted"INSTALL SCANNER.JAR AS SERVICE"
#CALL %LOCKERINSTALL%\build\new-service-scanner.bat
#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-scanner.bat
Start-Process 'new-service-scanner.bat' -Verb runAs


Write-Host "."
WriteInfoHighlighted "INSTALL KIOSKSERVER AS SERVICE"
#CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat
#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-kioskserver.bat
Start-Process 'new-service-kioskserver.bat' -Verb runAs

Write-Host "."
WriteInfoHighlighted "INSTALL DATA-COLLECTION.JAR AS SERVICE"
#CALL %LOCKERINSTALL%\build\new-service-datacollection.bat
#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-datacollection.bat
Start-Process 'ew-service-datacollection.bat' -Verb runAs


Write-Host "."
WriteInfoHighlighted "INSTALL CORE.JAR AS SERVICE"
## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-core.bat
Start-Process 'new-service-core.bat' -Verb runAs


# add user
Write-Host "ADD KIOSK USER"
## %TOOLS%\hstart.exe /elevate /uac add-kiosk-user.bat
& "$Env:SystemRoot\System32\net.exe" localgroup kiosk-group /add
& "$Env:SystemRoot\System32\net.exe" user /add kiosk locision123 /active:yes /comment:"kiosk" /fullname:"kiosk" /passwordchg:no
& "$Env:SystemRoot\System32\net.exe" localgroup "kiosk-group" "kiosk" /add


# [] auto create user profile (super quick, super dirty!)
Write-Host "Create kiosk user profile"
& psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir
& psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir

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

# --------------------------------------------------------------------------------------------
Write-Host "Set Autologon"
WriteInfoHighlighted "SETUP AUTOLOGON"
Start-Process 'autologon.exe' -Verb runAs -ArgumentList '/accepteula kiosk \ locision123'
