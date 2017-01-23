# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-bootstrap - install some stuff?
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 00-bootstrap"
$basename = $MyInvocation.MyCommand.Name



#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}

Breathe

# close previous IE windows ...
& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
$WebClient = New-Object System.Net.WebClient
(New-Object Net.WebClient).DownloadString("$Env:deployurl/99-DeploymentConfig.ps1") > "$Env:temp\99-DeploymentConfig.ps1"
. "$Env:temp\99-DeploymentConfig.ps1"

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

# Start Time and Transcript
Start-Transcript -Path "$Env:temp\$basename.log"
$StartDateTime = Get-Date
Write-Host "`t Script started at $StartDateTime" -ForegroundColor Green

# set window title
$pshost = Get-Host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 5500

# reminder: you can’t have a screen width that’s bigger than the buffer size.
# Therefore, before we can increase our window size we need to increase the buffer size
# powershell screen width and the buffer size are set to 150.
$newsize.width = 170
$pswindow.buffersize = $newsize

# the nul ensures window size does not chnage
#& cmd /c mode con: cols=150  >nul 2>nul


#--------------------------------------------------------------------
Write-Host "$basename - System eligibility check"
#--------------------------------------------------------------------

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


#--------------------------------------------------------------------
Write-Host "$basename - Install some software"
#--------------------------------------------------------------------

choco feature enable -n=allowGlobalConfirmation

cinst chocolatey --version 0.9.10.3 --forcex86 --allow-downgrade
choco pin add -n chocolatey -y

Reboot-IfRequired

# fix mis-versioned 7z.exe x64 binary
#Move-Item -Path "$Env:ProgramData\chocolatey\tools\7z.exe" "$Env:ProgramData\chocolatey\tools\7z-x64.exe" -Force
#Move-Item "$Env:ProgramData\chocolatey\tools\7za.exe" "$Env:ProgramData\chocolatey\tools\7z.exe" -Force

cinst 7zip --forcex86
cinst 7zip.commandline


#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?$Env:deployurl/01-bootstrap.ps1


cinst dotnet4.6.2 --version 4.6.01590.0
#if (Test-PendingReboot) { Invoke-Reboot }
Reboot-IfRequired

# below: requires .Net 4+ to run
cinst Boxstarter.Common
cinst boxstarter.WinConfig
cinst Boxstarter.Chocolatey
cinst chocolatey-core.extension
cinst chocolatey-uninstall.extension

RefreshEnv

#if (Test-PendingReboot) { Invoke-Reboot }
Reboot-IfRequired

choco install teamviewer.host --version 12.0.72365

# gow installer is easily confused ... only run if gow isn't installed ..
if (!(Test-Path "$Env:ProgramFiles\Gow"))
{
  cinst gow
  Reboot-IfRequired
}
cinst nircmd
cinst xmlstarlet
#cinst curl
cinst nssm

cinst ie11
Breathe
RefreshEnv
Reboot-IfRequired

cinst git.install -params '"/WindowsTerminal /GitOnlyOnPath /NoAutoCrlf"'
RefreshEnv
Reboot-IfRequired

cinst powershell -version 3.0.20121027
Breathe

Write-Host "$basename -- Fixing critical Windows svchost.exe memory leak -- KB2889748"
Enable-MicrosoftUpdate
& "$Env:curl" -Ss -k -o "$Env:_tmp\Windows6.1-KB2889748-x86.msu" --url "https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu"
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot

Breathe
Reboot-IfRequired

# usually machine rebooted ...
Write-Host "$basename -- Disable Windows Update"
Disable-MicrosoftUpdate

Write-Host "$basename -- installing a known-good version of 7z"
& "$Env:curl" -Ss -o "$Env:_tmp\7z1604.exe" --url "http://www.7-zip.org/a/7z1604.exe"
& "$Env:_tmp\7z1604.exe" /S


Write-Host "$basename -- Installing Powershell 4"
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
Reboot-IfRequired

Write-Host "$basename -- installing psget"
choco install powershell-packagemanagement -y

Write-Host ""
Write-Host "$basename -- Installing Microsoft Security Essentials (antivirus)"
Write-Host ""
cinst microsoftsecurityessentials -version 4.5.0216.0
#if (Test-PendingReboot) { Invoke-Reboot }
Reboot-IfRequired
Write-Host "."

# --------------------------------------------------------------------------------------------
# Temporarily stop antivirus
# --------------------------------------------------------------------------------------------
Write-Host "`n $basename -- Temporarily disabling antivirus"
& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc
& "$Env:SystemRoot\System32\timeout.exe" /t 5 /nobreak
& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc

Write-Host "`n $basename installing additional tools"
choco install bginfo
#choco install vim
choco install jq
choco install clink
#choco install putty
#choco install rsync
choco install wget
choco install nssm
choco install psexec
#choco install sysinternals
#choco install teraterm

Write-Host "$basename -- Installing Telnet Client (dism/windowsfeatures)"
cinst TelnetClient -source windowsfeatures
#if (Test-PendingReboot) { Invoke-Reboot }
Reboot-IfRequired


Write-Host "`n $basename -- second backup (more reliable) unzip"
& "$Env:curl" -Ss -k -o "$Env:_tmp\unzip-5.51-1.exe" --url "$Env:deployurl/unzip-5.51-1.exe"
& "$Env:_tmp\unzip-5.51-1.exe" /SILENT



# install java/jre
Write-Host "`n $basename Installing Java jre"
& "$Env:curl" -k -Ss -o "$Env:_tmp\jre-8u111-windows-i586.exe" --url "$Env:deployurl/_pkg/jre-8u111-windows-i586.exe"
& "$Env:curl" -k -Ss -o "$Env:_tmp\jre-install.properties" --url "$Env:deployurl/_pkg/jre-install.properties"
& "$Env:_tmp\jre-8u111-windows-i586.exe" INSTALLCFG=c:\temp\jre-install.properties /L "$Env:logs\jre-install.log"
# Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre NOSTARTMENU=ENABLE WEB_JAVA=DISABLE WEB_ANALYTICS=DISABLE REBOOT=ENABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE REMOVEOUTOFDATEJRES=1 " 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=216432'

#Write-Host ""
#& "$Env:curl" -k -Ss -o c:\local\bin\nssm-2.24.zip --url https://nssm.cc/release/nssm-2.24.zip
#"$Env:programfiles\7-Zip\7z.exe" e c:\local\bin\nssm-2.24.zip -y


Write-Host "`n $basename -- Applying Windows Update KB2889748 "
& "$Env:curl" -k -Ss -o "$Env:_tmp\Windows6.1-KB2889748-x86.msu"  --url "$Env:deployurl/Windows6.1-KB2889748-x86.msu"
& "$Env:curl" -k -Ss -o "$Env:_tmp\402810_intl_i386_zip.exe" --url "$Env:deployurl/402810_intl_i386_zip.exe"

#"$Env:programfiles\7-Zip\7z.exe" e c:\local\bin\nircmd.zip -y



Write-Host "."
& "$Env:curl" -Ss -k -o "$Env:local\bin\update-Gac.ps1" --url "https://msdnshared.blob.core.windows.net/media/MSDNBlogsFS/prod.evol.blogs.msdn.com/CommunityServer.Components.PostAttachments/00/08/92/01/09/update-Gac.ps1"

Write-Host "`n $basename Downloading Drivers"
Set-Location -Path "$Env:local\drivers"
#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer-filter.zip" --url "https://github.com/lockerlife-kiosk/deployment/blob/master/printer-filter.zip"
#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer-filter.zip" --url "$Env:deployurl/printer-filter.zip"
#& "$Env:ProgramFiles\GnuWin32\bin\unzip.exe" -o "printer-filter.zip"

#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer.zip" --url "$Env:deployurl/printer.zip"
#& "$Env:ProgramFiles\GnuWin32\bin\unzip.exe" -o "printer.zip"
& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer.exe" --url "$Env:deployurl/drivers/printer.exe"

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

Write-Host "`n GPO"
Set-Location -Path "$Env:SystemRoot\System32"
## make backup of GroupPolicy directories
7z a -t7z "$Env:SystemRoot\System32\GroupPolicy-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicy\"
7z a -t7z "$Env:SystemRoot\System32\GroupPolicyUsers-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicyUsers\"


RefreshEnv

chocolatey feature disable -n=allowGlobalConfirmation

# Make bginfo run on startup/login
# & "$Env:local\bin\bginfo.exe" "$Env:local\etc\production-admin-bginfo.bgi" /nolicprompt /silent /timer:0
if (-not (Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\bginfo.lnk"))
{
  $WshShell = New-Object -comObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\bginfo.lnk")
  $Shortcut.TargetPath = "$Env:local\bin\Bginfo.exe"
  $Shortcut.Arguments = "$Env:local\etc\production-kiosk.bgi /nolicprompt /timer:0"
  $Shortcut.Save()
}

# makes sense ?
#  ;Resort the Start Menu
#  [-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\MenuOrder]


Update-Help

Write-Host "Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

# last chance to reboot before next step ...
if (Test-PendingReboot) { Invoke-Reboot }

#--------------------------------------------------------------------
Write-Host "$basename - Cleanup"
#--------------------------------------------------------------------

# Cleanup Desktop
CleanupDesktop

Create-DeploymentLinks

# Internet Explorer: Temp Internet Files:
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

# touch $Env:local\status\00-init.done file
# echo date/time into file, add lines ...
New-Item -Path "$Env:local\status\$basename.done" -ItemType File -ErrorAction SilentlyContinue | Out-Null

& "$Env:curl" -Ss -k --url "https://api.github.com/zen"
Write-Host ""


#--------------------------------------------------------------------
Write-Host "$basename - Next stage ... "
#--------------------------------------------------------------------
& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f
#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/01-bootstrap.ps1"
#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/02-bootstrap.ps1"
& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?$Env:deployurl/10-identify.ps1
