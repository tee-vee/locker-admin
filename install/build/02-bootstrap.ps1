# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 02-bootstrap


#$path = Get-Location
$basename = $MyInvocation.MyCommand.Name


# Allow unattended reboots
$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true

#Set-Location -Path C:\temp
#Get-ChocolateyWebFile -PackageName "Windows6.1-KB2889748-x86.msu" -FileFullPath "C:\local\Windows6.1-KB2889748-x86.msu"
#& curl --Url "https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu" -o c:\temp\Windows6.1-KB2889748-x86.msu
#& C:\Windows\System32\wusa.exe c:\temp\Windows6.1-KB2889748-x86.msu /quiet /forcerestart
#Install-ChocolateyPackage 'Windows6.1-KB2889748-x86' 'msu' '/quiet /forcerestart' 'https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu'
#Install-ChocolateyPackage 'Windows6.1-KB2889748-x86' 'msu' '/quiet /forcerestart' "C:\temp\Windows6.1-KB2889748-x86.msu" 'https://github.com/lockerlife-kiosk/deployment/raw/master/Windows6.1-KB2889748-x86.msu'

if (Test-PendingReboot) { Invoke-Reboot }

# get local stuff
#Get-ChocolateyWebFile -Url https://github.com/lockerlife-kiosk/deployment/raw/master/xmlstarlet-1.6.1-win32.zip -fileFullPath "C:\local\src\xmlstarlet-1.6.1-win32.zip"
#Get-ChocolateyWebFile -Url https://github.com/lockerlife-kiosk/deployment/raw/master/nircmd.zip -fileFullPath "C:\local\src\nircmd.zip"
#Install-ChocolateyZipPackage -PackageName 'nircmd' -Url 'https://github.com/lockerlife-kiosk/deployment/raw/master/xmlstarlet-1.6.1-win32.zip' -UnzipLocation "C:\local\bin"


# cleanup

# & curl --url "http://$Env:baseurl/_pkg/jre-install.properties" -o "C:\local\etc\jre-install.properties"

# temporarily restart windows update services to install updates ...
Set-Service wuauserv -StartupType Mnaual
Start-Service wuauserv -Verbose
#Install-ChocolateyPackage 'jre8' 'exe' "/s INSTALLDIR=D:\java\jre REBOOT=DISABLE SPONSORS=ENABLE AUTO_UPDATE=DISABLE NOSTARTMENU=ENABLE WEB_JAVA=DISABLE EULA=Disable REMOVEOUTOFDATEJRES=1" 'http://lockerlife.hk/deploy/_pkg/jre-8u111-windows-i586.exe'
# Install-ChocolateyPath '%JAVA_HOME%\bin' Machine

#Remove-Item -Force "$env:UserProfile\Desktop\*.lnk"

& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?http://lockerlife.hk/deploy/10-configure.ps1
