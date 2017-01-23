# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 01-bootstrap - primarily a buffer for restarts
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 01-bootstrap"
$basename = $MyInvocation.MyCommand.Name



#--------------------------------------------------------------------
# Lets start
#--------------------------------------------------------------------

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
$WebClient = New-Object System.Net.WebClient
(New-Object Net.WebClient).DownloadString("$Env:deployurl/99-DeploymentConfig.ps1") > "$Env:temp\99-DeploymentConfig.ps1"
. "$Env:temp\99-DeploymentConfig.ps1"

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

& RefreshEnv
#chocolatey feature enable -n=allowGlobalConfirmation

# & "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

Write-Host "."
if (Test-PendingReboot) { Invoke-Reboot }

Write-Host "."
& RefreshEnv

& curl https://api.github.com/zen ; echo ""

# Internet Explorer: Temp Internet Files:
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

Write-Host "."

# cleanup desktop
CleanupDesktop

RefreshEnv
# touch $Env:local\status\01-bootstrap.done file

#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f
& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/02-bootstrap.ps1"
