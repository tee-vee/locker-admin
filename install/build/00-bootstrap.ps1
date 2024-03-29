# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-bootstrap - install some stuff?
$host.ui.RawUI.WindowTitle = "00-bootstrap"

$basename = "00-bootstrap"
$ErrorActionPreference = "Continue"
#$PSDefaultParameterValues += @{'Get*:Verbose' = $true}
#$PSDefaultParameterValues += @{'*:Confirm' = $false}


# --------------------------------------------------------------------------------------------
Write-Host "${basename}: Lets start" -ForegroundColor Magenta

$timer = Start-TimedSection "00-bootstrap"

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    1 .. 5 | % { Write-Host }
    exit
}

## backup
#Enable-ComputerRestore -Drive "C:\" -Confirm:$false
#Checkpoint-Computer -Description "Before 00-init"


#--------------------------------------------------------------------
Write-Host "${basename}: Loading Modules ..." -ForegroundColor Magenta

# Import BitsTransfer ...
#if (!(Get-Module BitsTransfer -ErrorAction SilentlyContinue)) {
#    Import-Module BitsTransfer
#} else {
#    # BitsTransfer module already loaded ... clear queue
#}
#    Get-BitsTransfer | Complete-BitsTransfer

if (Test-Path C:\local\lib\WASP.dll) {
    Import-Module C:\local\lib\WASP.dll
}

Write-Host "${basename}: Load DeploymentConfig"
# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1", "C:\local\bin\99-DeploymentConfig.ps1")
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/bin/Get-InstalledSoftware.ps1", "C:\local\bin\Get-InstalledSoftware.ps1")
. C:\local\bin\99-DeploymentConfig.ps1
. C:\local\bin\Get-InstalledSoftware.ps1

$basename = "00-bootstrap"

SetConsoleWindow
$host.ui.RawUI.WindowTitle = "00-bootstrap"

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

# close window for previous session
Select-Window -Title "00-init" | Send-Keys ~
Select-Window -Title "Administrator`: 00-init" | Send-Keys ~

Start-Sleep -Seconds 2
if (Select-Window -Title "00-init") {
    Select-Window -Title "00-init" | Send-Keys ~
    Select-Window -Title "00-init" | Send-Keys ~
}

# Start Time and Transcript
Start-Transcript -Path "$Env:temp\$basename.log"
$StartDateTime = Get-Date
Write-Host "Script started at $StartDateTime" -ForegroundColor Green

# --------------------------------------------------------------------------------------------
Write-Host "${basename}: System eligibility check" -ForegroundColor Magenta

# Checking for Compatible OS
Write-Host "Checking if OS is Windows 7"

$BuildNumber = Get-WindowsBuildNumber
if ($BuildNumber -le 7601) {
    # Windows 7 RTM=7600, SP1=7601
    WriteSuccess "`t PASS: OS is Windows 7 (RTM 7600/SP1 7601)"
}
else {
    WriteErrorAndExit "`t FAIL: Windows version $BuildNumber detected and is not supported. Exiting"
}

# --------------------------------------------------------------------------------------------
# get updated root certificates
#msiexec /i http://www.cacert.org/certs/CAcert_Root_Certificates.msi /quiet /passive

Write-Host "${basename}: Install Software and Required Toolset ..." -ForegroundColor Magenta

choco feature enable -n=allowGlobalConfirmation
Breathe

#if (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
#  # chocolatey already installed .. check for old version pin
#  C:\ProgramData\chocolatey\bin\choco.exe pin remove --name chocolatey
#}
#cinst chocolatey
#cinst Boxstarter

# fix mis-versioned 7z.exe x64 binary
#Move-Item -Path "$Env:ProgramData\chocolatey\tools\7z.exe" "$Env:ProgramData\chocolatey\tools\7z-x64.exe" -Force
#Move-Item "$Env:ProgramData\chocolatey\tools\7za.exe" "$Env:ProgramData\chocolatey\tools\7z.exe" -Force

cinst 7zip
cinst 7zip.commandline
cinst unzip --ignore-checksums

cinst dotnet4.5.1 --ignore-checksums
cinst dotnet4.5.2 --ignore-checksums
cinst dotnet4.6.2 --version 4.6.01590.0

# below: requires .Net 4+ to run
cinst Boxstarter.Common
cinst boxstarter.WinConfig
cinst Boxstarter.Chocolatey
cinst chocolatey-core.extension
cinst chocolatey-uninstall.extension

if (!(Get-Service -Name "TeamViewer" -ErrorAction SilentlyContinue)) {
    cinst teamviewer.host --version 12.0.72365
    Start-Sleep -Seconds 5
    Write-Host "${basename}: Download TeamViewer Settings"
    #Start-BitsTransfer -Source "$Env:deployurl/etc/PRODUCTION-201701-TEAMVIEWER-HOST.reg" -Destination "$Env:local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg"
    Invoke-WebRequest -Uri "$Env:deployurl/etc/PRODUCTION-201701-TEAMVIEWER-HOST.reg" -OutFile "$Env:local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg" -Verbose
    Write-Host "${basename}: Install teamviewer Settings"
    reg.exe import c:\local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg
    Stop-Service TeamViewer
    Stop-Service TeamViewer
}

$env:TeamViewerClientID = (Get-ItemProperty -Path "HKLM:\SOFTWARE\TeamViewer" -Name ClientID).ClientID
$env:TeamViewerClientID = (Get-ItemProperty -Path "HKLM:\SOFTWARE\TeamViewer" -Name ClientID).ClientID

# gow installer is easily confused ... only run if gow isn't installed ..
if (!(Test-Path "C:\Program Files\Gow\bin")) {
    cinst gow --ignore-checksums
}

cinst nircmd --ignore-checksums
# cinst xmlstarlet
## cinst curl
cinst nssm --ignore-checksums
# cinst f.lux

Breathe

cinst ie11 --ignore-checksums

Breathe

cinst git.install -params '"/WindowsTerminal /GitOnlyOnPath /NoAutoCrlf"'

#cinst powershell -version 3.0.20121027
#schtasks /Run /TN "\Microsoft\Windows\.NET Framework\.NET Framework NGEN v4.0.30319"

Write-Host "${basename}: Fixing critical Windows svchost.exe memory leak -- KB2889748"
& "$Env:SystemRoot\System32\wusa.exe" "$Env:_tmp\Windows6.1-KB2889748-x86.msu" /quiet
#& "$Env:SystemRoot\System32\wusa.exe" "$Env:_tmp\Windows6.1-KB2889748-x86.msu" /quiet /forcereboot
Start-Process -FilePath wusa.exe -ArgumentList "$Env:_tmp\Windows6.1-KB2889748-x86.msu /quiet" -Wait

Breathe

Write-Host "${basename}: Disable Windows Update"
#Disable-MicrosoftUpdate
Breathe

Write-Host "${basename}: Installing Powershell 5"
cinst powershell
Breathe
Start-Sleep -Seconds 5

(New-Object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex

# powershell performance issues
# https://blogs.msdn.microsoft.com/powershell/2008/07/11/speeding-up-powershell-startup/
if (!( Test-Path "$env:local\status\powershell4-ngen.ok" -ErrorAction SilentlyContinue)) {
    New-Item -Type File -Path "$env:local\status\powershell4-ngen.ok" -Force
    iex ((New-Object System.Net.WebClient).DownloadString('http://lockerlife.hk/deploy/fix-powershell4-performance.ps1'))
}

if ($PSVersionTable.PSVersion.Major -gt 4) {
    Install-PackageProvider -Name NuGet -Force
}

# --------------------------------------------------------------------------------------------
Write-Host "${basename}: Installing Microsoft Security Essentials (antivirus)"
# https://technet.microsoft.com/en-us/library/gg131918.aspx?f=255&MSPPError=-2147217396

cinst microsoftsecurityessentials -version 4.5.0216.0 --ignore-checksums

Write-Host "${basename}: Update MSAV Signature"
& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate
#& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2

#& "$Env:SystemRoot\System32\timeout.exe" /t 5 /nobreak
#& "$Env:SystemRoot\System32\sc.exe" stop MsMpSvc

# --------------------------------------------------------------------------------------------
Write-Host "${basename}: Installing additional tools"

cinst vim --ignore-checksums
cinst jq --ignore-checksums
cinst clink --ignore-checksums
#cinst wincommandpaste --ignore-checksums
#cinst webpicmd
#cinst putty
cinst rsync --ignore-checksums
#cinst wget
cinst which --ignore-checksums
cinst sysinternals --ignore-checksums

#cinst teraterm
Breathe

# --------------------------------------------------------------------------------------------
Write-Host "${basename}: START - Java and Java Runtime Environment ..."
#(Get-InstalledSoftware -Verbose -Computername $env:computername).DisplayName -like '*java*'

Write-Host "${basename}: Installing Java jre"
Set-Location -Path "C:\temp"
& ".\jre-8u111-windows-i586.exe" INSTALLCFG=c:\temp\jre-install.properties /L "$Env:logs\jre-install.log"
Breathe

# Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre NOSTARTMENU=ENABLE WEB_JAVA=DISABLE WEB_ANALYTICS=DISABLE REBOOT=ENABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE REMOVEOUTOFDATEJRES=1 " 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=216432'
Write-Host "${basename}: Java installed ..." -ForegroundColor Green
#java.exe -version 
#Reg.exe DELETE "HKLM\SOFTWARE\JavaSoft\Java Update" /f
Write-Host "${basename}: END - Java and Java Runtime Environment ..."

Breathe

# --------------------------------------------------------------------------------------------
Write-Host "${basename}: Out of band Installers"

Write-Host "${basename}: Install QuickSet ..."

if ( Get-WmiObject -Class Win32_Product | where { $_.Name -like "QuickSet*" } ) {
    Write-Host "${basename}: Installing QuickSet"
    Start-Process "msiexec.exe" -ArgumentList '/i http://lockerlife.hk/deploy/_pkg/QuickSet-2.07-bulid0805.msi /quiet /passive /L*v e:\logs\quickset-install.log' -Wait
}

Write-Host "${basename}: Install Axis Camera Tools ..."

if (Test-Path -Path '$env:programfiles\Axis*') {
    Start-Process "msiexec.exe" -ArgumentList '/i http://lockerlife.hk/deploy/_pkg/AMC_Embedded_msi.msi /quiet /passive /L*v e:\logs\amcembedded-install.log' -Wait
}
Write-Host "${basename}: Install Axis Companion"

# REMINDER: install Axis companion ...
#http://cdn.axis.com/ftp/pub_soft/cam_srv/cam_companion/3_31_001/AXISCompanionSetup.exe
#Invoke-WebRequest -Uri "http://cdn.axis.com/ftp/pub_soft/cam_srv/cam_companion/3_31_001/AXISCompanionSetup.exe" -OutFile "c:\temp\AXISCompanionSetup3_31_001.exe"
#Invoke-WebRequest -Uri "http://cdn.axis.com/ftp/pub_soft/cam_srv/cam_companion/3_40_007/AXISCompanionSetup.exe" -OutFile "C:\temp\AXISCompanionSetup3_40_007.exe"

Breathe
# --------------------------------------------------------------------------------------------
# after drivers, hardware ...
# --------------------------------------------------------------------------------------------

# Disable NTFS last access timestamp
fsutil.exe behavior set disablelastaccess 1

# disable monitor timeout
powercfg.exe -change -monitor-timeout-ac 0

Breathe
# --------------------------------------------------------------------------------------------
# Install scanner driver
# --------------------------------------------------------------------------------------------

Set-Location -Path "$env:local\drivers"

# step 1: install usb virtual com interface
# takes 3-5 minutes to install
Write-Host "${basename}: installing usb virtual com interface for driver"
#& "$Env:local\drivers\scanner\udp_and_vcom_drv211Setup\udp_and_vcom_drv.2.1.1.Setup.exe" /S
Start-Process "c:\windows\system32\msiexec.exe" -ArgumentList "/i http://lockerlife.hk/deploy/drivers/udp_and_vcom_drv_v2.0.1.msi /quiet /passive /L*v c:\logs\udp_and_vcom_drv-install.log" -Wait

# windows should look in IOUSB for remainder; 00-bootstrap


#Write-Host "${basename}: Auto Configure Scanner ... "
#
#

Breathe
# --------------------------------------------------------------------------------------------
# DISABLE 802.11 / Bluetooth interfaces
# --------------------------------------------------------------------------------------------

Write-Host "${basename}: Disable Bluetooth Interface"
& "$Env:local\bin\devcon.exe" disable BTH*
svchost.exe -k bthsvcs
Stop-Service bthserv
reg add "HKLM\SYSTEM\CurrentControlSet\services\bthserv" /v Start /t REG_DWORD /d 4 /f

# 2017-01 Temporarily hold off on disabling wifi
& "$Env:SystemRoot\System32\netsh.exe" interface set interface name="Wireless Network Connection" admin=DISABLED

## must install printer before gpo;
## must let machine contact windows update

# 2017 March - fix printer mistake
#net stop spooler
Stop-Service Spooler -Verbose
Remove-Item "$env:systemroot\System32\spool\printers\*.shd" -Force -Verbose
Remove-Item "$env:systemroot\System32\spool\printers\*.spl" -Force -Verbose
cscript c:\windows\system32\Printing_Admin_Scripts\en_US\prnjobs.vbs
Start-Service Spooler -Verbose

Breathe

Set-Location -Path "$env:local\drivers"
"printer.zip", "printer-filter.zip", "printer-test.zip" | ForEach-Object {
    if (Test-Path $_) {
        C:\ProgramData\chocolatey\bin\unzip.exe -o $_
        #Remove-Item $_ -Force -Confirm:$false -Force
    }
    else {
        Write-Host "${basename}: $_ missing" 
    }
}

# --------------------------------------------------------------------------------------------
# Install printer-filter driver
# RUNDLL32.EXE SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 path-to-inf\infname.inf
# --------------------------------------------------------------------------------------------
# choco install -y zadig
# check; don't reinstall if already exists
# ** implementation incomplete ...
#Write-Host "${basename}: Checking printer status ..."
& "$Env:SystemRoot\System32\wbem\wmic.exe" printer list status | Select-String 80mm

## step 1: install port
C:\windows\system32\RUNDLL32.EXE SETUPAPI.DLL, InstallHinfSection DefaultInstall 132 C:\local\drivers\printer\Windows81Driver\POS88EN.inf

## %LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install "--device=USB\VID_0483&PID_5720&REV_0100"

Write-Host "${basename}: Installing printer-filter driver" -ForegroundColor Magenta
#& "$Env:local\drivers\printer-filter\libusb-win32\bin\x86\install-filter.exe" install --device=USB\VID_0483"&"PID_5720"&"REV_0100

## step 2: connect/bridge printer-filter to printer
## %LOCKERDRIVERS%\libusb-win32-bin-1.2.6.0\bin\x86\install-filter.exe install --inf=%LOCKERDRIVERS%\printer\SPRT_Printer.inf
Write-Host "${basename}: onnecting printer-filter to printer" -ForegroundColor Magenta
& "$Env:local\drivers\printer-filter\libusb-win32\bin\x86\install-filter.exe" install --inf="$Env:local\drivers\printer\SPRT_Printer.inf"


## Print a test page to one or more printers
## for /f "tokens=1-4 delims=," %i in (%Printer.txt%) do cscript prnctrl.vbs -t -b \\%PrintServer%\%i
##Cscript Prnqctl -e
#& "C:\windows\system32\cscript.exe" "c:\windows\system32\Printing_Admin_Scripts\en-US\prncnfg.vbs" -g -p "80mm Series Printer"
#& "C:\windows\system32\cscript.exe" "c:\windows\system32\Printing_Admin_Scripts\en-US\prnqctl.vbs" -e -p "80mm Series Printer"


chocolatey feature disable -n=allowGlobalConfirmation



Breathe
# --------------------------------------------------------------------------------------------
# Make bginfo run on startup/login
# & "$Env:local\bin\bginfo.exe" "$Env:local\etc\production-admin-bginfo.bgi" /nolicprompt /silent /timer:0
if (-not (Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\bginfo.lnk")) {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\bginfo.lnk")
    $Shortcut.TargetPath = "$Env:local\bin\Bginfo.exe"
    $Shortcut.Arguments = "$Env:local\etc\kiosk-production-black.bgi /nolicprompt /timer:0 /silent"
    $Shortcut.Save()
}


Breathe


# --------------------------------------------------------------------------------------------
Write-Host "${basename}: Cleanup"
# --------------------------------------------------------------------------------------------
if (Get-Process -Name iexplore -ErrorAction SilentlyContinue) {
    Stop-Process -Name iexplore -Force
}

# Cleanup Desktop
CleanupDesktop
Create-DeploymentLinks

#New-Item -ItemType File -Path "$env:local\status\00-bootstrap.done" | Out-Null

Write-Host "${basename}: Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

Stop-TimedSection $timer


Breathe
# --------------------------------------------------------------------------------------------
Write-Host "${basename}: Next stage ... 10-identify"
# --------------------------------------------------------------------------------------------
START http://boxstarter.org/package/url?http://lockerlife.hk/deploy/10-identify.ps1

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('~');

#END OF FILE
