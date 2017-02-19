# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 10-configure -- perform local identification tasks and setup for locker registration
$host.ui.RawUI.WindowTitle = "10-identify"

$basename = "10-identify"
$ErrorActionPreference = "Continue"

# --------------------------------------------------------------------------------------------
Write-Host "$basename - Lets start"
# --------------------------------------------------------------------------------------------
$timer = Start-TimedSection "10-identify"

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	1..5 | % { Write-Host }
	exit
}

## backup
#Enable-ComputerRestore -Verbose -Drive "C:\" -Confirm:$false
#Checkpoint-Computer -Description "Before 00-init" -Verbose


# --------------------------------------------------------------------------------------------
Write-Host "$basename - Loading Modules ..."
# --------------------------------------------------------------------------------------------

# Import BitsTransfer ...
if (!(Get-Module BitsTransfer -ErrorAction SilentlyContinue)) {
	Import-Module BitsTransfer
} else {
	# BitsTransfer module already loaded ... clear queue
	Get-BitsTransfer -Verbose | Complete-BitsTransfer -Verbose
}

if (Test-Path C:\local\lib\WASP.dll) {
  Import-Module C:\local\lib\WASP.dll -Verbose
}


# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1
$basename = "10-identify"

SetConsoleWindow
$host.ui.RawUI.WindowTitle = "10-identify"

# close previous IE windows ...
Stop-Process -Name "iexplore" -ErrorAction SilentlyContinue

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted


# Start Time and Transcript
Start-Transcript -Path "$Env:temp\$basename.log"
$StartDateTime = Get-Date
Write-Host "`t Script started at $StartDateTime" -ForegroundColor Green


Set-TaskbarOptions -Size Small -Lock -Dock Bottom
Set-WindowsExplorerOptions -DisableShowProtectedOSFiles -DisableShowFileExtensions -DisableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess

(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/bin/curl.exe","C:\Windows\System32\curl.exe")


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Set local variables"
# --------------------------------------------------------------------------------------------

# Check if we're running PowerShell Version 2
# if running version 2, then must download and load functions ...
# http://msdn.microsoft.com/en-us/library/fhd1f0sw(v=vs.110).aspx
#(New-Object System.Net.WebClient).DownloadString("http://stackoverflow.com")
#

## dropbox api
#$authtoken "5nHPkEeCXnAAAAAAAAAAJI71YUOYRZgv4PeQ1h1ZHGmCHnbnosmjFdqkg5NPSggL"
#$authtoken = "5nHPkEeCXnAAAAAAAAAAIyI533NP8-Y1zXEK7m2LOvAk4-HC0jGOZLKjEoGcq2gU"
#$token = "Bearer " + $authtoken


## teamviewer api


#--------------------------------------------------------------------
#bcdedit /set bootux disabled


# find for camera
#"$Env:CameraIpAddress" = "$Env:local\bin\UPnPScan.exe" -m -i a

#--------------------------------------------------------------------

#if ((Get-WmiObject Win32_ComputerSystem).domain -eq "LOCKERLIFE.HK" -And (($env:iccid))) { Write-Host "ok" }
#Add-Type -AssemblyName Microsoft.VisualBasic
#
#Write-Host "Scan SIM card to identify locker" -ForegroundColor Red
#$Env:iccid = [Microsoft.VisualBasic.Interaction]::InputBox('Scan SIM Card', 'LockerLife Locker Deployment', "")
#if ($env:iccid) { New-Item -ItemType File -Path "C:\local\status\$env:iccid" }
#
#Write-Host "Scan locker barcode for serial number" -ForegroundColor Red
#$Env:lockerserialnumber = [Microsoft.VisualBasic.Interaction]::InputBox('Scan Locker Serial Barcode', 'LockerLife Locker Deployment', "")

# Search Dropbox locker-admin
#$uri = "https://api.dropboxapi.com/2/files/search"
#$token = "Bearer " + $authtoken
#$body = '{"path":"/locker-admin/locker","query":"' +  $env:iccid + '"}'
#$yy = Invoke-RestMethod -Uri $uri -Headers @{ "Authorization" = $token } -Body $body -ContentType 'application/json' -Method Post
#$yy
$url = "https://api.dropboxapi.com/2/files/search"
$data = @"
{\"path\":\"/locker-admin/locker\",\"query\":\"8985207155208607310\"}
"@
c:\windows\system32\curl.exe -X POST --url $url --header \"Authorization: Bearer pUG9KY-HtOAAAAAAAAAAXDMVy0VLbbw5jIi6f5PvpaXsHVaNTE4TSAjnt1ioy0Q5\" --header 'Content-Type: application/json' --data $data
	Start-Sleep -Seconds 60
#Write-Host "Number of matches: " $yy.start
#$yy.matches
#$yy.matches.metadata
#$yy.matches.metadata.path_display
#$env:sitename = $yy.matches.metadata.path_display | %{ $_.Split('/')[3]; }
#if ($env:sitename) { New-Item -ItemType File -Path "C:\local\status\$env:sitename" }

Write-Host "$basename -- iccid -- $env:iccid"
Write-Host "$basename -- sitename - $env:sitename"
Write-Host "$basename -- serial number - $env:lockerserialnumber"
#Write-Host "hostname - $Env:hostname"
#Write-Host "sitename - $Env:sitename"
#Write-Host "serial number - $Env:lockerserialnumber"

#
#if (!$Env:sitename) {
#    WriteError "*** WARNING *** WARNING *** WARNING *** WARNING *** WARNING ***"
#    WriteError "This SIM card is not authorized for LockerLife Locker Deployment"
#    WriteError "Send email to locker-admin@lockerlife.hk for further assistance."
#    WriteErrorAndExit "Exiting"
#    New-Item -Path C:\DEPLOYMENT-UNAUTHORIZED -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
#    ## function call to send error email
#
#} else {
#    # --------------------------------------------------------------------------------------------
#    # get MAC address for cloud registration
#    # REQUIRES: ALL NETWORK PORT MAC ADDRESS (INCLUDING WIRELESS)
#    # WARNING: MUST GET NETWORK MAC ADDRESS *BEFORE* DISABLE WIRELESS INTERFACES
#    # --------------------------------------------------------------------------------------------
#
#    #Write-Host "---"
#    #Write-Host "GET MAC ADDRESS FOR CLOUD REGISTRATION"
#    #Set-Location -Path "$Env:local\src\LOCKER\$Env:sitename"
#    #New-Item -Path "$Env:local\src\LOCKER\$Env:sitename\config\tmp" -ItemType Directory -ErrorAction SilentlyContinue
#    #& cmd /c mklink getmac-copy.bat "$Env:local\src\build\getmac-copy.bat"
#    #mklink combine-locker-properties.bat %LOCKERINSTALL%\build\combine-locker-properties.bat
#    #CALL combine-locker-properties.bat
#    #move locker.properties.part1 %_tmp%
#    #move locker.properties.part2 %_tmp%
#
#    if ($Env:sitename -like 'UFO*')
#    {
#      # rename as UFO
#      Install-ChocolateyEnvironmentVariable "UfoIccid" "NULL"
#      $Env:UfoIccid = $Env:iccid.SubString($Env:iccid.Length-5)
#      Write-Host "$Env:UfoIccid"
#      Rename-Computer -NewName "UFO-$Env:UfoIccid" -Force -Confirm:$false -Restart
#			#(Get-WmiObject Win32_ComputerSystem).Rename("MyMachineName") | Out-Null
#    }
#    else
#    {
#      Uninstall-ChocolateyEnvironmentVariable -VariableName 'UfoIccid'
#      Rename-Computer -NewName "$Env:sitename" -Force -Confirm:$false -Restart
#			#(Get-WmiObject Win32_ComputerSystem).Rename("MyMachineName") | Out-Null
#    }
#
#    Add-Computer -WorkGroupName "LOCKERLIFE.HK"
#    Write-Host "."
#    Write-Host "`t SIM ICCID $Env:iccid authorized for LockerLife Locker Deployment"
#    Write-Host "`t Locker sitename: $Env:sitename"
#    Write-Host "."
#    Write-Host "`t Proceeding to Stage 2"
#}
#
#Get-BitsTransfer | Complete-BitsTransfer

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
START http://boxstarter.org/package/url?http://lockerlife.hk/deploy/30-lockerlife.ps1

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('~');

#END OF FILE
