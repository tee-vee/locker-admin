# Derek Yuen <derekyuen@locision.com>
# complete-locker-setup.ps1 (was complete-locker-setup.cmd)
# December 2016, January 2017

# complete-locker-setup -

$basename = $MyInvocation.MyCommand.Name

# source DeploymentConfig
(New-Object Net.WebClient).DownloadString("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1") > C:\local\etc\99-DeploymentConfig.ps1
. C:\local\etc\99-DeploymentConfig.ps1

Write-Host "complete-locker-setup"

# Small taskbar
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom
Set-WindowsExplorerOptions -DisableShowProtectedOSFiles -DisableShowFileExtensions -DisableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess


# set up git
git config --global user.email kiosk@lockerlife.hk
git config --global user.name 'LockerLife Kiosk'

# set up scheduled tasks for kiosk user (before we elevate this script to administrator)
#schtasks.exe /Create /SC ONLOGON /TN "StartSeleniumNode" /TR "cmd /c ""C:\SeleniumGrid\startnode.bat"""

Write-Host ====================================================================
Write-Host
Write-Host     PLEASE LOGIN TO DROPBOX
Write-Host     Use username kiosk@lockerlife.hk
Write-Host
Write-Host ====================================================================
Write-Host



# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
  Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
  Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
  Write-Host; exit
}

choco install -y dropbox


# --------------------------------------------------------------------------------------------
# update boot screen
# --------------------------------------------------------------------------------------------
# & "$Env:local\bin\BootUpdCmd20.exe" "$Env:local\etc\build\lockerlife-boot-custom.bs7"


Write-Host "Setting up teamviewer"
#hstart /runas /wait "net stop teamviewer"
Stop-Service teamviewer
Stop-Service teamviewer
& "$Env:SystemRoot\System32\Reg.exe" IMPORT "$Env:local\etc\PRODUCTION-201701-TEAMVIEWER-HOST.reg"
#hstart /runas /wait "net start teamviewer"
Restart-Service teamviewer
Write-Host

# restart dropbox

# mklink %USERPROFILE%\AppData\Roaming\Microsoft\Windows\startm~1\Programs\startup\LockerLife_TV.exe D:\Locker-Slider\LockerLife_TV.exe
# mklink lockerlife_tv.exe d:\Locker-Slider\LockerLife_TV.exe

# --------------------------------------------------------------------------------------------
# [] GROUP POLICY CHECK
WriteInfo "GROUP POLICY"
#    Our group policy is applied to groups, not directly to users
#    Good to double check from perspective of user
#    Verify the RSoP
#    (RSoP = Resultant Set of Policy)
#& "$Env:SystemRoot\System32\gpresult" /r /user kiosk

#& hstart /runas /wait "%WINDIR%\System32\XCOPY.EXE /E /R /Y /H /F %USERPROFILE%\Dropbox\locker-admin\install\_gpo\export\production-gpo.zip %WINDIR%\System32"
#& hstart /runas /wait "move /Y %WINDIR%\System32\GroupPolicy %WINDIR%\System32\GroupPolicy-Backup"
#& hstart /runas /wait "move /Y %WINDIR%\System32\GroupPolicyUsers %WINDIR%\System32\GroupPolicyUsers-Backup"
cd "$ENV:SystemRoot\System32"
& hstart /runas /wait "$Env:PROGRAMFILES\7-Zip\7z.exe" e -y -bt production-gpo.zip
& gpupdate /force

# scrub "Recommended programs" options
#HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\filetype\OpenWithList

# [] DISABLE AERO
Write-Host "DISABLE AERO"
& net stop uxsms

# [] CLASSIC THEME
Write-Host "CLASSIC THEME"
#& "$Env:SystemRoot\System32\rundll32.exe" "$Env:SystemRoot\system32\shell32.dll,Control_RunDLL" "$Env:SystemRoot\system32\desk.cpl" desk,@Themes /Action:OpenTheme /file:"$Env:SystemRoot\Resources\Ease of Access Themes\classic.theme"

# set background
Write-Host "set background"
# & bginfo.exe "$Env:local\etc\kiosk-production-black.bgi" /TIMER:0 /NOLICPROMPT /silent
# xcopy /Y "%WPKG%\custom\bg\bg.bmp" "C:\WINDOWS\web\wallpaper\bg.bmp"
# REG ADD "HKCU\Control Panel\Desktop" /v Wallpaper /f /t REG_SZ /d "%WINDIR%\web\wallpaper\bg.bmp"
# RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters


# Update MSAV Signature
# https://technet.microsoft.com/en-us/library/gg131918.aspx?f=255&MSPPError=-2147217396
#"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate
#"%ProgramFiles%\Windows Defender\MpCmdRun.exe" -Scan -ScanType 2


# BACKUP Local Group Policy
#cd %WINDIR%\System32
#%tar% -cvf GroupPolicy-Backup.tar GroupPolicy
#%tar% -cvf GroupPolicyUsers-Backup.tar GroupPolicyUsers
#copy /V /Y %LOCKERINSTALL%\build\complete-locker-setup.cmd %KIOSKHOME%\Desktop

# --------------------------------------------------------------------------------------------
# Adjust for Best Performance:
#
# [HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects]
# "VisualFXSetting"=dword:00000002"

# suppress errors (production) - need watchdog
#%REGEXE% add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Windows" /v ErrorMode /t REG_DWORD /d 2 /f >nul 2>&1
#%REGEXE% add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f >nul 2>&1

# Disable Control Panel
#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer]
#"NoControlPanel"=dword:00000001

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
#Get-Service uxsms
#Stop-Service -Verbose uxsms


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


# Disable Lock screen
Write-Host "Disabling Lock screen..."
If (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization")) {
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" | Out-Null
}
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Type DWord -Value 1


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
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"


# Remove Desktop icon from computer namespace
#Write-Host "Removing Desktop icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" -Recurse -ErrorAction SilentlyContinue


# Add Desktop icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"


# Remove Documents icon from computer namespace
Write-Host "Removing Documents icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" -Recurse -ErrorAction SilentlyContinue


# Add Documents icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}"


# Remove Downloads icon from computer namespace
Write-Host "Removing Downloads icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" -Recurse -ErrorAction SilentlyContinue


# Add Downloads icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}"



# Remove Music icon from computer namespace
Write-Host "Removing Music icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -Recurse -ErrorAction SilentlyContinue


# Add Music icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}"


# Remove Pictures icon from computer namespace
Write-Host "Removing Pictures icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -Recurse -ErrorAction SilentlyContinue


# Add Pictures icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}"


# Remove Videos icon from computer namespace
Write-Host "Removing Videos icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -Recurse -ErrorAction SilentlyContinue


# Add Videos icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}"

# shorten shutdown wait time
# WaitToKillServiceTimeout
# REG add "HKLM\SYSTEM\CurrentControlSet\Control" /v Start /t REG_DWORD /d 4 /f

WriteInfoHighlighted "DISABLE GUEST USER"
# https://technet.microsoft.com/en-us/library/ff687018.aspx
& "$Env:SystemRoot\System32\net.exe" user guest /active:no


& "$Env:SystemRoot\System32\WinSAT.exe" -v forgethistory
& "$Env:SystemRoot\System32\dism.exe" /english /online /disable-feature /featurename:WindowsGadgetPlatform


#############
# finishing #
#############

# disable admin user


# Internet Explorer: All:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 255

# Internet Explorer: History:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 1

# Internet Explorer:Cookies:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 2

# Internet Explorer: Temp Internet Files:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 8

# Internet Explorer: Form Data:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 16

# Internet Explorer: Passwords:
& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 32

# Internet Explorer: All:
#& "$Env:SystemRoot\System32\RunDll32.exe" InetCpl.cpl,ClearMyTracksByProcess 4351

Enable-UAC
Disable-MicrosoftUpdate

#echo.
#echo "%~n0 clean up desktop"
## powershell cleanup script (also executes function-specific cmdlets)
#del /f /s /q "%KIOSKHOME%\Desktop\*.lnk"
#del /f /s /q "%KIOSKHOME%\Desktop\desktop.ini"
#del /f /s /q "%KIOSKHOME%\Recent\*.*"
#del /f /s /q "%USERPROFILE%\Desktop\*.lnk"
#del /f /s /q "%USERPROFILE%\Desktop\desktop.ini"
#del /f /s /q "%USERPROFILE%\Recent\*.*"
#del /f /s /q "%USERPROFILE%\Downloads\*.*"
#rm -fr "%USERPROFILE%\Favorites\*"
#del /f /s /q "%Public%\Desktop\*.lnk"
#del /f /s /q "%Public%\Desktop\desktop.ini"
#del /f /s /q "%Public%\Recent\*.*"
#del /f /s /q "%ALLUSERSPROFILE%\Desktop\*.lnk"
#del /f /s /q "%ALLUSERSPROFILE%\Desktop\desktop.ini"
#del /f /s /q "%ALLUSERSPROFILE%\Recent\*.*"
#sfc /scannow
#start %windir%\System32\cleanmgr.exe /verylowdisk
## del /f /s /q %_tmp%\

WriteInfoHighlighted "Press any key to seal this locker or close window to stop shutdown"
pause
& shutdown.exe /c "complete-locker-setup production sealing" /f /r /t 3"
