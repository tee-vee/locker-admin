# Derek Yuen <derekyuen@lockerlife.hk>


$ErrorActionPreference = "Continue"

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	1..5 | % { Write-Host }
	exit
}

$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("$env:deployurl/bin/devcon.exe","$local\bin\devcon.exe")

Write-Host "LockerLife Deployment Team - Tools"
Write-Host "Disabling Touch Screen"

Disable-UAC

C:\local\bin\devcon status "USB\VID_0EEF&PID_C000"
C:\local\bin\devcon disable "USB\VID_0EEF&PID_C000"

# cleanup
Enable-UAC
