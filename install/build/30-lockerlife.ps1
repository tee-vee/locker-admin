# Derek Yuen <derekyuen@locision.com>
# December 2016

# 30-lockerlife - LockerLife Internal Configuration (Preparation for purple console screen) *** WILL AUTOLOGON AS KIOSK when done
$host.ui.RawUI.WindowTitle = "30-lockerlife"

$basename = "30-lockerlife"
$ErrorActionPreference = "Continue"

#--------------------------------------------------------------------
Write-Host "${basename}: START"
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


# --------------------------------------------------------------------------------------------
Write-Host "${basename}: Loading Modules ..."
# --------------------------------------------------------------------------------------------

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

#SetConsoleWindow
$host.ui.RawUI.WindowTitle = "30-lockerlife"

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

# Start Time and Transcript
Start-Transcript -Path "$Env:temp\$basename.log"
$StartDateTime = Get-Date
Write-Host "${basename}: Script started at $StartDateTime" -ForegroundColor Green


# --------------------------------------------------------------------------------------------
Write-Host "${basename}: LockerLife -> Repo Checks ..."

$githubCheck = Invoke-RestMethod -Uri "https://api.github.com/users/lockerlife-kiosk"
#& "$Env:curl" --progress-bar -Ss -k --include --url "https://api.github.com/users/lockerlife-kiosk"
#& "$Env:curl" --progress-bar -Ss -k --user "lockerlife-kiosk:Locision123" --url "https://api.github.com/authorizations"

# curl --user "lockerlife-kiosk:Locision123" https://api.github.com/gists/starred
# curl --user "lockerlife-kiosk:Locision123" https://api.github.com/users/lockerlife-kiosk
#curl --user "lockerlife-kiosk:Locision123" --data '{"description":"Created via API","public":"true","files":{"file1.txt":{"content":"Demo"}}' --url https://api.github.com/gists

# read in from file -> post to my gist
#curl --user "lockerlife-kiosm" --data @data.txt https://api.github.com/gists

# --------------------------------------------------------------------------------------------
Write-Host "${basename}: LockerLife -> Pull Source ..."

Write-Host "${basename}: Set up git for kiosk ..."
& "$Env:ProgramFiles\git\cmd\git.exe" config --global user.email kiosk@lockerlife.hk
& "$Env:ProgramFiles\git\cmd\git.exe" config --global user.name 'LockerLife Kiosk'


# get \local\src
#& "$Env:ProgramFiles\git\cmd\git.exe" clone --progress https://lockerlife-kiosk:Locision123@github.com/tee-vee/locker-admin.git "$Env:local\src"
& "$Env:ProgramFiles\git\cmd\git.exe" clone https://lockerlife-kiosk:Locision123@github.com/tee-vee/locker-admin.git "$Env:local\src"


# --------------------------------------------------------------------------------------------
Write-Host "${basename}: LockerLife -> Setup D drive ..."

Set-Location -Path "D:\"

# lockerlife production
"RunLockerLifeConsole.bat","RunLockerLifeTV.bat","core.jar","data-collection.jar","run-manual.bat","run-test.bat","run.bat","scanner.jar","production-Locker-Console.zip","production-Locker-Slider.zip","production-kioskServer.zip" | ForEach-Object {
    if (!(Test-Path $_)) {
        Write-Host "${basename}: Working on $_"
        Start-BitsTransfer -DisplayName "LockerLifeConsoleSetup" -Source "http://lockerlife.hk/deploy/app/$_" -Destination "D:\$_" -Description "Download LockerLife Console Setup File $_" -TransferType Download -RetryInterval 60
        #Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/app/$_" -OutFile "D:\$_" -Verbose
    } else {
        Write-Host "${basename}: SKIPPING $_" -ForegroundColor Yellow
    }
}
Get-BitsTransfer | Complete-BitsTransfer

"production-Locker-Console.zip","production-Locker-Slider.zip","production-kioskServer.zip" | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "${basename}: Working on $_"
        C:\ProgramData\chocolatey\bin\unzip.exe -o $_
        #Remove-Item $_ -Force -Confirm:$false -Force
    } else {
        Write-Host "${basename}: $_ NOT FOUND" -ForegroundColor Red
    }
}


# --------------------------------------------------------------------------------------------
#Write-Host "${basename}: Install LockerLife Libraries"

# get-location of locker-libs first from locker-cloud; preserve Last-Modified --> restamp all files using each individual file Last-Modified time

#$jqopts = " '.[].url' "
#$lockercloudhost = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com"
#$lockercloudlibpath = "/dev/lockers/libs"
#$lockerlibfullpath = $lockercloudhost + $lockercloudlibpath

#$lockerlibs = "D:\locker-libs"
#$liblist = 'locker-libs-list.txt'
#$libtimestamp = 'locker-libs-timestamps.txt'

# Not sure why it takes two tries ... 
#Move-Item $lockerlibs\$liblist $lockerlibs\$liblist.old -Force
#Move-Item "D:\locker-libs\locker-libs-list-transfer.ps1" "D:\locker-libs\locker-libs-list-transfer-old.ps1" -Force

# locate locker-libs first from locker-cloud; then send output to locker-lib
## & "$Env:curl" -Ss -R -k --url "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers/libs" | jq '.[].url' > D:\locker-libs\locker-libs-list.txt
#& "$env:curl" -RSs -k --url "$lockercloudhost$lockercloudlibpath" | jq '.[].url' >> $lockerlibs\$liblist
#(Invoke-RestMethod -Uri "$lockercloudhost$lockercloudlibpath").url | Out-File -FilePath $lockerlibs\$liblist

# create timestamps file
# fetch Last-Modified header for specific file; only donwload if-modified
## cat %LIBLIST% | xargs %XARGSOPTS% -n 1 curl -LR

# download (e.g. cat or type %LIBLIST% | xargs -n 1 curl -LO )
# xargs -P to run in parallel; match nunber of cpu cores
#cat $lockerlibs\$liblist | xargs -n 1 curl -LO
#Get-Content D:\locker-libs\locker-libs-list.txt | xargs -P "$Env:Number_Of_Processors" -n 1 curl -LO
#Set-Location -Path "D:\locker-libs"

#Get-Content D:\locker-libs\locker-libs-list.txt | xargs -n 1 curl --progress-bar -k -LO
#Get-Content -Path "D:\locker-libs\locker-libs-list.txt" | ForEach-Object {
#    Add-Content -Path "D:\locker-libs\locker-libs-list-transfer.ps1" "Start-BitsTransfer -DisplayName LockerLifeLibraryDownload -TransferType Download -RetryInterval 60 -Source $_ -Destination D:\locker-libs"
#}

# Foreach ($file in Get-Content $lockerlibs\$liblist) {
# 	if (!(Test-Path "$env:local\bin\$_")) {
# 		Start-BitsTransfer -Source "http://lockerlife.hk/deploy/bin/$_" -Destination "$env:local\bin\$_" -DisplayName "LockerLifeLocalBin" -Description "Download LockerLife Local Tools $_" -TransferType Download -RetryInterval 60
# 	} else { WriteInfoHighlighted "$basename -- Skipping $_" }
# 	}
# #commit the downloaded files
# Get-BitsTransfer | Complete-BitsTransfer

# }

#powershell.exe -NoProfile -File "D:\locker-libs\locker-libs-list-transfer.ps1"
#Get-BitsTransfer | ? { $_.jobstate -ne 'transferred'}

#Get-BitsTransfer | Complete-BitsTransfer

# --------------------------------------------------------------------------------------------
#Write-Host "${basename}: Install LockerLife Services"

# Use reg-test...

# $sdkUri = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/latest/sdk"
# $headers = @{ "X-API-KEY" = "123456789" } 
# $sdkResponse = Invoke-RestMethod -Method Get -Headers $headers -Uri $sdkUri

# $sdkVersions = @( "core", "scanner", "dataCollection")
# foreach ($sdk in $sdkVersions) {
#     $sdkResponse.$sdk.version | Out-File -Encoding utf8 -FilePath "D:\$sdk.version.txt"
# }

# Invoke-RestMethod -Method Get -Headers $headers -Uri $sdkUri -Verbose


# if (!(Get-Service -Name kioskserver -ErrorAction SilentlyContinue)) {
#     WriteInfoHighlighted "$basename -- INSTALL KIOSKSERVER AS SERVICE"
#     #CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat
#     #CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-kioskserver.bat
#     Start-Process -FilePath $Env:local\bin\new-service-kioskserver.bat -Verb RunAs -Wait
#     Write-Host "."
# } else {
#     Write-Host "Kioskserver service installed."
#     Restart-Service -Name "kioskserver" -Verbose
#     c:\local\bin\NSSM.exe rotate kioskserver
# }


# #$installedSdkVer = unzip -p scanner.jar META-INF/MANIFEST.MF | Select-String "Implementation-Version"
# if (!(Get-Service -Name scanner -ErrorAction SilentlyContinue)) {
#     Write-Host "${basename}: INSTALL SCANNER AS SERVICE"
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.scanner.url -OutFile "D:\scanner.jar" -ContentType "application/octet-stream" -Verbose
#     #CALL %LOCKERINSTALL%\build\new-service-scanner.bat
#     #CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-scanner.bat
#     Start-Process -FilePath $Env:local\bin\new-service-scanner.bat -Verb RunAs -Wait
# } else {
#     Write-Host "${basename}: Scanner service installed."
#     Stop-Service -Name scanner -Verbose
#     Move-Item -Path "D:\scanner.jar" -Destination "D:\scanner.jar.old" -Force
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.scanner.url -OutFile "D:\scanner.jar" -ContentType "application/octet-stream" -Verbose
#     Start-Service -Name scanner -Verbose
#     c:\local\bin\NSSM.exe set scanner AppParameters -Dconfig=D:\locker-configuration.properties -jar D:\scanner.jar
#     c:\local\bin\NSSM.exe rotate scanner
# }

# if (!(Get-Service -Name "data-collection" -ErrorAction SilentlyContinue)) {
#     WriteInfoHighlighted "$basename -- INSTALL DATA-COLLECTION AS SERVICE"
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.dataCollection.url -OutFile "D:\data-collection.jar" -ContentType "application/octet-stream" -Verbose
#     Start-Process -FilePath $Env:local\bin\new-service-datacollection.bat -Verb RunAs -Wait
# } else {
#     Write-Host "${basename}: data-Collection service installed."
#     Stop-Service -Name "data-collection" -Verbose
#     Move-Item -Path "D:\data-collection.jar" -Destination "D:\data-collection.jar.old" -Force
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.dataCollection.url -OutFile "D:\data-collection.jar" -ContentType "application/octet-stream" -Verbose
#     Start-Service -Name "data-collection" -Verbose
#     c:\local\bin\NSSM.exe set data-collection AppParameters -Dconfig=D:\locker-configuration.properties -jar D:\data-collection.jar
#     c:\local\bin\NSSM.exe rotate data-collection
# }


# if (!(Get-Service -Name core -ErrorAction SilentlyContinue)) {
#     WriteInfoHighlighted "$basename -- INSTALL CORE AS SERVICE"
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.core.url -OutFile "D:\core.jar" -ContentType "application/octet-stream" -Verbose
#     Start-Process -FilePath $Env:local\bin\new-service-core.bat -Verb RunAs -Wait
#     Write-Host "${basename}: Core Service Installed ..."
# } else {
#     Write-Host "${basename}: core service installed."
#     Stop-Service -Name core -Verbose
#     Move-Item -Path "D:\core.jar" -Destination "D:\core.jar.old" -Force
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.core.url -OutFile "D:\core.jar" -ContentType "application/octet-stream" -Verbose
#     Start-Service -Name core -Verbose
#     c:\local\bin\NSSM.exe set core AppParameters "-Dconfig=D:\locker-configuration.properties -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -jar d:\core.jar"
#     c:\local\bin\NSSM.exe rotate core

# }

Write-Host "USE LOCKER-REGISTRATION CODE to install LockerLife Libraries and SDK ..." -ForegroundColor Red
Write-Host "USE LOCKER-REGISTRATION CODE to install LockerLife Libraries and SDK ..." -ForegroundColor Red
Write-Host "USE LOCKER-REGISTRATION CODE to install LockerLife Libraries and SDK ..." -ForegroundColor Red
Write-Host "USE LOCKER-REGISTRATION CODE to install LockerLife Libraries and SDK ..." -ForegroundColor Red
Write-Host "USE LOCKER-REGISTRATION CODE to install LockerLife Libraries and SDK ..." -ForegroundColor Red
# --------------------------------------------------------------------------------------------
Write-Host "${basename}: LockerLife User Accounts ..."

if (!(Get-CimInstance win32_useraccount | where { $_.Name -eq "kiosk" })) {
    # add user
    Write-Host "${basename}: Adding kiosk user ... "
    #Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup kiosk-group /add' -NoNewWindow -Verb RunAs

    net.exe localgroup kiosk-group /add
    net.exe localgroup kiosk-group /add

    #Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no' -NoNewWindow
    net.exe user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no /logonpasswordchg:no /expires:never /times:all
    net.exe user kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no /logonpasswordchg:no /expires:never /times:all

    #Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'localgroup "kiosk-group" "kiosk" /add' -NoNewWindow
    net.exe localgroup "kiosk-group" "kiosk" /add
    net.exe localgroup "kiosk-group" "kiosk"

} else {
    Write-Host "${basename}: Kiosk user already exists"
    net.exe user kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no /logonpasswordchg:no /expires:never /times:all
    net.exe localgroup "kiosk-group" "kiosk"

}

# --------------------------------------------------------------------------------------------
Write-Host "${basename}: Setting up kiosk user environment"
# Write-Host "$basename -- set autologon to kiosk user"

$KioskUser = "kiosk"
$KioskPass = ConvertTo-SecureString -String "locision123" -AsPlainText -Force

# just use $cred ...
$kioskCred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $KioskUser, $KioskPass
# $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

# [] auto create user profile (super quick, super dirty!)
# redundant because user profile creation isn't always guranteed ...
Write-Host "${basename}: Create kiosk user profile"
#Invoke-Expression "psexec.exe -accepteula -nobanner -u kiosk -p locision123 cmd /c dir"
Start-Process -FilePath "c:\local\bin\psexec.exe" -ArgumentList "-accepteula -nobanner -u kiosk -p locision123 cmd /c dir"
#Start-Process -FilePath "c:\local\bin\psexec.exe" -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir'
Start-Process -Credential $kioskCred cmd.exe -ArgumentList "/c"
Start-Process -Credential $kioskCred -LoadUserProfile -FilePath "C:\Windows\System32\cmd.exe" -ArgumentList "/c" -Wait

Start-Process -Credential $kioskCred -LoadUserProfile -FilePath "c:\ProgramData\chocolatey\bin\choco.exe" -ArgumentList "list -l" -Wait
Start-Process -Credential $kioskCred -FilePath "c:\windows\system32\calc.exe"
Start-Process -Credential $kioskCred -LoadUserProfile -FilePath "c:\windows\system32\calc.exe"
Stop-Process -Name "Calc" -Force

#Start-process psexec -ArgumentList '-accepteula -nobanner -u kiosk -p locision123 cmd /c dir' -NoNewWindow
#& psexec.exe -accepteula -nobanner -u kiosk -p locision123 cmd /c dir

# Write-Host "${basename}: Setting up logon script for kiosk user ..."

# use reg-test to register locker with Locision locker cloud ...

# --------------------------------------------------------------------------------------------
# Write-Host "$basename -- Purple screen and slider ..."

Write-Host "${basename}: Enabling Lockerlife Console and Slider for automatic startup for kiosk user ..." -ForegroundColor Magenta
$kioskstartup = "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
Set-Location -Path "$kioskstartup"
if (!(Test-Path -Path "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup")) {
    # Shouldn't really need to do this, but ...
    New-Item -ItemType Directory -Path "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Force
}
# No idea why it takes three tries to work ... 
#Copy-Item -Path "d:\run.bat" -Destination "$kioskstartup\run.bat" -Force
Copy-Item -Path "D:\run.bat" -Destination 'C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\run.bat' 
Copy-Item -Path "D:\run.bat" -Destination 'C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\run.bat' -Force | Out-Null
Copy-Item -Path "D:\run.bat" -Destination "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\run.bat" -Force | Out-Null 

# Previously wanted to do symlinks but this has big immediate impact on production .. no room for error ... 
# So now it's disabled. 
# symlink \Users\kiosk\...\startup items\run.bat->dropbox\locker-shared\production\run.bat
# symlink D:\run.bat->dropbox\locker-shared\production\run.bat


# --------------------------------------------------------------------------------------------
# Write-Host "$basename -- set scheduled tasks"
# Examples: https://technet.microsoft.com/en-us/library/bb490996.aspx
# --------------------------------------------------------------------------------------------

##
## testing schtasks.exe ...
#schtasks.exe /Create /SC ONLOGON /TN "StartSeleniumNode" /TR "cmd /c ""C:\SeleniumGrid\startnode.bat"""

##
## testing scheduled jobs
#Register-ScheduledJob -Name Update-Help -ScriptBlock {Update-Help -Module *} -Trigger ( New-JobTrigger -DaysOfWeek Monday -Weekly -At 8AM) -ScheduledJobOption (New-ScheduledJobOption -RequireNetwork) -Credential $cred
#Register-ScheduledJob -Name UpdatePowerShellHelpJob -ScriptBlock { Update-Help -Module * } -Trigger ( New-JobTrigger -Daily -At "1 AM" )

$dailyTrigger = New-JobTrigger -Daily -At "01:00 PM"

if (!(Get-ScheduledJob).Name -eq "Restart-LockerSlider") {
    Register-ScheduledJob -Name UpdateHelp -ScriptBlock {  } -Trigger $dailyTrigger
}


# if (!(Get-ScheduledJob).Name -eq "RotateLogs") {
#     Register-ScheduledJob -Name UpdateHelp -ScriptBlock {Update-Help -Force} -Trigger $dailyTrigger
# }
#
#
# Write-Host "$basename -- Setting up hourly auto production health checks ..."
# schtasks /create /sc hourly /st 00:05:00 /tn "My App" /tr c:\local\bin\health-check.ps1


# Write-Host "$basename -- Setting up daily auto checkin for production slider video updates ..."
# schtasks /create /tn "My App" /tr "powershell.exe c:\local\bin\update-slider-video.ps1" /sc daily /st 03:00:00


# Write-Host "$basename -- Setting up weekly reboot ..."
# schtasks /create /tn "My App" /tr "powershell.exe c:\local\bin\update-locker.ps1" /sc daily /st 03:00:00



# Write-Host "$basename -- Setting up auto update of locker-lib code on 1st day and 17th day of every month ..."
# schtasks /create /tn "My App" /tr "powershell.exe c:\local\bin\update-locker.ps1" /sc daily /st 01:00:00


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
#schtasks.exe /create /sc hourly /mo 5 /sd 03/01/2017 /tn "My App" /tr c:\apps\myapp.exe

# To schedule a task that runs every day
# The following example schedules the MyApp program to run once a day, every day, at 3:00 A.M.
# Because it omits the /mo parameter, the default interval of 1 is used to run the command every day.
## schtasks /create /tn "My App" /tr "powershell.exe c:\local\bin\update-locker.ps1" /sc daily /st 03:00:00


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Resetting Internet Explorer ..."

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


# --------------------------------------------------------------------------------------------
WriteInfoHighlighted "${basename}: Disable Automatic Updates"
# --------------------------------------------------------------------------------------------
#REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f


#$WUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
#$WUSettings
#$WUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
#
#
# NotificationLevel  :
#     0 = Not configured;
#     1 = Disabled;
#     2 = Notify before download;
#     3 = Notify before installation;
#     4 = Scheduled installation;
#
#
#$WUSettings.NotificationLevel=1
#$WUSettings.save()
#

# --------------------------------------------------------------------------------------------
Write-Host "${basename}: Final hardening ..."

Set-TaskbarOptions -Size Small -Lock -Dock Bottom
Set-WindowsExplorerOptions -DisableShowProtectedOSFiles -DisableShowFileExtensions -DisableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess


Write-Host "${basename}: Disable admin user"
#& net.exe user administrator /active:no
net user administrator /active:no

# set autologin to kiosk user, reboot computer ...
Write-Host "${basename}: SETUP AUTOLOGON"
#Start-Process 'autologon.exe' -Verb runAs -ArgumentList '/accepteula kiosk \ locision123'
& "$env:local\bin\autologon.exe" /accepteula kiosk $env:computername locision123
Write-Host "${basename}: Autologon set for kiosk user"


# --------------------------------------------------------------------
Write-Host "${basename}: Cleanup"
# --------------------------------------------------------------------
if (Get-Process -Name iexplore -ErrorAction SilentlyContinue) {
    Stop-Process -Name iexplore -Force
}

# Cleanup Desktop
CleanupDesktop
Create-DeploymentLinks
#Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -WindowStyle Hidden -Wait
Start-Process -FilePath "CleanMgr.exe" -ArgumentList '/verylowdisk' -WindowStyle Hidden -Wait

# touch $Env:local\status\00-init.done file
# echo date/time into file, add lines ...
New-Item -ItemType File -Path "$env:local\status\$basename.done" -Force | Out-Null

Write-Host "${basename}: Finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

Invoke-RestMethod -Uri "https://api.github.com/zen"

Stop-TimedSection $timer


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('~');

#END
