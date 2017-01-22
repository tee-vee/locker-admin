# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 20-setup - hardware & windows configuration/settings
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 20-setup"


$basename = $MyInvocation.MyCommand.Name

# source DeploymentConfig
(New-Object Net.WebClient).DownloadString("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1") > C:\local\etc\99-DeploymentConfig.ps1
. C:\local\etc\99-DeploymentConfig.ps1

& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

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


# --------------------------------------------------------------------------------------------
# LockerLife setup ...
# --------------------------------------------------------------------------------------------

Write-Host ""
Write-Host "LockerLife setup ..."
Write-Host ""
Write-Host ""

# check
& "$Env:curl" -k -Ss --url "https://api.github.com/users/lockerlife-kiosk"
Write-Host ""
& "$Env:curl" -k -Ss --include --url "https://api.github.com/users/lockerlife-kiosk"
Write-Host ""
& "$Env:curl" -k -Ss --user "lockerlife-kiosk:Locision123" --url "https://api.github.com/authorizations"
Write-Host ""

# curl --user "lockerlife-kiosk:Locision123" https://api.github.com/gists/starred
# curl --user "lockerlife-kiosk:Locision123" https://api.github.com/users/lockerlife-kiosk
#curl --user "lockerlife-kiosk:Locision123" --data '{"description":"Created via API","public":"true","files":{"file1.txt":{"content":"Demo"}}' --url https://api.github.com/gists
# read in from file -> post to my gist
#curl --user "caspyin" --data @data.txt https://api.github.com/gists

# get \local\src
& "$Env:ProgramFiles\git\cmd\git.exe" clone --progress https://lockerlife-kiosk:Locision123@github.com/tee-vee/locker-admin.git "$Env:local\src"
#& "$Env:ProgramFiles\git\cmd\git.exe" clone --progress https://lockerlife-kiosk:Locision123@github.com/tee-vee/locker-admin.git "$Env:local\src"

# get locker-libs
# get-location of locker-libs first from locker-cloud; preserve Last-Modified --> restamp all files using each individual file Last-Modified time
& "$Env:curl" -RSs -k --url "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers/libs" | jq '.[].url' > D:\locker-libs\locker-libs-list.txt


# initial download
# (e.g. cat or type %LIBLIST% | xargs -n 1 curl -LO )
# xargs -P to run in parallel; match nunber of cpu cores
Get-Content D:\locker-libs\locker-libs-list.txt | xargs -P "$Env:Number_Of_Processors" -n 1 curl -LO


# lockerlife production
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/RunLockerLifeConsole.bat"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/RunLockerLifeTV.bat"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/core.jar"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/data-collection.jar"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/run-manual.bat"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/run-test.bat"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/run.bat"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/scanner.jar"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/production-Locker-Console.zip"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/production-Locker-Slider.zip"
& "$Env:curl" -Ss -k -o "D:\" --url "$Env:deployurl/PRODUCTION/production-kioskServer.zip"


#schtasks.exe /Create /SC ONLOGON /TN "StartSeleniumNode" /TR "cmd /c ""C:\SeleniumGrid\startnode.bat"""


## Windows Firewall
WriteInfoHighlighted "LOCAL FIREWALL SETUP"
#& "$Env:SystemRoot\System32\netsh.exe" advfirewall show allprofiles
& "$Env:SystemRoot\System32\netsh.exe" advfirewall set allrprofiles state on

## QUERY FIREWALL RULES
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall show rule name=all

## set logging
& "$Env:SystemRoot\System32\netsh.exe" advfirewall set currentprofile logging filename "e:\logs\pfirewall.log"

## set applications
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Allow Java" dir=in action=allow program="D:\java\jre\java.exe"
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Allow Kioskserver" dir=in action=allow program="D:\kioskserver\kioskserver.exe"
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall set rule group="Remote Desktop" new enable=Yes

## set rulesets
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Open Port 23" dir=in action=allow protocol=TCP localport=23
#netsh advfirewall firewall delete rule name="Open Server Port 23" protocol=tcp localport=23
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Open Port 8080" dir=in action=allow protocol=TCP localport=8080
#netsh advfirewall firewall delete rule name="Open Server Port 8080" protocol=tcp localport=8080
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Open Port 8081" dir=in action=allow protocol=TCP localport=8081
#netsh advfirewall firewall delete rule name="Open Server Port 8081" protocol=tcp localport=8081
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Open Port 9012" dir=in action=allow protocol=TCP localport=9012


# Update MSAV Signature
# https://technet.microsoft.com/en-us/library/gg131918.aspx?f=255&MSPPError=-2147217396
#"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate
& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -SignatureUpdate

#"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2
& "$Env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2

## --------------------------------------------------------------------------------------------
## Windows Customizations ...
## --------------------------------------------------------------------------------------------
# Disable hibernate
Start-Process 'powercfg.exe' -Verb runAs -ArgumentList '/h off'

# hide boot
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set bootux disabled'

# disable booting into recovery mode
# undo: bcdedit /deletevalue {current} bootstatuspolicy
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set {default} recoveryenabled No'
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set {default} bootstatuspolicy ignoreallfailures'


# --------------------------------------------------------------------------------------------
# Adjust for Best Performance:
#
# [HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects]
# "VisualFXSetting"=dword:00000002"

# suppress errors (production) - need watchdog
#%REGEXE% add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Windows" /v ErrorMode /t REG_DWORD /d 2 /f >nul 2>&1
#%REGEXE% add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f >nul 2>&1


# Disable Location Tracking
Write-Host "Disabling Location Tracking..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0 -Verbose
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0 -Verbose


# Disable Advertising ID
Write-Host "Disabling Advertising ID..."
If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" | Out-Null
}

# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0

# Disable Remote Assistance
Write-Host "Disabling Remote Assistance..."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0 -Verbose


# #########
# UI Tweaks
# #########

# kill aero and visual effects
WriteInfoHighlighted ""
Get-Service uxsms
Stop-Service -Verbose uxsms


# Change LogonUI wallpaper
## first - create key
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\background" -Name OEMBackground -Value 1 -Force -Verbose
Copy-Item "$Env:local\etc\pantone-process-black-c.jpg" -Destination "$Env:SystemRoot\System32\oobe\info\backgrounds\logon-background-black.jpg" -Force


# Disable Action Center
Write-Host "Disabling Action Center..."
If (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) {
    New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" | Out-Null
}

Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0


# Enable Action Center
# Remove-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter"
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled"


# Disable Lock screen
#Write-Host "Disabling Lock screen..."
#If (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization")) {
#    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" | Out-Null
#}
#Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Type DWord -Value 1


# Enable Lock screen
# Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen"


# Disable Autoplay
Write-Host "Disabling Autoplay..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 1


# Enable Autoplay
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 0


# Disable Autorun for all drives
Write-Host "Disabling Autorun for all drives..."
If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" | Out-Null
}

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Type DWord -Value 255


# Enable Autorun for all drives
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun"

# Disable Sticky keys prompt
Write-Host "Disabling Sticky keys prompt..."
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "506"


# Enable Sticky keys prompt
# Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "510"

# Hide Search button / box
#Write-Host "Hiding Search Box / Button..."
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0


# Show Search button / box
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode"

# Hide Task View button
#Write-Host "Hiding Task View button..."
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0


# Show Task View button
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton"

# Show large icons in taskbar
#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons"

# Show small icons in taskbar
Write-Host "Showing small icons in taskbar..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Type DWord -Value 1


# Hide Computer shortcut from desktop
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"


# Remove Desktop icon from computer namespace
#Write-Host "Removing Desktop icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" -Recurse -ErrorAction SilentlyContinue


# Add Desktop icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"


# Remove Documents icon from computer namespace
#Write-Host "Removing Documents icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" -Recurse -ErrorAction SilentlyContinue
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" -Recurse -ErrorAction SilentlyContinue


# Add Documents icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}"



# Remove Downloads icon from computer namespace
#Write-Host "Removing Downloads icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" -Recurse -ErrorAction SilentlyContinue
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" -Recurse -ErrorAction SilentlyContinue


# Add Downloads icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}"



# Remove Music icon from computer namespace
#Write-Host "Removing Music icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -Recurse -ErrorAction SilentlyContinue
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -Recurse -ErrorAction SilentlyContinue


# Add Music icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}"


# Remove Pictures icon from computer namespace
#Write-Host "Removing Pictures icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -Recurse -ErrorAction SilentlyContinue
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -Recurse -ErrorAction SilentlyContinue


# Add Pictures icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}"


# Remove Videos icon from computer namespace
#Write-Host "Removing Videos icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -Recurse -ErrorAction SilentlyContinue
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -Recurse -ErrorAction SilentlyContinue


# Add Videos icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}"

# shorten shutdown wait time
# WaitToKillServiceTimeout
# REG add "HKLM\SYSTEM\CurrentControlSet\Control" /v Start /t REG_DWORD /d 4 /f


#############
# finishing #
#############

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

Remove-Item "$Env:userprofile\Desktop\*.lnk"
Install-ChocolateyShortcut -ShortcutFilePath "$Env:Public\Desktop\Restart Deployment.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/00-bootstrap.ps1" -Description "Redeploy Locker"

WriteInfo "Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript
WriteSuccess "Press any key to continue..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL

if (Test-PendingReboot) { Invoke-Reboot }

& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/30-lockerlife.ps1"
