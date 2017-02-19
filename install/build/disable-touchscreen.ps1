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
$touchscreenId = "USB\VID_0EEF&PID_C000"

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
