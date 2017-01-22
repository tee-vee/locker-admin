# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-init - handle user account, help manage system/environment variables, make a stable environment for next part;
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 00-init"
$basename = $MyInvocation.MyCommand.Name


# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}

# Allow unattended reboots
$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true

# get and source DeploymentConfig
$WebClient = New-Object System.Net.WebClient
(New-Object Net.WebClient).DownloadString("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1") > C:\local\etc\99-DeploymentConfig.ps1
. C:\local\etc\99-DeploymentConfig.ps1

#--------------------------------------------------------------------
# Lets start
#--------------------------------------------------------------------

# Start Time and Transcript
Start-Transcript -Path "$PSScriptRoot\Prereq.log"
$StartDateTime = get-date
Write-Host "`t Script started at $StartDateTime" -ForegroundColor Green


# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

# set window title
$pshost = Get-Host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 5500

# reminder: you can’t have a screen width that’s bigger than the buffer size.
# Therefore, before we can increase our window size we need to increase the buffer size
# powershell screen width and the buffer size are set to 150.
$newsize.width = 170
$pswindow.buffersize = $newsize

# the nul ensures window size does not chnage
#& cmd /c mode con: cols=150  >nul 2>nul


#--------------------------------------------------------------------
# Default variables
#--------------------------------------------------------------------
Install-ChocolateyEnvironmentVariable "baseurl" "http://lockerlife.hk"
Install-ChocolateyEnvironmentVariable "deployurl" "$Env:baseurl/deploy"
Install-ChocolateyEnvironmentVariable "domainname" "lockerlife.hk"

Install-ChocolateyEnvironmentVariable "iccid" "NULL"
Install-ChocolateyEnvironmentVariable "locker-type" "NULL"
Install-ChocolateyEnvironmentVariable "locker-sn" "NULL"
Install-ChocolateyEnvironmentVariable "hostname" "NULL"                         # $hostname == $sitename
Install-ChocolateyEnvironmentVariable "sitename" "NULL"                         # $hostname == $sitename

#Install-ChocolateyEnvironmentVariable 'JAVA_HOME' 'path\to\jre' 'Machine'
#Install-ChocolateyEnvironmentVariable -variableName "JAVA_HOME" -variableValue "D:\java\jre\bin" -variableType "Machine"
Install-ChocolateyEnvironmentVariable "JAVA_HOME" "d:\java\jre\bin"
Install-ChocolateyEnvironmentVariable "local" "C:\local"
Install-ChocolateyEnvironmentVariable "_tmp" "C:\temp"
Install-ChocolateyEnvironmentVariable "_temp" "C:\temp"                         # just in case
Install-ChocolateyEnvironmentVariable "logs" "E:\logs"
Install-ChocolateyEnvironmentVariable "images" "E:\images"
Install-ChocolateyEnvironmentVariable "imagesarchive" "E:\images\archive"

Install-ChocolateyEnvironmentVariable "curl" "$Env:ProgramFiles\Gow\bin\curl.exe"
Install-ChocolateyEnvironmentVariable "rm" "$Env:ProgramFiles\Gow\bin\rm.exe"


Disable-UAC

# important directories - create directories as early as possible ...
"$Env:local\status","$Env:local\src","$Env:local\gpo","$Env:local\etc","$Env:local\drivers","$Env:local\bin","$Env:imagesarchive","$Env:images","~\Documents\WindowsPowerShell","~\Desktop\LockerDeployment","~\Documents\PSConfiguration","D:\locker-libs","$Env:_tmp","$Env:logs" | ForEach-Object {
  if (!( Test-Path "$_" )) { New-Item -Type Directory -Path "$_" }
}
#New-Item -Path "~\Documents\WindowsPowerShell" -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path "~\Desktop\LockerDeployment" -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path "~\Documents\PSConfiguration" -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path "D:\locker-libs" -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path  -ItemType Directory -Force -ErrorAction SilentlyContinue
#New-Item -Path  -ItemType Directory -Force -ErrorAction SilentlyContinue
# $a = New-Item -ItemType Directory "$env:USERPROFILE\Desktop\Unattended Builds" -Force -ErrorAction SilentlyContinue


$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/curl.exe","C:\local\bin\curl.exe")
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/Autologon.exe","C:\local\bin\Autologon.exe")
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/Bginfo.exe","C:\local\bin\Bginfo.exe")
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/nssm.exe","C:\local\bin\nssm.exe")
#$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/nssm.exe","C:\local\bin\nssm.exe")
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/sendEmail.exe","C:\local\bin\sendEmail.exe")

#iexplore http://lockerlife.hk/deploy/bin/curl.exe

Write-Host "set password for aaicon account"
Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user AAICON Locision123' -NoNewWindow

Write-Host "load autologon"
#& "c:\local\bin\autologon.exe" AAICON Locision123
#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
#"AutoAdminLogon"="1"
#"DefaultUserName"="admnistrator"
#"DefaultPassword"="P@$$w0rd"
#"DefaultDomainName"="contoso"

# Cleanup Desktop
CleanupDesktop


# Internet Explorer: Temp Internet Files:
& RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/00-bootstrap.ps1"
