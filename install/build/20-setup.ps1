# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 20-setup - hardware & windows configuration/settings
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 20-setup"
#$basename = Split-Path -Leaf $PSCommandPath
#Set-PSDebug -Trace 1


#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------

$ErrorActionPreference = "Continue"

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

$basename = "20-setup"

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
$newsize.width = 200
$pswindow.buffersize = $newsize

# the nul ensures window size does not chnage
#& cmd /c mode con: cols=150  >nul 2>nul


# --------------------------------------------------------------------------------------------
# DISABLE 802.11 / Bluetooth interfaces
# --------------------------------------------------------------------------------------------
Write-Host ""
Write-Host "$basename -- Disable Bluetooth Interface"
& "$Env:local\bin\devcon.exe" disable BTH*
svchost.exe -k bthsvcs
net stop bthserv
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

# --------------------------------------------------------------------------------------------
# Install scanner driver
# --------------------------------------------------------------------------------------------
# step 1: install usb virtual com interface
# takes 3-5 minutes to install
Write-Host "20-setup: installing usb virtual com interface for driver"
#& "$Env:local\drivers\scanner\udp_and_vcom_drv211Setup\udp_and_vcom_drv.2.1.1.Setup.exe" /S
msiexec /i http://lockerlife.hk/deploy/drivers/udp_and_vcom_drv_v2.0.1.msi /quiet /passive

# windows should look in IOUSB for remainder; 00-bootstrap


# Update MSAV Signature
# https://technet.microsoft.com/en-us/library/gg131918.aspx?f=255&MSPPError=-2147217396
#"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate
& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate

#"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2
& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2


WriteInfoHighlighted "$basename -- Disable Automatic Updates"
REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f


# suppress errors (production) - need watchdog
#%REGEXE% add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Windows" /v ErrorMode /t REG_DWORD /d 2 /f >nul 2>&1
#%REGEXE% add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f >nul 2>&1

#--------------------------------------------------------------------
# Change LogonUI wallpaper
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\background" -Name OEMBackground -Value 1 -Force -Verbose
Copy-Item "$Env:local\etc\pantone-process-black-c.jpg" -Destination "$Env:SystemRoot\System32\oobe\info\backgrounds\logon-background-black.jpg" -Force


# Unpin from taskbar
Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Windows Media Player.lnk"

Get-BitsTransfer | Complete-BitsTransfer

#--------------------------------------------------------------------
# finishing #
#--------------------------------------------------------------------

# Internet Explorer: All:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255

# Internet Explorer: History:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 1

# Internet Explorer:Cookies:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 2

# Internet Explorer: Temp Internet Files:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 8

# Internet Explorer: Form Data:
#& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 16

# Internet Explorer: Passwords:
#& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 32

# Internet Explorer: All:
#& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 4351


#--------------------------------------------------------------------
Write-Host "$basename - Cleanup"
#--------------------------------------------------------------------

# Cleanup Desktop
CleanupDesktop
Create-DeploymentLinks

# touch $Env:local\status\00-init.done file
# echo date/time into file, add lines ...
New-Item -ItemType File -Path "$Env:local\status\$basename.done" -ErrorAction SilentlyContinue | Out-Null

& "$Env:curl" --progress-bar -Ss -k --url "https://api.github.com/zen" ; Write-Host "."


Write-Host "$basename -- Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript


#--------------------------------------------------------------------
Write-Host "$basename - Next stage ... "
#--------------------------------------------------------------------
#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f
#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/30-lockerlife.ps1"
START http://boxstarter.org/package/url?http://lockerlife.hk/deploy/30-lockerlife.ps1
