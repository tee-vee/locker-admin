# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-bootstrap

# native unzip 
## [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.Filesystem")

# Allow unattended reboots
$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true

#Install-ChocolateyEnvironmentVariable 'JAVA_HOME' 'path\to\jre' 'Machine'
Install-ChocolateyEnvironmentVariable "JAVA_HOME" "d:\java\jre\bin"
Install-ChocolateyEnvironmentVariable "baseurl" "http://lockerlife.hk/deploy"
Install-ChocolateyEnvironmentVariable "deployurl" "http://lockerlife.hk/deploy"
Install-ChocolateyEnvironmentVariable "domainname" "lockerlife.hk"
Install-ChocolateyEnvironmentVariable -variableName "JAVA_HOME" -variableValue "D:\java\jre\bin" -variableType "Machine"
Install-ChocolateyEnvironmentVariable "local" "C:\local"
Install-ChocolateyEnvironmentVariable "_tmp" "C:\temp"
Install-ChocolateyEnvironmentVariable "curl" "$Env:ProgramFiles\Gow\bin\curl.exe"
Install-ChocolateyEnvironmentVariable "rm" "$Env:ProgramFiles\Gow\bin\rm.exe"

choco feature enable -n=allowGlobalConfirmation

# remove limitations
Disable-MicrosoftUpdate
Disa
Disable-UAC
Update-ExecutionPolicy Unrestricted

# Windows Explorer Settings
Set-WindowsExplorerOptions  -EnableShowProtectedOSFiles `
                            -EnableShowFileExtensions `
                            -EnableShowFullPathInTitleBar `
                            -DisableShowRecentFilesInQuickAccess `
                            -DisableShowFrequentFoldersInQuickAccess

# Small taskbar
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom

## Configure Windows Time Service ##
Stop-Service w32time -Confirm:$False                                                # stop windows time service
& "$Env:SystemRoot\System32\tzutil.exe" /s "China Standard Time"                    # set timezone
& "$Env:SystemRoot\System32\w32tm.exe" /config /syncfromflags:manual `
        /manualpeerlist:"stdtime.gov.hk 0.asia.pool.ntp.org 3.asia.pool.ntp.org"    # set time
Start-Service w32time -Confirm:$False                                               # start windows time service


cinst chocolatey --version 0.9.10.3 --forcex86 --allow-downgrade
choco pin add -n chocolatey -y

# fix mis-versioned 7z.exe x64 binary
Move-Item "$Env:ProgramData\chocolatey\tools\7z.exe" "$Env:ProgramData\chocolatey\tools\7z-x64.exe"
Move-Item "$Env:ProgramData\chocolatey\tools\7za.exe" "$Env:ProgramData\chocolatey\tools\7z.exe"

cinst 7zip --forcex86
cinst 7zip.commandline

# important directories
New-Item -Path "~\Documents\WindowsPowerShell" -ItemType directory -Force
New-Item -Path "$Env:_tmp" -ItemType directory -Force
New-Item -Path "$Env:local\bin" -ItemType Directory -Force
New-Item -Path "$Env:local\drivers" -ItemType Directory -Force                      # for drivers (https://github.com/lockerlife-kiosk/deployment)
New-Item -Path "$Env:local\gpo" -ItemType Directory -Force                          # for gpo (on locker-admin github)
New-Item -Path "$Env:local\src" -ItemType Directory -Force                          # for locker-admin source (refactor?)
New-Item -Path "$Env:local\status" -ItemType Directory -Force                       # for deployment logging (refactor to use e: when drive detection code ready)
# $a = New-Item -ItemType Directory "$env:USERPROFILE\Desktop\Unattended Builds" -Force



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

# enable administrator
& "$env:SystemRoot\net.exe" user administrator /active:yes

# turn off startup sounds
#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation] "DisableStartupSound"=dword:00000000
Set-ItemProperty -Path HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name DisableStartupSound -Type DWord -Value 1

# set region
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sLanguage -Value ENU
Set-ItemProperty -Path "HKCU:\Control Panel\International\Geo" -Name Nation -Value 104

#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

Add-Computer -WorkGroupName "LOCKERLIFE.HK"
if (Test-PendingReboot) { Invoke-Reboot }

#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?http://lockerlife.hk/deploy/01-bootstrap.ps1

cinst dotnet4.6.2 --version 4.6.01590.0
if (Test-PendingReboot) { Invoke-Reboot }

# below: requires .Net 4+ to run
cinst Boxstarter.Common
cinst boxstarter.WinConfig
cinst Boxstarter.Chocolatey
cinst chocolatey-core.extension
cinst chocolatey-uninstall.extension

# cleanup desktop
if (Test-Path "$env:userprofile\Desktop\*.lnk") {
    Remove-Item "$env:userprofile\Desktop\*.lnk"
}

if (Test-PendingReboot) { Invoke-Reboot }

cinst gow
cinst nircmd
cinst xmlstarlet
cinst curl
cinst nssm

cinst ie11
if (Test-PendingReboot) { Invoke-Reboot }

& RefreshEnv

cinst git.install -params '"/WindowsTerminal /GitOnlyOnPath /NoAutoCrlf"'

cinst powershell -version 3.0.20121027

Enable-MicrosoftUpdate
# critical Windows svchost.exe memory leak update
& "$Env:curl" -Ss -k -o c:\temp\Windows6.1-KB2889748-x86.msu --url https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot

if (Test-PendingReboot) { Invoke-Reboot }

Disable-MicrosoftUpdate

& "$Env:curl" -Ss -o c:\temp\7z1604.exe --url http://www.7-zip.org/a/7z1604.exe
& c:\temp\7z1604.exe /S

cinst powershell4
if (Test-PendingReboot) { Invoke-Reboot }

cinst microsoftsecurityessentials -version 4.5.0216.0
if (Test-PendingReboot) { Invoke-Reboot }

# --------------------------------------------------------------------------------------------
# Temporarily stop antivirus 
# --------------------------------------------------------------------------------------------
Write-Host "Temporarily disabling antivirus"
& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc
& "$Env:SystemRoot\System32\timeout.exe" /t 5 /nobreak
& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc

Write-Host ""
Write-Host ""
choco install bginfo
choco install teamviewer.host --version 12.0.72365
choco install vim
choco install jq
choco install clink
choco install putty
choco install rsync
choco install wget
choco install nssm
#choco install teraterm
choco install sysinternals

# cleanup desktop
if (Test-Path "$env:userprofile\Desktop\*.lnk") {
    Remove-Item "$env:userprofile\Desktop\*.lnk"
}


Write-Host ""
& "$Env:curl" -Ss -k -o c:\temp\unzip-5.51-1.exe --url https://github.com/lockerlife-kiosk/deployment/blob/master/unzip-5.51-1.exe
& "c:\temp\unzip-5.51-1.exe" /SILENT


# install java/jre
Write-Host "Installing Java/jre"
& "$Env:curl" -k -Ss -o c:\temp\jre-8u111-windows-i586.exe --url http://lockerlife.hk/deploy/_pkg/jre-8u111-windows-i586.exe
& "$Env:curl" -k -Ss -o c:\temp\jre-install.properties --url http://lockerlife.hk/deploy/_pkg/jre-install.properties
& "$Env:_tmp\jre-8u111-windows-i586.exe" INSTALLCFG=c:\temp\jre-install.properties /L %SETUPLOGS%\jre-install.log
# Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre NOSTARTMENU=ENABLE WEB_JAVA=DISABLE WEB_ANALYTICS=DISABLE REBOOT=ENABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE REMOVEOUTOFDATEJRES=1 " 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=216432'

Write-Host ""
& "$Env:curl" -k -Ss -o c:\local\bin\nssm-2.24.zip --url https://nssm.cc/release/nssm-2.24.zip
#"$env:programfiles\7-Zip\7z.exe" e c:\local\bin\nssm-2.24.zip -y

Write-Host ""
& "$Env:curl" -k -Ss -o c:\temp\Windows6.1-KB2889748-x86.msu  --url https://github.com/lockerlife-kiosk/deployment/blob/master/Windows6.1-KB2889748-x86.msu 
& "$Env:curl" -k -Ss -o c:\temp\402810_intl_i386_zip.exe --url https://github.com/lockerlife-kiosk/deployment/blob/master/402810_intl_i386_zip.exe
& "$Env:curl" -k -Ss -o c:\local\bin\nircmd.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/nircmd.zip
#"$env:programfiles\7-Zip\7z.exe" e c:\local\bin\nircmd.zip -y

Write-Host ""
& "$Env:curl" -k -Ss -o c:\local\bin\xmlstarlet-1.6.1-win32.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/xmlstarlet-1.6.1-win32.zip
#"$env:programfiles\7-Zip\7z.exe" e c:\local\bin\xmlstarlet-1.6.1-win32.zip -y

Write-Host ""
& "$Env:curl" -Ss -k -o c:\local\bin\devcon.exe --url https://github.com/lockerlife-kiosk/deployment/blob/master/devcon.exe
& "$Env:curl" -Ss -k -o c:\local\bin\nssm.exe --url https://github.com/lockerlife-kiosk/deployment/blob/master/nssm.exe
& "$Env:curl" -Ss -k -o c:\local\bin\hstart.exe --url https://github.com/lockerlife-kiosk/deployment/blob/master/hstart.exe

& "$Env:curl" -Ss -o c:\local\bin\update-Gac.ps1 --url https://msdnshared.blob.core.windows.net/media/MSDNBlogsFS/prod.evol.blogs.msdn.com/CommunityServer.Components.PostAttachments/00/08/92/01/09/update-Gac.ps1 

Write-Host ""
Write-Host "Downloading Drivers"
& "$Env:curl" -Ss -k -o c:\local\drivers\printer-filter.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/printer-filter.zip
& "$Env:curl" -Ss -k -o c:\local\drivers\printer.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/printer.zip
& "$Env:curl" -Ss -k -o c:\local\drivers\scanner.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/scanner.zip

Write-Host ""
Write-Host "Gpo"
& "$Env:curl" -Ss -k -o c:\local\gpo\production-gpo.zip --url http://lockerlife.hk/deploy/production-gpo.zip



Remove-Item "$env:userprofile\Desktop\*.lnk"

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

chocolatey feature disable -n=allowGlobalConfirmation

# shortcut to the lockerlife/deploy on the desktop
Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\Deployment Team.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://lockerlife.hk/deploy" -Description "LockerLife Deployment Start"

Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\Deployment Team.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?http://lockerlife.hk/deploy/00-bootstrap.ps1" -Description "Redeploy Locker"
Write-Host ""
if (Test-PendingReboot) { Invoke-Reboot }

Write-Host ""
& "$Env:curl" -Ss -k --url https://api.github.com/zen ; echo ""
Write-Host ""

# & "$Env:rm" -r -f "$Env:local\src\*"
& "$Env:ProgramFiles\git\cmd\git.exe" clone --progress https://lockerlife-kiosk:Locision123@github.com/tee-vee/locker-admin.git "$Env:local\src"
& "$Env:rm" -rfv "$Env:local\src\.git"
Write-Host ""
Write-Host ""
Write-Host "00-bootstrap complete."
Write-Host ""
Write-Host ""

