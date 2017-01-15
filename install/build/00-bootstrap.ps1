# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-bootstrap

# Allow unattended reboots
$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

# stop windows time service
Stop-Service w32time -Confirm:$False

# set timezone
& "$Env:WinDir\System32\tzutil.exe" /s "China Standard Time"

# set time
& "$Env:WinDir\System32\w32tm.exe" /config /syncfromflags:manual /manualpeerlist:"stdtime.gov.hk 0.asia.pool.ntp.org 3.asia.pool.ntp.org"

# start windows time service
Start-Service w32time -Confirm:$False

cinst chocolatey --version 0.9.10.3 --forcex86 --allow-downgrade
choco pin add -n chocolatey -y

cinst 7zip --forcex86

# important directories
New-Item -Path C:\temp -ItemType directory -Force
New-Item -Path C:\local\bin -ItemType Directory -Force
New-Item -Path C:\local\src -ItemType Directory -Force
New-Item -Path C:\local\status -ItemType Directory -Force

#Install-ChocolateyEnvironmentVariable "JAVA_HOME" "d:\java\jre\bin"

# shortcut to the lockerlife/deploy on the desktop
Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\Deployment Team.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://lockerlife.hk/deploy" -Description "LockerLife Deployment Start"
if (Test-PendingReboot) { Invoke-Reboot }

  
# $a = New-Item -ItemType Directory "$env:USERPROFILE\Desktop\Unattended Builds" -Force

# create scripts that kick off the required build
## Base Build:
#$script = @"
#    `$cred = Get-Credential $env:USERNAME
#    Install-BoxstarterPackage https://gitlab.com/locker-admin/...ps1 -Credential `$cred
#"@
#Set-Content (Join-Path $a "BaseBuild.ps1") ($script)

## Scan SIM Card:
#$script = @"
#    `$cred = Get-Credential $env:USERNAME
#    Install-BoxstarterPackage https://gitlab.com/locker-admin/...ps1 -Credential `$cred
#"@
#Set-Content (Join-Path $a "scan-sim-card.ps1") ($script)

## Register Locker with Locker Cloud:
#$script = @"
#    `$cred = Get-Credential $env:USERNAME
#    Install-BoxstarterPackage https://gitlab.com/locker-admin/...ps1 -Credential `$cred
#"@
#Set-Content (Join-Path $a "register-locker.ps1") ($script)

## Finish Locker Deployment:
#$script = @"
#    `$cred = Get-Credential $env:USERNAME
#    Install-BoxstarterPackage https://gitlab.com/locker-admin/...ps1 -Credential `$cred
#"@
#Set-Content (Join-Path $a "finish-locker-deployment.ps1") ($script)


### ----- reload current shell elevated to administrator -> prepare for 01-bootstrap -> exec 01-bootstrap ----- ###

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    exit
}

# Skipping 10 lines because if running when all prereqs met, statusbar covers powershell output
1..10 |% { Write-Host ""}

# turn off startup sounds
Set-ItemProperty -Path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name DisableStartupSound -Type DWord -Value 1

#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation] "DisableStartupSound"=dword:00000000

# stop windows update service
#Stop-Service wuauserv -Confirm:$False

# disable windows update
#Set-Service wuauserv -StartupType Disabled -Confirm:$False

#reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 1 /f


New-Item -Path "~\Documents\WindowsPowerShell" -ItemType directory -Force


if (Test-Path "$env:userprofile\Desktop\*.lnk") {
    Remove-Item "$env:userprofile\Desktop\*.lnk"
}

Remove-Item "$env:userprofile\Desktop\*.lnk"

# set region
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sLanguage -Value ENU
Set-ItemProperty -Path "HKCU:\Control Panel\International\Geo" -Name Nation -Value 104

#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

Add-Computer -WorkGroupName "LOCKERLIFE.HK"

# To reboot or not to reboot?
if (Test-PendingReboot) { Invoke-Reboot }

#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?http://lockerlife.hk/deploy/01-bootstrap.ps1

cinst dotnet4.6.2 --version 4.6.01590.0
if (Test-PendingReboot) { Invoke-Reboot }

cinst Boxstarter.Common
cinst boxstarter.WinConfig
cinst Boxstarter.Chocolatey
if (Test-PendingReboot) { Invoke-Reboot }

cinst gow
cinst nircmd
cinst xmlstarlet
cinst curl
cinst nssm

cinst ie11
if (Test-PendingReboot) { Invoke-Reboot }

& RefreshEnv

#chocolatey feature disable -n=allowGlobalConfirmation


#Install-ChocolateyEnvironmentVariable 'JAVA_HOME' 'path\to\jre' 'Machine'
Install-ChocolateyEnvironmentVariable "baseurl" "http://lockerlife.hk/deploy"
Install-ChocolateyEnvironmentVariable -variableName "JAVA_HOME" -variableValue "d:\java\jdk\bin" -variableType "Machine"
Install-ChocolateyEnvironmentVariable "local" "C:\local"

# Windows Explorer Settings
Set-WindowsExplorerOptions -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess

# Small taskbar
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom

#chocolatey feature enable -n=allowGlobalConfirmation

cinst chocolatey-core.extension
cinst chocolatey-uninstall.extension
cinst git.install -params '"/WindowsTerminal /GitOnlyOnPath /NoAutoCrlf"'

cinst powershell -version 3.0.20121027
if (Test-PendingReboot) { Invoke-Reboot }

cinst powershell4
if (Test-PendingReboot) { Invoke-Reboot }

cinst microsoftsecurityessentials -version 4.5.0216.0
if (Test-PendingReboot) { Invoke-Reboot }

choco install teamviewer.host --version 12.0.72365
choco install vim
choco install jq
choco install clink
choco install putty
choco install rsync
choco install wget
choco install nssm
choco install teraterm
choco install sysinternals

& curl https://api.github.com/zen ; echo ""

