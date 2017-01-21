# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 99-DeploymentConfig

#$basename = $MyInvocation.MyCommand.Name

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

$Env:Path += ";C:\local\bin;C:\$Env:ProgramFiles\GnuWin32\bin"

# Windows Explorer Settings
#Set-WindowsExplorerOptions -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess

# Small taskbar
#Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom


 #############
 # Functions #
 #############

 # native unzip
 ## [Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.Filesystem")

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
}


# Let libs/modules load ...
1..10 | % { Write-Host }

WriteSuccess "99-DeploymentConfig - out"
Write-Host
