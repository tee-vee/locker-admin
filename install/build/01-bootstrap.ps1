# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 01-bootstrap
# --- RETIRED ---

# Allow unattended reboots
$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true

#Disable-MicrosoftUpdate
#Disable-UAC
#Update-ExecutionPolicy Unrestricted

#chocolatey feature enable -n=allowGlobalConfirmation

#$path = Get-Location
$basename = $MyInvocation.MyCommand.Name

& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

if (Test-PendingReboot) { Invoke-Reboot }

#cinst dotnet4.6.2 --version 4.6.01590.0
#if (Test-PendingReboot) { Invoke-Reboot }

#cinst Boxstarter.Common
#cinst boxstarter.WinConfig
#cinst Boxstarter.Chocolatey
#if (Test-PendingReboot) { Invoke-Reboot }

#cinst gow
#cinst nircmd
#cinst xmlstarlet
#cinst curl
#cinst nssm

#cinst ie11
#if (Test-PendingReboot) { Invoke-Reboot }

& RefreshEnv

#chocolatey feature disable -n=allowGlobalConfirmation

& curl https://api.github.com/zen ; echo ""

& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?http://lockerlife.hk/deploy/02-bootstrap.ps1
