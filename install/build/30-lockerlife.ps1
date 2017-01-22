# Derek Yuen <derekyuen@locision.com>
# December 2016

# 30-lockerlife - LockerLife Internal Configuration (Preparation for purple console screen)
# ** autologon as kiosk user after boot
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 30-lockerlife"


$basename = $MyInvocation.MyCommand.Name

# source DeploymentConfig
(New-Object Net.WebClient).DownloadString("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1") > C:\local\etc\99-DeploymentConfig.ps1
. C:\local\etc\99-DeploymentConfig.ps1

### ----- reload current shell elevated to administrator -> prepare for 01-bootstrap -> exec 01-bootstrap ----- ###
# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
  Write-Host "`n"
  Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
  Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
  Write-Host; exit
}

#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user AAICON Locision123 /active:yes' -NoNewWindow

# --------------------------------------------------------------------------------------------
Write-Host "."
WriteInfoHighlighted "install services"
WriteInfoHighlighted"INSTALL SCANNER.JAR AS SERVICE"
#CALL %LOCKERINSTALL%\build\new-service-scanner.bat
#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-scanner.bat
Start-Process 'new-service-scanner.bat' -Verb runAs -Wait

Write-Host "."
WriteInfoHighlighted "INSTALL KIOSKSERVER AS SERVICE"
#CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat
#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-kioskserver.bat
Start-Process 'new-service-kioskserver.bat' -Verb runAs -Wait

Write-Host "."
WriteInfoHighlighted "INSTALL DATA-COLLECTION.JAR AS SERVICE"
#CALL %LOCKERINSTALL%\build\new-service-datacollection.bat
#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-datacollection.bat
Start-Process 'ew-service-datacollection.bat' -Verb runAs -Wait


Write-Host "."
WriteInfoHighlighted "INSTALL CORE.JAR AS SERVICE"
## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-core.bat
Start-Process 'new-service-core.bat' -Verb runAs -Wait


# add user
Write-Host "."
Write-Host "ADD KIOSK USER"
Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup kiosk-group /add' -NoNewWindow -Verb runAs ; WriteInfo
Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no' -NoNewWindow
Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup "kiosk-group" "kiosk" /add' -NoNewWindow


# [] auto create user profile (super quick, super dirty!)
Write-Host "."
Write-Host "Create kiosk user profile"
Start-Process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir' -NoNewWindow -Wait
Start-process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir' -NoNewWindow

Start-process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c bginfo c:\local\etc\kiosk-production-black.bgi /silent /NOLICPROMPT /TIMER:0' -NoNewWindow
# psexec -u kiosk to use bginfo to change background to black


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


# --------------------------------------------------------------------------------------------
# set scheduled tasks
# Examples: https://technet.microsoft.com/en-us/library/bb490996.aspx
# --------------------------------------------------------------------------------------------
# To schedule a command that runs every hour at five minutes past the hour
# The following command schedules the MyApp program to run hourly beginning at five minutes past midnight.
# Because the /mo parameter is omitted, the command uses the default value for the hourly schedule, which is every (1) hour.
# If this command is issued after 12:05 A.M., the program will not run until the next day.
## schtasks /create /sc hourly /st 00:05:00 /tn "My App" /tr c:\apps\myapp.exe

# To schedule a command that runs every five hours
# The following command schedules the MyApp program to run every five hours beginning on the first day of March 2001.
# It uses the /mo parameter to specify the interval and the /sd parameter to specify the start date.
# Because the command does not specify a start time, the current time is used as the start time.
## schtasks /create /sc hourly /mo 5 /sd 03/01/2001 /tn "My App" /tr c:\apps\myapp.exe

# To schedule a task that runs every day
# The following example schedules the MyApp program to run once a day, every day, at 8:00 A.M. until December 31, 2001.
# Because it omits the /mo parameter, the default interval of 1 is used to run the command every day.
## schtasks /create /tn "My App" /tr c:\apps\myapp.exe /sc daily /st 08:00:00 /ed 12/31/2001


if (Test-PendingReboot) { Invoke-Reboot }

# --------------------------------------------------------------------------------------------
Write-Host "Set Autologon"
WriteInfoHighlighted "SETUP AUTOLOGON"
Start-Process 'autologon.exe' -Verb runAs -ArgumentList '/accepteula kiosk \ locision123'
