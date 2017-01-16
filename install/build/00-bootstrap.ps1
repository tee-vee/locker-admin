# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-bootstrap

### ----- reload current shell elevated to administrator -> prepare for 01-bootstrap -> exec 01-bootstrap ----- ###

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Let libs/modules load ...
 1..10 |% { Write-Host ""}


 #############
 # Functions #
 #############

 # native unzip
 ## [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.Filesystem")

 function WriteInfo($message)
 {
     Write-Host $message
 }

 function WriteInfoHighlighted($message)
 {
     Write-Host $message -ForegroundColor Cyan
 }

 function WriteSuccess($message)
 {
     Write-Host $message -ForegroundColor Green
 }

 function WriteError($message)
 {
     Write-Host $message -ForegroundColor Red
 }

 function WriteErrorAndExit($message)
 {
     Write-Host $message -ForegroundColor Red
     Write-Host "Press any key to continue ..."
     $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
     $HOST.UI.RawUI.Flushinputbuffer()
     Exit
 }

 function  Get-WindowsBuildNumber
 {
     $os = Get-WmiObject -Class Win32_OperatingSystem
     return [int]($os.BuildNumber)
 }


 ##############
 # Lets start #
 ##############

 #$path = Get-Location
 $basename = $MyInvocation.MyCommand.Name

 # Start Time and Transcript
 Start-Transcript -Path "C:\$basename.log"
 $StartDateTime = get-date
 WriteInfo "$basename Script started at $StartDateTime"

# Load DeploymentConfig ...
# Import-Module BitsTransfer
#Get-BitsTransfer -AllUsers | Remove-BitsTransfer
#Start-BitsTransfer -Source https://gist.githubusercontent.com/tee-vee/b20f5ec8bfc4ce539c9ba8ffbea85753/raw/99-DeploymentConfig.ps1 -Destination C:\ ...?

# If (C:\DEPLOYMENT-UNAUTHORIZED) {
#   WriteError "Deployment Unauthorized"
#   WriteError "Contact email: locker-admin@lockerlife.hk
#   WriteErrorAndExit "Exiting ..."
#}

#####################
# Default variables #
#####################

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
Install-ChocolateyEnvironmentVariable "_temp" "C:\temp"                         # just in case
Install-ChocolateyEnvironmentVariable "logs" "E:\logs"
Install-ChocolateyEnvironmentVariable "curl" "$Env:ProgramFiles\Gow\bin\curl.exe"
Install-ChocolateyEnvironmentVariable "rm" "$Env:ProgramFiles\Gow\bin\rm.exe"

Install-ChocolateyEnvironmentVariable "iccid" "NULL"
Install-ChocolateyEnvironmentVariable "hostname" "NULL"
Install-ChocolateyEnvironmentVariable "sitename" "NULL"
Install-ChocolateyEnvironmentVariable "images" "E:\images"
Install-ChocolateyEnvironmentVariable "imagesarchive" "E:\images\archive"


choco feature enable -n=allowGlobalConfirmation


##########
# Checks #
##########


# Checking for Compatible OS
WriteInfoHighlighted "Checking if OS is Windows 7"

$BuildNumber=Get-WindowsBuildNumber
if ($BuildNumber -le 7601)
{
    # Windows 7 RTM=7600, SP1=7601
    WriteSuccess "`t PASS: OS is Windows 7 (RTM 7600/SP1 7601)"
    } else {
    WriteErrorAndExit "`t FAIL: Windows version $BuildNumber detected and is not supported. Exiting"
}


# remove limitations
Disable-MicrosoftUpdate
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
New-Item -Path "~\Documents\WindowsPowerShell" -ItemType directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "~\Documents\PSConfiguration" -ItemType directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:_tmp" -ItemType directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:logs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:images" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:imagesarchive" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:local\bin" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:local\drivers" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null     # for drivers (https://github.com/lockerlife-kiosk/deployment)
New-Item -Path "$Env:local\etc" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:local\gpo" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null         # for gpo (on locker-admin github)
New-Item -Path "$Env:local\src" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null         # for locker-admin source (refactor?)
New-Item -Path "$Env:local\status" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null      # for deployment logging (refactor to use e: when drive detection code ready)
# $a = New-Item -ItemType Directory "$env:USERPROFILE\Desktop\Unattended Builds" -Force -ErrorAction SilentlyContinue


# enable administrator
& "$env:SystemRoot\net.exe" user administrator /active:yes

# turn off startup sounds
#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation] "DisableStartupSound"=dword:00000001
& "$Env:SystemRoot\System32\reg.exe" ADD HKLM\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation /v DisableStartupSound /t REG_DWORD /d 1 /f
Set-ItemProperty "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1 -Verbose
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1 -Verbose
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" "DisableStartupSound" 1 -Verbose


# set region
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sLanguage -Value ENU
Set-ItemProperty -Path "HKCU:\Control Panel\International\Geo" -Name Nation -Value 104

#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

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
#cinst curl
cinst nssm

cinst ie11
if (Test-PendingReboot) { Invoke-Reboot }

& RefreshEnv

cinst git.install -params '"/WindowsTerminal /GitOnlyOnPath /NoAutoCrlf"'

cinst powershell -version 3.0.20121027

Enable-MicrosoftUpdate
# critical Windows svchost.exe memory leak update
& "$Env:curl" -Ss -k -o c:\temp\Windows6.1-KB2889748-x86.msu --url "https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu"
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot

if (Test-PendingReboot) { Invoke-Reboot }

Disable-MicrosoftUpdate

& "$Env:curl" -Ss -o c:\temp\7z1604.exe --url http://www.7-zip.org/a/7z1604.exe
& c:\temp\7z1604.exe /S

cinst powershell4
# powershell performance issues
# https://blogs.msdn.microsoft.com/powershell/2008/07/11/speeding-up-powershell-startup/
& "$Env:curl" -Ss -k -o fix-powershell4-performance.ps1 --url "https://gist.githubusercontent.com/tee-vee/dd42f3f87160c68c0518217dba4ec21b/raw/c9835bcf2f0ac62225144a26ed53c6bfed784ba8/fix-powershell4-performance.ps1"

if (Test-PendingReboot) { Invoke-Reboot }

choco install powershell-packagemanagement -y

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
choco install psexec
#choco install teraterm
choco install sysinternals

cinst TelnetClient -source windowsfeatures
if (Test-PendingReboot) { Invoke-Reboot }


# cleanup desktop
if (Test-Path "$Env:userprofile\Desktop\*.lnk") {
    Remove-Item "$Env:userprofile\Desktop\*.lnk"
}

WriteInfo ""
WriteInfo "add \local\etc"
& "$Env:curl" -Ss -k -o "$Env:local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg" --url "http://lockerlife.hk/deploy/PRODUCTION-201701-TEAMVIEWER-HOST.reg"

WriteInfo ""
Write-Host "backup (more reliable) unzip"
& "$Env:curl" -Ss -k -o "$Env:_tmp\unzip-5.51-1.exe" --url "https://github.com/lockerlife-kiosk/deployment/blob/master/unzip-5.51-1.exe"
& "$Env:_tmp\unzip-5.51-1.exe" /SILENT


# install java/jre
Write-Host "Installing Java/jre"
& "$Env:curl" -k -Ss -o "$Env:_tmp\jre-8u111-windows-i586.exe" --url "http://lockerlife.hk/deploy/_pkg/jre-8u111-windows-i586.exe"
& "$Env:curl" -k -Ss -o "$Env:_tmp\jre-install.properties" --url "http://lockerlife.hk/deploy/_pkg/jre-install.properties"
& "$Env:_tmp\jre-8u111-windows-i586.exe" INSTALLCFG=c:\temp\jre-install.properties /L "jre-install.log"
# Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre NOSTARTMENU=ENABLE WEB_JAVA=DISABLE WEB_ANALYTICS=DISABLE REBOOT=ENABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE REMOVEOUTOFDATEJRES=1 " 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=216432'

#Write-Host ""
#& "$Env:curl" -k -Ss -o c:\local\bin\nssm-2.24.zip --url https://nssm.cc/release/nssm-2.24.zip
#"$env:programfiles\7-Zip\7z.exe" e c:\local\bin\nssm-2.24.zip -y

Write-Host "updates"
& "$Env:curl" -k -Ss -o c:\temp\Windows6.1-KB2889748-x86.msu  --url https://github.com/lockerlife-kiosk/deployment/blob/master/Windows6.1-KB2889748-x86.msu
& "$Env:curl" -k -Ss -o c:\temp\402810_intl_i386_zip.exe --url https://github.com/lockerlife-kiosk/deployment/blob/master/402810_intl_i386_zip.exe

& "$Env:curl" -k -Ss -o c:\local\bin\nircmd.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/nircmd.zip
#"$env:programfiles\7-Zip\7z.exe" e c:\local\bin\nircmd.zip -y

Write-Host "xmlstarlet"
& "$Env:curl" -k -Ss -o c:\local\bin\xmlstarlet-1.6.1-win32.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/xmlstarlet-1.6.1-win32.zip
#"$env:programfiles\7-Zip\7z.exe" e c:\local\bin\xmlstarlet-1.6.1-win32.zip -y

Write-Host "devcon, nssm, hstart"
& "$Env:curl" -Ss -k -o c:\Windows\System32\devcon.exe --url https://github.com/lockerlife-kiosk/deployment/blob/master/devcon.exe
& "$Env:curl" -Ss -k -o c:\local\bin\nssm.exe --url https://github.com/lockerlife-kiosk/deployment/blob/master/nssm.exe
& "$Env:curl" -Ss -k -o c:\local\bin\hstart.exe --url https://github.com/lockerlife-kiosk/deployment/blob/master/hstart.exe

& "$Env:curl" -Ss -o c:\local\bin\update-Gac.ps1 --url https://msdnshared.blob.core.windows.net/media/MSDNBlogsFS/prod.evol.blogs.msdn.com/CommunityServer.Components.PostAttachments/00/08/92/01/09/update-Gac.ps1

Write-Host ""
Write-Host "Downloading Drivers"
& "$Env:curl" -Ss -k -o c:\local\drivers\printer-filter.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/printer-filter.zip
& "$Env:curl" -Ss -k -o c:\local\drivers\printer.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/printer.zip
& "$Env:curl" -Ss -k -o c:\local\drivers\scanner.zip --url https://github.com/lockerlife-kiosk/deployment/blob/master/scanner.zip

Write-Host ""
& "$Env:curl" -Ss -k -o c:\local\etc\kiosk-production-black.bgi --url http://lockerlife.hk/deploy/kiosk-production-black.bgi

Write-Host ""
Write-Host "Gpo"
& "$Env:curl" -Ss -k -o c:\local\gpo\production-gpo.zip --url http://lockerlife.hk/deploy/production-gpo.zip

# cleanup
Remove-Item "$env:userprofile\Desktop\*.lnk"
& RefreshEnv

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
Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\Deployment Homepage.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://lockerlife.hk/deploy" -Description "LockerLife Deployment Start"
Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\Restart Deployment.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?http://lockerlife.hk/deploy/00-bootstrap.ps1" -Description "Redeploy Locker"
Write-Host ""
if (Test-PendingReboot) { Invoke-Reboot }

Write-Host ""
& "$Env:curl" -Ss -k --url https://api.github.com/zen ; echo ""
Write-Host ""

# & "$Env:rm" -r -f "$Env:local\src\*"
#& "$Env:rm" -rfv "$Env:local\src\.git"
WriteInfo ""
WriteInfo ""
Write-Host "00-bootstrap complete."
Write-Host ""
Write-Host ""

#############
# finishing #
#############

Update-Help

WriteInfo ""
& bginfo "$Env:local\etc\production-admin-bginfo.bgi" /nolicprompt /silent

& "$Env:curl" -Ss -k https://api.github.com/zen ; echo ""
WriteInfo ""

WriteInfo "Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

#WriteSuccess "Press any key to continue..."
#$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL

WriteInfo ""
& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?http://lockerlife.hk/deploy/01-bootstrap.ps1
#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?http://lockerlife.hk/deploy/10-configure.ps1
