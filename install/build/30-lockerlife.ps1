# Derek Yuen <derekyuen@locision.com>
# December 2016

# 30-lockerlife - LockerLife Internal Configuration (Preparation for purple console screen) *** WILL AUTOLOGON AS KIOSK when done
$host.ui.RawUI.WindowTitle = "30-lockerlife"

$basename = "30-lockerlife"
$ErrorActionPreference = "Continue"

#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------
$timer = Start-TimedSection "30-lockerlife"

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	1..5 | % { Write-Host }
	exit
}

## backup
#Enable-ComputerRestore -Drive "C:\" -Confirm:$false
#Checkpoint-Computer -Description "Before 00-init"


#--------------------------------------------------------------------
Write-Host "$basename - Loading Modules ..."
#--------------------------------------------------------------------

# Import BitsTransfer ...
if (!(Get-Module BitsTransfer -ErrorAction SilentlyContinue)) {
	Import-Module BitsTransfer
} else {
	# BitsTransfer module already loaded ... clear queue
	Get-BitsTransfer | Complete-BitsTransfer
}

if (Test-Path C:\local\lib\WASP.dll) {
  Import-Module C:\local\lib\WASP.dll
}

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1
$basename = "30-lockerlife"

SetConsoleWindow
$host.ui.RawUI.WindowTitle = "30-lockerlife"

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

# Start Time and Transcript
Start-Transcript -Path "$Env:temp\$basename.log"
$StartDateTime = Get-Date
Write-Host "`t Script started at $StartDateTime" -ForegroundColor Green


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- LockerLife -> Repo Checks ..."
# --------------------------------------------------------------------------------------------

Invoke-RestMethod -Uri "https://api.github.com/users/lockerlife-kiosk"
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
Set-Location -Path "D:\"

# lockerlife production
"RunLockerLifeConsole.bat","RunLockerLifeTV.bat","core.jar","data-collection.jar","run-manual.bat","run-test.bat","run.bat","scanner.jar","production-Locker-Console.zip","production-Locker-Slider.zip","production-kioskServer.zip" | ForEach-Object {
	if (!(Test-Path $_)) {
		Start-BitsTransfer -DisplayName "LockerLifeConsoleSetup" -Source "http://lockerlife.hk/deploy/app/$_" -Destination "D:\$_" -Description "Download LockerLife Console Setup File $_" -TransferType Download -RetryInterval 60
	} else { Write-Host "$basename -- Skipping $_" }
}
Get-BitsTransfer | Complete-BitsTransfer

"production-Locker-Console.zip","production-Locker-Slider.zip","production-kioskServer.zip" | ForEach-Object {
	if (Test-Path $_) {
		C:\ProgramData\chocolatey\bin\unzip.exe -o $_
		#Remove-Item $_ -Force -Confirm:$false -Force
	} else { Write-Host "$basename --- $_ missing" }
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
Write-Host "$basename -- LockerLife -> Get lockerlife libraries ..."
# --------------------------------------------------------------------------------------------

# get-location of locker-libs first from locker-cloud; preserve Last-Modified --> restamp all files using each individual file Last-Modified time

#$jqopts = " '.[].url' "
$lockercloudhost = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com"
$lockercloudlibpath = "/dev/lockers/libs"
$lockerlibfullpath = $lockercloudhost + $lockercloudlibpath

$lockerlibs = "D:\locker-libs"
$liblist = "locker-libs-list.txt"
$libtimestamp = "locker-libs-timestamps.txt"

Move-Item $lockerlibs\$liblist $lockerlibs\$liblist.old -Force
Move-Item "D:\locker-libs\locker-libs-list-transfer.ps1" "D:\locker-libs\locker-libs-list-transfer-old.ps1" -Force
#locate locker-libs first; then send output to locker-lib
## & "$Env:curl" -Ss -R -k --url "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers/libs" | jq '.[].url' > D:\locker-libs\locker-libs-list.txt
#& "$env:curl" -RSs -k --url "$lockercloudhost$lockercloudlibpath" | jq '.[].url' >> $lockerlibs\$liblist
(Invoke-RestMethod -Uri "$lockercloudhost$lockercloudlibpath").url | Out-File -FilePath $lockerlibs\$liblist

# create timestamps file
# fetch Last-Modified header for specific file; only donwload if-modified
## cat %LIBLIST% | xargs %XARGSOPTS% -n 1 curl -LR

# download (e.g. cat or type %LIBLIST% | xargs -n 1 curl -LO )
# xargs -P to run in parallel; match nunber of cpu cores
#cat $lockerlibs\$liblist | xargs -n 1 curl -LO
#Get-Content D:\locker-libs\locker-libs-list.txt | xargs -P "$Env:Number_Of_Processors" -n 1 curl -LO
Set-Location -Path "D:\locker-libs"

#Get-Content D:\locker-libs\locker-libs-list.txt | xargs -n 1 curl --progress-bar -k -LO
Get-Content -Path "D:\locker-libs\locker-libs-list.txt" | ForEach-Object {
	Add-Content -Path "D:\locker-libs\locker-libs-list-transfer.ps1" "Start-BitsTransfer -DisplayName LockerLifeLibraryDownload -TransferType Download -RetryInterval 60 -Source $_ -Destination D:\locker-libs"
}

# Foreach ($file in Get-Content $lockerlibs\$liblist) {
# 	if (!(Test-Path "$env:local\bin\$_")) {
# 		Start-BitsTransfer -Source "http://lockerlife.hk/deploy/bin/$_" -Destination "$env:local\bin\$_" -DisplayName "LockerLifeLocalBin" -Description "Download LockerLife Local Tools $_" -TransferType Download -RetryInterval 60
# 	} else { WriteInfoHighlighted "$basename -- Skipping $_" }
# 	}
# #commit the downloaded files
# Get-BitsTransfer | Complete-BitsTransfer

# }

D:\locker-libs\locker-libs-list-transfer.ps1
#Get-BitsTransfer | ? { $_.jobstate -ne 'transferred'}

Get-BitsTransfer | Complete-BitsTransfer

#--------------------------------------------------------------------
Write-Host "$basename - Install LockerLife Services"
#--------------------------------------------------------------------

$chkservice = Get-Service -Name scanner -ErrorAction SilentlyContinue
if (!($?)) {
	WriteInfoHighlighted "`t $basename -- INSTALL SCANNER AS SERVICE"
	#CALL %LOCKERINSTALL%\build\new-service-scanner.bat
	#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-scanner.bat
	Start-Process -FilePath $Env:local\bin\new-service-scanner.bat -Verb RunAs -Wait
} else { Write-Host "Scanner service installed." }
Write-Host "."


$chkservice = Get-Service -Name kioskserver -ErrorAction SilentlyContinue
if (!($?)) {
	WriteInfoHighlighted "$basename -- INSTALL KIOSKSERVER AS SERVICE"
	#CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat
	#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-kioskserver.bat
	Start-Process -FilePath $Env:local\bin\new-service-kioskserver.bat -Verb RunAs -Wait
	Write-Host "."
} else { Write-Host "Kioskserver service installed."}

$chkservice = Get-Service -Name "data-collection" -ErrorAction SilentlyContinue
if (!($?)) {
	WriteInfoHighlighted "$basename -- INSTALL DATA-COLLECTION AS SERVICE"
	#CALL %LOCKERINSTALL%\build\new-service-datacollection.bat
	#CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-datacollection.bat
	Start-Process -FilePath $Env:local\bin\new-service-datacollection.bat -Verb RunAs -Wait
} else { Write-Host "Data-Collection service installed."}
Write-Host "."

$chkservice = Get-Service -Name core -ErrorAction SilentlyContinue
if (!($?)) {
	WriteInfoHighlighted "$basename -- INSTALL CORE AS SERVICE"
	## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-core.bat
	Start-Process -FilePath $Env:local\bin\new-service-core.bat -Verb RunAs -Wait
	Write-Host "."
} else { Write-Host "Core service installed."}

#--------------------------------------------------------------------
Write-Host "$basename - Manage LockerLife User Accounts ..."

# add user
Write-Host "$basename -- ADD KIOSK USER"
#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup kiosk-group /add' -NoNewWindow -Verb RunAs
& net.exe localgroup kiosk-group /add
net.exe localgroup kiosk-group /add

#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no' -NoNewWindow
& net.exe user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no
net.exe user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no

#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup "kiosk-group" "kiosk" /add' -NoNewWindow
& net.exe localgroup "kiosk-group" "kiosk" /add
net.exe localgroup "kiosk-group" "kiosk" /add

#--------------------------------------------------------------------
Write-Host "$basename - Setting up kiosk user environment"


$KioskUser = "kiosk"
$KioskPass = ConvertTo-SecureString -String "locision123" -AsPlainText -Force

# just use $cred ...
$kioskCred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $KioskUser, $KioskPass
# $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

# [] auto create user profile (super quick, super dirty!)
# redundant because user profile creation isn't always guranteed ...
Write-Host "$basename -- Create kiosk user profile"
Invoke-Expression "psexec -accepteula -nobanner -u kiosk -p locision123 cmd /c dir"
Start-Process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir'
Start-Process -Credential $kioskCred cmd -ArgumentList "/c"
Start-Process -Credential $kioskCred -LoadUserProfile cmd -ArgumentList "/c"

Start-Process -Credential $kioskCred -LoadUserProfile "c:\ProgramData\chocolatey\bin\choco.exe" -ArgumentList "list -l"
Start-Process -Credential $kioskCred "c:\windows\system32\calc.exe"
Start-Process -Credential $kioskCred -LoadUserProfile "c:\windows\system32\calc.exe"
Stop-Process -Name "Calc" -Force
Copy-Item -Path "D:\run.bat" -Destination 'C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\run.bat' -ErrorAction SilentlyContinue
Copy-Item -Path "D:\run.bat" -Destination 'C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\run.bat' -ErrorAction SilentlyContinue

#Start-process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir' -NoNewWindow
#& psexec.exe -accepteula -nobanner -u kiosk -p locision123 cmd /c dir
# Copy-Item -Path "D:\run.bat" -Destination 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\run.bat'
Set-Location "C:\local\etc"


# set autologon to kiosk user

# symlink \Users\kiosk\...\startup items\run.bat->dropbox\locker-shared\production\run.bat
# symlink D:\run.bat->dropbox\locker-shared\production\run.bat

# create finish-locker-setup.ps1 on kiosk\desktop, reboot



#WriteInfoHighlighted "$basename -- Disable Automatic Updates"
#REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f


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
#Register-ScheduledJob -Name UpdatePowerShellHelpJob -ScriptBlock { Update-Help -Module * } -Trigger ( New-JobTrigger -Daily -At "1 AM" )

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
# The following example schedules the MyApp program to run once a day, every day, at 3:00 A.M.
# Because it omits the /mo parameter, the default interval of 1 is used to run the command every day.
## schtasks /create /tn "My App" /tr "powershell.exe c:\local\bin\update-locker.ps1" /sc daily /st 03:00:00


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- final hardening ..."

Set-TaskbarOptions -Size Small -Lock -Dock Bottom
Set-WindowsExplorerOptions -DisableShowProtectedOSFiles -DisableShowFileExtensions -DisableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess


Write-Host "$basename - disable admin user"
& net.exe user administrator /active:no
net user administrator /active:no

# set autologin to kiosk user, reboot computer ...
WriteInfoHighlighted "SETUP AUTOLOGON"
#Start-Process 'autologon.exe' -Verb runAs -ArgumentList '/accepteula kiosk \ locision123'
& "$env:local\bin\autologon.exe" /accepteula kiosk $env:computername locision123
Write-Host "."


# --------------------------------------------------------------------------------------------
# purple screen
Write-Host "$basename -- enabling purple screen and lockerlife slider on startup for kiosk user ..."
$kioskstartup = "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
Set-Location -Path "$kioskstartup"
#Copy-Item -Path "d:\run.bat" -Destination "$kioskstartup\run.bat" -Force
New-Item -ItemType Directory -Path "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Force
Copy-Item -Path "D:\run.bat" -Destination "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\run.bat" -Force

# Internet Explorer: All:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 255

# Internet Explorer: History:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 1

# Internet Explorer:Cookies:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 2

# Internet Explorer: Temp Internet Files:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 8

# Internet Explorer: Form Data:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 16

# Internet Explorer: Passwords:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 32

# Internet Explorer: All:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 4351



# --------------------------------------------------------------------
Write-Host "$basename - Cleanup"
# --------------------------------------------------------------------
Stop-Process -Name iexplore

# Cleanup Desktop
CleanupDesktop
Create-DeploymentLinks
cleanmgr.exe /verylowdisk

# touch $Env:local\status\00-init.done file
# echo date/time into file, add lines ...
New-Item -ItemType File -Path "$env:local\status\$basename.done" | Out-Null

Write-Host "$basename -- Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript


Invoke-RestMethod -Uri "https://api.github.com/zen"
Write-Host "."

Stop-TimedSection $timer


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('~');

#END OF FILE
