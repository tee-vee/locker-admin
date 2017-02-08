# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 99-DeploymentConfig - setup variables, functions
#$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 99-DeploymentConfig"
#$basename = $MyInvocation.MyCommand.Name


$basename = "99-DeploymentConfig"
#--------------------------------------------------------------------
Write-Host "99-DeploymentConfig - Lets start"
#--------------------------------------------------------------------
Write-Host "$basename - in" -ForegroundColor Green

# make an entrance ...
1..5 | % { Write-Host }

#--------------------------------------------------------------------
Write-Host "$basename - Loading Modules ..."
#--------------------------------------------------------------------

# Import BitsTransfer ...
if (!(Get-Module BitsTransfer -ErrorAction SilentlyContinue)) {
	Import-Module BitsTransfer -Verbose
} else {
	# BitsTransfer module already loaded ... clear queue
	Get-BitsTransfer -Verbose | Complete-BitsTransfer -Verbose
}


#--------------------------------------------------------------------
Write-Host "$basename - Setting Variables ..."
#--------------------------------------------------------------------

$ErrorActionPreference = "Continue"

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
$newsize.width = 200
$pswindow.buffersize = $newsize
#$pswindow.windowtitle = "LockerLife Locker Deployment 99-DeploymentConfig"

# the nul ensures window size does not chnage
#& cmd /c mode con: cols=150  >nul 2>nul

Write-Host "$basename -- Setting additional local variables ..."
# easy add to %path% to the path based on finding the executable.
#if(!(where.exe chocolatey)) { $env:Path += ';C:\Chocolatey\bin;' }
$Env:Path += ";C:\local\bin;C:\$Env:ProgramFiles\GnuWin32\bin"


# Fix SSH-Agent error by adding the bin directory to the Path environment variable
#$Env:PSModulePath = $Env:PSModulePath + ";${Env:ProgramFiles(x86)}\Git\bin"


# dot Net method to create Environment Variables:
# [Environment]::SetEnvironmentVariable("TestVariable", "Test value.", "User")

#$userName = $env:UserName
#$userDomain = $env:UserDomain
## REMINDER: either set both $Env:variable only set $Env:variable!!

Install-ChocolateyEnvironmentVariable "baseurl" "http://lockerlife.hk"
$env:baseurl = "http://lockerlife.hk"
$baseurl = $Env:baseurl

Install-ChocolateyEnvironmentVariable "deployurl" "http://lockerlife.hk/deploy"
$env:deployurl = "http://lockerlife.hk/deploy"
$deployurl = $Env:deployurl

Install-ChocolateyEnvironmentVariable "domainname" "lockerlife.hk"
$domainname = $env:domainname

Install-ChocolateyEnvironmentVariable "iccid" "NULL"
$iccid = $Env:iccid

Install-ChocolateyEnvironmentVariable "lockertype" "NULL"
$lockertype = $Env:lockertype

Install-ChocolateyEnvironmentVariable "lockerserialnumber" "NULL"
$lockerserialnumber = $Env:lockerserialnumber

Install-ChocolateyEnvironmentVariable "hostname" [system.environment]::MachineName                                 # $hostname == $sitename
$hostname = [system.environment]::MachineName

Install-ChocolateyEnvironmentVariable "local" "C:\local"
$env:local = "C:\local"
$local = $Env:local

Install-ChocolateyEnvironmentVariable "sitename" "NULL"                                 # $hostname == $sitename
$sitename = $Env:sitename

Install-ChocolateyEnvironmentVariable "CameraIpAddress" "0.0.0.0"                       # camera ip address

Install-ChocolateyEnvironmentVariable "RouterInternalIpAddress" "0.0.0.0"               # router internal ip address
$RouterInternalIpAddress = $env:RouterInternalIpAddress

Install-ChocolateyEnvironmentVariable "RouterExternalIpAddress" "0.0.0.0"               # router external ip address

if (Get-Command ConvertFrom-JSON -ErrorAction SilentlyContinue) {
  $WebClient = New-Object System.Net.WebClient
  $Env:RouterExternalIpAddress = ((New-Object System.Net.WebClient).DownloadString("https://httpbin.org/ip") | convertfrom-json).origin
  $RouterExternalIpAddress = $env:RouterExternalIpAddress
  Write-Host "$basename -- External IP Address found: $Env:RouterExternalIpAddress"
}

#Install-ChocolateyEnvironmentVariable 'JAVA_HOME' 'path\to\jre' 'Machine'
#Install-ChocolateyEnvironmentVariable -variableName "JAVA_HOME" -variableValue "D:\java\jre\bin" -variableType "Machine"
Install-ChocolateyEnvironmentVariable "JAVA_HOME" "D:\java\jre\bin"
$JAVA_HOME = $Env:JAVA_HOME

Install-ChocolateyEnvironmentVariable "_tmp" "C:\temp"
$_tmp = "C:\temp"
$_temp = "C:\temp"                                                              # just in case
$env:_tmp = $_tmp

Install-ChocolateyEnvironmentVariable "logs" "E:\logs"
$env:logs = "E:\logs"
$logs = $Env:logs

Install-ChocolateyEnvironmentVariable "images" "E:\images"
$env:images = "E:\images"
$images = $env:images

Install-ChocolateyEnvironmentVariable "imagesarchive" "E:\images\archive"
$env:imagesarchive = "E:\images\archive"
$imagesarchive = $env:imagesarchive

Install-ChocolateyEnvironmentVariable "curl" "c:\local\bin\curl.exe"
$env:curl = "$local\bin\curl.exe"
$curl = $env:curl

Install-ChocolateyEnvironmentVariable "rm" "$Env:ProgramFiles\Gow\bin\rm.exe"

Install-ChocolateyEnvironmentVariable "kioskprofile" "c:\users\kiosk"

# determine user ...
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent()


#--------------------------------------------------------------------
Write-Host "$basename - Aliases"
#--------------------------------------------------------------------
Set-Alias -Name "iexplore" "C:\Program Files\Internet Explorer\iexplore.exe" -Option AllScope
Set-Alias -Name "zip" "C:\Program Files\7-Zip\7z.exe" -Option AllScope -Force
Set-Alias -Name "curl" -Value "C:\local\bin\curl.exe" -Option AllScope -Force
Set-Alias -Name "logout" invoke-userLogout
Set-Alias -Name "halt" invoke-systemShutdown
Set-Alias -Name "restart" invoke-systemReboot
#--------------------------------------------------------------------
Write-Host "$basename - Get updated SSL Certificate store"
#--------------------------------------------------------------------

& "$env:curl" --progress-bar --url "https://curl.haxx.se/ca/cacert.pem" > $ALLUSERSPROFILE\cacert.pem
Install-ChocolateyEnvironmentVariable "CURL_CA_BUNDLE" "$ALLUSERSPROFILE\cacert.pem"

#--------------------------------------------------------------------
Write-Host "$basename - Functions"
#--------------------------------------------------------------------

function Download-File
{
  param ([string]$url,[string]$file)
  Write-Host "Downloading $url to $file"
  $downloader = new-object System.Net.WebClient
  $downloader.DownloadFile($url, $file)
}


function Get-SystemDrive
{
    return $env:SystemDrive[0]
}

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

function ConfigureDisk
{
  # list disks (raw disks)
  # wmic diskdrive list brief
  Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.Partitions -eq 0 }

  # list volumes
  # wmic volume list brief

  # using diskpart
  Write-Host "$basename -- Setup D drive"
  #select disk=1
  #create partition primary
  #select partition=1
  #format FS=NTFS UNIT=4096 LABEL="LOCKERLIFEAPP" QUICK
  #assign letter="D"
  #(New-Object System.Net.WebClient).DownloadFile("https://gist.githubusercontent.com/tee-vee/9b597a682a2fe6fee417be5039445da7/raw/20430a6353efa49f2cb8f03a3c75ecef009a2e9e/diskpart-d.txt","C:\local\etc\diskpart-d.txt")


  # using diskpart
  Write-Host "$basename -- Setup E drive"
  #select disk=2
  #create partition primary
  #select partition=1
  #format FS=NTFS UNIT=4906 LABEL="logs" QUICK
  #assign letter=E
  #(New-Object System.Net.WebClient).DownloadFile("https://gist.githubusercontent.com/tee-vee/ef21fd19a8e91c0cc3eef37a9557ad49/raw/b22394680129ffc07e1ff76685427319a5f704bd/diskpart-e.txt","C:\local\etc\diskpart-e.txt")

}

#
#function Reboot-IfRequired()
#{
#  if(Test-PendingReboot)
#  {
#    Write-Host "$basename -- Reboot required. Rebooting now"
#		Invoke-Reboot
#	}
#	else
#  {
#		Write-Host "$basename -- No reboot is required. Continuing ..."
#	}
#} #end function Reboot-IfRequired

function Breathe
{
  # Let libs/modules load ...
  1..5 | % { Write-Host " -- "}
}

function AddTo-7zip($zipFileName) {
    BEGIN {
        #$7zip = "$($env:ProgramFiles)\7-zip\7z.exe"
        $7zip = Find-Program "\7-zip\7z.exe"
		if(!([System.IO.File]::Exists($7zip))){
			throw "7zip not found";
		}
    }
    PROCESS {
        & $7zip a -tzip $zipFileName $_
    }
    END {
    }
}

function touch($file) {
    if(test-path $file) {
        $f = get-item $file;
        $d = get-date
        $f.LastWriteTime = $d
    }
    else
    {
        "" | out-file -FilePath $file -Encoding ASCII
    }
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
  InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\DeploymentHomepage.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "$env:deployurl" -Description "Locker Deployment Website"
  InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-00.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/00-init.ps1" -Description "00-init"
  InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-00.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/00-bootstrap.ps1" -Description "00-bootstrap"
  InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-10.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/00-init.ps1" -Description "00-init"
  InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-20.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/10-identify.ps1" -Description "10-identify"
  InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-10.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/20-setup.ps1" -Description "20-setup"
  InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-30.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/30-lockerlife.ps1" -Description "30-lockerlife"
  InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-40.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/complete-locker-setup.ps1" -Description "complete-locker-setup"
}  #end function Create-DeploymentLinks


function Get-UserSID
{
  $PatternSID = 'S-1-5-21-\d+-\d+\-\d+\-\d+$'
  Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' | Where-Object {$_.PSChildName -match $PatternSID} |
     select  @{name="SID";expression={$_.PSChildName}},
             @{name="UserHive";expression={"$($_.ProfileImagePath)\ntuser.dat"}},
             @{name="Username";expression={$_.ProfileImagePath -replace '^(.*[\\\/])', ''}}
}

#function Make-Shortcut {
#  # Create a Shortcut with native Windows PowerShell
#  $TargetFile = "$env:SystemRoot\System32\notepad.exe"
#  $ShortcutFile = "$env:Public\Desktop\Notepad.lnk"
#  $WScriptShell = New-Object -ComObject WScript.Shell
#  $Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
#  $Shortcut.TargetPath = $TargetFile
#  $Shortcut.Save()
#}

function Is64Bit {  [IntPtr]::Size -eq 8  }

function Enable-Net40 {
    if(Is64Bit) {$fx="framework64"} else {$fx="framework"}
    if(!(test-path "$env:windir\Microsoft.Net\$fx\v4.0.30319")) {
        if((Test-PendingReboot) -and $Boxstarter.RebootOk) {return Invoke-Reboot}
        Write-BoxstarterMessage "Downloading .net 4.5..."
        Get-HttpResource "http://download.microsoft.com/download/b/a/4/ba4a7e71-2906-4b2d-a0e1-80cf16844f5f/dotnetfx45_full_x86_x64.exe" "$env:temp\net45.exe"
        Write-BoxstarterMessage "Installing .net 4.5..."
        if(Get-IsRemote) {
            Invoke-FromTask @"
Start-Process "$env:temp\net45.exe" -verb runas -wait -argumentList "/quiet /norestart /log $Env:temp\net45.log"
"@
        }
        else {
            $proc = Start-Process "$Env:temp\net45.exe" -verb runas -argumentList "/quiet /norestart /log $Env:temp\net45.log" -PassThru
            while(!$proc.HasExited){ sleep -Seconds 1 }
        }
    }
}

Function Rename-ComputerName ([string]$NewComputerName)
{
 	$ComputerInfo = Get-WmiObject -Class Win32_ComputerSystem
	$ComputerInfo.Rename($NewComputerName)
}

## cleanup desktop
function CleanupDesktop {
  Write-Host "$basename -- Clean up Desktop..." -ForegroundColor Green

  # Internet Explorer: Temp Internet Files:
  RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

  "AppData\Roaming\Microsoft\Windows\Libraries\*","AppData\Roaming\Microsoft\Windows\SendTo\*.lnk","SendTo\*.lnk","Recent\*.lnk","LockerDeployment","Desktop\LockerDeployment","Links\*.lnk","Desktop\*.lnk","Favorites\*","Videos\*","Recorded TV","Pictures","Music" | ForEach-Object {
    if (Test-Path -Path "$env:UserProfile\$_" -Verbose) { Remove-Item -Path "$env:UserProfile\$_" -Recurse -Force -Verbose }
    if (Test-Path -Path "$env:Public\$_" -Verbose) { Remove-Item -Path "$env:Public\$_" -Recurse -Force -Verbose }
    if (Test-Path -Path "C:\Users\kiosk\$_" -Verbose) { Remove-Item -Path "C:\Users\kiosk\$_" -Recurse -Force -Verbose }
  }
  Remove-Item "C:\99-DeploymentConfig.ps1" -Force | Out-Null
  Enable-UAC
  Disable-MicrosoftUpdate
}  #end function CleanupDesktop

# Helper functions for user/computer session management
function invoke-userLogout { shutdown /l /t 0 }
function invoke-systemShutdown { shutdown /s /t 5 }
function invoke-systemReboot { shutdown /r /t 5 }
function invoke-systemSleep { RunDll32.exe PowrProf.dll,SetSuspendState }
function invoke-terminalLock { RunDll32.exe User32.dll,LockWorkStation }

# Make an exit ....
Breathe

Write-Host "$basename - out" -ForegroundColor Green
