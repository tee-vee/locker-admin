# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

$basename = $MyInvocation.MyCommand.Name

# Allow unattended reboots
$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true


# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted


$pshost = Get-Host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 5500

# reminder: you can’t have a screen width that’s bigger than the buffer size.
# Therefore, before we can increase our window size we need to increase the buffer size
# powershell screen width and the buffer size are set to 150.
$newsize.width = 175
$pswindow.buffersize = $newsize
$pswindow.windowtitle = "LockerLife Locker Deployment 00-init"

# the nul ensures window size does not chnage
#& cmd /c mode con: cols=150  >nul 2>nul


#####################
# Default variables #
#####################

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



### ----- reload current shell elevated to administrator -> prepare for 01-bootstrap -> exec 01-bootstrap ----- ###
# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
  Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
  Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
  Write-Host
  exit
}

Disable-UAC

# important directories
New-Item -Path "~\Documents\WindowsPowerShell" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "~\Desktop\LockerDeployment" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "~\Documents\PSConfiguration" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "D:\locker-libs" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:_tmp" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:logs" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:images" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:imagesarchive" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:local\bin" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:local\drivers" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:local\etc" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:local\gpo" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:local\src" -ItemType Directory -Force -ErrorAction SilentlyContinue
New-Item -Path "$Env:local\status" -ItemType Directory -Force -ErrorAction SilentlyContinue
# $a = New-Item -ItemType Directory "$env:USERPROFILE\Desktop\Unattended Builds" -Force -ErrorAction SilentlyContinue


$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/curl.exe","C:\local\bin\curl.exe")
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/Autologon.exe","C:\local\bin\Autologon.exe")
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/Bginfo.exe","C:\local\bin\Bginfo.exe")
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/nssm.exe","C:\local\bin\nssm.exe")
$WebClient.DownloadFile("http://lockerlife.hk/deploy/bin/nssm.exe","C:\local\bin\nssm.exe")
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


# create shortcut to deployment - 00-bootstrap
Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\LockerDeployment\DeploymentHomepage.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "$Env:deployurl" -Description "LockerLife Deployment Start"
Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\LockerDeployment\Restart-00.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/00-bootstrap.ps1" -Description "Redeploy Locker"

# Internet Explorer: Temp Internet Files:
& RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/00-bootstrap.ps1"
