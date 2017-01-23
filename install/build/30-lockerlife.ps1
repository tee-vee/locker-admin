# Derek Yuen <derekyuen@locision.com>
# December 2016

# 30-lockerlife - LockerLife Internal Configuration (Preparation for purple console screen)
# ** autologon as kiosk user after boot
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 30-lockerlife"
$basename = Split-Path -Leaf $PSCommandPath


#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}

Breathe

# close previous IE windows ...
& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
$WebClient = New-Object System.Net.WebClient
(New-Object Net.WebClient).DownloadString("$Env:deployurl/99-DeploymentConfig.ps1") > "$Env:temp\99-DeploymentConfig.ps1"
. "$Env:temp\99-DeploymentConfig.ps1"

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

# Start Time and Transcript
Start-Transcript -Path "$Env:temp\$basename.log"
$StartDateTime = Get-Date
Write-Host "`t Script started at $StartDateTime" -ForegroundColor Green

# set window title
$pshost = Get-Host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 5500

# reminder: you can’t have a screen width that’s bigger than the buffer size.
# Therefore, before we can increase our window size we need to increase the buffer size
# powershell screen width and the buffer size are set to 150.
$newsize.width = 170
$pswindow.buffersize = $newsize

# the nul ensures window size does not chnage
#& cmd /c mode con: cols=150  >nul 2>nul


#--------------------------------------------------------------------
Write-Host "$basename - Install LockerLife Services"
#--------------------------------------------------------------------

WriteInfoHighlighted "$basename -- INSTALL SCANNER.JAR AS SERVICE"
#CALL %LOCKERINSTALL%\build\new-service-scanner.bat
#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-scanner.bat
Start-Process $Env:local\bin\new-service-scanner.bat -Verb RunAs -Wait

Write-Host "."
WriteInfoHighlighted "$basename -- INSTALL KIOSKSERVER AS SERVICE"
#CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat
#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-kioskserver.bat
Start-Process $Env:local\bin\new-service-kioskserver.bat -Verb RunAs -Wait

Write-Host "."
WriteInfoHighlighted "$basename -- INSTALL DATA-COLLECTION.JAR AS SERVICE"
#CALL %LOCKERINSTALL%\build\new-service-datacollection.bat
#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-datacollection.bat
Start-Process $Env:local\bin\new-service-datacollection.bat -Verb RunAs -Wait

Write-Host "."
WriteInfoHighlighted "$basename -- INSTALL CORE.JAR AS SERVICE"
## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-core.bat
Start-Process $Env:local\bin\new-service-core.bat -Verb RunAs -Wait


#--------------------------------------------------------------------
Write-Host "$basename - Manage LockerLife User Accounts"
#--------------------------------------------------------------------

# add user
Write-Host "$basename -- ADD KIOSK USER"
Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup kiosk-group /add' -NoNewWindow -Verb RunAs
Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no' -NoNewWindow
Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup "kiosk-group" "kiosk" /add' -NoNewWindow


# [] auto create user profile (super quick, super dirty!)
Write-Host "$basename -- Create kiosk user profile"
Start-Process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir' -NoNewWindow -Wait
psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir
Start-process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir' -NoNewWindow
psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir

# psexec -u kiosk to use bginfo to change background to black
Start-process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c bginfo c:\local\etc\kiosk-production-black.bgi /silent /NOLICPROMPT /TIMER:0' -NoNewWindow
psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c bginfo c:\local\etc\kiosk-production-black.bgi /silent /NOLICPROMPT /TIMER:0


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


#if (Test-PendingReboot) { Invoke-Reboot }
Reboot-IfRequired

# --------------------------------------------------------------------------------------------
Write-Host "Set Autologon"
WriteInfoHighlighted "SETUP AUTOLOGON"
#Start-Process 'autologon.exe' -Verb runAs -ArgumentList '/accepteula kiosk \ locision123'

### Use New-GPO ???
#New-GPO NoDisplay | Set-GPRegistryValue -key “HKCU\Software\Microsoft\Windows\CurrentVersion\Policies \System” -ValueName NoDispCPL -Type DWORD -value 1 | New-GPLink -target “ou=executive,dc=sample,dc=com”

# cleanup desktop
CleanupDesktop

RefreshEnv
# touch $Env:local\status\30-lockerlife.done file
