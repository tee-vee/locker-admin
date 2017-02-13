# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 10-configure -- perform local identification tasks and setup for locker registration
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 10-identify"
#$basename = Split-Path -Leaf $PSCommandPath
#Set-PSDebug -Trace 1


$basename = "10-identify"
#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------
$ErrorActionPreference = "Continue"
$timer = Start-TimedSection "10-identify"

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
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1

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


#--------------------------------------------------------------------
Write-Host "$basename -- Set local variables"
#--------------------------------------------------------------------

## dropbox api
#$authtoken "5nHPkEeCXnAAAAAAAAAAJI71YUOYRZgv4PeQ1h1ZHGmCHnbnosmjFdqkg5NPSggL"
$authtoken = "5nHPkEeCXnAAAAAAAAAAIyI533NP8-Y1zXEK7m2LOvAk4-HC0jGOZLKjEoGcq2gU"
$token = "Bearer " + $authtoken


## teamviewer api


#--------------------------------------------------------------------


# find for camera
#"$Env:CameraIpAddress" = "$Env:local\bin\UPnPScan.exe" -m -i a

#--------------------------------------------------------------------

if ((Get-WmiObject Win32_ComputerSystem).domain -eq "LOCKERLIFE.HK" -And (($env:iccid))) { Write-Host "ok" }
Add-Type -AssemblyName Microsoft.VisualBasic

Write-Host "Scan SIM card to identify locker" -ForegroundColor Red
$Env:iccid = [Microsoft.VisualBasic.Interaction]::InputBox('Scan SIM Card', 'LockerLife Locker Deployment', "")
if ($env:iccid) { New-Item -ItemType File -Path "C:\local\status\$env:iccid" }

Write-Host "Scan locker barcode for serial number" -ForegroundColor Red
$Env:lockerserialnumber = [Microsoft.VisualBasic.Interaction]::InputBox('Scan Locker Serial Barcode', 'LockerLife Locker Deployment', "")


# $Env:sitename = & "$Env:curl" -Ss -k --url "https://gist.githubusercontent.com/tee-vee/bfa0ea73871ce47e6436beb88b2b77ac/raw/locker-iccid.db" | findstr "$Env:iccid" | awk '{ print $2 }'
# $Env:sitename = & "$Env:curl" -Ss -k --url "https://gist.githubusercontent.com/tee-vee/bfa0ea73871ce47e6436beb88b2b77ac/raw/locker-iccid.db" | Select-String "$Env:iccid" | Out-String | %{ $_.Split(' ')[1]; } | foreach { $_ -replace "`r|`n","" }

# Search Dropbox locker-admin
$uri = "https://api.dropboxapi.com/2/files/search"
$token = "Bearer " + $authtoken
$body = '{"path":"/locker-admin/locker","query":"' +  $env:iccid + '"}'
$yy = Invoke-RestMethod -Uri $uri -Headers @{ "Authorization" = $token } -Body $body -ContentType 'application/json' -Method Post
#$yy
#Write-Host "Number of matches: " $yy.start
#$yy.matches
#$yy.matches.metadata
#$yy.matches.metadata.path_display
$env:sitename = $yy.matches.metadata.path_display | %{ $_.Split('/')[3]; }
if ($env:sitename) { New-Item -ItemType File -Path "C:\local\status\$env:sitename" }

Write-Host "$basename -- iccid -- $env:iccid"
Write-Host "$basename -- sitename - $env:sitename"
Write-Host "$basename -- serial number - $env:lockerserialnumber"
#Write-Host "hostname - $Env:hostname"
#Write-Host "sitename - $Env:sitename"
#Write-Host "serial number - $Env:lockerserialnumber"


if (!$Env:sitename) {
    WriteError "*** WARNING *** WARNING *** WARNING *** WARNING *** WARNING ***"
    WriteError "This SIM card is not authorized for LockerLife Locker Deployment"
    WriteError "Send email to locker-admin@lockerlife.hk for further assistance."
    WriteErrorAndExit "Exiting"
    New-Item -Path C:\DEPLOYMENT-UNAUTHORIZED -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
    ## function call to send error email

} else {
    # --------------------------------------------------------------------------------------------
    # get MAC address for cloud registration
    # REQUIRES: ALL NETWORK PORT MAC ADDRESS (INCLUDING WIRELESS)
    # WARNING: MUST GET NETWORK MAC ADDRESS *BEFORE* DISABLE WIRELESS INTERFACES
    # --------------------------------------------------------------------------------------------

    #Write-Host "---"
    #Write-Host "GET MAC ADDRESS FOR CLOUD REGISTRATION"
    #Set-Location -Path "$Env:local\src\LOCKER\$Env:sitename"
    #New-Item -Path "$Env:local\src\LOCKER\$Env:sitename\config\tmp" -ItemType Directory -ErrorAction SilentlyContinue
    #& cmd /c mklink getmac-copy.bat "$Env:local\src\build\getmac-copy.bat"
    #mklink combine-locker-properties.bat %LOCKERINSTALL%\build\combine-locker-properties.bat
    #CALL combine-locker-properties.bat
    #move locker.properties.part1 %_tmp%
    #move locker.properties.part2 %_tmp%

    if ($Env:sitename -like 'UFO*')
    {
      # rename as UFO
      Install-ChocolateyEnvironmentVariable "UfoIccid" "NULL"
      $Env:UfoIccid = $Env:iccid.SubString($Env:iccid.Length-5)
      Write-Host "$Env:UfoIccid"
      Rename-Computer -NewName "UFO-$Env:UfoIccid" -Force -Confirm:$false -Restart
			#(Get-WmiObject Win32_ComputerSystem).Rename("MyMachineName") | Out-Null
    }
    else
    {
      Uninstall-ChocolateyEnvironmentVariable -VariableName 'UfoIccid'
      Rename-Computer -NewName "$Env:sitename" -Force -Confirm:$false -Restart
			#(Get-WmiObject Win32_ComputerSystem).Rename("MyMachineName") | Out-Null
    }

    Add-Computer -WorkGroupName "LOCKERLIFE.HK"
    Write-Host "."
    Write-Host "`t SIM ICCID $Env:iccid authorized for LockerLife Locker Deployment"
    Write-Host "`t Locker sitename: $Env:sitename"
    Write-Host "."
    Write-Host "`t Proceeding to Stage 2"
}

Get-BitsTransfer | Complete-BitsTransfer

#--------------------------------------------------------------------
# finishing #
#--------------------------------------------------------------------

# Internet Explorer: All:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255

# Internet Explorer:History:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 1

# Internet Explorer:Cookies:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 2

# Internet Explorer: Temp Internet Files:
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

# Internet Explorer: Form Data:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 16

# Internet Explorer: Passwords:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 32

# Internet Explorer: All:
# rundll32.exe InetCpl.cpl,ClearMyTracksByProcess 4351



Write-Host "Mistake with Locker registration? Double-click the register-locker icon on the desktop..."
#Write-Host "`t Or Continue to the next step ..."
#$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL


# --------------------------------------------------------------------
Write-Host "$basename - Cleanup"
# --------------------------------------------------------------------
Stop-Process -Name iexplore -ErrorAction SilentlyContinue -Verbose

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

# --------------------------------------------------------------------
Write-Host "$basename - Next stage ... "
# --------------------------------------------------------------------
#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?$Env:deployurl/20-setup.ps1
#START http://boxstarter.org/package/url?http://lockerlife.hk/deploy/20-setup.ps1
START http://boxstarter.org/package/url?http://lockerlife.hk/deploy/30-lockerlife.ps1
