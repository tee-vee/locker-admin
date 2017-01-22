# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 99-DeploymentConfig

# make an entrance ...
1..5 | % { Write-Host }
Write-Host "99-DeploymentConfig - in" -ForegroundColor Green
Write-Host


# Allow unattended reboots
$Boxstarter.RebootOk=$true
$Boxstarter.NoPassword=$false
$Boxstarter.AutoLogin=$true

$pshost = Get-Host
$pswindow = $pshost.ui.rawui
$newsize = $pswindow.buffersize
$newsize.height = 5500

# reminder: you can’t have a screen width that’s bigger than the buffer size.
# Therefore, before we can increase our window size we need to increase the buffer size
# powershell screen width and the buffer size are set to 150.
$newsize.width = 170
$pswindow.buffersize = $newsize
#$pswindow.windowtitle = "LockerLife Locker Deployment 99-DeploymentConfig"

# the nul ensures window size does not chnage
#& cmd /c mode con: cols=150  >nul 2>nul



#####################
# Default variables #
#####################

$Env:Path += ";C:\local\bin;C:\$Env:ProgramFiles\GnuWin32\bin"

# Fix SSH-Agent error by adding the bin directory to the `Path` environment variable
$env:PSModulePath = $env:PSModulePath + ";${Env:ProgramFiles(x86)}\Git\bin"

#$userName = $env:UserName
#$userDomain = $env:UserDomain

Install-ChocolateyEnvironmentVariable "baseurl" "http://lockerlife.hk"
Install-ChocolateyEnvironmentVariable "deployurl" "$Env:baseurl/deploy"
Install-ChocolateyEnvironmentVariable "domainname" "lockerlife.hk"

Install-ChocolateyEnvironmentVariable "iccid" "NULL"
Install-ChocolateyEnvironmentVariable "locker-type" "NULL"
Install-ChocolateyEnvironmentVariable "lockerserialnumber" "NULL"
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


#--------------------------------------------------------------------
# Functions
#--------------------------------------------------------------------
function Reboot-IfRequired() {
  if(Test-PendingReboot) {
    Write-Host "Test-PendingReboot shows a reboot is required. Rebooting now"
		Invoke-Reboot
	}
	else {
		Write-Host "No reboot is required. installation continuing"
	}
}

function WriteInfo($message)
{
  Write-Host $message
}

function WriteInfoHighlighted($message)
{
  Write-Host $message -ForegroundColor Cyan
}

function WriteSuccess($message) {
  Write-Host $message -ForegroundColor Green
}

function WriteError($message) {
  Write-Host $message -ForegroundColor Red
 }

function WriteErrorAndExit($message) {
  Write-Host $message -ForegroundColor Red
  Write-Host "Press any key to continue ..."
  $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
  $HOST.UI.RawUI.Flushinputbuffer()
  Exit
}

function Get-WindowsBuildNumber {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return [int]($os.BuildNumber)
}

function Create-DeploymentLinks {
  Write-Host "Create-DeploymentLinks"
  # create shortcut to deployment - 00-bootstrap
  Install-ChocolateyShortcut -ShortcutFilePath "$Env:Public\Desktop\LockerDeployment\DeploymentHomepage.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "$Env:deployurl" -Description "LockerLife Deployment Start"
  Install-ChocolateyShortcut -ShortcutFilePath "$Env:Public\Desktop\LockerDeployment\Restart-00.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/00-bootstrap.ps1" -Description "Redeploy Locker"
}

# cleanup desktop
function CleanupDesktop {
  if (Test-Path "$Env:UserProfile\Desktop\*.lnk") {
    Write-Host "$basename cleaning up desktop"
    Remove-Item "$Env:UserProfile\Desktop\*.lnk" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\99-DeploymentConfig.ps1" -Force -ErrorAction SilentlyContinue
    Remove-Item "$Env:Public\Desktop\*.lnk" -Force -ErrorAction SilentlyContinue
  }
}

# Make an exit ....
1..5 | % { Write-Host }

Write-Host "99-DeploymentConfig - out" -ForegroundColor Green
Write-Host
