# Derek Yuen <derekyuen@lockerlife.hk>


$ErrorActionPreference = "Continue"
#
## Verify Running as Admin
#$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
#If (!( $isAdmin )) {
#	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
#	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
#	1..5 | % { Write-Host }
#	exit
#}

Write-Host "LockerLife Deployment Team - Tools"
Write-Host "Disabling Touch Screen"

Disable-UAC

$devcon = "C:\local\bin\devcon.exe"
#"USB\VID_222A&PID_0001*"," "USB\VID_0EEF&PID_C000"
$touchscreenId = "USB\VID_0EEF&PID_C000"

# C:\local\bin\devcon.exe disable "USB\VID_222A&PID_0001*"
# USB\VID_222A&PID_0001\6&97C04CA&0&6                         : Disable failed
# USB\VID_222A&PID_0001&MI_00\7&659BED&0&0000                 : Disabled
# USB\VID_222A&PID_0001&MI_01\7&659BED&0&0001                 : Disable failed 

if (!(Test-Path "C:\local\bin\devcon.exe")) {
	$WebClient = New-Object System.Net.WebClient
	$WebClient.DownloadFile("$env:deployurl/bin/devcon.exe","$local\bin\devcon.exe")
}


$audioID = ""
$displayID = "@PCI\VEN_8086&DEV_0A16&SUBSYS_130D1043&REV_09\3&11583659&0&10"
. $devcon status $touchscreenId
. $devcon disable $touchscreenId
#. $devcon restart $audioID
#. $devcon restart $displayId


C:\local\bin\devcon status "USB\VID_0EEF&PID_C000"
C:\local\bin\devcon disable "USB\VID_0EEF&PID_C000"


# cleanup
Enable-UAC
