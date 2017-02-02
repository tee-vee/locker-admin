# Derek Yuen <derekyuen@locision.com>
# December 2016

# 30-lockerlife - LockerLife Internal Configuration (Preparation for purple console screen)
# ** autologon as kiosk user after boot
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 30-lockerlife"
#$basename = Split-Path -Leaf $PSCommandPath
#Set-PSDebug -Trace 1

#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	1..5 | % { Write-Host }
	exit
}

# close previous IE windows ...
#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
#$WebClient = New-Object System.Net.WebClient
#$WebClient.DownloadFile("$Env:deployurl/99-DeploymentConfig.ps1","$Env:temp\99-DeploymentConfig.ps1")
#. "$Env:temp\99-DeploymentConfig.ps1"
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1

$basename = "30-lockerlife"

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
$newsize.width = 200
$pswindow.buffersize = $newsize

# the nul ensures window size does not chnage
#& cmd /c mode con: cols=150  >nul 2>nul


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- LockerLife -> Repo Checks ..."
# --------------------------------------------------------------------------------------------

# check
& "$Env:curl" --progress-bar -Ss -k --url "https://api.github.com/users/lockerlife-kiosk"
#& "$Env:curl" --progress-bar -Ss -k --include --url "https://api.github.com/users/lockerlife-kiosk"
#& "$Env:curl" --progress-bar -Ss -k --user "lockerlife-kiosk:Locision123" --url "https://api.github.com/authorizations"

# curl --user "lockerlife-kiosk:Locision123" https://api.github.com/gists/starred
# curl --user "lockerlife-kiosk:Locision123" https://api.github.com/users/lockerlife-kiosk
#curl --user "lockerlife-kiosk:Locision123" --data '{"description":"Created via API","public":"true","files":{"file1.txt":{"content":"Demo"}}' --url https://api.github.com/gists

# read in from file -> post to my gist
#curl --user "lockerlife-kiosm" --data @data.txt https://api.github.com/gists

# --------------------------------------------------------------------------------------------
Write-Host "$basename -- LockerLife -> Pull Source ..."
# --------------------------------------------------------------------------------------------

WriteInfo "$basename -- set up git"
& "$Env:ProgramFiles\git\cmd\git.exe" config --global user.email kiosk@lockerlife.hk
& "$Env:ProgramFiles\git\cmd\git.exe" config --global user.name 'LockerLife Kiosk'


# get \local\src
#& "$Env:ProgramFiles\git\cmd\git.exe" clone --progress https://lockerlife-kiosk:Locision123@github.com/tee-vee/locker-admin.git "$Env:local\src"
& "$Env:ProgramFiles\git\cmd\git.exe" clone https://lockerlife-kiosk:Locision123@github.com/tee-vee/locker-admin.git "$Env:local\src"


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- LockerLife -> Setup D drive ..."
# --------------------------------------------------------------------------------------------

# lockerlife production
"RunLockerLifeConsole.bat","RunLockerLifeTV.bat","core.jar","data-collection.jar","run-manual.bat","run-test.bat","run.bat","scanner.jar","production-Locker-Console.zip","production-Locker-Slider.zip","production-kioskServer.zip" | ForEach-Object {
	& "$Env:curl" --progress-bar -Ss -k -o "D:\$_" --url "$env:deployurl/PRODUCTION/$_"
}

#schtasks.exe /Create /SC ONLOGON /TN "StartSeleniumNode" /TR "cmd /c ""C:\SeleniumGrid\startnode.bat"""

## Register Locker with Locker Cloud:
#$script = @"
#    `$cred = Get-Credential $env:USERNAME
#    Install-BoxstarterPackage https://gitlab.com/locker-admin/...ps1 -Credential `$cred
#"@
#Set-Content (Join-Path $a "register-locker.ps1") ($script)

## Finish Locker Deployment:
#$script = @"
#    `$cred = Get-Credential $env:USERNAME
#    Install-BoxstarterPackage https://gitlab.com/locker-admin/...ps1 -Credential `$cred
#"@
#Set-Content (Join-Path $a "finish-locker-deployment.ps1") ($script)


#--------------------------------------------------------------------
Write-Host "$basename - Install LockerLife Libraries"
#--------------------------------------------------------------------

# --------------------------------------------------------------------------------------------
Write-Host "$basename -- LockerLife -> Get lockerlife libraries ..."
# --------------------------------------------------------------------------------------------

# get-location of locker-libs first from locker-cloud; preserve Last-Modified --> restamp all files using each individual file Last-Modified time

#$jqopts = " '.[].url' "
$lockercloudhost = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com"
$lockercloudlibpath= "/dev/lockers/libs"

$lockerlibs = "D:\locker-libs"
$liblist = "locker-libs-list.txt"
$libtimestamp = "locker-libs-timestamps.txt"

#locate locker-libs first; then send output to locker-lib
## & "$Env:curl" -Ss -R -k --url "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers/libs" | jq '.[].url' > D:\locker-libs\locker-libs-list.txt
& "$env:curl" -RSs -k --cacert ~\cacert.pem --url "$lockercloudhost$lockercloudlibpath" | jq '.[].url' > $lockerlibs\$liblist

# create timestamps file
# fetch Last-Modified header for specific file; only donwload if-modified
## cat %LIBLIST% | xargs %XARGSOPTS% -n 1 curl -LR

# download (e.g. cat or type %LIBLIST% | xargs -n 1 curl -LO )
# xargs -P to run in parallel; match nunber of cpu cores
#cat $lockerlibs\$liblist | xargs -n 1 curl -LO
#Get-Content D:\locker-libs\locker-libs-list.txt | xargs -P "$Env:Number_Of_Processors" -n 1 curl -LO
Get-Content D:\locker-libs\locker-libs-list.txt | xargs -n 1 curl --progress-bar -k -LO


#--------------------------------------------------------------------
Write-Host "$basename - Install LockerLife Services"
#--------------------------------------------------------------------

$chkservice = Get-Service -Name scanner -ErrorAction SilentlyContinue
if ($chkservice.Length -gt 0) {
	WriteInfoHighlighted "`t $basename -- INSTALL SCANNER AS SERVICE"
	#CALL %LOCKERINSTALL%\build\new-service-scanner.bat
	#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-scanner.bat
	Start-Process -FilePath $Env:local\src\install\build\new-service-scanner.bat -Verb RunAs -Wait
}
Write-Host "."


$chkservice = Get-Service -Name kioskserver -ErrorAction SilentlyContinue
if ($chkservice.Length -gt 0) {
	WriteInfoHighlighted "$basename -- INSTALL KIOSKSERVER AS SERVICE"
	#CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat
	#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-kioskserver.bat
	Start-Process -FilePath $Env:local\src\install\build\new-service-kioskserver.bat -Verb RunAs -Wait
	Write-Host "."
}

$chkservice = Get-Service -Name "data-collection" -ErrorAction SilentlyContinue
if ($chkservice.Length -gt 0) {
	WriteInfoHighlighted "$basename -- INSTALL DATA-COLLECTION AS SERVICE"
	#CALL %LOCKERINSTALL%\build\new-service-datacollection.bat
	#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-datacollection.bat
	Start-Process -FilePath $Env:local\src\install\build\new-service-datacollection.bat -Verb RunAs -Wait
}
Write-Host "."

$chkservice = Get-Service -Name core -ErrorAction SilentlyContinue
if ($chkservice.Length -gt 0) {
	WriteInfoHighlighted "$basename -- INSTALL CORE AS SERVICE"
	## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-core.bat
	Start-Process -FilePath $Env:local\src\install\build\new-service-core.bat -Verb RunAs -Wait
	Write-Host "."
}

#--------------------------------------------------------------------
Write-Host "$basename - Manage LockerLife User Accounts"
#--------------------------------------------------------------------

# add user
Write-Host "$basename -- ADD KIOSK USER"
#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup kiosk-group /add' -NoNewWindow -Verb RunAs
net localgroup kiosk-group /add
#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no' -NoNewWindow
net user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no
#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup "kiosk-group" "kiosk" /add' -NoNewWindow
net localgroup "kiosk-group" "kiosk" /add

# [] auto create user profile (super quick, super dirty!)
Write-Host "$basename -- Create kiosk user profile"
Start-Process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir' -NoNewWindow -Wait
psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir
Start-process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir' -NoNewWindow
psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir

# psexec -u kiosk to use bginfo to change background to black
#Start-process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c bginfo c:\local\etc\kiosk-production-black.bgi /silent /NOLICPROMPT /TIMER:0' -NoNewWindow
#psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c bginfo c:\local\etc\kiosk-production-black.bgi /silent /NOLICPROMPT /TIMER:0


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

#Register-ScheduledJob -Name Update-Help -ScriptBlock {Update-Help -Module *} -Trigger ( New-JobTrigger -DaysOfWeek Monday -Weekly -At 8AM) -ScheduledJobOption (New-ScheduledJobOption -RequireNetwork)
# -Credential $cred
Register-ScheduledJob -Verbose -Name UpdatePowerShellHelpJob -ScriptBlock { Update-Help -Module * } -Trigger ( New-JobTrigger -Daily -At "1 AM" )
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



#--------------------------------------------------------------------
Write-Host "$basename - Setting up kiosk user environment"
#--------------------------------------------------------------------


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- final hardening ..."

Write-Host "$basename - disable admin user"
## generate random password for administrator
# -join ((65..90) + (97..122) | Get-Random -Count 5 | % {[char]$_})
net user administrator /active:no

# set autologin to kiosk user, reboot computer ...
WriteInfoHighlighted "SETUP AUTOLOGON"
#Start-Process 'autologon.exe' -Verb runAs -ArgumentList '/accepteula kiosk \ locision123'
& "$env:local\bin\autologon.exe" /accepteula kiosk $env:computername locision123

Write-Host "."

### Use New-GPO ???
#New-GPO NoDisplay | Set-GPRegistryValue -key “HKCU\Software\Microsoft\Windows\CurrentVersion\Policies \System” -ValueName NoDispCPL -Type DWORD -value 1 | New-GPLink -target “ou=executive,dc=sample,dc=com”


# Reset for kiosk user -> Small taskbar
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom
Set-WindowsExplorerOptions -DisableShowProtectedOSFiles -DisableShowFileExtensions -DisableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess


Write-Host "$basename -- Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

cleanmgr.exe /verylowdisk

Write-Host "$basename -- enabling purple screen and lockerlife slider on startup for kiosk user ..."
$kioskstartup = "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
if (!(Test-Path -Path $kioskstartup)) {
	Set-Location $kioskstartup
	Copy-Item -Path "d:\run.bat" -Destination $kioskstartup
}
# Internet Explorer: All:
#& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 255

# Internet Explorer: History:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 1

# Internet Explorer:Cookies:
#& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 2

# Internet Explorer: Temp Internet Files:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 8

# Internet Explorer: Form Data:
#& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 16

# Internet Explorer: Passwords:
#& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 32

# Internet Explorer: All:
#& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 4351

touch "$Env:local\status\30-lockerlife.done"

RefreshEnv

# cleanup desktop
CleanupDesktop




# last chance to reboot before next step ...
Reboot-IfRequired
