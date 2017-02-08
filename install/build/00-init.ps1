# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-init - make directories, setup system-only user accounts (no LockerLife customizations)
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 00-init"




#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------
$ErrorActionPreference = "Continue"

## Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	1..5 | % { Write-Host }
	exit
}

# backup
Enable-ComputerRestore -Verbose -Drive "C:\" -Confirm:$false
Checkpoint-Computer -Description "Pre-Deployment" -Verbose

# close previous IE windows ...
Stop-Process -Name iexplore -Verbose

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
#$WebClient = New-Object System.Net.WebClient
#$WebClient.DownloadFile("$Env:deployurl/99-DeploymentConfig.ps1","$Env:temp\99-DeploymentConfig.ps1")
#. "$Env:temp\99-DeploymentConfig.ps1"
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1

$basename = "00-init"

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

$BuildNumber = Get-WindowsBuildNumber
if ($BuildNumber -le 7601)
{
    # Windows 7 RTM=7600, SP1=7601
    WriteSuccess "PASS: OS is Windows 7 (RTM 7600/SP1 7601)"
    } else {
    WriteErrorAndExit "`t FAIL: Windows version $BuildNumber detected and is not supported. Exiting"
}

# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Setup D drive ..."
# --------------------------------------------------------------------------------------------
$diskpartD = @"
select disk=1
clean
create partition primary
select partition=1
format FS=NTFS UNIT=4096 LABEL="LOCKERLIFEAPP" QUICK
assign letter=D
"@
Set-Content -Path C:\diskpartD.txt -Value $diskpartD
diskpart /s C:\diskpartD.txt

$diskpartE = @"
select disk=2
clean
create partition primary
select partition=1
format FS=NTFS LABEL="logs" QUICK
assign letter=E
"@
Set-Content -Path C:\diskpartE.txt -Value $diskpartE
diskpart /s C:\diskpartE.txt

#--------------------------------------------------------------------
Write-Host "$basename - General Windows Configuration"
#--------------------------------------------------------------------

#--------------------------------------------------------------------
Write-Host "$basename -- HARDWARE CONFIGURATION"
Write-Host "$basename -- Disable hibernate"
Start-Process 'powercfg.exe' -Verb RunAs -ArgumentList '/h off' -Wait -Verbose

#power plan type (0=power saver, 1=high performance, 2=balanced)
#powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c fea3413e-7e05-4911-9a71-700331f1c294 245d8541-3943-4422-b025-13a784f679b7 1
#powercfg -setdcvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c fea3413e-7e05-4911-9a71-700331f1c294 245d8541-3943-4422-b025-13a784f679b7 1

# sets the power configuration to High Performance -- does this really work?
#powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# turns hibernation off
#powercfg -hibernate OFF

#monitor timeout
#powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
#powercfg -setdcvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0

#multimedia settings (0=take no action, 1=prevent computer from sleeping, 2=enable away mode)
#powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 2
#powercfg -setdcvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 2

## SAMPLE ...
#$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
#$Name = "NoLockScreen"
#$value = "1"
#
#if(!(Test-Path $registryPath))
#        {
#            New-Item -Path $RegistryPath -Force | Out-Null
#            New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
#        }
#else
#        {
#            New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
#        }
#
#Get-ItemProperty $RegistryPath

# --------------------------------------------------------------------------------------------
Write-Host "$basename - SOFTWARE CONFIGURATION"
# --------------------------------------------------------------------------------------------

# Write-Host "$basename -- Update boot screen"
# & "$Env:local\bin\BootUpdCmd20.exe" "$Env:local\etc\build\lockerlife-boot-custom.bs7"

Write-Host "$basename -- Hide boot"
Start-Process 'bcdedit.exe' -Verb RunAs -ArgumentList '/set bootux disabled' -Wait -Verbose

Write-Host "$basename -- disable boot startup repair mode for current mode"
bcdedit /set {current} bootstatuspolicy ignoreallfailures

Write-Host "$basename -- Set Boot startup repair mode as disabled as default"
# undo: bcdedit /deletevalue {current} bootstatuspolicy
Start-Process 'bcdedit.exe' -Verb RunAs -ArgumentList '/set {default} recoveryenabled No' -Wait -Verbose
Start-Process 'bcdedit.exe' -Verb RunAs -ArgumentList '/set {default} bootstatuspolicy ignoreallfailures' -Wait -Verbose

Stop-Service CscService -Confirm:$False -Verbose
# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Configure Windows Time Services"
# stop windows time service
Stop-Service w32time -Confirm:$False -Verbose
Write-Host "$basename -- Set Time Zone"
& "$Env:SystemRoot\System32\tzutil.exe" /s "China Standard Time"
& "$Env:SystemRoot\System32\w32tm.exe" /tz
Write-Host "$basename -- Set Nearby NTP Servers"
& "$Env:SystemRoot\System32\w32tm.exe" /config /syncfromflags:manual /manualpeerlist:"stdtime.gov.hk 0.asia.pool.ntp.org 3.asia.pool.ntp.org"
Start-Service w32time -Confirm:$False -Verbose
& "$Env:SystemRoot\System32\w32tm.exe" /query /status /verbose

#--------------------------------------------------------------------
Write-Host "$basename -- Set Language and Region"
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sLanguage -Value ENU
Set-ItemProperty -Path "HKCU:\Control Panel\International\Geo" -Name Nation -Value 104

# --------------------------------------------------------------------------------------------
# Disable Location Tracking
#Write-Host "$basename - Disabling Location Tracking..."
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Type DWord -Value 0 -Verbose
#Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Type DWord -Value 0 -Verbose
#Set-ItemProperty -Path "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Diagnostics" -Name "GPSvcDebugLevel" -Type DWord -Value "GPSvcDebugLevel"=dword:00030002

## Disable Advertising ID
#Write-Host "$basename - Disabling Advertising ID..."
#If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
#    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" | Out-Null
#}
#
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Type DWord -Value 0

#--------------------------------------------------------------------
Write-Host "$basename -- Set Sound Volume to minimum"
$obj = new-object -com wscript.shell
$obj.SendKeys([char]173)

#  Disable user from enabling the startup sound
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupSound /t REG_DWORD /d 1 /f

# Somehow setting DisableStartupSound = 0 here actually disables the sound
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v DisableStartupSound /t REG_DWORD /d 0 /f

# And finally, change the sound scheme to No Sound:
# Set the sound scheme to No Sound
# reg add "HKCU\AppEvents\Schemes" /t REG_SZ /d ".None" /f 2>nul >nul

Write-Host "$basename -- Set File Associations"
Install-ChocolateyFileAssociation ".err" "${Env:SystemRoot}\System32\notepad.exe"


#--------------------------------------------------------------------
Write-Host "$basename - Before login ..."
Write-Host "$basename - set logon UI Background image"
# enable custom logon background
#HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background" -Name OEMBackground -Value 1 -Verbose -Force
WriteInfoHighlighted "."

# Disable Welcome logon screen & require CTRL+ALT+DEL
REG ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v LogonType /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD /t REG_DWORD /d 0 /f

# Interactive logon: Do not display last user name
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v dontdisplaylastusername /t REG_DWORD /d 1 /f

#--------------------------------------------------------------------
Write-Host "$basename - After login ..."
#--------------------------------------------------------------------
New-Item -ItemType File "C:\local\bin\autologon.bat" -ErrorAction SilentlyContinue -Verbose

# Windows Explorer Settings through Choco
#Set-WindowsExplorerOptions -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom


# --------------------------------------------------------------------------------------------
Write-Host "$basename --  Adjust UI for Best Performance"
reg load "hku\temp" "%USERPROFILE%\..\Default User\NTUSER.DAT"
REG ADD "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f
Set-ItemProperty "HKEY_USERS:\.DEFAULT\Control Panel\Colors" -Name Background -Value "0 0 0" -Verbose

reg unload "hku\temp"

# kill aero and visual effects
WriteInfoHighlighted "$basename -- Stopping uxsms"
Get-Service uxsms
Stop-Service -Verbose uxsms -ErrorAction SilentlyContinue
net stop uxsms

Write-Host "$basename - Set UI to Classic Theme"
#& "$Env:SystemRoot\System32\rundll32.exe" "$Env:SystemRoot\system32\shell32.dll,Control_RunDLL" "$Env:SystemRoot\system32\desk.cpl" desk,@Themes /Action:OpenTheme /file:"$Env:SystemRoot\Resources\Ease of Access Themes\classic.theme"
Start-Process -Wait -FilePath "rundll32.exe" -ArgumentList "$env:SystemRoot\system32\shell32.dll,Control_RunDLL $env:SystemRoot\system32\desk.cpl desk,@Themes /Action:OpenTheme /file:""C:\Windows\Resources\Ease of Access Themes\classic.theme"""
# close Personalization window ...
(New-Object -ComObject Shell.Application).Windows() | Where-Object { $_.LocationName -eq "Personalization" } | ForEach-Object { $_.quit() }

Write-Host "$basename - Set Desktop Background to solid colors"
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies" -Name System -Verbose -Force
#Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value "" -Verbose -Force
#New-Item -Path "HKEY_USERS:\.DEFAULT\Control Panel\Desktop" -Name Wallpaper -Verbose
#Set-ItemProperty -Path "HKEY_USERS:\.DEFAULT\Control Panel\Desktop" -Name Wallpaper -Value "" -Verbose -Force
Write-Host "$basename - Set Desktop Background color"
Set-ItemProperty "HKCU:\Control Panel\Colors" -Name Background -Value "0 0 0" -Verbose


#Write-Host "$basename -- Set Desktop Wallpaper"
#Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name Wallpaper -Value "C:\local\etc\pantone-process-black-c.jpg" -Verbose -Force
#Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name Wallpaper -Value "" -Force
#Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name WallpaperStyle -Value 2 -Verbose -Force

#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$Env:SystemRoot\Web\Wallpaper\YOUR_FILE.bmp" /f
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d "2" /f
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d "0" /f


#--------------------------------------------------------------------
# Disable Lock screen
#Write-Host "$basename -- Disabling Lock screen..."
#If (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization")) {
#    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Verbose -ErrorAction SilentlyContinue
#}
#Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Type DWord -Value 1


# Enable Lock screen
# Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen"


WriteInfo "$basename - Set lock screen background image"
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows" -Name Personalization -Verbose -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "C:\local\etc\pantone-process-black-c.jpg" -Verbose


#Set the Screen Saver Settings
#REG ADD "HKU\.DEFAULT\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 1 /f
#reg add "HKU\.DEFAULT\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 1 /f
#reg add "HKU\.DEFAULT\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d 900 /f
#reg add "HKU\.DEFAULT\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d "$env:SystemRoot\System32\YOUR_FILE.scr" /f


#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation] "DisableStartupSound"=dword:00000001
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v DisableStartupSound /t REG_DWORD /d 1 /f
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" "DisableStartupSound" 1 -Verbose -Force
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupSound /t REG_DWORD /d 1 /f
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1 -Verbose -Force


#--------------------------------------------------------------------
# Enable Action Center
# Remove-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter"
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled"

# Disable Action Center
Write-Host "$basename - Disabling Action Center..."
If (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) {
    New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" | Out-Null
}

Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0


# --------------------------------------------------------------------
# Disable Autoplay
Write-Host "$basename - Disabling Autoplay..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 1


# Enable Autoplay
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 0


#--------------------------------------------------------------------
# Disable Autorun for all drives
Write-Host "$basename - Disabling Autorun for all drives..."
If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" | Out-Null
}

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Type DWord -Value 255


# Enable Autorun for all drives
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun"

#--------------------------------------------------------------------
# Disable Sticky keys prompt
Write-Host "$basename - Disabling Sticky keys prompt..."
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name Flags -Type String -Value 506 -Verbose -Force


# Enable Sticky keys prompt
# Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "510"

#--------------------------------------------------------------------
# Hide Search button / box
#Write-Host "$basename - Hiding Search Box / Button..."
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0


# Show Search button / box
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode"

#--------------------------------------------------------------------
# Hide Task View button
#Write-Host "$basename - Hiding Task View button..."
#Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0


# Show Task View button
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton"

#--------------------------------------------------------------------
# Show large icons in taskbar
#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons"

# Show small icons in taskbar
Write-Host "$basename - Showing small icons in taskbar ..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Type DWord -Value 1 -Verbose -Force


# ;Adjust the system tray icons – 0 = Display inactive tray icons
#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer]
#“EnableAutoTray”=dword:00000000


# ;Clear Most Frequently Used items
#[-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\{75048700-EF1F-11D0-9888-006097DEACF9}]
#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\{75048700-EF1F-11D0-9888-006097DEACF9}]
#@=””


# ;Show/Hide desktop icons
#; Internet Explorer = {871C5380-42A0-1069-A2EA-08002B30309D}
#; User’s Files = {450D8FBA-AD25-11D0-98A8-0800361B1103}
#; Network = {208D2C60-3AEA-1069-A2D7-08002B30309D}

# ; 0 = Display
# ; 1 = Hide


#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons]
#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel]
#“{871C5380-42A0-1069-A2EA-08002B30309D}”=dword:00000001
#“{450D8FBA-AD25-11D0-98A8-0800361B1103}”=dword:00000000
#“{20D04FE0-3AEA-1069-A2D8-08002B30309D}”=dword:00000000
#“{208D2C60-3AEA-1069-A2D7-08002B30309D}”=dword:00000000


# --------------------------------------------------------------------
# Hide Computer shortcut from desktop
#   ; Computer = {20D04FE0-3AEA-1069-A2D8-08002B30309D}
#Remove-ItemProperty -Path "[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons]" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"

#Remove-ItemProperty -Path "[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel]" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"


# --------------------------------------------------------------------
# Remove Desktop icon from computer namespace
#Write-Host "Removing Desktop icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" -Recurse -ErrorAction SilentlyContinue


# Add Desktop icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"


# --------------------------------------------------------------------
# Remove Documents icon from computer namespace
Write-Host "$basename - Removing Documents icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" -Recurse -Verbose
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" -Recurse -Verbose


# Add Documents icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}"


# --------------------------------------------------------------------
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



# --------------------------------------------------------------------
# Internet Explorer customizations ...
REG ADD "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main" /v DisableFirstRunCustomize /t REG_DWORD /d 1 /f
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "http://lockerlife.hk/deploy" /f

#--------------------------------------------------------------------
Write-Host "$basename -- Windows Networking Configuration"

Write-Host "$basename -- speed up network copies"
netsh int tcp set glocal autotuninglevel=disabled

Write-Host "$basename -- disable the network location prompt"
## reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\FirstNetwork" /v Category /t REG_DWORD /d 00000001 /f
Write-Host "$basename -- disable netbios"
wmic nicconfig where TcpipNetbiosOptions=0 call SetTcpipNetbios 2
wmic nicconfig where TcpipNetbiosOptions=1 call SetTcpipNetbios 2

## Windows Firewall
WriteInfoHighlighted "$basename -- Configure Windows Firewall"
WriteInfoHighlighted "$basename -- turn on firewall"
& "$Env:SystemRoot\System32\netsh.exe"  advfirewall set allprofiles state on

## QUERY FIREWALL RULES
#& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall show rule name=all

## set logging
& "$Env:SystemRoot\System32\netsh.exe" advfirewall set currentprofile logging filename "e:\logs\firewall-cur.log"
& "$Env:SystemRoot\System32\netsh.exe" advfirewall set allprofiles logging filename "e:\logs\firewall-all.log"

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


#--------------------------------------------------------------------
# Enable Remote Desktop for locker deployment
# REG ADD "HKLM\System\Currentcontrolset\control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
# Allow connections from computers running any version of Remote Desktop (less secure)
# REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f

## Disable Remote Assistance
#Write-Host "$basename - Disabling Remote Assistance..."
#Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0 -Verbose
#

# --------------------------------------------------------------------------------------------
# Disable Remote Assistance
Write-Host "$basename -- Disabling Remote Assistance..."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0 -Verbose


#--------------------------------------------------------------------
Write-Host "$basename - Make some directories"
#--------------------------------------------------------------------

# important directories - create directories as early as possible ...
"E:\images\archive","$Env:SystemRoot\System32\oobe\info\backgrounds","$env:local\status","$env:local\logs","$env:local\src","$env:local\gpo","$env:local\etc","$Env:local\drivers","$Env:local\bin","$Env:imagesarchive","$Env:images","~\Documents\WindowsPowerShell","~\Desktop\LockerDeployment","~\Documents\PSConfiguration","D:\locker-libs","$Env:_tmp","$Env:logs" | ForEach-Object {
  if (!( Test-Path "$_" )) { New-Item -ItemType Directory -Path "$_" -Verbose}
} # ForEach-Object ...

#--------------------------------------------------------------------
Write-Host "$basename - Make some Files"
#--------------------------------------------------------------------

"~\Documents\PSConfiguration\Microsoft.PowerShell_profile.ps1" | ForEach-Object {
	#New-Item -Path "~\Documents\PSConfiguration\Microsoft.PowerShell_profile.ps1" -ItemType File | Out-Null
  if (!( Test-Path "$_" )) { New-Item -ItemType File -Path "$_" -Verbose }
} # ForEach-Object ...

#--------------------------------------------------------------------
Write-Host "$basename - Get some basic tools"
#--------------------------------------------------------------------

#$WebClient = New-Object System.Net.WebClient
#(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/bin/curl.exe","c:\local\bin\curl.exe")
#$WebClient.DownloadFile("$Env:deployurl/bin/Bginfo.exe","$Env:local\bin\Bginfo.exe")
#& "$Env:curl" --progress-bar -Ss -k -o "$Env:local\bin\devcon.exe" --url "$Env:deployurl/bin/devcon.exe"
#& "$env:curl" --progress-bar -Ss -k --url "https://live.sysinternals.com/Autologon.exe" -o "$Env:local\bin\Autologon.exe"
#& "$env:curl" --progress-bar -Ss -k -o "$env:local\bin\xml.exe" --url "$env:deployurl/bin/xml.exe"


if (!(Get-Module BitsTransfer -ErrorAction SilentlyContinue)) {
	Import-Module BitsTransfer -Verbose
} else {
	# BitsTransfer module already loaded ... clear queue
	Get-BitsTransfer -Verbose | Complete-BitsTransfer -Verbose
}

"mailsend.exe","Bginfo.exe","Autologon.exe","curl.exe","speedtest-cli.exe","devcon.exe","hstart.exe","nircmd.exe","nircmdc.exe","nssm.exe","sendEmail.exe","UPnPScan.exe","xml.exe","du.exe","LGPO.exe","BootUpdCmd20.exe","psexec.exe" | ForEach-Object {
	#Start-Bitstransfer -Source "http://lockerlife.hk/deploy/bin/curl.exe" -Destination "c:\local\bin\curl.exe"
	Start-BitsTransfer -DisplayName "LockerLifeLocalBin" -Source "http://lockerlife.hk/deploy/bin/$_" -Destination "$env:local\bin\$_" -TransferType Download -RetryInterval 60 -Verbose
}
Get-BitsTransfer -Verbose | Complete-BitsTransfer -Verbose

Write-Host "$basename -- GAC Update ..."
& "$Env:curl" -Ss -k -o "$Env:local\bin\update-Gac.ps1" --url "https://msdnshared.blob.core.windows.net/media/MSDNBlogsFS/prod.evol.blogs.msdn.com/CommunityServer.Components.PostAttachments/00/08/92/01/09/update-Gac.ps1"


Write-Host "$basename -- Download System Settings Files ..."

"kiosk-production-black.bgi","lockerlife-boot.bs7","lockerlife-boot-custom.bs7","pantone-classic-blue.bmp","pantone-classic-blue.jpg","pantone-process-black-c.bmp","pantone-process-black-c.jpg","production-admin.bgi","production-kiosk.bgi","PRODUCTION-201701-TEAMVIEWER-HOST.reg","production-gpo.zip" | ForEach-Object {
	Start-BitsTransfer -DisplayName "LockerLifeLocalEtc" -Source "http://lockerlife.hk/deploy/etc/$_" -Destination "$env:local\etc\$_" -TransferType Download -RetryInterval 60 -Verbose
} # ForEach-Object ...

#--------------------------------------------------------------------
Write-Host "$basename - Manage System User Accounts (no lockerlife accounts)"
#--------------------------------------------------------------------

WriteInfoHighlighted "$basename - DISABLE GUEST USER"
# https://technet.microsoft.com/en-us/library/ff687018.aspx
net user guest /active:no

& "$Env:SystemRoot\System32\WinSAT.exe" -v forgethistory

Write-Host "$basename -- Enable Administrator"
net user Administrator /active:yes
NET USER Administrator Locision123
#net user administrator /active:no

$U = Get-WmiObject -class Win32_UserAccount | Where-Object { $_.Name -eq "AAICON" }
if ($U) {
	WriteInfo "$basename -- AAICON user exists"
	WriteInfoHighlighted "$basename -- force Update AAICON Password ..."
	net user AAICON Locision123
} else {
	Write-Host "$basename -- fixing AAICON user account ..."
	#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user AAICON Locision123' -NoNewWindow
	#& "c:\local\bin\autologon.exe" AAICON Locision123
	#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
	#"AutoAdminLogon"="1"
	#"DefaultUserName"="admnistrator"
	#"DefaultPassword"="P@$$w0rd"
	#"DefaultDomainName"="contoso"
	#Start-ChocolateyProcessAsAdmin -statements $args -exeToRun $vcdmount
	net user AAICON Locision123
	net user AAICON Locision123 /add /expires:never /passwordchg:no
}

Get-BitsTransfer | Complete-BitsTransfer

#--------------------------------------------------------------------
Write-Host "$basename - Cleanup"
#--------------------------------------------------------------------

Write-Host "."
Write-Host "$basename -- Running Internet Connection Speed Test ..."
$SpeedTestResults = C:\local\bin\speedtest-cli.exe
$SpeedTestResults
C:\local\bin\mailsend.exe -t locker-admin@lockerlife.hk -f locker-deploy@locision.com -name "locker-deployment speed test" -rp pi-admin@locision.com -rt pi-admin@locision.com -ssl -port 465 -auth -smtp hwsmtp.exmail.qq.com -domain locision.com -user pi-admin@locision.com -pass Locision1707 -sub "4G SpeedTestResults for $Env:ComputerName at $Env:Sitename" -M "$SpeedTestResults"

Write-Host "."

CleanupDesktop
Create-DeploymentLinks
Update-Help -Verbose

# touch $Env:local\status\00-init.done file
New-Item -Path "$local\status\$basename.done" -ItemType File -Verbose -Force -ErrorAction SilentlyContinue | Out-Null

& "$env:curl" --progress-bar -Ss -k --url "https://api.github.com/zen"
Write-Host "."

Write-Host "$basename -- done"
Write-Host "$basename - Next stage ..."
#& "$env:ProgramFiles\Internet Explorer\iexplore.exe" "http://boxstarter.org/package/url?http://lockerlife.hk/deploy/00-bootstrap.ps1"
START http://boxstarter.org/package/url?http://lockerlife.hk/deploy/00-bootstrap.ps1
