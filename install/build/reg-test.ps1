#Requires -Version 3.0

# Derek Yuen <derekyuen@lockerlife.hk>
# March 2017

## reg-test.ps1 -- base tester script for locker-registration

## NOTE: MUST SET $Env:ComputerName to LockerShortName else script will FAIL
## NOTE: NEED PROCESS TO UPDATE SIM CARD
## powershell-remoting ok - start nlasvc, netprofm, winrm; then run Enable-PsRemoting

${basename} = "locker-register"

Write-Host "${basename} - START`n"
$StartTime = (Get-Date).Second

# --------------------------------------------------------------------------------------------
##
## Configure Locker Environment
##

$destEnvironment = "DEV"
#$destEnvironment = "PRODUCTION"


$LockerStatus = 1

if (Test-Path "C:\local\status\$env:hostname-$destEnvironment") {
    Write-Host "Previous Registration Detected ..."
}


# --------------------------------------------------------------------------------------------
##
## If computername is null, just exit ...
##

if ($Env:ComputerName -eq "NULL") {
    Write-Host "${basename}: Locker Console PC Name is not set" -ForegroundColor Red
    Write-Host "${basename}: Locker Console PC Name: $Env:ComputerName" -ForegroundColor Red
    Write-Host "${basename}: Break out of script and fix computername!" -ForegroundColor Red

    $score -= 1000
    Start-Sleep -Seconds 30
}
else {
    Write-Host "${basename}: Locker Console PC Name: $Env:ComputerName `n"
}


# --------------------------------------------------------------------------------------------
##
## Functions
##

# Stop services - Note "data-collection" is hyphenated
function StopLocalServices {
    $LockerServicesList = @("core", "data-collection", "scanner", "kioskserver")
    foreach ($LockerService in $LockerServicesList) {
        Get-Service -Name $LockerService
        Stop-Service -Name $LockerService -Force
    }
}

# --------------------------------------------------------------------------------------------
##
## Environment Setup
##

[int]$score = 0

## Check if redeploy is needed - use scoreboard
# set $score = 100
# check $psversiontable - if base psshell is leq 3  (-100)
# if java is missing (-100), locker-console (-1), locker-libs (-1)



## Configure PowerShell Environment
## Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -NoExit -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    1 .. 5 | % { Write-Host }
    Write-Host "" 
    Write-Host "${basename}: Unable to elevate to admin ... try psexec instead." -ForegroundColor Red
    Write-Host "${basename}: Exiting in 10 seconds ..."
    Start-Sleep -Seconds 10
    exit
}


Write-Host "${basename}: Set PowerShell Work Environment"
$ErrorActionPreference = "Continue"
$ConfirmPreference = "None"


if (Test-Path -Path "$env:programfiles\7-Zip") {
    #$7zExe = "$env:programfiles\7-Zip\7z.exe"
    $Env:Path += ";C:\local\bin;$env:programfiles\7-Zip;$Env:Programdata\chocolatey\bin"
}
else {
    $Env:Path += ";C:\local\bin;$Env:Programdata\chocolatey\bin"
}

if ($PSDefaultParameterValues) {
    $PSDefaultParameterValues.Clear()
}

#$PSDefaultParameterValues=@{"<CmdletName>:<ParameterName>"="<DefaultValue>"}
#$PSDefaultParameterValues.Add("Invoke-*:Verbose", $True)
#$PSDefaultParameterValues.Add("Invoke-RestMethod:Debug", $True)

## *-File
$PSDefaultParameterValues.Add("*-File:Confirm", $False)
$PSDefaultParameterValues.Add("Out-File:Encoding", "utf8")

## *-Item*
#$PSDefaultParameterValues += @{'New-Item*:Confirm' = $False}
#$PSDefaultParameterValues.Add("*-Item*:Verbose", $True)
$PSDefaultParameterValues.Add("Copy-Item:ErrorAction", "SilentlyContinue")
$PSDefaultParameterValues.Add("Set-ItemProperty:ErrorAction", "SilentlyContinue")


## *-Path
#$PSDefaultParameterValues.Add("*-Path:Verbose", $True)
$PSDefaultParameterValues.Add("Test-Path:ErrorAction", "SilentlyContinue")

## *-Location
$PSDefaultParameterValues.Add("*-Location:Verbose", $True)

## *-Service
$PSDefaultParameterValues.Add("*-Service:Verbose", $True)
$PSDefaultParameterValues.Add("*-Service:Confirm", $False)


## set codepage
& "$env:windir\system32\chcp" 65001


$OutputEncoding = [Console]::OutputEncoding

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
$ContentTypeJsonU8 = "application/json; charset=utf-8"
$ContentTypeOctetStream = "application/octet-stream"

# --------------------------------------------------------------------------------------------
## Some Keys

## Google API Keys
## Use Google Maps Geocoding API - Developer Key -> Derek Y Developer Account
$GoogleGeocodeApiKey = "AIzaSyClvw0s2I9miLfAniQ97wb6QkxFlGalho4"

## Use Google Maps Places API for Address Validation - Developer Key -> Derek Y Developer Account
$googlePlaceApiKey = "AIzaSyBt6QTvw5JEPujtT36s4CE1SV-C3-BhpgM"

## Microsoft API Keys -> Derek Y Developer Account
$BingMapsApiKey = "Ag0utFeSmBi9G8segv0hBn5jLY896KrizfBeSzQ6JsTsc4vUsNytSbN85UsMAN1r"


# --------------------------------------------------------------------------------------------
##
## Set URL ... 
## NOTE: LockerId is different depending on environment ... (hostname-DEV / hostname-PRODUCTION)
##

$LockerIdFile = "$Env:ComputerName-$destEnvironment"

if ($destEnvironment -eq "DEV") {
    Write-Host "${basename}: Working in $destEnvironment"
    $certificateId = "b44cb38a56296034fa13e0c6b9e1ffcb97150b05e11563642b8b4117ab202617"
    $LockerCloudApiKey = @{ "X-API-KEY" = "2a7d1233-28da-41c1-9349-77a65a69ef93" }
    #$LockerCloudSdkUrl = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/latest/sdk"
    $LockerCloudSdkUrl = "https://locker-cloud-test.locision.cloud/latest/sdk"
    #$LockerRegistrationUrl = "https://kv7slzj8yk.execute-api.ap-northeast-1.amazonaws.com/local/lockers"
    #$LockerRegistrationUrl = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers"
    $LockerRegistrationUrl = "https://locker-cloud-test.locision.cloud/lockers"


    ## TeamViewer DEV groupid: "g101663132"
    $TeamViewerGroupId = "g101663132"
}

if ($destEnvironment -eq "PRODUCTION") {
    Write-Host "${basename}: Working in $destEnvironment"
    $certificateId = "f652ade7d63a83429ac22a726b8cdf1b9759893978de335695ac08263b073278"
    $LockerCloudApiKey = @{ "X-API-KEY" = "1506e0e9-72d2-48c7-98d9-ca6662b40a10" }
    #$LockerCloudSdkUrl = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/latest/sdk"
    $LockerCloudSdkUrl = "https://locker-cloud.locision.cloud/latest/sdk"
    #$LockerRegistrationUrl = "https://0ngcozbnmf.execute-api.ap-northeast-1.amazonaws.com/prod/lockers"
    $LockerRegistrationUrl = "https://locker-cloud.locision.cloud/lockers"

    ## Google API Keys
    ## Use Google Maps Geocoding API - Developer Key -> Derek Y Developer Account
    #$GoogleGeocodeApiKey = "AIzaSyClvw0s2I9miLfAniQ97wb6QkxFlGalho4"

    ## Use Google Maps Places API for Address Validation - Developer Key -> Derek Y Developer Account
    #$googlePlaceApiKey = "AIzaSyBt6QTvw5JEPujtT36s4CE1SV-C3-BhpgM"

    ## TeamViewer PRODUCTION groupid: "g95523193"
    $TeamViewerGroupId = "g95523193"
}

## Configure Windows Environmnet

Write-Host "${basename}: Set Sound Volume to minimum"
$SetSystemVolumeObj = New-Object -com wscript.shell

## vol down
$SetSystemVolumeObj.SendKeys([char]174)
$SetSystemVolumeObj.SendKeys([char]174)
$SetSystemVolumeObj.SendKeys([char]174)
$SetSystemVolumeObj.SendKeys([char]174)
$SetSystemVolumeObj.SendKeys([char]173)                     ## mute

Write-Host "${basename}: Set Time Zone"
tzutil.exe /s "China Standard Time"

Write-Host "${basename}: Set Nearby NTP Servers"
w32tm.exe /config /update /manualpeerlist:"stdtime.gov.hk asia.pool.ntp.org"

# fix time service & force time resync
if (Get-Service -Name "w32time") {
    Restart-Service "w32time"
    w32tm.exe /query /peers
    w32tm.exe /resync
}
else {
    Set-Service -Name "w32time" -StartupType Automatic
    Restart-Service -Name "w32time"
    w32tm.exe /query /peers
    w32tm.exe /resync
}


##
## Update LockerLife System Configuration (March 2017)
##

Write-Host "${basename}: Updating LockerLife System Configuration (March 2017) ..." -ForegroundColor Magenta
Update-Help -ErrorAction SilentlyContinue


Write-Host "${basename}: User Accounting Updates ..." -ForegroundColor Magenta
net.exe accounts /maxpwage:unlimited
net.exe user kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no /logonpasswordchg:no /expires:never /times:all
net.exe user AAICON Locision123 /active:yes /expires:never /times:all

net.exe user administrator /active:no

Write-Host "${basename}: Updating kiosk run.bat ..." -ForegroundColor Magenta
if (!(Get-Item "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup") -is [System.IO.DirectoryInfo]) {
    Remove-Item "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Force -Verbose
    New-Item -ItemType Directory -Path "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" -Verbose
}
Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/app/run.bat" -OutFile "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\run.bat"

Remove-Item -Path "C:\Users\kiosk\Desktop\*.*" -Force
Remove-Item -Path "C:\Users\kiosk\Favorites" -Recurse -Force
Remove-Item -Path "C:\Users\kiosk\Saved Games" -Recurse -Force
Remove-Item -Path "C:\Users\kiosk\Pictures" -Recurse -Force
Remove-Item -Path "C:\Users\kiosk\Music" -Recurse -Force
Remove-Item -Path "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Libraries\*.*" -Force
Remove-Item -Path "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Recent\*.lnk" -Recurse -Force
Remove-Item -Path "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\SendTo\*.*" -Force

Remove-Item -Path "C:\Users\public\Music" -Recurse -Force
Remove-Item -Path "C:\Users\public\Pictures" -Recurse -Force
Remove-Item -Path "C:\Users\public\Videos" -Recurse -Force


Remove-Item -Path "C:\local\bin\nssm.exe" -Verbose -Force -ErrorAction SilentlyContinue

Write-Host "${basename}: System Updates ..." -ForegroundColor Magenta
# Remove Shutdown option from Start Menu
#New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Verbose -Force
#Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "5000" -Verbose -Force

#New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_ButtonAction" -Force
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_ButtonAction" -Value "4" -Force

#New-ItemProperty -Path "HKCU:\Software\Microsoft\Wisp\Pen\SysEventParameters" -Name "FlickMode" -Force
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Wisp\Pen\SysEventParameters" -Name "FlickMode" -Value "0" -Force

#New-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\TabletPC" -Name "TurnOffPenFeedback" -Verbose -Force
#Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\TabletPC" -Name "TurnOffPenFeedback" -Value 1 -Verbose -Force

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "ShowTabletKeyboard" -Verbose -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -Name "ShowTabletKeyboard" -Value "0" -Verbose

New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background" -Name "OEMBackground" -Force -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background" -Name "OEMBackground" -Value "1" -Force -Verbose

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Verbose -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Value "5000" -Verbose -Force

New-ItemProperty -Path "HKLM:\Software\Microsoft\Wisp\Pen\SysEventParameters" -Name "FlickMode" -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Wisp\Pen\SysEventParameters" -Name "FlickMode" -Value "0" -Force

#New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\TabletPC" -Name "TurnOffPenFeedback" -Force
#Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\TabletPC" -Name "TurnOffPenFeedback" -Value "1" -Force

## disable on-screen keyboard for production 
Stop-Service -Name "TabletInputService"
Set-Service -Name "TabletInputService" -StartupType Disabled
Get-Service -Name "TabletInputService"

## set lock computer background to black
New-Item -ItemType Directory -Path "C:\Windows\System32\oobe\info" -Force -ErrorAction SilentlyContinue -Verbose
New-Item -ItemType Directory -Path "C:\Windows\System32\oobe\info\backgrounds" -Force -ErrorAction SilentlyContinue -Verbose
Copy-Item -Path "C:\local\etc\pantone-process-black-c.jpg" -Destination "C:\Windows\System32\oobe\info\backgrounds\backgroundDefault.jpg" -Force -Verbose -ErrorAction SilentlyContinue

## Additional tools ...
Write-Host "${basename}: Tools update ..." -ForegroundColor Magenta
Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/bin/Get-InstalledSoftware.ps1" -OutFile "C:\local\bin\Get-InstalledSoftware.ps1"


Write-Host "${basename}: Add fast log viewing program" -ForegroundColor Magenta
choco install -y baretail
choco install -y nssm

# Where is 7-zip? Too lazy to do checks ...
choco install -y 7zip --forcex86
choco install -y 7zip.commandline
choco install -y unzip --ignore-checksums


Write-Host "${basename}: Hardware Configuration Updates ..." -ForegroundColor Magenta
& "$Env:SystemRoot\System32\netsh.exe" interface set interface name="Wireless Network Connection" admin=DISABLED
netsh.exe interface set interface name="Wireless Network Connection" admin=DISABLED

Write-Host "${basename}: Fix Display Resolution Issues ..." -ForegroundColor Magenta
## Idenify Display ... "Digital" must be "1"



Write-Host "${basename}: Re-enable touch display ..." -ForegroundColor Magenta
## Known touch display Hardware IDs:
##		Standard Locker Generation 1:
##		Standard Locker Generation 2:
## 		Mini Generation 1:
## 		Mini Generation 2:
## 		Mini Generation 3:

## identify touch display
$TouchDisplayObj = (Get-CimInstance Win32_PnPEntity | where Service -ieq "HidUsb")
$TouchDisplayDeviceId = (Get-CimInstance Win32_PnPEntity | where Service -ieq "HidUsb" ).DeviceID
$TouchDisplayPnPDeviceId = (Get-CimInstance Win32_PnPEntity | where Service -ieq "HidUsb" ).PNPDeviceID

if ($TouchDisplayObj.Status -ieq "Error") {
    Write-Host "${basename}: Found probable disabled touchscreen at $TouchDisplayId" -ForegroundColor Yellow
    $TouchDisplayPPID = "{0}{1}" -f '@', $TouchDisplayPnPDeviceId
    C:\local\bin\devcon.exe status $TouchDisplayPPID
    ## C:\local\bin\devcon.exe enable $TouchDisplayPPID
    ## Write-Host "${basename}: Enabled touchscreen at $TouchDisplayId" -ForegroundColor Green
}
else {
    Write-Host "${basename}: No disabled touchscreen found ..." -ForegroundColor Yellow
}

# C:\local\bin\devcon.exe status "USB\VID_13D3&PID_3393*"
# $TouchDisplayId = (Get-CimInstance Win32_PnPEntity | where caption -match '_touchscreen_id_placeholder_').pnpDeviceID
# $ppid = "{0}{1}" -f '@',$id

# .\devcon.exe status $ppid

## Configure Router


# speedtest
# if (Test-Path -Path "c:\local\bin\speedtest-cli.exe") {
#     c:\local\bin\speedtest-cli.exe
# }


##
## Fix Printer Driver - Need Printer Filter Driver
##
## Start in /local/drivers ...

Set-Location -Path "C:\local\drivers"

## Clear print queue
Stop-Service Spooler
Remove-Item "$env:systemroot\System32\spool\printers\*.shd" -Force
Remove-Item "$env:systemroot\System32\spool\printers\*.spl" -Force
#cscript c:\windows\system32\Printing_Admin_Scripts\en_US\prnjobs.vbs
Start-Service Spooler

## test if printer driver install is needed ... 
## Run Gilbert's run-printer-test.bat ... 
## capture output ... 

## Use devcon.exe to idenitfy printer and printer driver
#devcon.exe status "USB\VID_0483&PID_5720&REV_0100"
## or use rundll32.exe to idenitfy active driver

# printer.zip
if (Test-Path -Path "C:\local\drivers\printer.zip") {
    # printer.zip exists ...
    if (Test-Path -Path "C:\local\drivers\printer\SPRT_Printer.inf") {
        # .zip file expanded and inf file available; proceed with driver install ...
        Write-Host "Printer driver available for install ..." -ForegroundColor Green
        # install code ... 
    } #if
    else {
        # zip file available, needs to be expanded ...
        Write-Host "Expanding printer.zip"
        7z.exe t "C:\local\drivers\printer.zip"
        7z.exe x -aoa -y "C:\local\drivers\printer.zip"
        # install ...
    }  # else
} # if
else {
    # printer.zip does not exist; download and prep for install ...
    Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/drivers/printer.zip" -Outfile "C:\local\drivers\printer.zip"
    Write-Host "Expanding printer.zip"
    7z.exe t "C:\local\drivers\printer.zip"
    7z.exe x -aoa -y "C:\local\drivers\printer.zip"
} # else


# printer-filter.zip
if (Test-Path -Path "C:\local\drivers\printer-filter.zip") {
    # printer-filter.zip file exists ...
    if (Test-Path -Path "C:\local\drivers\printer-filter") {
        # filter expanded ... install filter driver (combined with above printer SPRT_Printer.inf)

        # Install printer-filter driver
        # RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 path-to-inf\infname.inf
        #Write-Host "${basename}: Checking printer status ..."
        & "$Env:SystemRoot\System32\wbem\wmic.exe" printer list status | Select-String 80mm

        # step 1: install port
        & "C:\Windows\System32\RUNDLL32.EXE" SETUPAPI.DLL, InstallHinfSection DefaultInstall 132 C:\local\drivers\printer\Windows81Driver\POS88EN.inf
        # %LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--device=USB\VID_0483&PID_5720&REV_0100"
        # %LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--device=USB\VID_0483&PID_5720"

        Write-Host "${basename}: Installing printer-filter driver ..."
        #& "$Env:local\drivers\printer-filter\libusb-win32\bin\x86\install-filter.exe" install --device=USB\VID_0483"&"PID_5720

        # step 2: connect/bridge printer-filter to printer
        Write-Host "${basename}: Connecting printer-filter driver to Windows printer object ..."
        & "$Env:local\drivers\printer-filter\libusb-win32\bin\x86\install-filter.exe" install --inf="$Env:local\drivers\printer\SPRT_Printer.inf"

        Write-Host "${basename}: Printer filter driver should be ok" -ForegroundColor Yellow
        #Write-Host "${basename}: RUN PARCEL FLOW FOR CHECK" -ForegroundColor Yellow
    }
    else {
        #7z.exe t "C:\local\drivers\printer-filter.zip"
        # bah, can't capture non-powershell errorcodes easily... expand the zip ...
        7z.exe x -aoa -y "C:\local\drivers\printer-filter.zip"

    }

}
#Pop-Location



# Preparation for updating LockerCloud Middleware (SDK)

Set-Location "D:" -Verbose

# Kill LockerLife processes ...
if (Get-Process -Name "LockerLife*" -ErrorAction SilentlyContinue) {
    Stop-Process -Name "LockerLife*" -Force
}

## Stop Local Services for code update
StopLocalServices

# Get locker-libs.zip ...
Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/app/locker-libs.zip" -OutFile "d:\Locker-Console\locker-libs.zip" -Verbose
Write-Host "${basename}: locker-libs.zip also available just in case ..."


# Update LockerCloud Middleware (SDK)
$LockerCloudSdkHeaders = $LockerCloudApiKey
$LockerCloudSdkResponse = Invoke-RestMethod -Method Get -Headers $LockerCloudSdkHeaders -Uri $LockerCloudSdkUrl

Set-Location -Path "c:\local\bin" -Verbose
Remove-Item -Path "D:\data-collection.jar" -Force -Verbose

# LockerCloudSdk: "datacollection" is NOT hyphenated
$LockerLifeSdkList = @( "core", "scanner", "dataCollection")
foreach ($sdk in $LockerLifeSdkList) {
    # start from scratch ...
    #$LockerCloudSdkResponse.$sdk.version | Out-File -FilePath "D:\$sdk.version.txt" -Force
    Remove-Item -Path "C:\local\bin\new-service-$sdk.bat" -Force -Verbose -ErrorAction SilentlyContinue
    Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/bin/new-service-$($sdk).bat" -OutFile "C:\local\bin\new-service-$($sdk).bat" -Verbose

    Remove-Item -Path "D:\$sdk.jar" -ErrorAction SilentlyContinue
    Invoke-WebRequest -Method Get -Headers $LockerCloudSdkHeaders -Uri "$($LockerCloudSdkResponse.$sdk.url)" -OutFile "D:\$sdk.jar" -Verbose
    $localJarHash = (Get-FileHash -Path "D:\$sdk.jar" -Algorithm SHA256).Hash
    Write-Host "${basename}: local hash for ${sdk}: $localJarHash"
    Write-Host "${basename}: remote hash: $($LockerCloudSdkResponse.$sdk.sha256)"

    # check hash
    if ($localJarHash -eq $LockerCloudSdkResponse.$sdk.sha256) {
        Write-Host "${basename}: local hash for ${sdk}: $localJarHash"
        Write-Host "${basename}: remote hash: $($LockerCloudSdkResponse.$sdk.sha256)"
        Write-Host "${basename}: Hashes match for $sdk!" -ForegroundColor Green
        #Start-Process -FilePath "c:\local\bin\new-service-$sdk.bat" -Verb RunAs -Wait
        & "C:\local\bin\new-service-$sdk.bat"
        Restart-Service -Name $sdk
    } #if
    else {
        Write-Host "${basename}: local hash for ${sdk}: $localJarHash"
        Write-Host "${basename}: remote hash: $($LockerCloudSdkResponse.$sdk.sha256)"
        Write-Host "${basename}: Hashes do not match for $sdk!" -ForegroundColor Red
        & "C:\local\bin\new-service-$sdk.bat"
        #Start-Process -FilePath "c:\local\bin\new-service-$sdk.bat" -Verb RunAs -Wait
        Restart-Service -Name $sdk
    } #else
} # foreach

Move-Item -Path "D:\datacollection.jar" -Destination "D:\data-collection.jar" -Force -Verbose

## EXCEPTION: kioskserver (not served from LockerCloud)
## NOTED: Not checking ...
## sometimes missing kioskserver.exe ...
Write-Host "${basename}: INSTALL KIOSKSERVER AS SERVICE"
Remove-Item -Path "C:\local\bin\new-service-kioskserver.bat" -ErrorAction SilentlyContinue -Verbose
Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/bin/new-service-kioskserver.bat" -OutFile "c:\local\bin\new-service-kioskserver.bat" -Verbose
Start-Process -FilePath "c:\local\bin\new-service-kioskserver.bat" -Verb RunAs -Wait

Write-Host "${basename}: Kioskserver service should be installed ..."
#Pop-Location


## Printer Test
## REQUIRES: KioskServer Service & on-site

Set-Location -Path "C:\local\drivers" -Verbose

if ((Get-Service -Name "kioskserver").Status -eq "Running") {
    if (Test-Path -Path "C:\local\drivers\printer-test\run-printer-test.bat") {
        Write-Host "${basename}: printer-test tool availalble ..." -ForegroundColor Green
        #Write-Host "checking paper ..."
    }
    else {
        # missing printer-test.zip
        Write-Host "${basename}: Downloading printer-test ..." -ForegroundColor Yellow
        Invoke-WebRequest -Method Get -Uri "http://lockerlife.hk/deploy/drivers/printer-test.zip" -OutFile "C:\local\drivers\printer-test.zip" -Verbose
        7z.exe x -aoa -y "C:\local\drivers\printer-test.zip"
        Write-Host "${basename}: printer-test tool availalble ..." -ForegroundColor Green
        Write-Host "${basename}: Printer status check: "
        Set-Location -Path "C:\local\drivers\printer-test"
        Add-Content -Path "C:\local\drivers\printer-test\init.txt" -Value "127.0.0.1 9012"
        Add-Content -Path "C:\local\drivers\printer-test\init.txt" -Value "WAIT `"connected to server`""
        Add-Content -Path "C:\local\drivers\printer-test\init.txt" -Value "SEND `"printer_init\m`""
        #Add-Content -Path "C:\local\drivers\printer-test\init.txt" -Value "WAIT `"printer_init:0`""
        Start-Process -FilePath "C:\local\drivers\printer-test\TST10.exe" -ArgumentList "/r:init.txt /o:init-out.txt" -NoNewWindow
        Get-Content -Path "init-out.txt"
        #Pop-Location
        
    } #else
} 
else {
    # Get-Service kioskserver fail - fix kioskserver
    Write-Host "${basename}: Fixing kioskserver ..."
    Stop-Service -Name "kioskserver"
    Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/bin/new-service-kioskserver.bat" -OutFile "c:\local\bin\new-service-kioskserver.bat" -Verbose
    Start-Process -FilePath "c:\local\bin\new-service-kioskserver.bat" -Verb RunAs -Wait
    Get-Service -Name "kioskserver"
}


# First, validate sitename & build locker.properties
# Get LockerManagementDataFile Data
Write-Host "${basename}: Get LockerManagement Data File"
$LockerManagementDataFile = "LockerManagement.csv"
if (Test-Path -Path "C:\temp\$LockerManagementDataFile") {
    Remove-Item "C:\temp\$LockerManagementDataFile" -Force -ErrorAction SilentlyContinue
}
$request = Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/$LockerManagementDataFile" -OutFile "C:\temp\$LockerManagementDataFile"

Write-Host "${basename}: Reading LockerManagementDataFile Data"
$lmdata = (Get-Content "c:\temp\$LockerManagementDataFile" -Encoding UTF8 -ErrorAction Stop | Select-Object | ConvertFrom-Csv)

# https://translation.googleapis.com/language/translate/v2?key=YOUR_API_KEY&source=en&target=de&q=Hello%20world&q=My%20name%20is%20Jeff

# Build locker.properties - Get Site ...
#$Fdata = $lmdata | Where-Object { $_.LockerShortName -eq "test-hk3" }
$Fdata = $lmdata | Where-Object { $_.LockerShortName -ieq $env:computername }

##
## Check if previously registered & Validate LockerID

if (Test-Path -Path "c:\local\status\$LockerIdFile") {
    $LockerRegistrationCheck = (Get-Content -Path "C:\local\status\$LockerIdFile" -ErrorAction Stop | Select-Object -Last 1)
    $LockerRegistrationCheckResult = (Invoke-RestMethod -Method Get -Headers $LockerCloudApiKey -Uri $LockerRegistrationUrl/$($LockerRegistrationCheck)).nickname
    if ($LockerRegistrationCheckResult -eq $Fdata.LockerName) {
        Write-Host "${basename}: Locker Identified: $LockerRegistrationCheckResult" -ForegroundColor Green
        Write-Host "${basename}: Using LockerID $LockerRegistrationCheck" -ForegroundColor Green
        Write-Host "${basename}: Will Patch LockerCloud LockerProfile" -ForegroundColor Green

        # override LockerRegistrationUrl
        $LockerRegistrationUrl = "$LockerRegistrationUrl/$LockerRegistrationCheck"
        Write-Host "${basename}: Using endpoint $LockerRegistrationUrl" -ForegroundColor Green
        # Set Web Services Methods to PATCH
        $LockerRegistrationHttpMethod = "PATCH"
    }
    else {
        Write-Host "${basename}: Locker Registerered but LockerId not valid ..." -ForegroundColor Red
        $score -= 1000
    }
}
else {
    Write-Host "${basename}: New Registration" -ForegroundColor Green
    $LockerRegistrationHttpMethod = "POST"
}


# Build locker.properties - location (lat/lon)
Write-Host "${basename}: Geocode Locker Address to GPS Coordinates"

[string]$RegionBias = "hk"
[string]$GoogleGeocodeApiComponentType = "convenience_store"
$protocol = "https"
$RawDataFormat = "JSON"
[string]$language = "en"

if ($($Fdata.scope) -eq "711") {
    [string]$GoogleGeocodeApiComponentType = "convenience_store"
}

# massage address for google ...
# has tendency to include blank spaces
# v2 fix: construct array -- add if not blank; convertfrom... to build
# use stack (pushd, popd)

# first try ...

#$geocodeAddress = $Fdata.GpsRef + "," + $Fdata.StreetNo + "," + $Fdata.StreetName + "," + $Fdata.Town + "," + $Fdata.District
$geocodeAddress = $Fdata.GpsRef + "," + $Fdata.Town + "," + $Fdata.District
#$geocodeAddress = $geocodeAddress.Replace("NULL", "")
#$geocodeAddress = $geocodeAddress.TrimEnd(" ")
$convertedAddress = $geocodeAddress.Replace(" ", "+")

#$url = "https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=AIzaSyClvw0s2I9miLfAniQ97wb6QkxFlGalho4"
#$url = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&key=$($GoogleGeocodeApiKey)"
#$url = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&result_type=$($GoogleGeocodeApiComponentType)&region=$($RegionBias)&key=$($GoogleGeocodeApiKey)"
$geourl = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&key=$($GoogleGeocodeApiKey)"
$geourlTW = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&language=zh-TW&key=$($GoogleGeocodeApiKey)"
$geourlCN = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&language=zh-CN&key=$($GoogleGeocodeApiKey)"


#[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11
#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "${basename}: Geocoding $geocodeAddress ..." -ForegroundColor Yellow
#$geo = Invoke-RestMethod "https://maps.googleapis.com/maps/api/geocode/json?address=2+King+San+Path,+New+Territories,+Hong+Kong&key=$GoogleGeocodeApiKey"
$georesponse = Invoke-RestMethod -Uri $geourl -Method Get -ContentType $ContentTypeJsonU8
$georesponseTW = Invoke-RestMethod -Uri $geourlTW -Method Get -ContentType $ContentTypeJsonU8
$georesponseCN = Invoke-RestMethod -Uri $geourlCN -Method Get -ContentType $ContentTypeJsonU8

# difficult to build algo to select best result due to need for fuzzy matching ...
# google places api can be helpful in fuzzy matching .

if ($georesponse.status -eq "OK") {

    # Verify result
    Write-Host "${basename}: Found $($georesponse.results.formatted_address)"
    Write-Host "${basename}: Latitude: $($georesponse.results.geometry.location.lat), Longitude: $($georesponse.results.geometry.location.lng)"

    # Quality of results ...
    # "ROOFTOP" -> 100% the building found
    if ($georesponse.results.geometry | where { ($_.location_type -eq "ROOFTOP") -or ($_.location_type -eq "APPROXIMATE") }) {
        Write-Host "${basename}: Geocode Accuracy: $($georesponse.results.geometry.location_type) " -ForegroundColor Green
    }
    else {
        #$location = $georesponse.results.geometry
        Write-Host "${basename}: Location coordinates may not be completely accurate ... check georesponse and address immediately" -ForegroundColor Yellow
        Write-Host "${basename}: GPS may not be completely accurate ... check georesponse and address immediately" -ForegroundColor Yellow
        Write-Host "${basename}: Geocode Accuracy: $($georesponse.results.geometry.location_type) " -ForegroundColor Green
    }
}
elseif ($georesponse.Status -eq 'ZERO_RESULTS') {
    Write-Host "${basename}: Your search for '$($geocodeAddress)' returned zero results."
}
elseif ($georesponse.Status -eq 'OVER_QUERY_LIMIT') {
    Write-Warning "${basename}: Error: Exceeded Address-to-Geocoding service quota."
}
elseif ($georesponse.Status -eq 'REQUEST_DENIED') {
    Write-Warning "${basename}: Request denied ..."
}
elseif ($georesponse.Status -eq 'INVALID_REQUEST') {
    Write-Warning "${basename}: Invalid request ..."
}
elseif ($georesponse.Status -eq 'UNKNOWN_ERROR') {
    Write-Warning "${basename}: Request could not be processed due to a server error. Please try again."
}
else {
    # Not sure what the fuck happened here ...
    Write-Warning "${basename}: UNKNOWN-UNKNOWN ERROR ... Unable to retrieve location coordinates"
    #$georesponse = c:\local\bin\curl.exe --url "$geourl"
}

#lat-long is stored in:
#$geo.results.geometry.location


# Handling multiple responses
if (($georesponse.results).Count -ge 2) {
    Write-host "${basename}: Multiple locations found ... check georesponse and location before registering locker" -ForegroundColor Yellow
    Write-host "${basename}: Displaying Results ..." -ForegroundColor Yellow
    $($georesponse.results)
    # because google geocode-api uses lat/lng - and we use lat/lon
    $location = $georesponse.results.geometry.location | Select-Object @{N = 'lat'; E = {($georesponse.results)[0].geometry.location.lat}}, @{N = 'lon'; E = {($georesponse.results)[0].geometry.location.lng}}
}
else {
    # because google geocode-api uses lat/lng - and we use lat/lon
    $location = $georesponse.results.geometry.location | Select-Object @{N = 'lat'; E = {$georesponse.results.geometry.location.lat}}, @{N = 'lon'; E = {$georesponse.results.geometry.location.lng}}

}

# because google geocode-api uses lat/lng - and we use lat/lon
#$location = $georesponse.results.geometry.location | Select-Object @{N='lat'; E={$georesponse.results.geometry.location.lat}}, @{N='lon'; E={$georesponse.results.geometry.location.lng}}

# store place_id
$placeId = $georesponse.results.place_id

# Testing Google Places API for address verification (based on building name) -- FUTURE
#$place = Invoke-RestMethod "https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJP4Go7FQHBDQR1CUFeViLOzM&key=$googlePlaceApiKey" -Method Get -ContentType $ContentTypeJsonU8
#$place = Invoke-RestMethod -Uri $placeUrl -Method Get -ContentType $ContentTypeJsonU8
$placeUrl = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/place/details/json?placeid=$($placeId)&key=$googlePlaceApiKey"
$placeUrlTW = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/place/details/json?placeid=$($placeId)&language=zh-TW&key=$googlePlaceApiKey"
$placeUrlCN = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/place/details/json?placeid=$($placeId)&language=zh-CN&key=$googlePlaceApiKey"


# locker-properties: description
$description = @"
{
  "en": "null"
}
"@ | ConvertFrom-Json

if ($Fdata.Description) {
    $description | Add-Member -Name "en" -Value $Fdata.Description -MemberType NoteProperty -Force
}
if ($Fdata.DescriptionC) {
    $description | Add-Member -Name "zh_HK" -Value $Fdata.DescriptionC -MemberType NoteProperty -Force
    $description | Add-Member -Name "zh_CN" -Value $Fdata.DescriptionC -MemberType NoteProperty -Force
}

# locker-properties: lockerProfile
$lockerProfile = @"
{
	"cameraHost": "192.168.1.200",
	"cameraPassword": "pass",
	"cameras": [
	  "1",
	  "2"
	],
	"cameraUsername": "Locision",
	"lockerBoard": 2,
	"lockerHost": "127.0.0.1",
	"lockerPort": 9012,
	"lockerStructure": "NULL",
	"scannerHost": "127.0.0.1",
	"scannerPort": 23
}
"@ | ConvertFrom-Json

# update $LockerStructure
$lockerProfile | Add-Member -Name "lockerStructure" -Value $Fdata.LockerStructure -MemberType NoteProperty -Force
#$lockerProfile | Add-Member -Name "cameraHost" -Value "192.168.1.200" -MemberType NoteProperty -Force

# find camera

# #wake up UPnP devices
# c:\local\bin\upnpscan.exe -m
# c:\local\bin\upnpscan.exe -m
# c:\local\bin\upnpscan.exe -m

# # #$findCam = (C:\local\bin\upnpscan.exe -m | Select-String LOCATION).ToString().Split(" ")
# # [uri]$a = (C:\local\bin\upnpscan.exe -m | Select-String LOCATION).ToString().Split(" ") | select -skip 1
# # $env:CameraIpAddress = $a.Host

# if (($env:CameraIpAddress -eq "0.0.0.0") -or (!$env:CameraIpAddress)) {
#     $findCam = (C:\local\bin\upnpscan.exe -m | Select-String LOCATION).ToString().Split(" ")
#     $env:CameraIpAddress = ([uri]$findCam[1]).Host
# }
# else {
#     Write-Host "Unable to find camera ... setting to 192.168.1.200"
#     $lockerProfile | Add-Member -Name "cameraHost" -Value "192.168.1.200" -MemberType NoteProperty -Force
# }

# locker-properties: address
$address = [pscustomobject]@{
    en = [pscustomobject]@{
        room = $Fdata.Floor
        building = $Fdata.Building
        street = $Fdata.StreetNo + " " + $Fdata.StreetName
        town = $Fdata.Town
        district = $Fdata.District
        city = "Hong Kong"
        country = "CHINA"
    }
    zh_CN = [pscustomobject]@{
        room = $Fdata.FloorC
        building = $Fdata.BuildingC
        street = $Fdata.StreetNoC + " " + $Fdata.StreetNameC
        town = $Fdata.TownC
        district = $Fdata.DistrictC
        city = "香港"
        country = "中国"
    }
    zh_HK = [pscustomobject]@{
        room = $Fdata.FloorC
        building = $Fdata.BuildingC
        street = $Fdata.StreetNoC + " " + $Fdata.StreetNameC
        town = $Fdata.TownC
        district = $Fdata.DistrictC
        city = "香港"
        country = "中國"
    }
} # $address

# locker-properties: boxes
$boxes = @()
$type = $Fdata.Boxes

if (!$type) {
    Write-Host "${basename}: Locker type missing ..." -ForegroundColor Red
    Write-Host "${basename}: Cannot continue locker registration - Exit ..." -ForegroundColor Red
    exit
}

if ($type -eq 72) {
    Write-Host "${basename}: Standard 72 Locker Type" -ForegroundColor Green
    $typeDescription = "Standard Locker, 72 Boxes"
    $col = 8
    $row = 9
}
elseif ($type -eq 54) {
    Write-Host "${basename}: Standard 54 Locker Type" -ForegroundColor Green
    $typeDescription = "Standard Locker, 54 Boxes"
    $col = 6
    $row = 9
}
elseif ($type -eq 36) {
    Write-Host "${basename}: Standard 36 Locker Type" -ForegroundColor Green
    $typeDescription = "Standard Locker, 36 Boxes"
    $col = 4
    $row = 9
}
elseif ($type -eq 18) {
    Write-Host "${basename}: Standard 18 Locker Type" -ForegroundColor Green
    $typeDescription = "Standard Locker, 18 Boxes"
    $col = 2
    $row = 9
}
else {
    # $type probably == 13
    # Locker Type == 7-11
    Write-Host "${basename}: 7-11 Locker Type" -ForegroundColor Green
    $typeDescription = "Mini Locker, 13 Boxes"
    $col = 2
    # set $row within foreach
}

ForEach ($i in (1 .. $col)) {
    # 7-11 exception (column 1 has only 4 rows; column 2 has 9)
    if ($type -eq 7 -Or $type -eq 13) {
        if ($i -eq 1) {
            $row = 4
        }
        else {
            $row = 9
        }
    }
    ForEach ($j in (1 .. $row)) {
        if ($type -eq 7 -Or $type -eq 13) {
            $size = 0
        }
        else {
            if ($j -eq 1) {
                $size = 3
            }
            elseif ($j -le 3) {
                $size = 2
            }
            elseif ($j -le 7) {
                $size = 1
            }
            elseif ($j -le 9) {
                $size = 2
            }
        }
        $boxes += [pscustomobject]@{
            bayNum = $i
            boxNum = $j
            owner = "LIKONS"
            size = $size
        }
    }
}

$boxes | ConvertTo-Json | Set-Content -Path "C:\local\status\boxes.json" -Force
$xboxes = Get-Content -Path "C:\local\status\boxes.json" -Raw
$xxboxes = [scriptblock]::Create(($xboxes| ConvertFrom-Json))
#Measure-Command $TestAddMember | Format-Table TotalSeconds -Autosize

# lp -> locker properties
Write-Host "${basename}: Create locker.properties profile"
$lp = New-Object PSObject
#$lp = [PSCustomObject]

# if Method = Patch, do not send certificateId, mac, boxes
if ($LockerRegistrationHttpMethod -eq "PATCH") {
    $lp | Add-Member -Name "nickname" -Value $Fdata.LockerName -MemberType NoteProperty -Force
    $lp | Add-Member -Name "csNumber" -Value "85236672668" -MemberType NoteProperty -Force
    $lp | Add-Member -Name "status" -Value $LockerStatus -MemberType NoteProperty -Force
    $lp | Add-Member -Name "openTime" -Value $Fdata.Availability -MemberType NoteProperty -Force
    $lp | Add-Member -Name "location" -Value $location -MemberType NoteProperty -Force
    $lp | Add-Member -Name "description" -Value $description -MemberType NoteProperty -Force
    $lp | Add-Member -Name "lockerProfile" -Value $lockerProfile -MemberType NoteProperty -Force
    $lp | Add-Member -Name "address" -Value $address -MemberType NoteProperty -Force
    $lp | Add-Member -Name "scope" -Value $Fdata.scope -MemberType NoteProperty -Force
}
else {
    $lp | Add-Member -Name "nickname" -Value $Fdata.LockerName -MemberType NoteProperty -Force
    $lp | Add-Member -Name "certificateId" -Value $certificateId -MemberType NoteProperty -Force
    $lp | Add-Member -Name "csNumber" -Value "85236672668" -MemberType NoteProperty -Force
    $lp | Add-Member -Name "status" -Value $LockerStatus -MemberType NoteProperty -Force
    $lp | Add-Member -Name "openTime" -Value $Fdata.Availability -MemberType NoteProperty -Force
    $lp | Add-Member -Name "location" -Value $location -MemberType NoteProperty -Force
    $lp | Add-Member -Name "description" -Value $description -MemberType NoteProperty -Force
    $lp | Add-Member -Name "lockerProfile" -Value $lockerProfile -MemberType NoteProperty -Force
    $lp | Add-Member -Name "mac" -Value (getmac /fo csv | ConvertFrom-Csv | Where-Object { -not ( $_.'Transport Name' -eq "Hardware not present") -and -not ( $_.'Transport Name' -eq "Disconnected")}).'Physical Address' -MemberType NoteProperty -Force
    $lp | Add-Member -Name "address" -Value $address -MemberType NoteProperty -Force
    $lp | Add-Member -Name "boxes" -Value $boxes -MemberType NoteProperty -Force
    $lp | Add-Member -Name "scope" -Value $Fdata.scope -MemberType NoteProperty -Force
}

Write-Host "${basename}: "
Write-Host "${basename}: backup locker.properties to file ..."
$lp > D:\locker.properties.txt

# assemble $body from $lp
$body = ($lp | ConvertTo-Json)
$body | Out-File -FilePath "C:\local\status\locker-registration.properties" -ErrorAction SilentlyContinue
Write-Host "${basename}: Locker Profile Created" -ForegroundColor Green
Write-Host "${basename}: "


Write-Host "${basename}: lp check ..."
$lp

#$lp.address
#$lp.address.zh_HK

$lockercfgfile = "locker-configuration.properties"

try {
    Write-Host "${basename}: "
    Write-Host "${basename}: Using $LockerRegistrationHttpMethod on locker for $destEnvironment  ..." -ForegroundColor Yellow

    $LockerRegistrationResult = Invoke-RestMethod -Method $LockerRegistrationHttpMethod -Body $body -ContentType "application/json; charset=utf-8" -Headers $LockerCloudApiKey -Uri $LockerRegistrationUrl -DisableKeepAlive -TimeoutSec 30
    if ($LockerRegistrationCheck) {
        $LockerCloudId = $LockerRegistrationCheck
    }
    else {
        $LockerCloudId = $($LockerRegistrationResult.lockerId)
    }

    Write-Host "${basename}: $($Fdata.LockerName) $LockerRegistrationHttpMethod successful in $destEnvironment ..." -ForegroundColor Green
    Write-Host "${basename}: LockerCloud ID: $LockerCloudId" -ForegroundColor Green

    # hard-store the LockerCloudId (reference only); file-creation time serves as a registration timestamp
    New-Item -ItemType File -Path "C:\local\status\$LockerCloudId" -ErrorAction SilentlyContinue
    Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -Append -FilePath "c:\local\status\$LockerCloudId"

    # if LockerCloud Locker ID changed, add it to bottom of file. (i.e.: Last line is most recent/newest Locker ID)
    #Add-Content -Path "C:\local\status\$env:computername" -Value "4bc0ae55-d000-41d2-84b9-139047d3c950" -Verbose
    Add-Content -Path "C:\local\status\$LockerIdFile" -Value "$LockerCloudId" -Verbose

    Write-Host "${basename}: Retrieving configuration information for $LockerCloudId $destEnvironment ..."

    # capture lockerId and append to url used to get locker configuration url
    if ($LockerRegistrationCheck) {
        Write-Host "Using $LockerConfigurationUrl"
        $LockerConfigurationUrl = $LockerRegistrationUrl
    }
    else {
        $LockerCloudId = $($LockerRegistrationResult.lockerId)
        $LockerConfigurationUrl = "$LockerRegistrationUrl/$($LockerCloudId)"

    }

    $result2 = Invoke-RestMethod -Method Get -DisableKeepAlive -ContentType "application/json; charset=utf-8" -Headers $LockerCloudApiKey -Uri $LockerConfigurationUrl -TimeoutSec 30
    $lockercfg = ($result2.configuration | Out-String).Replace(" : ", "=")
    # Set-Location "D:\"
    $lockercfg | Out-File -FilePath "d:\$lockercfgfile"
    $configContent = Get-Content "d:\$lockercfgfile"
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    #[IO.File]::WriteAllLines($filename, $content)
    [System.IO.File]::WriteAllLines("d:\$lockercfgfile", $configContent, $Utf8NoBomEncoding)

    Write-Host "${basename}: Locker Configuration Created" -ForegroundColor Green

}
catch {
    # set-location d:
    # curl --url $uri -H "X-API-KEY: 123456789" -H "Content-Type: application/json" -d "@locker.properties.txt"
    Write-Host "${basename}: Error somewhere ..." -ForegroundColor Red

    Write-Host "${basename}: StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "${basename}: StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host "${basename}: StatusCode:" $_.Exception.Response.StatusCode.value__

}

Write-Host "${basename}: Locker Registration Complete!`n" -ForegroundColor Green


# Update TeamViewer
Write-Host "${basename}: Teamviewer: Start"

# Groups:
#   disabled: "groupid": "g95467798"
#   testing: "groupid": "g95523178",
#   production: "groupid": "g95523193",
#   deploying: "groupid": "g96017647",
#   DEV: "groupid": "g101663132"

# get current computer TeamViewer ClientID
$TVclientId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\TeamViewer" -Name ClientID).ClientID

# teamviewer api setup

Write-Host "${basename}: TeamViewer: API Setup"
$TVheader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$TVtoken = "Bearer", "2034214-P3aa9qGG323SKWVqqKBV"
$TVheader.Add("authorization", $TVtoken)
$TVdeviceProfileData = @"
{
	"alias": "$($fdata.LockerName)",
	"password": "Locision123",
	"groupid": "$TeamViewerGroupId",
	"description": "LockerLife Locker\nComputerName: $($Fdata.LockerName)\nType: $typeDescription"
}
"@


Write-Host "${basename}: TeamViewer: Test API Connectivity ..."
$ping = Invoke-RestMethod -Uri "https://webapi.teamviewer.com/api/v1/ping" -ContentType $ContentTypeJsonU8 -Method Get -Headers $TVheader

if ($ping.token_valid -eq "True") {
    Write-Host "${basename}: TeamViewer API Connection Established" -ForegroundColor Green
    # Note: TeamViewer API calls this "remotecontrol_id"
    # changes to device profile require "device_id"
    # Need to convert "remotecontrol_id" to "device_id"
    $TVremoteControlId = "r" + $TVclientId
    Write-Host "${basename}: TeamViewer: Init ..."
    $TVprofileUri = "https://webapi.teamviewer.com/api/v1/devices/?remotecontrol_id=" + $TVremoteControlId
    $TVdeviceProfile = Invoke-RestMethod -Method Get -Uri $TVprofileUri -Headers $TVheader

    Write-Host "${basename}: TeamViewer: Get Profile"
    $TVprofileUri = "https://webapi.teamviewer.com/api/v1/devices/?remotecontrol_id=" + $TVremoteControlId
    $TVdeviceProfile = Invoke-RestMethod -Method Get -Uri $TVprofileUri -Headers $TVheader

    Write-Host "${basename}: TeamViewer: Move locker into teamviewer to $destEnvironment group"
    $TVdeviceUri = "https://webapi.teamviewer.com/api/v1/devices/" + $TVdeviceProfile.devices.device_id
    $TVrepsonse = Invoke-RestMethod -Method Put -Uri $TVdeviceUri -Headers $TVheader -ContentType $ContentTypeJsonU8 -Body $TVdeviceProfileData
    Write-Host "${basename}: Teamviewer: Locker Moved into $destEnvironment group" -ForegroundColor Green

    Write-Host "${basename}: Teamviewer: END"
    Write-Host "${basename}: Teamviewer Complete`n" -ForegroundColor Green

}
else {
    Write-Host "${basename}: Unable to connect to TeamViewer API" -ForegroundColor Red
}


Write-Host "${basename}: Starting Services ..."
Restart-Service -Name "data-collection"
Restart-Service -Name "scanner"
Restart-Service -Name "core"

Write-Host "${basename}: Checking Services ..."
Get-Service -Name "data-collection"
Get-Service -Name "scanner"
Get-Service -Name "core"

# Write-Host "${basename}: Rotating logs"
# c:\local\bin\nssm.exe rotate data-collection
# c:\local\bin\nssm.exe rotate scanner
# c:\local\bin\nssm.exe rotate core

# pull down new locker-console (purple screen)
Write-Host "${basename}: Updating locker-console ..."
Set-Location -Path "D:"

if (!(Test-Path "D:\Locker-Console\Locker-Console-2.zip" -ErrorAction SilentlyContinue)) {
    Remove-Item -Path "d:\Locker-Console" -Recurse -Force
    New-Item -ItemType Directory -Path "D:\Locker-Console" -Force
    Set-Location -Path "D:\Locker-Console"
    Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/app/Locker-Console-2.zip" -OutFile "d:\Locker-Console\Locker-Console-2.zip" -Verbose
    7z.exe x -aoa -y .\Locker-Console-2.zip
    Write-Host "Updating locker-console ... Done" -ForegroundColor Green
    #Pop-Location
}
else {
    Write-Host "${basename}: Locker-Console already up-to-date" -ForegroundColor Green
}
#Pop-Location

$sim = (Get-ChildItem -Path "C:\local\status\8985*").Name
$deployDate = (Get-ChildItem -Path "C:\local\status\8985*").CreationTime
$LockerConsoleLocalIpAddress = ([net.dns]::GetHostAddresses("")).IPAddressToString
$LockerConsoleExternalIpAddress = (Invoke-RestMethod -Method Get -Uri "https://httpbin.org/ip").origin

$EndTime = (Get-Date).Second
$runtime = $StartTime - $EndTime

Write-Host "Registration took $($EndTime - $StartTime) seconds to run"


Write-Host "${basename}: Pre-flight checks:" -ForegroundColor Green


Write-Host "${basename}: Verify services startup parameters ..." -ForegroundColor Yellow
Write-Host "${basename}: 15-second timer to review ..." -ForegroundColor Yellow

[Console]::OutputEncoding = [Text.Encoding]::Unicode
nssm.exe get core AppParameters
nssm.exe get data-collection AppParameters
nssm.exe get scanner AppParameters
nssm.exe get kioskserver AppParameters
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8





# send email
Write-Host "${basename}: Sending email ..."

if ($destEnvironment -eq "PRODUCTION") {
    $to = "locker-admin@lockerlife.hk"
    $cc = "pi-admin@locision.com"
    #$to = "derekyuen@l2iot.com"
    #$cc = "pi-admin@locision.com"
}
else {
    $to = "derekyuen@l2iot.com"
    $cc = "pi-admin@locision.com"
    #$to = "derekyuen@l2iot.com"
    #$cc = "gilbertzhong@locision.com"
}

$ehlo_domain = "lockerlife.hk"
$from = "postmaster@lockerlife.hk"
$fromname = "Locker Registration Robot"
$returnpath = "derekyuen@lockerlife.hk"
$subject = "locker-registration: $($Fdata.LockerName) $destEnvironment"
$attach = "d:\locker.properties.txt"
$mimetype = "text/plain"

$SMTPServer = "ns62.hostingspeed.net"
$SMTPPort = "587"
$Username = "postmaster@lockerlife.hk"
$Password = "Locision123"

$rfc822body = @"
Hi, it's me - your friendly Locker Registration Robot!

I registered another locker today. Details as follows:

LockerLife $destEnvironment Environment

--- CUSTOMER VISIBLE - PLEASE VERIFY ---

Locker Name: $($Fdata.LockerName)
Customer Service Number: $($lp.csNumber)
Operational Hours: $($lp.openTime)

Locker Structure: $($lp.lockerProfile.lockerStructure)

Description:
  English: $($lp.description.en)
  Chinese: $($lp.description.zh_HK)

Address (English):
  Room: $($lp.address.en.room)
  Building: $($lp.address.en.building)
  Street: $($lp.address.en.street)
  Town: $($lp.address.en.town)
  District: $($lp.address.en.district)
  City: $($lp.address.en.city)

Address (Chinese):
  Room: $($lp.address.zh_HK.room)
  Building: $($lp.address.zh_HK.building)
  Street: $($lp.address.zh_HK.street)
  Town: $($lp.address.zh_HK.town)
  District: $($lp.address.zh_HK.district)
  City: $($lp.address.zh_HK.city)

GPS Coordinates: $($lp.location.lat)N, $($lp.location.lon)W (DMS)



--- LOCKERLIFE INTERNAL USE ONLY ---

Locker Name: $($Fdata.LockerName)
$destEnvironment Environment

Deployment Date: $deployDate
Registration Date: $(Get-Date)

Locker ID: $LockerCloudId
Locker Console (PC) Name: $($Fdata.LockerShortName)
Locker Console IP Address (internal): $LockerConsoleLocalIpAddress
Locker Console IP Address (external): $LockerConsoleExternalIpAddress

TeamViewer ID: $TVclientId
TeamvViewer Group: $destEnvironment

Camera Model:
Camera IP Address:
Camera Serial Number:

Router IMEI:
Current Active SIM Card:
SIM ICCID: $sim


Locker Profile:
$lp


Love,
Locker Registration Robot

"@

$message = New-Object System.Net.Mail.MailMessage
$message.subject = $subject
$message.body = $rfc822body
$message.to.add($to)
$message.cc.add($cc)
$message.from = $username
$message.attachments.add($attach)

$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
$smtp.send($message)


Write-Host "${basename}: Email Sent `n" -ForegroundColor Green


# rename computer using $LockerShortName
# if (!($fdata.LockerShortName -eq $env:computername)) {
#     Rename-Computer -NewName $($Fdata.LockerShortName) -Force -ErrorAction SilentlyContinue
# }

Write-Host "${basename}: END"

# END
