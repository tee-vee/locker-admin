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
Write-Host "DISABLE BLUETOOTH INTERFACE"
& "$Env:SystemRoot\System32\devcon.exe" disable BTH*
& "$Env:SystemRoot\System32\svchost.exe" -k bthsvcs
& "$Env:SystemRoot\System32\net.exe" stop bthserv
& "$Env:SystemRoot\System32\reg.exe" add "HKLM\SYSTEM\CurrentControlSet\services\bthserv" /v Start /t REG_DWORD /d 4 /f

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
& "$Env:local\drivers\udp_and_vcom_drv.2.1.1.Setup.exe" /S


# windows should look in IOUSB for remainder; 00-bootstrap

# install scanner tools
#& C:\temp\QuickSet-2.07-bulid0805.msi

# Update MSAV Signature
# https://technet.microsoft.com/en-us/library/gg131918.aspx?f=255&MSPPError=-2147217396
#"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate
& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate

#"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2
& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2


WriteInfoHighlighted "$basename -- Disable Automatic Updates"
REG ADD "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f

# --------------------------------------------------------------------------------------------
# Disable Remote Assistance
Write-Host "$basename -- Disabling Remote Assistance..."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0 -Verbose

# --------------------------------------------------------------------------------------------
# Adjust for Best Performance
REG ADD "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 2 /f

# suppress errors (production) - need watchdog
#%REGEXE% add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Windows" /v ErrorMode /t REG_DWORD /d 2 /f >nul 2>&1
#%REGEXE% add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f >nul 2>&1

# --------------------------------------------------------------------------------------------
# Disable Location Tracking
Write-Host "$basename -- Disabling Location Tracking..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0 -Verbose
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0 -Verbose


# --------------------------------------------------------------------------------------------
# Disable Advertising ID
Write-Host "$basename -- Disabling Advertising ID..."
If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" | Out-Null
}

# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0


#--------------------------------------------------------------------
# UI Tweaks
#--------------------------------------------------------------------

# kill aero and visual effects
WriteInfoHighlighted "$basename -- Stopping uxsms"
Get-Service uxsms
Stop-Service -Verbose uxsms -ErrorAction SilentlyContinue
net stop uxsms


#--------------------------------------------------------------------
# Change LogonUI wallpaper
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\background" -Name OEMBackground -Value 1 -Force -Verbose
Copy-Item "$Env:local\etc\pantone-process-black-c.jpg" -Destination "$Env:SystemRoot\System32\oobe\info\backgrounds\logon-background-black.jpg" -Force


#--------------------------------------------------------------------
# Disable Action Center
Write-Host "$basename -- Disabling Action Center..."
If (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) {
    New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" | Out-Null
}

Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0


# Enable Action Center
# Remove-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter"
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled"


#--------------------------------------------------------------------
# Disable Lock screen
#Write-Host "$basename -- Disabling Lock screen..."
#If (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization")) {
#    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" | Out-Null
#}
#Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Type DWord -Value 1


# Enable Lock screen
# Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen"


#--------------------------------------------------------------------
# Disable Autoplay
Write-Host "$basename -- Disabling Autoplay..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 1


# Enable Autoplay
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 0


#--------------------------------------------------------------------
# Disable Autorun for all drives
Write-Host "$basename -- Disabling Autorun for all drives..."
If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ErrorAction SilentlyContinue
}

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Type DWord -Value 255


# Enable Autorun for all drives
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun"

#--------------------------------------------------------------------
# Disable Sticky keys prompt
Write-Host "$basename -- Disabling Sticky keys prompt..."
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value 506


# Enable Sticky keys prompt
# Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value 510

#--------------------------------------------------------------------
# Hide Search button / box
#Write-Host "$basename -- Hiding Search Box / Button..."
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0


# Show Search button / box
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode"

#--------------------------------------------------------------------
# Hide Task View button
#Write-Host "$basename -- Hiding Task View button..."
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0


# Show Task View button
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton"

#--------------------------------------------------------------------
# Show large icons in taskbar
#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons"

# Show small icons in taskbar
Write-Host "$basename -- Showing small icons in taskbar..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Type DWord -Value 1

# Unpin from taskbar
"$env:USERPROFILE\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Windows Media Player.lnk"

#--------------------------------------------------------------------
# Hide Computer shortcut from desktop
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"


#--------------------------------------------------------------------
# Remove Desktop icon from computer namespace
#Write-Host "$basename -- Removing Desktop icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" -Recurse -ErrorAction SilentlyContinue


# Add Desktop icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"


#--------------------------------------------------------------------
# Remove Documents icon from computer namespace
#Write-Host "$basename -- Removing Documents icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" -Recurse -ErrorAction SilentlyContinue
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" -Recurse -ErrorAction SilentlyContinue


# Add Documents icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}"


#--------------------------------------------------------------------
# Remove Downloads icon from computer namespace
#Write-Host "Removing Downloads icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" -Recurse -ErrorAction SilentlyContinue
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" -Recurse -ErrorAction SilentlyContinue


# Add Downloads icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}"


#--------------------------------------------------------------------
# Remove Music icon from computer namespace
Write-Host "$basename -- Removing Music icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -Recurse -ErrorAction SilentlyContinue


# Add Music icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}"


#--------------------------------------------------------------------
# Remove Pictures icon from computer namespace
Write-Host "$basename -- Removing Pictures icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -Recurse -ErrorAction SilentlyContinue


# Add Pictures icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}"


#--------------------------------------------------------------------
# Remove Videos icon from computer namespace
Write-Host "$basename -- Removing Videos icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -Recurse -ErrorAction SilentlyContinue


# Add Videos icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}"

#--------------------------------------------------------------------
# shorten shutdown wait time - WaitToKillServiceTimeout
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control" /v Start /t REG_DWORD /d 4 /f



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


WriteInfo "$basename -- Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

#if (Test-PendingReboot) { Invoke-Reboot }
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
New-Item -ItemType File -Path "$Env:local\status\$basename.done" -ErrorAction SilentlyContinue | Out-Null

& "$Env:curl" --progress-bar -Ss -k --url "https://api.github.com/zen" ; Write-Host "."
Write-Host "`n`n"


Write-Host "`n $basename -- Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

# last chance to reboot before next step ...
Reboot-IfRequired

#--------------------------------------------------------------------
Write-Host "$basename - Next stage ... "
#--------------------------------------------------------------------
#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f
Stop-Process -Name iexplore -ErrorAction SilentlyContinue -Verbose
& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/30-lockerlife.ps1"
