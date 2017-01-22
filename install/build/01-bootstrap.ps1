# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 01-bootstrap - primarily a buffer for restarts
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 01-bootstrap"
$basename = $MyInvocation.MyCommand.Name

# source DeploymentConfig
(New-Object Net.WebClient).DownloadString("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1") > C:\local\etc\99-DeploymentConfig.ps1
. C:\local\etc\99-DeploymentConfig.ps1

Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

& RefreshEnv
#chocolatey feature enable -n=allowGlobalConfirmation

& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

Write-Host "."
if (Test-PendingReboot) { Invoke-Reboot }

Write-Host "."
& RefreshEnv

if (Test-PendingReboot) { Invoke-Reboot }

#chocolatey feature disable -n=allowGlobalConfirmation

& curl https://api.github.com/zen ; echo ""

# Internet Explorer: Temp Internet Files:
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

Write-Host "."

& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/02-bootstrap.ps1"
