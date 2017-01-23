# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 99-DeploymentConfig - setup variables, functions
#$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 00-init"
#$basename = $MyInvocation.MyCommand.Name


$basename = "99-DeploymentConfig"
#--------------------------------------------------------------------
Write-Host "$basename - Lets start"
#--------------------------------------------------------------------

# make an entrance ...
1..5 | % { Write-Host }

Write-Host "99-DeploymentConfig - in" -ForegroundColor Green


#--------------------------------------------------------------------
Write-Host "$basename - Setting variables"
#--------------------------------------------------------------------

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
$newsize.width = 160
$pswindow.buffersize = $newsize
#$pswindow.windowtitle = "LockerLife Locker Deployment 99-DeploymentConfig"

# the nul ensures window size does not chnage
#& cmd /c mode con: cols=150  >nul 2>nul


Write-Host "99-DeploymentConfig -- Setup variables ..."
$Env:Path += ";C:\local\bin;C:\$Env:ProgramFiles\GnuWin32\bin"

# Fix SSH-Agent error by adding the bin directory to the `Path` environment variable
$env:PSModulePath = $env:PSModulePath + ";${Env:ProgramFiles(x86)}\Git\bin"

$WebClient = New-Object System.Net.WebClient

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

Breathe


#--------------------------------------------------------------------
Write-Host "$basename - Aliases"
#--------------------------------------------------------------------
Set-Alias iexplore 'C:\Program Files\Internet Explorer\iexplore.exe'


#--------------------------------------------------------------------
Write-Host "$basename - Functions"
#--------------------------------------------------------------------
function Test-IsAdministrator
{
    <#
    .Synopsis
        Tests if the user is an administrator
    .Description
        Returns true if a user is an administrator, false if the user is not an administrator
    .Example
        Test-IsAdministrator
    #>
    param()
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
} #end function Test-IsAdministrator

function OkToDeploy
{
  # If (C:\DEPLOYMENT-UNAUTHORIZED) {
  #   WriteError "Deployment Unauthorized"
  #   WriteError "Contact email: locker-admin@lockerlife.hk
  #   WriteErrorAndExit "Exiting ..."
  #}

}

function Reboot-IfRequired()
{
  if(Test-PendingReboot)
  {
    Write-Host "$basename -- Test-PendingReboot -- Reboot is required. Rebooting now"
		Invoke-Reboot
	}
	else
  {
		Write-Host "$basename -- No reboot is required. Continuing ..."
	}
} #end function Reboot-IfRequired

function Breathe
{
  # Let libs/modules load ...
  1..5 | % { Write-Host " -- "}
}

function WriteInfo($message)
{
  Write-Host $message
}  #end function WriteInfo

function WriteInfoHighlighted($message)
{
  Write-Host $message -ForegroundColor Cyan
}  #end function WriteInfoHighlighted

function WriteSuccess($message)
{
  Write-Host $message -ForegroundColor Green
}  #end function WriteSuccess

function WriteError($message)
{
  Write-Host $message -ForegroundColor Red
 }  #end function WriteError

function WriteErrorAndExit($message)
{
  Write-Host $message -ForegroundColor Red
  Write-Host "Press any key to continue ..."
  $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
  $HOST.UI.RawUI.Flushinputbuffer()
  Exit
}  #end function WriteErrorAndExit

function Get-WindowsBuildNumber
{
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return [int]($os.BuildNumber)
}  #end function Get-WindowsBuildNumber

function Create-DeploymentLinks
{
  Write-Host "$basename -- Create-DeploymentLinks"
  Set-Alias InstChocoSCut Install-ChocolateyShortcut
  ## create shortcut to deployment - 00-bootstrap
  InstChocoSCut -ShortcutFilePath "$Env:Public\Desktop\LockerDeployment\DeploymentHomepage.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "$Env:deployurl" -Description "Locker Deployment Website"
  InstChocoSCut -ShortcutFilePath "$env:Public\Desktop\LockerDeployment\00-start-deployment.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/00-init.ps1" -Description "00 Start locker deployment"
  InstChocoSCut -ShortcutFilePath "$env:Public\Desktop\LockerDeployment\10-identify.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/10-identify.ps1" -Description "10-identify-locker"
  InstChocoSCut -ShortcutFilePath "$Env:Public\Desktop\LockerDeployment\20.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/20-bootstrap.ps1" -Description "Redeploy 00"
  InstChocoSCut -ShortcutFilePath "$Env:Public\Desktop\LockerDeployment\30-setup-lockerlife.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/30-bootstrap.ps1" -Description "Redeploy 10"
  InstChocoSCut -ShortcutFilePath "$Env:Public\Desktop\LockerDeployment\Restart-20.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/complete-locker-setup.ps1" -Description "Redeploy 20"
  InstChocoSCut -ShortcutFilePath "$Env:Public\Desktop\LockerDeployment\Restart-30.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/00-bootstrap.ps1" -Description "Redeploy 30"
  InstChocoSCut -ShortcutFilePath "$Env:Public\Desktop\LockerDeployment\complete-locker-setup.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/00-bootstrap.ps1" -Description "Redeploy Locker"
}  #end function Create-DeploymentLinks

## cleanup desktop
function CleanupDesktop
{
  Write-Host "$basename -- Clean up ..."
  Remove-Item "C:\99-DeploymentConfig.ps1" -Force -ErrorAction SilentlyContinue | Out-Null
  Remove-Item "$Env:Public\Desktop\*.lnk" -Force -ErrorAction SilentlyContinue
  Remove-Item "$Env:UserProfile\Desktop\*.lnk" -Force -ErrorAction SilentlyContinue
}  #end function CleanupDesktop


# Make an exit ....
Breathe

Write-Host "$basename - out" -ForegroundColor Green
Write-Host
