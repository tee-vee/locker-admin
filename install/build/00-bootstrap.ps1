# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-bootstrap - install some stuff?
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 00-bootstrap"




#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    1..5 | % { Write-Host }
    exit
}

# close previous IE windows ...
#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
#$WebClient = New-Object System.Net.WebClient
#$WebClient.DownloadFile("$Env:deployurl/99-DeploymentConfig.ps1","$Env:temp\99-DeploymentConfig.ps1")
#. "$Env:temp\99-DeploymentConfig.ps1"
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1

$basename = "00-bootstrap"

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted


# Start Time and Transcript
Start-Transcript -Path "$Env:temp\$basename.log"
$StartDateTime = Get-Date
Write-Host "Script started at $StartDateTime" -ForegroundColor Green


# set window title
$pshost = Get-Host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 5500

# reminder: you can’t have a screen width that’s bigger than the buffer size.
# Therefore, before we can increase our window size we need to increase the buffer size
# powershell screen width and the buffer size are set to 150.
$newsize.width = 200
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

cinst chocolatey
cinst Boxstarter
Reboot-IfRequired

# fix mis-versioned 7z.exe x64 binary
#Move-Item -Path "$Env:ProgramData\chocolatey\tools\7z.exe" "$Env:ProgramData\chocolatey\tools\7z-x64.exe" -Force
#Move-Item "$Env:ProgramData\chocolatey\tools\7za.exe" "$Env:ProgramData\chocolatey\tools\7z.exe" -Force

cinst 7zip --forcex86
cinst 7zip.commandline
cinst unzip --ignore-checksums
Reboot-IfRequired

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
Reboot-IfRequired

cinst teamviewer.host --version 12.0.72365
Reboot-IfRequired

# gow installer is easily confused ... only run if gow isn't installed ..
if (!(Test-Path "$Env:ProgramFiles\Gow"))
{
    cinst gow --ignore-checksums
}

cinst nircmd
cinst xmlstarlet
cinst curl
cinst nssm --ignore-checksums
Reboot-IfRequired

cinst ie11 --ignore-checksums
Reboot-IfRequired

cinst git.install -params '"/WindowsTerminal /GitOnlyOnPath /NoAutoCrlf"'
Reboot-IfRequired

cinst powershell -version 3.0.20121027
#schtasks /Run /TN "\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319"
Write-Host "$basename -- Temporarily enable Windows Update"
Enable-MicrosoftUpdate
Write-Host "$basename -- Fixing critical Windows svchost.exe memory leak -- KB2889748"
& "$Env:curl" -Ss -k -o "$Env:_tmp\Windows6.1-KB2889748-x86.msu" --url "https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu"
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot
Breathe
Write-Host "$basename -- Disable Windows Update"
Disable-MicrosoftUpdate

Reboot-IfRequired

Write-Host "$basename -- Installing Powershell 4"
cinst powershell4 --ignore-checksums
# powershell performance issues
# https://blogs.msdn.microsoft.com/powershell/2008/07/11/speeding-up-powershell-startup/
if (!( Test-Path "$env:local\status\powershell4-ngen.ok" -ErrorAction SilentlyContinue))
{
  New-Item -Type File -Path "$env:local\status\powershell4-ngen.ok" -Force -Verbose
  iex ((New-Object System.Net.WebClient).DownloadString('http://lockerlife.hk/deploy/fix-powershell4-performance.ps1'))

}

Write-Host "$basename -- test-reboot check"
Reboot-IfRequired

Write-Host "$basename -- installing psget"
cinst powershell-packagemanagement

Write-Host "$basename -- Installing Microsoft Security Essentials (antivirus)"
cinst microsoftsecurityessentials -version 4.5.0216.0 --ignore-checksums
Reboot-IfRequired
Write-Host "."

# --------------------------------------------------------------------------------------------
WriteInfo "$basename -- Temporarily stop antivirus"
# --------------------------------------------------------------------------------------------
& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc
& "$Env:SystemRoot\System32\timeout.exe" /t 5 /nobreak
& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc
Write-Host "$basename -- Update MSAV Signature"
# https://technet.microsoft.com/en-us/library/gg131918.aspx?f=255&MSPPError=-2147217396
& "$envProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate
& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2


Write-Host "`n $basename -- Installing additional tools"
cinst bginfo
#cinst vim
cinst jq --ignore-checksums
cinst clink
cinst wincommandpaste --ignore-checksums
#cinst webpicmd
#cinst putty
#cinst rsync
cinst wget
cinst which
cinst nssm
cinst psexec
#cinst sysinternals
#cinst teraterm

Write-Host "$basename -- Installing Telnet Client (dism/windowsfeatures)"
cinst TelnetClient -source windowsfeatures
Reboot-IfRequired

if (!(Test-Path "$JAVA_HOME\java.exe")) {
  Write-Host "`n $basename -- Installing Java jre"
  & "$Env:curl" --progress-bar -k -Ss -o "$Env:_tmp\jre-8u111-windows-i586.exe" --url "$Env:deployurl/_pkg/jre-8u111-windows-i586.exe"
  & "$Env:curl" --progress-bar -k -Ss -o "$Env:_tmp\jre-install.properties" --url "$Env:deployurl/_pkg/jre-install.properties"
  & "$Env:_tmp\jre-8u111-windows-i586.exe" INSTALLCFG=c:\temp\jre-install.properties /L "$Env:logs\jre-install.log"
  # Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre NOSTARTMENU=ENABLE WEB_JAVA=DISABLE WEB_ANALYTICS=DISABLE REBOOT=ENABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE REMOVEOUTOFDATEJRES=1 " 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=216432'
} else { Write-Host "`n $basename -- Java already installed, skipping ..." }


Write-Host "`n $basename -- Applying Windows Update KB2889748 "
& "$Env:curl" -k -Ss -o "$Env:_tmp\Windows6.1-KB2889748-x86.msu"  --url "$Env:deployurl/Windows6.1-KB2889748-x86.msu"
& "$Env:curl" -k -Ss -o "$Env:_tmp\402810_intl_i386_zip.exe" --url "$Env:deployurl/402810_intl_i386_zip.exe"

cinst dropbox --ignore-checksums

#--------------------------------------------------------------------
Write-Host "$basename - Out of band Installers"
#--------------------------------------------------------------------

WriteInfoHighlighted "$basename -- Installing QuickSet"
msiexec /i http://lockerlife.hk/deploy/_pkg/QuickSet-2.07-bulid0805.msi /quiet /passive

#--------------------------------------------------------------------
Write-Host "$basename -- Begin -- Remove unnecessary Windows components"

dism /online /disable-feature /featurename:InboxGames
dism /online /disable-feature /featurename:FaxServicesClientPackage
dism /online /disable-feature /featurename:WindowsGadgetPlatform
dism /online /disable-feature /featurename:OpticalMediaDisc
dism /online /disable-feature /featurename:Xps-Foundation-Xps-Viewer
Write-Host "$basename -- End -- Remove unnecessary Windows components"

#--------------------------------------------------------------------
Write-Host "$basename -- GAC Update ..."
& "$Env:curl" -Ss -k -o "$Env:local\bin\update-Gac.ps1" --url "https://msdnshared.blob.core.windows.net/media/MSDNBlogsFS/prod.evol.blogs.msdn.com/CommunityServer.Components.PostAttachments/00/08/92/01/09/update-Gac.ps1"

#--------------------------------------------------------------------
Write-Host "$basename -- Downloading Drivers"
Set-Location -Path "$Env:local\drivers"
#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer-filter.zip" --url "https://github.com/lockerlife-kiosk/deployment/blob/master/printer-filter.zip"
#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer-filter.zip" --url "$Env:deployurl/printer-filter.zip"
#& "$Env:ProgramFiles\GnuWin32\bin\unzip.exe" -o "printer-filter.zip"

#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer.zip" --url "$Env:deployurl/printer.zip"
#& "$Env:ProgramFiles\GnuWin32\bin\unzip.exe" -o "printer.zip"
& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer.exe" --url "$Env:deployurl/drivers/printer.exe"

& "$Env:curl" -Ss -k -o "$Env:local\drivers\scanner.zip" --url "$Env:deployurl/scanner.zip"
cd "$local\drivers"
unzip.exe -o "scanner.zip"

Write-Host "$basename -- local\etc stuff"
& "$Env:curl" -Ss -k -o "$Env:local\etc\kiosk-production-black.bgi" --url "$Env:deployurl/etc/kiosk-production-black.bgi"
& "$Env:curl" -Ss -k -o "$Env:local\etc\lockerlife-boot-custom.bs7" --url "$Env:deployurl/etc/lockerlife-boot-custom.bs7"
& "$Env:curl" -Ss -k -o "$Env:local\etc\lockerlife-boot.bs7" --url "$Env:deployurl/etc/lockerlife-boot.bs7"
& "$Env:curl" -Ss -k -o "$Env:local\etc\production-admin.bgi" --url "$Env:deployurl/etc/production-admin.bgi"
& "$Env:curl" -Ss -k -o "$Env:local\etc\production-kiosk.bgi" --url "$Env:deployurl/etc/production-kiosk.bgi"
& "$Env:curl" -Ss -k -o "$Env:local\etc\pantone-classic-blue.bmp" --url "$Env:deployurl/etc/pantone-classic-blue.bmp"
& "$Env:curl" -Ss -k -o "$Env:local\etc\pantone-classic-blue.jpg" --url "$Env:deployurl/etc/pantone-classic-blue.jpg"
& "$Env:curl" -Ss -k -o "$Env:local\etc\pantone-process-black-c.bmp" --url "$Env:deployurl/etc/pantone-process-black-c.bmp"
& "$Env:curl" -Ss -k -o "$Env:local\etc\pantone-process-black-c.jpg" --url "$Env:deployurl/etc/pantone-process-black-c.jpg"
Copy-Item "$local\etc\pantone-process-black-c.jpg" "C:\windows\system32\oobe\info\backgrounds\backgroundDefault.jpg" -Force
Copy-Item "$local\etc\pantone-process-black-c.bmp" "C:\Windows\System32\oobe\background.bmp" -Force
& "$Env:curl" -Ss -k -o "$Env:local\etc\production-gpo.zip" --url "$Env:deployurl/etc/production-gpo.zip"

#--------------------------------------------------------------------
Write-Host "$basename -- download teamviewer Settings"
& "$Env:curl" -Ss -k -o "$Env:local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg" --url "$Env:deployurl/etc/PRODUCTION-201701-TEAMVIEWER-HOST.reg"
Write-Host "$basename -- install teamviewer Settings"
net stop teamviewer
reg import c:\local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg
net start teamviewer

Write-Host "$basename -- GPO"
Set-Location -Path "$Env:SystemRoot\System32"
## make backup of GroupPolicy directories
c:\programdata\chocolatey\tools\7za a -t7z "$Env:SystemRoot\System32\GroupPolicy-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicy\"
c:\programdata\chocolatey\tools\7za a -t7z "$Env:SystemRoot\System32\GroupPolicyUsers-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicyUsers\"

chocolatey feature disable -n=allowGlobalConfirmation


#--------------------------------------------------------------------
# Make bginfo run on startup/login
# & "$Env:local\bin\bginfo.exe" "$Env:local\etc\production-admin-bginfo.bgi" /nolicprompt /silent /timer:0
if (-not (Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\bginfo.lnk"))
{
  $WshShell = New-Object -comObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\bginfo.lnk")
  $Shortcut.TargetPath = "$Env:local\bin\Bginfo.exe"
  $Shortcut.Arguments = "$Env:local\etc\production-kiosk.bgi /nolicprompt /timer:0 /silent"
  $Shortcut.Save()
}

Write-Host "$basename -- Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

# last chance to reboot before next step ...
Reboot-IfRequired

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
New-Item -Path "$local\status\$basename.done" -ItemType File | Out-Null

& "$env:curl" -Ss -k --url "https://api.github.com/zen"
Write-Host "."

#--------------------------------------------------------------------
Write-Host "$basename - Next stage ... "
#--------------------------------------------------------------------
#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f
#Stop-Process -Name iexplore
#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/01-bootstrap.ps1"
#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/02-bootstrap.ps1"
& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" "http://boxstarter.org/package/url?http://lockerlife.hk/deploy/10-identify.ps1"
