# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 02-bootstrap
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 02-bootstrap"
$basename = $MyInvocation.MyCommand.Name



#--------------------------------------------------------------------
# Lets start
#--------------------------------------------------------------------

# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
	exit
}

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp ...
$WebClient = New-Object System.Net.WebClient
(New-Object Net.WebClient).DownloadString("$Env:deployurl/99-DeploymentConfig.ps1") > "$Env:temp\99-DeploymentConfig.ps1"
. "$Env:temp\99-DeploymentConfig.ps1"

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted


#Set-Location -Path C:\temp
#Get-ChocolateyWebFile -PackageName "Windows6.1-KB2889748-x86.msu" -FileFullPath "C:\local\Windows6.1-KB2889748-x86.msu"
#& curl --Url "https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu" -o c:\temp\Windows6.1-KB2889748-x86.msu
#& C:\Windows\System32\wusa.exe c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcerestart
#Install-ChocolateyPackage 'Windows6.1-KB2889748-x86' 'msu' '/quiet /forcerestart' 'https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu'
#Install-ChocolateyPackage 'Windows6.1-KB2889748-x86' 'msu' '/quiet /forcerestart' "C:\temp\Windows6.1-KB2889748-x86.msu" 'https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu'

if (Test-PendingReboot) { Invoke-Reboot }

# temporarily restart windows update services to install updates ...
Set-Service wuauserv -StartupType Mnaual -Verbose
Start-Service wuauserv -Verbose
#Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre REBOOT=DISABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE NOSTARTMENU=ENABLE WEB_JAVA=DISABLE EULA=Disable REMOVEOUTOFDATEJRES=1" 'http://lockerlife.hk/deploy/_pkg/jre-8u111-windows-i586.exe'
# Install-ChocolateyPath '%JAVA_HOME%\bin' Machine

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
Write-Host ""


#--------------------------------------------------------------------
Write-Host "$basename - Next stage ... "
#--------------------------------------------------------------------
& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f
& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff "http://boxstarter.org/package/url?$Env:deployurl/10-configure.ps1"
