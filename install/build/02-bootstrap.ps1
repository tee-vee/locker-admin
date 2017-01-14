# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 02-bootstrap

# Allow unattended reboots
$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true

#Install-ChocolateyEnvironmentVariable 'JAVA_HOME' 'path\to\jre' 'Machine'
Install-ChocolateyEnvironmentVariable "baseurl" "http://lockerlife.hk/deploy"
Install-ChocolateyEnvironmentVariable -variableName "JAVA_HOME" -variableValue "d:\java\jdk\bin" -variableType "Machine"
Install-ChocolateyEnvironmentVariable "local" "C:\local"

# Windows Explorer Settings
Set-WindowsExplorerOptions -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess

# Small taskbar
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom

#Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

#chocolatey feature enable -n=allowGlobalConfirmation

cinst chocolatey-core.extension
cinst git.install -params '"/WindowsTerminal /GitOnlyOnPath /NoAutoCrlf"'

cinst powershell -version 3.0.20121027
if (Test-PendingReboot) { Invoke-Reboot }

cinst powershell4
if (Test-PendingReboot) { Invoke-Reboot }

cinst microsoftsecurityessentials -version 4.5.0216.0
if (Test-PendingReboot) { Invoke-Reboot }

choco install teamviewer.host --version 12.0.72365
choco install vim
choco install jq
choco install clink
choco install putty
choco install rsync
choco install wget
choco install nssm
choco install teraterm

cinst TelnetClient -source windowsfeatures
if (Test-PendingReboot) { Invoke-Reboot }


# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Start-Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Skipping 10 lines because if running when all prereqs met, statusbar covers powershell output
1..10 |% { Write-Host ""}

Set-Location -Path C:\temp
#Get-ChocolateyWebFile -PackageName "Windows6.1-KB2889748-x86.msu" -FileFullPath "C:\local\Windows6.1-KB2889748-x86.msu" 
#& curl --Url "https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu" -o c:\temp\Windows6.1-KB2889748-x86.msu
#& C:\Windows\System32\wusa.exe c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcerestart
Install-ChocolateyPackage 'Windows6.1-KB2889748-x86' 'msu' '/quiet /forcerestart' 'https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu'
#Install-ChocolateyPackage 'Windows6.1-KB2889748-x86' 'msu' '/quiet /forcerestart' "C:\temp\Windows6.1-KB2889748-x86.msu" 'https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu'

if (Test-PendingReboot) { Invoke-Reboot }

# get local stuff
Get-ChocolateyWebFile -Url https://github.com/lockerlife-kiosk/deployment/raw/master/xmlstarlet-1.6.1-win32.zip -fileFullPath "C:\local\src\xmlstarlet-1.6.1-win32.zip"
Get-ChocolateyWebFile -Url https://github.com/lockerlife-kiosk/deployment/raw/master/nircmd.zip -fileFullPath "C:\local\src\nircmd.zip"
Install-ChocolateyZipPackage -PackageName 'nircmd' -Url 'https://github.com/lockerlife-kiosk/deployment/raw/master/xmlstarlet-1.6.1-win32.zip' -UnzipLocation "C:\local\bin"


# cleanup
# mkdir C:\local\status
New-Item -Path C:\temp -ItemType directory -Force
New-Item -Path C:\local -ItemType directory -Force
New-Item -Path C:\local\bin -ItemType directory -Force
New-Item -Path C:\local\etc -ItemType directory -Force

# & curl --url "http://$Env:baseurl/_pkg/jre-install.properties" -o "C:\local\etc\jre-install.properties"

# temporarily restart windows update services to install updates ...
Set-Service wuauserv -StartupType Mnaual
Start-Service wuauserv -Verbose
Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre REBOOT=DISABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE NOSTARTMENU=ENABLE WEB_JAVA=DISABLE EULA=Disable REMOVEOUTOFDATEJRES=1" 'http://lockerlife.hk/deploy/_pkg/jre-8u111-windows-i586.exe'
# Install-ChocolateyPath '%JAVA_HOME%\bin' Machine

Remove-Item -Force "$env:UserProfile\Desktop\*.lnk"

& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?http://lockerlife.hk/deploy/20-setup.ps1

