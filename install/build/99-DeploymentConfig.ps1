# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 99-DeploymentConfig - setup variables, functions
$host.ui.RawUI.WindowTitle = "99-DeploymentConfig"




$basename = "99-DeploymentConfig"
#--------------------------------------------------------------------
Write-Host "99-DeploymentConfig - Lets start"
#--------------------------------------------------------------------
Write-Host "$basename - in" -ForegroundColor Green

# make an entrance ...
1..5 | % { Write-Host }

Write-Host "$basename -- Set Sound Volume to minimum"
$obj = new-object -com wscript.shell
$obj.SendKeys([char]173)

#--------------------------------------------------------------------
Write-Host "$basename - Loading Modules ..."
#--------------------------------------------------------------------

# Import BitsTransfer ...
if (!(Get-Module BitsTransfer)) {
	Import-Module BitsTransfer
} else {
	# BitsTransfer module already loaded ... clear queue
	Get-BitsTransfer | Complete-BitsTransfer
}


#--------------------------------------------------------------------
Write-Host "$basename - Setting Variables ..."
#--------------------------------------------------------------------

$ErrorActionPreference = "Continue"
$PSDefaultParameterValues += @{'*:Verbose' = $true}
$PSDefaultParameterValues += @{'*:Confirm' = $false}
$PSDefaultParameterValues.Add("*:ErrorAction","Continue")

$now = Get-Date -Format "yyyy-MM-ddTHH:mm"

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
$newsize.width = 205
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
## REMINDER: either set both $Env:variable only set $Env:variable

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

Install-ChocolateyEnvironmentVariable "hostname" "NULL"
$env:hostname = [System.Environment]::MachineName
$hostname = [System.Environment]::MachineName

Install-ChocolateyEnvironmentVariable "local" "C:\local"
$env:local = "C:\local"
$local = $Env:local

Install-ChocolateyEnvironmentVariable "sitename" "NULL"
$sitename = $Env:sitename

Write-Host "$basename -- Router Internal IP Address Discovery ..."
Install-ChocolateyEnvironmentVariable "RouterInternalIpAddress" "0.0.0.0"
$RouterInternalIpAddress = $env:RouterInternalIpAddress

Write-Host "$basename -- External IP Address Discovery ..."
Install-ChocolateyEnvironmentVariable "RouterExternalIpAddress" "0.0.0.0"

if (Get-Command ConvertFrom-JSON -ErrorAction SilentlyContinue) {
  $WebClient = New-Object System.Net.WebClient
  $Env:RouterExternalIpAddress = ((New-Object System.Net.WebClient).DownloadString("https://httpbin.org/ip") | ConvertFrom-JSON).origin
  $RouterExternalIpAddress = $env:RouterExternalIpAddress
  Write-Host "$basename -- External IP Address found: $Env:RouterExternalIpAddress"
}

Write-Host "$basename -- Console PC Internal IP Address Discovery ..."
Install-ChocolateyEnvironmentVariable "LocalIPAddress" "0.0.0.0"
#$LocalIPAddress = ((Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter 'ipenabled = "true"').IPAddress | findstr [0-9].\.)[0]).Split()[-1] )
$env:LocalIPAddress = ([net.dns]::GetHostAddresses("")| Select -Expa IP* | findstr [0-9].\. )
Write-Host "$basename -- Console PC Internal IP Address: $env:LocalIPAddress"

#Install-ChocolateyEnvironmentVariable 'JAVA_HOME' 'path\to\jre' 'Machine'
#Install-ChocolateyEnvironmentVariable -variableName "JAVA_HOME" -variableValue "D:\java\jre\bin" -variableType "Machine"
Install-ChocolateyEnvironmentVariable 'JAVA_HOME' "D:\java\jre\bin"
$JAVA_HOME = $Env:JAVA_HOME

Install-ChocolateyEnvironmentVariable '_tmp' 'C:\temp'
$_tmp = "C:\temp"
$_temp = "C:\temp"
$env:_tmp = $_tmp

Install-ChocolateyEnvironmentVariable 'logs' 'E:\logs'
$env:logs = "E:\logs"
$logs = $env:logs

Install-ChocolateyEnvironmentVariable 'images' 'E:\images'
$env:images = "E:\images"
$images = $env:images

Install-ChocolateyEnvironmentVariable 'imagesarchive' 'E:\images\archive'
$env:imagesarchive = "E:\images\archive"
$imagesarchive = $env:imagesarchive

Install-ChocolateyEnvironmentVariable 'curl' "c:\local\bin\curl.exe"
$env:curl = "$local\bin\curl.exe"
$curl = $env:curl

Install-ChocolateyEnvironmentVariable 'rm' "$Env:ProgramFiles\Gow\bin\rm.exe"

Install-ChocolateyEnvironmentVariable 'kioskprofile' 'c:\users\kiosk'

Install-ChocolateyEnvironmentVariable 'smtphost' 'hwsmtp.exmail.qq.com'
$env:smtphost = $smtphost

Install-ChocolateyEnvironmentVariable 'smtpport' '465'
$smtpport = '465'
$env:smtpport = $smtpport

Install-ChocolateyEnvironmentVariable 'emailUser' "pi-admin@locision.com"
$emailUser = "pi-admin@locision.com"
$env:emailUser = $emailUser

Install-ChocolateyEnvironmentVariable 'SMTP_USER_PASS' 'Locision1707'
$SMTP_USER_PASS = "Locision1707"
$env:SMTP_USER_PASS = $SMTP_USER_PASS

# determine user ...
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent()

# Get TeamViewer Client ID
Install-ChocolateyEnvironmentVariable 'TeamViewerClientID' '0'
#$TeamViewerClientID = (Get-ItemProperty -Path "HKLM:\SOFTWARE\TeamViewer" -Name ClientID).ClientID


#--------------------------------------------------------------------
Write-Host "$basename - Aliases"
#--------------------------------------------------------------------
Set-Alias -Name 'iexplore' "C:\Program Files\Internet Explorer\iexplore.exe" -Option AllScope
Set-Alias -Name 'zip' "C:\Program Files\7-Zip\7z.exe" -Option AllScope -Force
Set-Alias -Name 'curl' -Value "C:\local\bin\curl.exe" -Option AllScope -Force
Set-Alias -Name 'logout' 'invoke-userLogout'
Set-Alias -Name 'halt' 'invoke-systemShutdown'
Set-Alias -Name 'restart' 'invoke-systemReboot'


#--------------------------------------------------------------------
Write-Host "$basename - Get updated SSL Certificate store"
#--------------------------------------------------------------------

#& "$env:curl" --progress-bar --url "https://curl.haxx.se/ca/cacert.pem" > $ALLUSERSPROFILE\cacert.pem
#Install-ChocolateyEnvironmentVariable "CURL_CA_BUNDLE" "$ALLUSERSPROFILE\cacert.pem"


#--------------------------------------------------------------------
Write-Host "$basename - Functions"
#--------------------------------------------------------------------
function SetConsoleWindow {

	# set window size
	$H = Get-Host
	$Win = $H.UI.RawUI.WindowSize
	$Win.Width = 150
	$Win.Height = 50
	$H.UI.RawUI.Set_WindowSize($Win)

	$H = Get-Host
	$Win = $H.UI.RawUI.BufferSize
	$Win.Width = 150
	$Win.height = 5000
	$H.UI.RawUI.Set_BufferSize($Win)
	$host.UI.RawUI.ForegroundColor = "DarkYellow"
	$host.UI.RawUI.BackgroundColor = "Black"
}

function NewScheduledTask {
	$jobname = "Recurring PowerShell Task"
	# make sure script returns $true or $false or else scheduling won't work properly
	$script =  "C:\local\bin\Test-ExampleScript.ps1 -Server $env:computername"
	$repeat = (New-TimeSpan -Minutes 5)

	# The script below will run as the specified user (you will be prompted for credentials)
	# and is set to be elevated to use the highest privileges.
	# In addition, the task will run every 5 minutes or however long specified in $repeat.
	$action = New-ScheduledTaskAction –Execute "$pshome\powershell.exe" -Argument  "$script; quit"
	$duration = ([timeSpan]::maxvalue)
	$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval $repeat -RepetitionDuration $duration

	$msg = "Enter the username and password that will run the task";
	$credential = $Host.UI.PromptForCredential("Task username and password",$msg,"$env:userdomain\$env:username",$env:userdomain)
	$username = $credential.UserName
	$password = $credential.GetNetworkCredential().Password
	$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable -DontStopOnIdleEnd

	Register-ScheduledTask -TaskName $jobname -Action $action -Trigger $trigger -RunLevel Highest -User $username -Password $password -Settings $settings
}

function NewScheduledJob {
	# Change these three variables to whatever you want
	$jobname = 'Recurring PowerShell Task'
	$script =  "C:\local\bin\Test-ExampleScript.ps1 -Server server1"
	$repeat = (New-TimeSpan -Minutes 5)

	# The script below will run as the specified user (you will be prompted for credentials)
	# and is set to be elevated to use the highest privileges.
	# In addition, the task will run every 5 minutes or however long specified in $repeat.
	$scriptblock = [scriptblock]::Create($script)
	$trigger = New-JobTrigger -Once -At (Get-Date).Date -RepeatIndefinitely -RepetitionInterval $repeat
	$msg = "Enter the username and password that will run the task";
	$credential = $Host.UI.PromptForCredential("Task username and password",$msg,"$env:userdomain\$env:username",$env:userdomain)

	$options = New-ScheduledJobOption -RunElevated
	Register-ScheduledJob -Name $jobname -ScriptBlock $scriptblock -Trigger $trigger -ScheduledJobOption $options -Credential $credential
}

function Test-4G {
	Write-Host "$basename -- Running Internet Connection Speed Test ..."
	$SpeedTestResults = "c:\temp\speedtest.txt"
	C:\local\bin\speedtest-cli.exe | Out-File -Encoding utf8 $SpeedTestResults
	Get-Content $SpeedTestResults | Select -Skip 1 | Out-File -Encoding utf8 c:\temp\speedtest8.txt
	Move-Item c:\temp\speedtest8.txt $SpeedTestResults -Force
	$ehlo_domain = "locision.com"
	$to = "derekyuen@lockerlife.hk"
	$replyto = "pi-admin@locision.com"
	$from = "locker-deploy@locision.com"
	$fromname = "Locker Deployment"
	$returnpath = "pi-admin@locision.com"
	$subject = "testing"
	$attach = "c:\temp\speedtest.txt"
	$mailbody = "message body"
	$mimetype = "text/plain"
	#$extargs = " -ehlo -info"
	#Send-MailMessage -From $from -To $to -Subject $subject -Body $mailbody -SmtpServer $smtphost -Port $smtpport -UseSsl -Credential (Get-Credential) -Debug
	C:\local\bin\mailsend.exe -smtp $env:smtphost -port $env:smtpport -domain $ehlo_domain -t $to -f $from -name -sub $subject -name "locker-deployment speed test" -rp $returnpath -rt $replyto -ssl -auth -user $emailUser -pass "Locision1707" -attach $attach -M $mailbody -mime-type $mimetype -v
}

function Download-File {
  param ([string]$url,[string]$file)
  Write-Host "Downloading $url to $file"
  $downloader = new-object System.Net.WebClient
  $downloader.DownloadFile($url, $file)
}

function Get-SystemDrive {
    return $env:SystemDrive[0]
}

function Test-IsAdministrator {
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

function ConfigureDisk {
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

# Function to set a registry property value and create the registry key if it doesn't exist
Function Set-RegistryKey {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True,HelpMessage="Please Enter Registry Item Path",Position=1)]
		$Path,
		[Parameter(Mandatory=$True,HelpMessage="Please Enter Registry Item Name",Position=2)]
		$Name,
		[Parameter(Mandatory=$True,HelpMessage="Please Enter Registry Property Item Value",Position=3)]
		$Value,
		[Parameter(Mandatory=$False,HelpMessage="Please Enter Registry Property Type",Position=4)]
		$PropertyType = "DWORD"
	)
	# If path does not exist, create it
	if ((Test-Path $Path) -eq $False ) {
		$newItem = New-Item -Path $Path -Force
	}
	# Update registry value, create it if does not exist (DWORD is default)
	$itemProperty = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
	if($itemProperty -ne $null) {
		$itemProperty = Set-ItemProperty -Path $Path -Name $Name -Value $Value
	} else {
		$itemProperty = New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType
	}
}

function Breathe {
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
	if (Test-Path $file) {
		$f = get-item $file;
		$d = get-date
		$f.LastWriteTime = $d
	} else {
		"" | out-file -FilePath $file -Encoding ASCII
	} #else
}


function WriteInfo($message) {
  Write-Host $message
}  #end function WriteInfo

function WriteInfoHighlighted($message) {
  Write-Host $message -ForegroundColor Cyan
}  #end function WriteInfoHighlighted

function WriteSuccess($message) {
  Write-Host $message -ForegroundColor Green
}  #end function WriteSuccess

function WriteError($message) {
	Write-Host $message -ForegroundColor Red
}

function WriteErrorAndExit($message) {
	Write-Host $message -ForegroundColor Red
	Write-Host "Press any key to continue ..."
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
	$host.UI.RawUI.Flushinputbuffer()
	Exit
}  #end function WriteErrorAndExit

function Get-WindowsBuildNumber {
	$os = Get-WmiObject -Class Win32_OperatingSystem
	return [int]($os.BuildNumber)
}  #end function Get-WindowsBuildNumber

function Create-DeploymentLinks {
	Write-Host "$basename -- Create-DeploymentLinks"
	Set-Alias InstChocoSCut Install-ChocolateyShortcut
	## create shortcut to deployment - 00-bootstrap
	InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\DeploymentHomepage.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "$env:deployurl" -Description "Locker Deployment Website"
	InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-00bootstrap.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/00-bootstrap.ps1" -Description "00-bootstrap"
	InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-00init.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/00-init.ps1" -Description "00-init"
	InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-10.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/10-identify.ps1" -Description "10-identify"
	InstChocoSCut -ShortcutFilePath "$env:UserProfile\Desktop\LockerDeployment\Deployment-30.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$env:deployurl/30-lockerlife.ps1" -Description "30-lockerlife"
}  #end function Create-DeploymentLinks


function Get-UserSID {
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

function Is64Bit { [IntPtr]::Size -eq 8 }

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

Function Rename-ComputerName ([string]$NewComputerName) {
 	$ComputerInfo = Get-WmiObject -Class Win32_ComputerSystem
	$ComputerInfo.Rename($NewComputerName)
}

## cleanup desktop
function CleanupDesktop {
	Write-Host "$basename -- Clean up Desktop..." -ForegroundColor Green
	w32tm /query /configuration
	w32tm /query /status
	w32tm /resync /rediscover /nowait
	# Internet Explorer: Temp Internet Files:
	RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

	"AppData\Roaming\Microsoft\Windows\Libraries\*","AppData\Roaming\Microsoft\Windows\SendTo\*.lnk","SendTo\*.lnk","Recent\*.lnk","LockerDeployment","Desktop\LockerDeployment","Links\*.lnk","Desktop\*.lnk","Favorites\*","Videos\*","Recorded TV","Pictures","Music" | ForEach-Object {
		if (Test-Path -Path "$env:UserProfile\$_") { Remove-Item -Path "$env:UserProfile\$_" -Recurse -Force }
		if (Test-Path -Path "$env:Public\$_") { Remove-Item -Path "$env:Public\$_" -Recurse -Force }
		if (Test-Path -Path "C:\Users\kiosk\$_") { Remove-Item -Path "C:\Users\kiosk\$_" -Recurse -Force }
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

Write-Host "$basename - out" -ForegroundColor Green

#END OF FILE
