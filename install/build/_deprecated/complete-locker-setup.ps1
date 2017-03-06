# Derek Yuen <derekyuen@locision.com>
# December 2016, January 2017

# complete-locker-setup - must run script while logged in as kiosk user
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment - complete-locker-setup"
#$basename = $MyInvocation.MyCommand.Name
#Set-PSDebug -Trace 1


#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------

$ErrorActionPreference = "Continue"

## Verify Running as Admin
#$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
#If (!( $isAdmin )) {
#	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
#	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
#	1..5 | % { Write-Host }
#	exit
#}

# close previous IE windows ...
#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
#$WebClient = New-Object System.Net.WebClient
#$WebClient.DownloadFile("$Env:deployurl/99-DeploymentConfig.ps1","$Env:temp\99-DeploymentConfig.ps1")
#. "$Env:temp\99-DeploymentConfig.ps1"
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1

$basename = "complete-locker-setup"

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted


# Start Time and Transcript
Start-Transcript -Path "$Env:temp\$basename.log"
$StartDateTime = Get-Date
Write-Host "`t Script started at $StartDateTime" -ForegroundColor Green

## set window title
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


# set up scheduled tasks for kiosk user (before we elevate this script to administrator)
#schtasks.exe /Create /SC ONLOGON /TN "StartSeleniumNode" /TR "cmd /c ""C:\SeleniumGrid\startnode.bat"""

# restart dropbox

# mklink %USERPROFILE%\AppData\Roaming\Microsoft\Windows\startm~1\Programs\startup\LockerLife_TV.exe D:\Locker-Slider\LockerLife_TV.exe
# mklink lockerlife_tv.exe d:\Locker-Slider\LockerLife_TV.exe

# --------------------------------------------------------------------------------------------
# [] GROUP POLICY CHECK
WriteInfo "$basename -- GROUP POLICY"
# Original install group policy already backed up
#    Our group policy is applied to groups, not directly to users
#    Good to double check from perspective of user
#    Verify the RSoP
#    (RSoP = Resultant Set of Policy)
#& "$Env:SystemRoot\System32\gpresult" /r /user kiosk

# BACKUP Local Group Policy
#cd %WINDIR%\System32
#%tar% -cvf GroupPolicy-Backup.tar GroupPolicy
#%tar% -cvf GroupPolicyUsers-Backup.tar GroupPolicyUsers
#copy /V /Y %LOCKERINSTALL%\build\complete-locker-setup.cmd %KIOSKHOME%\Desktop


# set background
Write-Host "$basename - Set background"
# & bginfo.exe "$Env:local\etc\kiosk-production-black.bgi" /TIMER:0 /NOLICPROMPT /silent
# xcopy /Y "%WPKG%\custom\bg\bg.bmp" "C:\WINDOWS\web\wallpaper\bg.bmp"
# REG ADD "HKCU\Control Panel\Desktop" /v Wallpaper /f /t REG_SZ /d "%WINDIR%\web\wallpaper\bg.bmp"
# RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters


# --------------------------------------------------------------------------------------------
# Adjust for Best Performance:
#
#(Get-UserSID).SID | ForEach-Object {
#	Write-Host "$_"
#	Set-ItemProperty "HKEY_USERS:\S-1-5-21-3463664321-2923530833-3546627382-1000\Control Panel\Colors" -Name Background -Value "0 0 0" -Verbose
#}
#
#Set-ItemProperty "HKEY_USERS:\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name VisualFXSetting -Type DWord -Value 2 -Verbose
# ""=dword:00000002"

# suppress errors (production) - need watchdog
#%REGEXE% add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Windows" /v ErrorMode /t REG_DWORD /d 2 /f >nul 2>&1
#%REGEXE% add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f >nul 2>&1

# Disable Control Panel
#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer]
#"NoControlPanel"=dword:00000001



#Disable Remote Desktop
REG ADD "HKLM\system\currentcontrolset\control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f


#Allow connections from computers running any version of Remote Desktop (less secure)
#reg add "hklm\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f


# UI Tweaks

# kill aero and visual effects
#Get-Service uxsms
#Stop-Service -Verbose uxsms


# Change LogonUI wallpaper
## first - create key
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\background" -Name OEMBackground -Value 1 -Force -Verbose
#mkdir "$Env:SystemRoot\System32\oobe\info\backgrounds"
Copy-Item "$Env:local\etc\pantone-process-black-c.jpg" -Destination "$Env:SystemRoot\System32\oobe\info\backgrounds\logon-background-black.jpg" -Force


# Disable Lock screen
Write-Host "$basename - Disabling Lock screen..."
If (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization")) {
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" | Out-Null
}
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Type DWord -Value 1


# Enable Lock screen
# Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen"




# Remove Music icon from computer namespace
Write-Host "$basename - Removing Music icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -Recurse -Verbose -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -Recurse -Verbose -ErrorAction SilentlyContinue


# Add Music icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}"


# Remove Pictures icon from computer namespace
Write-Host "$basename - Removing Pictures icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -Recurse -Verbose -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -Recurse -Verbose -ErrorAction SilentlyContinue


# Add Pictures icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}"


# Remove Videos icon from computer namespace
Write-Host "$basename - Removing Videos icon from computer namespace..."
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -Recurse -Verbose -ErrorAction SilentlyContinue
Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -Recurse -Verbose -ErrorAction SilentlyContinue


# Add Videos icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -Verbose
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -Verbose

# shorten shutdown wait time
# WaitToKillServiceTimeout
# REG add "HKLM\SYSTEM\CurrentControlSet\Control" /v Start /t REG_DWORD /d 4 /f


# finishing #


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
cleanmgr.exe /verylowdisk
## del /f /s /q %_tmp%\


Write-Host "`n $basename -- Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript

# last chance to reboot before next step ...
Reboot-IfRequired

Write-Host "."

WriteInfoHighlighted "Press any key to seal this locker or close window to stop shutdown"
pause
& shutdown.exe /c "complete-locker-setup production sealing" /f /r /t 3"
