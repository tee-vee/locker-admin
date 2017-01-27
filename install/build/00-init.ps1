# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-init - make directories, setup system-only user accounts (no LockerLife customizations)
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 00-init"
#$basename = $MyInvocation.MyCommand.Name



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

$basename = "00-init"

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


#--------------------------------------------------------------------
Write-Host "$basename - System eligibility check"
#--------------------------------------------------------------------

# Checking for Compatible OS
Write-Host "Checking if OS is Windows 7"

$BuildNumber = Get-WindowsBuildNumber
if ($BuildNumber -le 7601)
{
    # Windows 7 RTM=7600, SP1=7601
    WriteSuccess "`t PASS: OS is Windows 7 (RTM 7600/SP1 7601)"
    } else {
    WriteErrorAndExit "`t FAIL: Windows version $BuildNumber detected and is not supported. Exiting"
}


#--------------------------------------------------------------------
Write-Host "$basename - General Windows Configuration"
#--------------------------------------------------------------------

#power plan type (0=power saver, 1=high performance, 2=balanced)
#powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c fea3413e-7e05-4911-9a71-700331f1c294 245d8541-3943-4422-b025-13a784f679b7 1
#powercfg -setdcvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c fea3413e-7e05-4911-9a71-700331f1c294 245d8541-3943-4422-b025-13a784f679b7 1

# sets the power configuration to High Performance -- does this really work?
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# turns hibernation off
powercfg -hibernate OFF

#monitor timeout
#powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
#powercfg -setdcvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0

#multimedia settings (0=take no action, 1=prevent computer from sleeping, 2=enable away mode)
#powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 2
#powercfg -setdcvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 2

Write-Host "$basename -- set region"
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sLanguage -Value ENU
Set-ItemProperty -Path "HKCU:\Control Panel\International\Geo" -Name Nation -Value 104


Write-Host "$basename -- Configure Windows Time Services"
Stop-Service w32time -Confirm:$False                                                		# stop windows time service
& "$Env:SystemRoot\System32\tzutil.exe" /s "China Standard Time"                    		# set timezone
& "$Env:SystemRoot\System32\w32tm.exe" /config /syncfromflags:manual /manualpeerlist:"stdtime.gov.hk 0.asia.pool.ntp.org 3.asia.pool.ntp.org"    # set time

Start-Service w32time -Confirm:$False                                               		# start windows time service
Breathe

# turn off startup sounds
##;Turn Off System Beeps
#reg add "[HKEY_CURRENT_USER\Control Panel\Sound]" “Beep”=No
#net stop beep
#sc stop beep
#sc config beep start= demand
REG ADD "HKLM\System\CurrentControlSet\Services\Beep" /v start /t REG_DWORD /d 4 /f

# Disable Welcome logon screen & require CTRL+ALT+DEL
REG ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v LogonType /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD /t REG_DWORD /d 0 /f


# Interactive logon: Do not display last user name
REG ADD "hklm\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v dontdisplaylastusername /t REG_DWORD /d 1 /f

# Enable Remote Desktop for locker deployment
REG ADD "HKLM\System\Currentcontrolset\control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
# Allow connections from computers running any version of Remote Desktop (less secure)
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f

#Set the Screen Saver Settings
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 1 /f
#reg add "hku\.DEFAULT\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 1 /f
#reg add "hku\.DEFAULT\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d 900 /f
#reg add "hku\.DEFAULT\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d “%SystemRoot%\System32\YOUR_FILE.scr” /f


#Set the Desktop Wallpaper
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "%SystemRoot%\Web\Wallpaper\YOUR_FILE.bmp" /f
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d “2” /f
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d “0” /f

# enable custom logon background
#HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background

#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation] "DisableStartupSound"=dword:00000001
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v DisableStartupSound /t REG_DWORD /d 1 /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupSound /t REG_DWORD /d 1 /f
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" "DisableStartupSound" 1 -Verbose
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1 -Verbose

# Windows Explorer Settings through Choco
Set-WindowsExplorerOptions -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom


# make Windows faster ...
##  ;Disable Menu Delay
##  [HKEY_CURRENT_USER\Control Panel\Desktop]
##  “MenuShowDelay”=”0”

#;Increase NTFS System Peformance by disabling NTFS Last Access Update and 8.3 Creation
#[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem]
#“NTFSDisableLastAccessUpdate”=1
#“NTFSDisable8Dot3NameCreation”=1


## Windows Firewall
WriteInfoHighlighted "$basename -- Configure Windows Firewall"
#& "$Env:SystemRoot\System32\netsh.exe" advfirewall show allprofiles
#& "$Env:SystemRoot\System32\netsh.exe" advfirewall set allrprofiles state on

## QUERY FIREWALL RULES
#& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall show rule name=all

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

# Disable hibernate
Start-Process 'powercfg.exe' -Verb runAs -ArgumentList '/h off'

# hide boot
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set bootux disabled'

# disable booting into recovery mode
# undo: bcdedit /deletevalue {current} bootstatuspolicy
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set {default} recoveryenabled No'
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set {default} bootstatuspolicy ignoreallfailures'


#--------------------------------------------------------------------
Write-Host "$basename - Make some directories"
#--------------------------------------------------------------------

# important directories - create directories as early as possible ...
"$Env:local\status","$Env:local\src","$Env:local\gpo","$Env:local\etc","$Env:local\drivers","$Env:local\bin","$Env:imagesarchive","$Env:images","~\Documents\WindowsPowerShell","~\Desktop\LockerDeployment","~\Documents\PSConfiguration","D:\locker-libs","$Env:_tmp","$Env:logs" | ForEach-Object {
  if (!( Test-Path "$_" )) { write-host $_ ; New-Item -ItemType Directory -Path "$_" }
}
#New-Item -Path "~\Documents\WindowsPowerShell" -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path "~\Desktop\LockerDeployment" -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path "~\Documents\PSConfiguration" -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path "D:\locker-libs" -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path  -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path  -ItemType Directory -Force -ErrorAction SilentlyContinue
# $a = New-Item -ItemType Directory "$env:USERPROFILE\Desktop\Unattended Builds" -Force -ErrorAction SilentlyContinue


#--------------------------------------------------------------------
Write-Host "$basename - Make some Files"
#--------------------------------------------------------------------

"~\Documents\PSConfiguration\Microsoft.PowerShell_profile.ps1" | ForEach-Object {
	#New-Item -Path "~\Documents\PSConfiguration\Microsoft.PowerShell_profile.ps1" -ItemType File -ErrorAction SilentlyContinue | Out-Null
  if (!( Test-Path "$_" )) { New-Item -ItemType File -Path "$_" }
}


#--------------------------------------------------------------------
Write-Host "$basename - Get some basic tools"
#--------------------------------------------------------------------

$WebClient = New-Object System.Net.WebClient
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/bin/curl.exe","c:\local\bin\curl.exe")
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/bin/Bginfo.exe","c:\local\bin\Bginfo.exe")

#$WebClient.DownloadFile("$Env:deployurl/bin/curl.exe","$Env:local\bin\curl.exe")

#& "$Env:curl" -Ss -k --url "https://live.sysinternals.com/Autologon.exe" -o "$Env:local\bin\Autologon.exe"
$WebClient.DownloadFile("$Env:deployurl/bin/Autologon.exe","$Env:local\bin\Autologon.exe")
#$WebClient.DownloadFile("$Env:deployurl/bin/Bginfo.exe","$Env:local\bin\Bginfo.exe")
#& "$Env:curl" -Ss -k -o "$Env:local\bin\devcon.exe" --url "$Env:deployurl/bin/devcon.exe"
$WebClient.DownloadFile("$Env:deployurl/bin/devcon.exe","$Env:local\bin\devcon.exe")
& "$Env:curl" -Ss -k -o "$Env:local\bin\hstart.exe" --url "$Env:deployurl/bin/hstart.exe"
& "$Env:curl" -k -Ss -o "$Env:local\bin\nircmd.exe "--url "$Env:deployurl/bin/nircmd.exe"
& "$Env:curl" -k -Ss -o "$Env:local\bin\nircmdc.exe "--url "$Env:deployurl/bin/nircmdc.exe"
$WebClient.DownloadFile("$Env:deployurl/bin/nssm.exe","$Env:local\bin\nssm.exe")
#& "$Env:curl" -Ss -k -o "$Env:local\bin\sendEmail.exe" --url "$Env:deployurl/bin/sendEmail.exe"
$WebClient.DownloadFile("$Env:deployurl/bin/sendEmail.exe","$Env:local\bin\sendEmail.exe")
#& "$Env:curl" -Ss -k --url "$Env:deployurl/bin/UPnPScan.exe" -o "$Env:local\bin\UPnPScan.exe"
$WebClient.DownloadFile("$Env:deployurl/bin/UPnPScan.exe","$Env:local\bin\UPnPScan.exe")
& "$Env:curl" -k -Ss -o "$Env:local\bin\xml.exe" --url "$Env:deployurl/bin/xml.exe"

& "$Env:curl" -Ss -k -o "$Env:local\bin\du.exe" --url "$Env:deployurl/bin/du.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\LGPO.exe" --url "$Env:deployurl/bin/LGPO.exe"
& "$Env:curl" -Ss -k -o "$Env:local\bin\psexec.exe" --url "$Env:deployurl/bin/psexec.exe"
& "$Env:curl" -k -Ss -o "$Env:local\bin\BootUpdCmd20.exe" --url "$Env:deployurl/bin/BootUpdCmd20.exe"

# Configuration
$files = @{
	# Curl for command line web downloads (x86)
	curl			= 'http://curl.haxx.se/gknw.net/win32/curl-7.24.0-ssl-sspi-zlib-static-bin-w32.zip'

	# MsysGit (x86)
	git				= 'http://msysgit.googlecode.com/files/Git-1.7.9-preview20120201.exe'

	# KDiff3 (x86)
	kdiff3		= 'http://sourceforge.net/projects/kdiff3/files/latest/download?source=files'

	# 7-zip (x64)
	sevenZip	= 'http://downloads.sourceforge.net/sevenzip/7z920-x64.msi'

	# Vim for Windows (works x86 and x64)
	gvim				= 'http://ftp.vim.org/pub/vim/pc/gvim73_46.exe'

	# msvcredist_x64 - required by HardLinkShellExt_x64
	linkshellreq = 'http://download.microsoft.com/download/6/B/B/6BB661D6-A8AE-4819-B79F-236472F6070C/vcredist_x64.exe'

	# HardLinkShellExt_x64 - Shows hard links and junctions in Windows Explorer
	linkshell = 'http://schinagl.priv.at/nt/hardlinkshellext/HardLinkShellExt_X64.exe'
}
$downloadDir = "C:\temp"

#--------------------------------------------------------------------
Write-Host "$basename - Get installers"
#--------------------------------------------------------------------

#$WebClient.DownloadFile("http://lockerlife.hk/deploy/_pkg/QuickSet-2.07-bulid0805.msi","C:\temp\QuickSet-2.07-bulid0805.msi")


#--------------------------------------------------------------------
Write-Host "$basename - Manage System User Accounts"
#--------------------------------------------------------------------

Write-Host "$basename -- Enable Administrator"
# & "$env:SystemRoot\System32\net.exe" user administrator /active:yes
net user Administrator /active:yes
## net user administrator /active:no (later!)

$U = gwmi -class Win32_UserAccount | Where { $_.Name -eq "AAICON" }
if ($U) {
	WriteInfo "$basename -- AAICON exists"
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

	net user AAICON "Locision123" /add /expires:never /passwordchg:no
	net user AAICON Locision123
}


#Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUserName -Value "AAICON"
#Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "Locision123"
#Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1
#Set-ItemProperty -Path 'registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name ForceAutoLogon -Value 0


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
New-Item -Path "$Env:local\status\$basename.done" -ItemType File -ErrorAction SilentlyContinue | Out-Null

& "$Env:curl" -Ss -k https://api.github.com/zen ; Write-Host ""
Write-Host "$basename -- done"


#--------------------------------------------------------------------
Write-Host "$basename - Next stage ... "
#--------------------------------------------------------------------
#& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f
Stop-Process -Name iexplore -ErrorAction SilentlyContinue
& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/00-bootstrap.ps1"
