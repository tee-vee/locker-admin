# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-init - make directories, setup system-only user accounts (no LockerLife customizations)
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 00-init"




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
Stop-Process -Name iexplore -ErrorAction SilentlyContinue -Verbose

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
WriteInfo "$basename -- Not Yet Implemented ... Skipping"

#--------------------------------------------------------------------
Write-Host "$basename - General Windows Configuration"
#--------------------------------------------------------------------

#--------------------------------------------------------------------
Write-Host "$basename -- HARDWARE CONFIGURATION"
Write-Host "$basename -- Disable hibernate"
Start-Process 'powercfg.exe' -Verb runAs -ArgumentList '/h off' -Wait -Verbose

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



#--------------------------------------------------------------------
Write-Host "$basename - SOFTWARE CONFIGURATION"
#--------------------------------------------------------------------
Write-Host "$basename -- Hide boot"
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set bootux disabled' -Wait -Verbose


Write-Host "$basename -- Disable Boot Recovery Mode"
# disable booting into recovery mode
# undo: bcdedit /deletevalue {current} bootstatuspolicy
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set {default} recoveryenabled No' -Wait -Verbose
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set {default} bootstatuspolicy ignoreallfailures' -Wait -Verbose

#--------------------------------------------------------------------
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

#--------------------------------------------------------------------
Write-Host "$basename -- Set Sound Volume = 0"
$obj = new-object -com wscript.shell
$obj.SendKeys([char]173)

# turn off startup sounds
#reg add "[HKEY_CURRENT_USER\Control Panel\Sound]" "Beep"=No
#REG ADD "HKLM\System\CurrentControlSet\Services\Beep" /v start /t REG_DWORD /d 4 /f

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
# Windows Explorer Settings through Choco
#Set-WindowsExplorerOptions -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom

Write-Host "$basename - Set UI to Classic Theme"
#& "$Env:SystemRoot\System32\rundll32.exe" "$Env:SystemRoot\system32\shell32.dll,Control_RunDLL" "$Env:SystemRoot\system32\desk.cpl" desk,@Themes /Action:OpenTheme /file:"$Env:SystemRoot\Resources\Ease of Access Themes\classic.theme"
Start-Process -Wait -FilePath "rundll32.exe" -ArgumentList "$env:SystemRoot\system32\shell32.dll,Control_RunDLL $env:SystemRoot\system32\desk.cpl desk,@Themes /Action:OpenTheme /file:""C:\Windows\Resources\Ease of Access Themes\classic.theme"""

Write-Host "$basename - Set Desktop Background"
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies" -Name System -Verbose -Force
#Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value "" -Verbose -Force
Set-ItemProperty -Path "HKEY_USERS:\.DEFAULT\Control Panel\Desktop" -Name Wallpaper -Value "" -Verbose -Force

#Write-Host "$basename -- Set Desktop Wallpaper"
#Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name Wallpaper -Value "C:\local\etc\pantone-process-black-c.jpg" -Verbose -Force
#Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name Wallpaper -Value "" -Force
#Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name WallpaperStyle -Value 2 -Verbose -Force

#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$Env:SystemRoot\Web\Wallpaper\YOUR_FILE.bmp" /f
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d "2" /f
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d "0" /f


WriteInfo "$basename - Set lock screen background image"
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows" -Name Personalization -Verbose -ErrorAction SilentlyContinue -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name LockScreenImage -Value "C:\local\etc\pantone-process-black-c.jpg" -Verbose



#Set the Screen Saver Settings
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 1 /f
#reg add "hku\.DEFAULT\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 1 /f
#reg add "hku\.DEFAULT\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d 900 /f
#reg add "hku\.DEFAULT\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d "$env:SystemRoot\System32\YOUR_FILE.scr" /f


#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation] "DisableStartupSound"=dword:00000001
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v DisableStartupSound /t REG_DWORD /d 1 /f
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" "DisableStartupSound" 1 -Verbose -Force
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupSound /t REG_DWORD /d 1 /f
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1 -Verbose -Force


#--------------------------------------------------------------------
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



#--------------------------------------------------------------------
Write-Host "$basename - Make some directories"
#--------------------------------------------------------------------

# important directories - create directories as early as possible ...
"E:\images\archive","$Env:SystemRoot\System32\oobe\info\backgrounds","$local\status","$local\src","$local\gpo","$local\etc","$Env:local\drivers","$Env:local\bin","$Env:imagesarchive","$Env:images","~\Documents\WindowsPowerShell","~\Desktop\LockerDeployment","~\Documents\PSConfiguration","D:\locker-libs","$Env:_tmp","$Env:logs" | ForEach-Object {
  if (!( Test-Path "$_" )) { New-Item -ItemType Directory -Path "$_" -Verbose -ErrorAction SilentlyContinue }
}

#--------------------------------------------------------------------
Write-Host "$basename - Make some Files"
#--------------------------------------------------------------------

"~\Documents\PSConfiguration\Microsoft.PowerShell_profile.ps1" | ForEach-Object {
	#New-Item -Path "~\Documents\PSConfiguration\Microsoft.PowerShell_profile.ps1" -ItemType File -ErrorAction SilentlyContinue | Out-Null
  if (!( Test-Path "$_" )) { New-Item -ItemType File -Path "$_" -Verbose -ErrorAction SilentlyContinue }
}

#--------------------------------------------------------------------
Write-Host "$basename - Get some basic tools"
#--------------------------------------------------------------------

$WebClient = New-Object System.Net.WebClient
#Import-Module BitsTransfer
#Start-Bitstransfer -Source "http://lockerlife.hk/deploy/bin/curl.exe" -Destination "c:\local\bin\curl.exe"
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/bin/curl.exe","c:\local\bin\curl.exe")
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/bin/Bginfo.exe","c:\local\bin\Bginfo.exe")

#& "$env:curl" --progress-bar -Ss -k --url "https://live.sysinternals.com/Autologon.exe" -o "$Env:local\bin\Autologon.exe"
$WebClient.DownloadFile("$env:deployurl/bin/Autologon.exe","$local\bin\Autologon.exe")
#$WebClient.DownloadFile("$Env:deployurl/bin/Bginfo.exe","$Env:local\bin\Bginfo.exe")
#& "$Env:curl" --progress-bar -Ss -k -o "$Env:local\bin\devcon.exe" --url "$Env:deployurl/bin/devcon.exe"
$WebClient.DownloadFile("$env:deployurl/bin/devcon.exe","$local\bin\devcon.exe")
& "$env:curl" --progress-bar -Ss -k -o "$env:local\bin\hstart.exe" --url "$env:deployurl/bin/hstart.exe"
& "$env:curl" --progress-bar -Ss -k -o "$local\bin\nircmd.exe" --url "$env:deployurl/bin/nircmd.exe"
& "$env:curl" --progress-bar -Ss -k -o "$local\bin\nircmdc.exe" --url "$env:deployurl/bin/nircmdc.exe"
$WebClient.DownloadFile("$env:deployurl/bin/nssm.exe","$local\bin\nssm.exe")
#& "$env:curl" --progress-bar -Ss -k -o "$Env:local\bin\sendEmail.exe" --url "$Env:deployurl/bin/sendEmail.exe"
$WebClient.DownloadFile("$env:deployurl/bin/sendEmail.exe","$env:local\bin\sendEmail.exe")
$WebClient.DownloadFile("$env:deployurl/bin/UPnPScan.exe","$env:local\bin\UPnPScan.exe")
& "$env:curl" --progress-bar -Ss -k -o "$env:local\bin\xml.exe" --url "$env:deployurl/bin/xml.exe"
& "$env:curl" --progress-bar -Ss -k -o "$env:local\bin\du.exe" --url "$env:deployurl/bin/du.exe"
& "$env:curl" --progress-bar -Ss -k -o "$env:local\bin\LGPO.exe" --url "$env:deployurl/bin/LGPO.exe"
& "$env:curl" --progress-bar -Ss -k -o "$env:local\bin\psexec.exe" --url "$env:deployurl/bin/psexec.exe"
& "$env:curl" --progress-bar -Ss -k -o "$env:local\bin\BootUpdCmd20.exe" --url "$env:deployurl/bin/BootUpdCmd20.exe"


#--------------------------------------------------------------------
Write-Host "$basename - Manage System User Accounts (no lockerlife accounts)"
#--------------------------------------------------------------------

Write-Host "$basename -- Enable Administrator"
net user Administrator /active:yes
#net user administrator /active:no

$U = gwmi -class Win32_UserAccount | Where { $_.Name -eq "AAICON" }
if ($U) {
	WriteInfo "$basename -- AAICON exists"
	WriteInfoHighlighted "$basename -- force Update AAICON Password ..."
	net user AAICON Locision123
}
else
{
	Write-Host "$basename -- fixing AAICON account ..."
	#Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user AAICON Locision123' -NoNewWindow
	#& "c:\local\bin\autologon.exe" AAICON Locision123
	#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
	#"AutoAdminLogon"="1"
	#"DefaultUserName"="admnistrator"
	#"DefaultPassword"="P@$$w0rd"
	#"DefaultDomainName"="contoso"
	#Start-ChocolateyProcessAsAdmin -statements $args -exeToRun $vcdmount
	net user AAICON Locision123 /add /expires:never /passwordchg:no
	net user AAICON Locision123
}


#--------------------------------------------------------------------
Write-Host "$basename - Cleanup"
#--------------------------------------------------------------------

CleanupDesktop
Create-DeploymentLinks
Update-Help -Verbose -ErrorAction SilentlyContinue

# Internet Explorer: Temp Internet Files:
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

# touch $Env:local\status\00-init.done file
New-Item -Path "$local\status\$basename.done" -ItemType File -Verbose -ErrorAction SilentlyContinue | Out-Null

& "$env:curl" --progress-bar -Ss -k --url "https://api.github.com/zen"
Write-Host "."

Write-Host "$basename -- done"
Write-Host "$basename - Next stage ..."
& "$env:ProgramFiles\Internet Explorer\iexplore.exe" "http://boxstarter.org/package/url?http://lockerlife.hk/deploy/00-bootstrap.ps1"
