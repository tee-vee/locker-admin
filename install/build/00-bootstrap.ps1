# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-bootstrap - install some stuff?
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 00-bootstrap"




$basename = "00-bootstrap"
# --------------------------------------------------------------------------------------------
Write-Host "$basename - Lets start"
# --------------------------------------------------------------------------------------------
$ErrorActionPreference = "Continue"
$timer = Start-TimedSection "00-bootstrap"

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
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1

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


# --------------------------------------------------------------------------------------------
Write-Host "$basename - System eligibility check"
# --------------------------------------------------------------------------------------------

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
Write-Host "$basename - Loading Modules ..."
#--------------------------------------------------------------------

# Import BitsTransfer ...
if (!(Get-Module BitsTransfer -ErrorAction SilentlyContinue)) {
	Import-Module BitsTransfer
} else {
	# BitsTransfer module already loaded ... clear queue
	Get-BitsTransfer -Verbose | Complete-BitsTransfer -Verbose
}


# --------------------------------------------------------------------------------------------
# get updated root certificates
#msiexec /i http://www.cacert.org/certs/CAcert_Root_Certificates.msi /quiet /passive

# --------------------------------------------------------------------------------------------
Write-Host "$basename - Install some software"
# --------------------------------------------------------------------------------------------

choco feature enable -n=allowGlobalConfirmation

cinst chocolatey
if (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
  choco pin remove --name chocolatey
  choco upgrade chocolatey
}
cinst Boxstarter

# fix mis-versioned 7z.exe x64 binary
#Move-Item -Path "$Env:ProgramData\chocolatey\tools\7z.exe" "$Env:ProgramData\chocolatey\tools\7z-x64.exe" -Force
#Move-Item "$Env:ProgramData\chocolatey\tools\7za.exe" "$Env:ProgramData\chocolatey\tools\7z.exe" -Force

cinst 7zip --forcex86
cinst 7zip.commandline
cinst unzip --ignore-checksums

cinst dotnet4.5.1 --ignore-checksums
cinst dotnet4.6.2 --version 4.6.01590.0

# below: requires .Net 4+ to run
cinst Boxstarter.Common
cinst boxstarter.WinConfig
cinst Boxstarter.Chocolatey
cinst chocolatey-core.extension
cinst chocolatey-uninstall.extension

cinst teamviewer.host --version 12.0.72365
Start-Sleep -Seconds 5
Restart-Service TeamViewer -Verbose
Write-Host "$basename -- Download TeamViewer Settings"
Start-BitsTransfer -Source "$Env:deployurl/etc/PRODUCTION-201701-TEAMVIEWER-HOST.reg" -Destination "$Env:local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg"
Write-Host "$basename -- Install teamviewer Settings"
Stop-Service TeamViewer -Verbose
Stop-Service TeamViewer -Verbose
reg import c:\local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg
$env:TeamViewerClientID = (Get-ItemProperty -Path "HKLM:\SOFTWARE\TeamViewer" -Name ClientID).ClientID
$env:TeamViewerClientID = (Get-ItemProperty -Path "HKLM:\SOFTWARE\TeamViewer" -Name ClientID).ClientID

# gow installer is easily confused ... only run if gow isn't installed ..
if (!(Test-Path "C:\Program Files\Gow\bin")) {
    cinst gow --ignore-checksums
}

cinst nircmd
cinst xmlstarlet
## cinst curl
cinst nssm --ignore-checksums
# cinst f.lux

cinst ie11 --ignore-checksums

cinst git.install -params '"/WindowsTerminal /GitOnlyOnPath /NoAutoCrlf"'

#cinst powershell -version 3.0.20121027
#schtasks /Run /TN "\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319"

Write-Host "$basename -- Temporarily enable Windows Update"
Enable-MicrosoftUpdate
Write-Host "$basename -- Fixing critical Windows svchost.exe memory leak -- KB2889748"
& "$Env:curl" -Ss -k -o "$Env:_tmp\Windows6.1-KB2889748-x86.msu" --url "https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu"
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet
& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot
#& "$Env:SystemRoot\System32\wusa.exe" c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcereboot

Breathe
Write-Host "$basename -- Disable Windows Update"
Disable-MicrosoftUpdate

Write-Host "$basename -- Installing Powershell 5"
cinst powershell
# powershell performance issues
# https://blogs.msdn.microsoft.com/powershell/2008/07/11/speeding-up-powershell-startup/
if (!( Test-Path "$env:local\status\powershell4-ngen.ok" -ErrorAction SilentlyContinue)) {
  New-Item -Type File -Path "$env:local\status\powershell4-ngen.ok" -Force
  iex ((New-Object System.Net.WebClient).DownloadString('http://lockerlife.hk/deploy/fix-powershell4-performance.ps1'))

}

# check for powershell 5
# $PSVersionTable.PSVersion
# if not installed, install
#install-PackageProvider -Name NuGet -Confirm:$false -Force
#Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
#Install-Module PSWindowsUpdate -Verbose -Confirm:$false
# Import-Module PSWindowsUpdate
# if version 5
# Import-Module PSWindowsUpdate
# Get-Command –module PSWindowsUpdate
# Add-WUServiceManager -ServiceID 7971f918-a847-4430-9279-4a52d1efe18d -Confirm:$false
# Get-WUInstall –MicrosoftUpdate –AcceptAll –AutoReboot

Write-Host "$basename -- installing psget"
cinst powershell-packagemanagement

# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Installing Microsoft Security Essentials (antivirus)"
# --------------------------------------------------------------------------------------------
cinst microsoftsecurityessentials -version 4.5.0216.0 --ignore-checksums

Write-Host "$basename -- Update MSAV Signature"
# https://technet.microsoft.com/en-us/library/gg131918.aspx?f=255&MSPPError=-2147217396
& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate
#& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2


#& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc
#& "$Env:SystemRoot\System32\timeout.exe" /t 5 /nobreak
#& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc


Write-Host "$basename -- Installing additional tools"
cinst bginfo
#cinst vim
cinst jq --ignore-checksums
cinst clink
#cinst wincommandpaste --ignore-checksums
#cinst webpicmd
#cinst putty
#cinst rsync
#cinst wget
cinst which
cinst nssm
cinst psexec
#cinst sysinternals
#cinst teraterm

Write-Host "$basename -- Installing Telnet Client (dism/windowsfeatures)"
cinst TelnetClient -source windowsfeatures

if (!(Test-Path "$JAVA_HOME\java.exe")) {
  Write-Host "`n $basename -- Installing Java jre"
  # & "$Env:curl" --progress-bar -k -Ss -o "$Env:_tmp\jre-8u111-windows-i586.exe" --url "$Env:deployurl/_pkg/jre-8u111-windows-i586.exe"
  # & "$Env:curl" --progress-bar -k -Ss -o "$Env:_tmp\jre-install.properties" --url "$Env:deployurl/_pkg/jre-install.properties"
  & "$Env:_tmp\jre-8u111-windows-i586.exe" INSTALLCFG=c:\temp\jre-install.properties /L "$Env:logs\jre-install.log"
  # Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre NOSTARTMENU=ENABLE WEB_JAVA=DISABLE WEB_ANALYTICS=DISABLE REBOOT=ENABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE REMOVEOUTOFDATEJRES=1 " 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=216432'
} else { Write-Host "`n $basename -- Java already installed, skipping ..." }


# Write-Host "`n $basename -- Applying Windows Update KB2889748 "
# & "$Env:curl" -k -Ss -o "$Env:_tmp\Windows6.1-KB2889748-x86.msu"  --url "$Env:deployurl/Windows6.1-KB2889748-x86.msu"
# & "$Env:curl" -k -Ss -o "$Env:_tmp\402810_intl_i386_zip.exe" --url "$Env:deployurl/402810_intl_i386_zip.exe"

cinst dropbox --ignore-checksums


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Begin -- Remove unnecessary Windows components"
dism /online /disable-feature /featurename:InboxGames /NoRestart
dism /online /disable-feature /featurename:FaxServicesClientPackage /NoRestart
dism /online /disable-feature /featurename:WindowsGadgetPlatform /NoRestart
dism /online /disable-feature /featurename:OpticalMediaDisc /NoRestart
dism /online /disable-feature /featurename:Xps-Foundation-Xps-Viewer /NoRestart
Write-Host "$basename -- End -- Remove unnecessary Windows components"


# --------------------------------------------------------------------------------------------
Write-Host "$basename - Out of band Installers"
# --------------------------------------------------------------------------------------------

WriteInfoHighlighted "$basename -- Installing QuickSet"
Start-Process "msiexec.exe" -ArgumentList '/i http://lockerlife.hk/deploy/_pkg/QuickSet-2.07-bulid0805.msi /quiet /passive /L*v e:\logs\quickset-install.log' -Wait


# --------------------------------------------------------------------
Write-Host "$basename -- Downloading Drivers"
Set-Location -Path "$Env:local\drivers"
Remove-Item -Path scanner.zip -Force -ErrorAction SilentlyContinue

#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer-filter.zip" --url "https://github.com/lockerlife-kiosk/deployment/blob/master/printer-filter.zip"
#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer-filter.zip" --url "$Env:deployurl/printer-filter.zip"
#& "$Env:ProgramFiles\GnuWin32\bin\unzip.exe" -o "printer-filter.zip"

#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer.zip" --url "$Env:deployurl/printer.zip"
#& "$Env:ProgramFiles\GnuWin32\bin\unzip.exe" -o "printer.zip"
#& "$Env:curl" -Ss -k -o "$Env:local\drivers\printer.exe" --url "$Env:deployurl/drivers/printer.exe"

#& "$Env:curl" -Ss -k -o "$Env:local\drivers\scanner.zip" --url "$Env:deployurl/scanner.zip"
#cd "$env:local\drivers"
#c:\ProgramData\chocolatey\bin\unzip.exe scanner.zip
#Remove-Item -Path scanner.zip -Force -ErrorAction SilentlyContinue

Write-Host "$basename -- local\etc stuff"
#& "$Env:curl" -Ss -k -o "$Env:local\etc\lockerlife-boot-custom.bs7" --url "$Env:deployurl/etc/lockerlife-boot-custom.bs7"
#& "$Env:curl" -Ss -k -o "$Env:local\etc\lockerlife-boot.bs7" --url "$Env:deployurl/etc/lockerlife-boot.bs7"
#& "$Env:curl" -Ss -k -o "$Env:local\etc\production-admin.bgi" --url "$Env:deployurl/etc/production-admin.bgi"
#& "$Env:curl" -Ss -k -o "$Env:local\etc\production-kiosk.bgi" --url "$Env:deployurl/etc/production-kiosk.bgi"
Copy-Item "$env:local\etc\pantone-process-black-c.jpg" "C:\Windows\System32\oobe\info\backgrounds\backgroundDefault.jpg" -Force
Copy-Item "$env:local\etc\pantone-process-black-c.bmp" "C:\Windows\System32\oobe\background.bmp" -Force
Copy-Item "$env:local\etc\pantone-process-black-c.jpg" "C:\Windows\Web\Wallpaper\Windows\img0.jpg" -Force
#& "$Env:curl" -Ss -k -o "$Env:local\etc\production-gpo.zip" --url "$Env:deployurl/etc/production-gpo.zip"

# --------------------------------------------------------------------------------------------
# after drivers, hardware ...

# Disable NTFS last access timestamp
fsutil.exe behavior set disablelastaccess 1

# disable monitor timeout
powercfg.exe -change -monitor-timeout-ac 0

# --------------------------------------------------------------------------------------------
# Install scanner driver
# --------------------------------------------------------------------------------------------
# step 1: install usb virtual com interface
# takes 3-5 minutes to install
Write-Host "20-setup: installing usb virtual com interface for driver"
#& "$Env:local\drivers\scanner\udp_and_vcom_drv211Setup\udp_and_vcom_drv.2.1.1.Setup.exe" /S
Start-Process "msiexec.exe" -ArgumentList "/i http://lockerlife.hk/deploy/drivers/udp_and_vcom_drv_v2.0.1.msi /quiet /passive /L*v c:\logs\udp_and_vcom_drv-install.log" -Wait

# windows should look in IOUSB for remainder; 00-bootstrap


# --------------------------------------------------------------------------------------------
# DISABLE 802.11 / Bluetooth interfaces
# --------------------------------------------------------------------------------------------
Write-Host ""
Write-Host "$basename -- Disable Bluetooth Interface"
& "$Env:local\bin\devcon.exe" disable BTH*
svchost.exe -k bthsvcs
Stop-Service bthserv -Verbose
reg add "HKLM\SYSTEM\CurrentControlSet\services\bthserv" /v Start /t REG_DWORD /d 4 /f

# 2017-01 Temporarily hold off on disabling wifi
#& "$Env:SystemRoot\System32\netsh.exe" interface set interface name="Wireless Network Connection" admin=DISABLED

## must install printer before gpo;
## must let machine contact windows update


# --------------------------------------------------------------------------------------------
# Install printer-filter driver
# RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 path-to-inf\infname.inf
# --------------------------------------------------------------------------------------------
# choco install -y zadig
# check; don't reinstall if already exists
# ** implementation incomplete ...
#Write-Host "Checking printer status ..."
#& "$Env:SystemRoot\System32\webm\wmic.exe" printer list status | Select-String 80mm
#
## step 1: install port
##& "$Env:local\drivers\printer\Windows81Driver\RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 %LOCKERDRIVERS%\printer\Windows81Driver\POS88EN.inf
## %LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--device=USB\VID_0483&PID_5720&REV_0100"
#Write-Host "20-setup: Installing printer-filter driver"
#& "$Env:local\drivers\printer-filter\libusb-win32\bin\x86\install-filter.exe" install --device=USB\VID_0483"&"PID_5720"&"REV_0100
#
## step 2: connect/bridge printer-filter to printer
## %LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install --inf=%LOCKERDRIVERS%\printer\SPRT_Printer.inf
#Write-Host "20-setup: connecting printer-filter to printer"
#& "$Env:local\drivers\printer-filter\libusb-win32\bin\x86\install-filter.exe" install --inf="$Env:local\drivers\printer\SPRT_Printer.inf"
#
## Print a test page to one or more printers
## for /f "tokens=1-4 delims=," %i in (%Printer.txt%) do cscript prnctrl.vbs -t -b \\%PrintServer%\%i
##Cscript Prnqctl -e
#& "C:\windows\system32\cscript.exe" "c:\windows\system32\Printing_Admin_Scripts\en-US\prncnfg.vbs" -g -p "80mm Series Printer"
#& "C:\windows\system32\cscript.exe" "c:\windows\system32\Printing_Admin_Scripts\en-US\prnqctl.vbs" -e -p "80mm Series Printer"



Write-Host "$basename -- GPO"
Set-Location -Path "$Env:SystemRoot\System32"
## make backup of GroupPolicy directories
#c:\programdata\chocolatey\tools\7za a -t7z "$Env:SystemRoot\System32\GroupPolicy-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicy\"
#c:\programdata\chocolatey\tools\7za a -t7z "$Env:SystemRoot\System32\GroupPolicyUsers-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicyUsers\"

chocolatey feature disable -n=allowGlobalConfirmation


Get-BitsTransfer | Complete-BitsTransfer

# --------------------------------------------------------------------------------------------
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


# --------------------------------------------------------------------------------------------
Write-Host "$basename - Cleanup"
# --------------------------------------------------------------------------------------------
Stop-Process -Name iexplore -ErrorAction SilentlyContinue -Verbose

# Cleanup Desktop
CleanupDesktop
Create-DeploymentLinks
cleanmgr.exe /verylowdisk

# touch $Env:local\status\00-init.done file
# echo date/time into file, add lines ...
New-Item -ItemType File -Path "$env:local\status\$basename.done" | Out-Null

Write-Host "$basename -- Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript


Invoke-RestMethod -Uri "https://api.github.com/zen"
Write-Host "."

Stop-TimedSection $timer

# --------------------------------------------------------------------------------------------
Write-Host "$basename - Next stage ... "
# --------------------------------------------------------------------------------------------
#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" "http://boxstarter.org/package/url?http://lockerlife.hk/deploy/10-identify.ps1"
START http://boxstarter.org/package/url?http://lockerlife.hk/deploy/10-identify.ps1
