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

& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?http://lockerlife.hk/deploy/01-bootstrap.ps1

# To reboot or not to reboot?
if (Test-PendingReboot) { Invoke-Reboot }

