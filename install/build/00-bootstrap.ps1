# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-bootstrap
$pswindow.windowtitle = "LockerLife Locker Deployment 00-bootstrap"

$basename = $MyInvocation.MyCommand.Name

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin ))
{
  Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
  Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
  Write-Host; exit
}



$WebClient = New-Object System.Net.WebClient

# source DeploymentConfig
(New-Object Net.WebClient).DownloadString("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1") > C:\local\etc\99-DeploymentConfig.ps1
. C:\local\etc\99-DeploymentConfig.ps1

# Let libs/modules load ...
1..10 | % { Write-Host }

#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user AAICON Locision123' -NoNewWindow
& net user AAICON Locision123


#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff https://live.sysinternals.com/Autologon.exe
#Start-Process 'autologon.exe' -Verb runAs -ArgumentList '/accepteula kiosk \ locision123'

# hide boot

#Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set bootux disabled'
#Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/timeout 2'
#Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "AAICON"
#Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "Locision123"
#Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name ForceAutoLogon -Value 0


##############
# Lets start #
##############

 # Start Time and Transcript
 Start-Transcript -Path "C:\$basename.log"
 $StartDateTime = Get-Date
 Write-Host "$basename Script started at $StartDateTime"


# Load DeploymentConfig ...
# Import-Module BitsTransfer
#Get-BitsTransfer -AllUsers | Remove-BitsTransfer
#Start-BitsTransfer -Source https://gist.githubusercontent.com/tee-vee/b20f5ec8bfc4ce539c9ba8ffbea85753/raw/99-DeploymentConfig.ps1 -Destination C:\ ...?

# If (C:\DEPLOYMENT-UNAUTHORIZED) {
#   WriteError "Deployment Unauthorized"
#   WriteError "Contact email: locker-admin@lockerlife.hk
#   WriteErrorAndExit "Exiting ..."
#}

# temp
Install-ChocolateyShortcut -ShortcutFilePath "$Env:Public\Desktop\LockerDeployment\Restart-00.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/00-bootstrap.ps1" -Description "Redeploy 00"

#####################
# Default variables #
#####################

Install-ChocolateyEnvironmentVariable "baseurl" "http://lockerlife.hk"
Install-ChocolateyEnvironmentVariable "deployurl" "$Env:baseurl/deploy"
Install-ChocolateyEnvironmentVariable "domainname" "lockerlife.hk"

Install-ChocolateyEnvironmentVariable "iccid" "NULL"
Install-ChocolateyEnvironmentVariable "locker-type" "NULL"
Install-ChocolateyEnvironmentVariable "lockerserialnumber" "NULL"
Install-ChocolateyEnvironmentVariable "hostname" "NULL"                         # $hostname == $sitename
Install-ChocolateyEnvironmentVariable "sitename" "NULL"                         # $hostname == $sitename

#Install-ChocolateyEnvironmentVariable 'JAVA_HOME' 'path\to\jre' 'Machine'
#Install-ChocolateyEnvironmentVariable -variableName "JAVA_HOME" -variableValue "D:\java\jre\bin" -variableType "Machine"
Install-ChocolateyEnvironmentVariable "JAVA_HOME" "d:\java\jre\bin"
Install-ChocolateyEnvironmentVariable "local" "C:\local"
Install-ChocolateyEnvironmentVariable "_tmp" "C:\temp"
Install-ChocolateyEnvironmentVariable "_temp" "C:\temp"                         # just in case
Install-ChocolateyEnvironmentVariable "logs" "E:\logs"
Install-ChocolateyEnvironmentVariable "images" "E:\images"
Install-ChocolateyEnvironmentVariable "imagesarchive" "E:\images\archive"

Install-ChocolateyEnvironmentVariable "curl" "$Env:ProgramFiles\Gow\bin\curl.exe"
Install-ChocolateyEnvironmentVariable "rm" "$Env:ProgramFiles\Gow\bin\rm.exe"

#Set-Alias show Get-ChildItem

Write-Host "."
Write-Host "$basename Setting path"
Write-Host "."


choco feature enable -n=allowGlobalConfirmation

##########
# Checks #
##########
Write-Host "."
Write-Host "$basename system eligibility check"
Write-Host "."

# Checking for Compatible OS
Write-Host "Checking if OS is Windows 7"

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
Set-WindowsExplorerOptions -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess

# Small taskbar
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom

## Configure Windows Time Service ##
Stop-Service w32time -Confirm:$False                                                # stop windows time service
& "$Env:SystemRoot\System32\tzutil.exe" /s "China Standard Time"                    # set timezone
& "$Env:SystemRoot\System32\w32tm.exe" /config /syncfromflags:manual /manualpeerlist:"stdtime.gov.hk 0.asia.pool.ntp.org 3.asia.pool.ntp.org"    # set time

Start-Service w32time -Confirm:$False                                               # start windows time service


cinst chocolatey --version 0.9.10.3 --forcex86 --allow-downgrade
choco pin add -n chocolatey -y

# fix mis-versioned 7z.exe x64 binary
#Move-Item -Path "$Env:ProgramData\chocolatey\tools\7z.exe" "$Env:ProgramData\chocolatey\tools\7z-x64.exe" -Force
#Move-Item "$Env:ProgramData\chocolatey\tools\7za.exe" "$Env:ProgramData\chocolatey\tools\7z.exe" -Force

cinst 7zip --forcex86
cinst 7zip.commandline

New-Item -Path "~\Documents\PSConfiguration\Microsoft.PowerShell_profile.ps1" -ItemType File -ErrorAction SilentlyContinue | Out-Null

# important directories
New-Item -Path "~\Documents\WindowsPowerShell" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "~\Documents\PSConfiguration" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "D:\locker-libs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:_tmp" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
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
# & "$env:SystemRoot\System32\net.exe" user administrator /active:yes
Start-Process 'net.exe' -Verb runAs -ArgumentList 'user administrator /active:yes'


# turn off startup sounds
#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation] "DisableStartupSound"=dword:00000001
& "$Env:SystemRoot\System32\reg.exe" ADD HKLM\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation /v DisableStartupSound /t REG_DWORD /d 1 /f
& "$Env:SystemRoot\System32\reg.exe" ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v DisableStartupSound /t REG_DWORD /d 1 /f
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" "DisableStartupSound" 1 -Verbose
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1 -Verbose


# set region
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sLanguage -Value ENU
Set-ItemProperty -Path "HKCU:\Control Panel\International\Geo" -Name Nation -Value 104

#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?$Env:deployurl/01-bootstrap.ps1

cinst dotnet4.6.2 --version 4.6.01590.0
if (Test-PendingReboot) { Invoke-Reboot }

# below: requires .Net 4+ to run
cinst Boxstarter.Common
cinst boxstarter.WinConfig
cinst Boxstarter.Chocolatey
cinst chocolatey-core.extension
cinst chocolatey-uninstall.extension

# cleanup desktop
if (Test-Path "$Env:userprofile\Desktop\*.lnk")
{
    Remove-Item "$Env:userprofile\Desktop\*.lnk"
}

if (Test-PendingReboot) { Invoke-Reboot }
choco install teamviewer.host --version 12.0.72365

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

Write-Host ""
Write-Host "temporarily enabling microsoft update"
Enable-MicrosoftUpdate
# critical Windows svchost.exe memory leak update
& "$Env:curl" -Ss -k -o "$Env:_tmp\Windows6.1-KB2889748-x86.msu" --url "https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu"
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot

if (Test-PendingReboot) { Invoke-Reboot }
Write-Host "."

# usually machine rebooted ...
Write-Host "Disable Windows Update"
Disable-MicrosoftUpdate

Write-Host "."
Write-Host "installing a known-good version of 7z"
& "$Env:curl" -Ss -o "$Env:_tmp\7z1604.exe" --url "http://www.7-zip.org/a/7z1604.exe"
& "$Env:_tmp\7z1604.exe" /S
Write-Host "."


Write-Host "."
Write-Host "Installing Powershell 4"
Write-Host ""
cinst powershell4
# powershell performance issues
# https://blogs.msdn.microsoft.com/powershell/2008/07/11/speeding-up-powershell-startup/
if (!(Test-Path "$Env:local\bin\fix-powershell4-performance.ps1") -Or !(Test-Path "$Env:local\status\powershell4-ngen.ok"))
{
  ##& "$Env:curl" -Ss -k -o "$Env:local\bin\fix-powershell4-performance.ps1" --url "$Env:deployurl/fix-powershell4-performance.ps1"
  #& "$Env:local\bin\fix-powershell4-performance.ps1" -Verb runAs
  iex ((New-Object System.Net.WebClient).DownloadString('$Env:deployurl/fix-powershell4-performance.ps1'))
  #(new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex
}

Write-Host "$basename -- test-reboot"
if (Test-PendingReboot) { Invoke-Reboot }

Write-Host "$basename -- installing psget"
choco install powershell-packagemanagement -y

Write-Host ""
Write-Host "$basename -- Installing Microsoft Security Essentials (antivirus)"
Write-Host ""
cinst microsoftsecurityessentials -version 4.5.0216.0
if (Test-PendingReboot) { Invoke-Reboot }
Write-Host "."

# --------------------------------------------------------------------------------------------
# Temporarily stop antivirus
# --------------------------------------------------------------------------------------------
Write-Host "`n $basename Temporarily disabling antivirus"
Write-Host "."
& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc
& "$Env:SystemRoot\System32\timeout.exe" /t 5 /nobreak
& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc

Write-Host "`n $basename installing additional tools"
choco install bginfo
#choco install vim
choco install jq
choco install clink
#choco install putty
choco install rsync
choco install wget
choco install nssm
choco install psexec
#choco install sysinternals
#choco install teraterm

Write-Host "."
Write-Host "Installing Telnet Client (dism/windowsfeatures)"
cinst TelnetClient -source windowsfeatures
if (Test-PendingReboot) { Invoke-Reboot }


# cleanup desktop
if (Test-Path "$Env:UserProfile\Desktop\*.lnk")
{
    Write-Host "$basename cleaning up desktop"
    Remove-Item "$Env:UserProfile\Desktop\*.lnk"
    Remove-Item "$Env:Public\Desktop\*.lnk"
}

Write-Host "`n $basename second backup (more reliable) unzip"
& "$Env:curl" -Ss -k -o "$Env:_tmp\unzip-5.51-1.exe" --url "$Env:deployurl/unzip-5.51-1.exe"
& "$Env:_tmp\unzip-5.51-1.exe" /SILENT

$WebClient.DownloadFile("http://lockerlife.hk/deploy/_pkg/QuickSet-2.07-bulid0805.msi","C:\temp\QuickSet-2.07-bulid0805.msi")


# install java/jre
Write-Host "`n $basename Installing Java jre"
& "$Env:curl" -k -Ss -o "$Env:_tmp\jre-8u111-windows-i586.exe" --url "$Env:deployurl/_pkg/jre-8u111-windows-i586.exe"
& "$Env:curl" -k -Ss -o "$Env:_tmp\jre-install.properties" --url "$Env:deployurl/_pkg/jre-install.properties"
& "$Env:_tmp\jre-8u111-windows-i586.exe" INSTALLCFG=c:\temp\jre-install.properties /L "$Env:logs\jre-install.log"
# Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre NOSTARTMENU=ENABLE WEB_JAVA=DISABLE WEB_ANALYTICS=DISABLE REBOOT=ENABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE REMOVEOUTOFDATEJRES=1 " 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=216432'

#Write-Host ""
#& "$Env:curl" -k -Ss -o c:\local\bin\nssm-2.24.zip --url https://nssm.cc/release/nssm-2.24.zip
#"$Env:programfiles\7-Zip\7z.exe" e c:\local\bin\nssm-2.24.zip -y


Write-Host "`n $basename applying Windows Update KB 2889748 "
& "$Env:curl" -k -Ss -o "$Env:_tmp\Windows6.1-KB2889748-x86.msu"  --url "$Env:deployurl/Windows6.1-KB2889748-x86.msu"
& "$Env:curl" -k -Ss -o "$Env:_tmp\402810_intl_i386_zip.exe" --url "$Env:deployurl/402810_intl_i386_zip.exe"

# mostly \local\bin
& "$Env:curl" -k -Ss -o "$Env:local\bin\nircmd.exe "--url "$Env:deployurl/bin/nircmd.exe"
& "$Env:curl" -k -Ss -o "$Env:local\bin\nircmdc.exe "--url "$Env:deployurl/bin/nircmdc.exe"
#"$Env:programfiles\7-Zip\7z.exe" e c:\local\bin\nircmd.zip -y

Write-Host "`n $basename installing xmlstarlet"
& "$Env:curl" -k -Ss -o "c:\local\bin\xml.exe" --url "$Env:deployurl/bin/xml.exe"
#"$Env:programfiles\7-Zip\7z.exe" e c:\local\bin\xmlstarlet-1.6.1-win32.zip -y

Write-Host "`n $basename devcon, nssm, hstart"

& "$Env:curl" -Ss -k -o "$Env:local\bin\curl.exe" --url "$Env:deployurl/bin/curl.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\du.exe" --url "$Env:deployurl/bin/du.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\LGPO.exe" --url "$Env:deployurl/bin/LGPO.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\psexec.exe" --url "$Env:deployurl/bin/psexec.exe"
& "$Env:curl" -k -Ss -o "$Env:local\bin\BootUpdCmd20.exe" --url "$Env:deployurl/bin/BootUpdCmd20.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\devcon.exe" --url "$Env:deployurl/bin/devcon.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\nssm.exe" --url "$Env:deployurl/bin/nssm.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\sendEmail.exe" --url "$Env:deployurl/bin/sendEmail.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\hstart.exe" --url "$Env:deployurl/bin/hstart.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\UPnPScan.exe" --url "$Env:deployurl/bin/UPnPScan.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\Autologon.exe" --url "https://live.sysinternals.com/Autologon.exe"

Write-Host "."
& "$Env:curl" -Ss -k -o "$Env:local\bin\update-Gac.ps1" --url "https://msdnshared.blob.core.windows.net/media/MSDNBlogsFS/prod.evol.blogs.msdn.com/CommunityServer.Components.PostAttachments/00/08/92/01/09/update-Gac.ps1"

Write-Host "`n $basename Downloading Drivers"
Set-Location -Path \local\drivers
#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer-filter.zip" --url "https://github.com/lockerlife-kiosk/deployment/blob/master/printer-filter.zip"
& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer-filter.zip" --url "$Env:deployurl/printer-filter.zip"
& "$Env:ProgramFiles\GnuWin32\bin\unzip.exe" -o "printer-filter.zip"
& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer.zip" --url "$Env:deployurl/printer.zip"
& "$Env:ProgramFiles\GnuWin32\bin\unzip.exe" -o "printer.zip"
& "$Env:curl" -Ss -k -o "$Env:local\drivers\scanner.zip" --url "$Env:deployurl/scanner.zip"
& "$Env:ProgramFiles\GnuWin32\bin\unzip.exe" -o "scanner.zip"

Write-Host ""
& "$Env:curl" -Ss -k -o "$Env:local\etc\kiosk-production-black.bgi" --url "$Env:deployurl/etc/kiosk-production-black.bgi"
& "$Env:curl" -Ss -k -o "$Env:local\etc\lockerlife-boot-custom.bs7" --url "$Env:deployurl/etc/lockerlife-boot-custom.bs7"
& "$Env:curl" -Ss -k -o "$Env:local\etc\lockerlife-boot.bs7" --url "$Env:deployurl/etc/lockerlife-boot.bs7"
& "$Env:curl" -Ss -k -o "$Env:local\etc\production-admin.bgi" --url "$Env:deployurl/etc/production-admin.bgi"
& "$Env:curl" -Ss -k -o "$Env:local\etc\production-kiosk.bgi" --url "$Env:deployurl/etc/production-kiosk.bgi"
& "$Env:curl" -Ss -k -o "$Env:local\etc\pantone-classic-blue.bmp" --url "$Env:deployurl/etc/pantone-classic-blue.bmp"
& "$Env:curl" -Ss -k -o "$Env:local\etc\pantone-classic-blue.jpg" --url "$Env:deployurl/etc/pantone-classic-blue.jpg"
& "$Env:curl" -Ss -k -o "$Env:local\etc\pantone-process-black-c.bmp" --url "$Env:deployurl/etc/pantone-process-black-c.bmp"
& "$Env:curl" -Ss -k -o "$Env:local\etc\pantone-process-black-c.jpg" --url "$Env:deployurl/etc/pantone-process-black-c.jpg"
& "$Env:curl" -Ss -k -o "$Env:local\etc\production-gpo.zip" --url "$Env:deployurl/etc/production-gpo.zip"

Write-Host "`n $basename download teamviewer Settings"
& "$Env:curl" -Ss -k -o "$Env:local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg" --url "$Env:deployurl/etc/PRODUCTION-201701-TEAMVIEWER-HOST.reg"



Write-Host "`n Gpo"
Set-Location -Path "$Env:SystemRoot\System32"
## make backup of GroupPolicy directories
& 7z a -t7z "$Env:SystemRoot\System32\GroupPolicy-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicy\"
& 7z a -t7z "$Env:SystemRoot\System32\GroupPolicyUsers-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicyUsers\"


# cleanup
Remove-Item "$Env:userprofile\Desktop\*.lnk"
Remove-Item "$Env:Public\Desktop\*.lnk"

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
Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\LockerDeployment\DeploymentHomepage.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "$Env:deployurl" -Description "LockerLife Deployment Start"

Write-Host "."
if (Test-PendingReboot) { Invoke-Reboot }

Write-Host "."
& "$Env:curl" -Ss -k --url "https://api.github.com/zen" ; Write-Host "`n"
Write-Host "."

# & "$Env:rm" -r -f "$Env:local\src\*"
#& "$Env:rm" -rfv "$Env:local\src\.git"
Write-Host "$basename process complete"
Write-Host ""

#############
# finishing #
#############

Update-Help

Write-Host ""
& "$Env:local\bin\bginfo.exe" "$Env:local\etc\production-admin-bginfo.bgi" /nolicprompt /silent /timer:0

& "$Env:curl" -Ss -k https://api.github.com/zen ; Write-Host ""
Write-Host ""

Write-Host "Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

#WriteSuccess "Press any key to continue..."
#$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL

Write-Host ""
# Internet Explorer: Temp Internet Files:
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

# touch status file in \local\status

# proceed to next step
& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/01-bootstrap.ps1"
#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?$Env:deployurl/10-configure.ps1

Write-Host "."
Write-Host "."
Write-Host "."
exit
