function Install-PSModule ([string] $ModuleName)
{
  $existingVersion = $(Get-Module -ListAvailable -Name $ModuleName | Select-Object -First 1).Version
  $newestVersion = $(Find-Module -Name "$ModuleName" | Select-Object -First 1).Version
  if (-Not $existingVersion) {
    Install-Module -Name "$ModuleName"
    Write-BoxstarterMessage "Installing Powershell module $ModuleName (v$newestVersion)"

  } elseif ($newestVersion -gt $existingVersion) {
        Write-BoxstarterMessage "Upgrading Powershell module $ModuleName from v$existingVersion to v$newestVersion"
        Install-Module -Force -Name "$ModuleName"
  } else {
        Write-BoxstarterMessage "Powershell module $ModuleName is already at the latest version (v$existingVersion)"
  }
}

# System settings
Write-BoxstarterMessage "Configuring system settings"
Update-ExecutionPolicy Unrestricted
Enable-MicrosoftUpdate
Install-WindowsUpdate -AcceptEula `
                      -GetUpdatesFromMs `
                      -SupressReboots
Set-StartScreenOptions -EnableBootToDesktop
## Windows features
choco install -y IIS-WebServerRole -source WindowsFeatures

# Desktop settings
Write-BoxstarterMessage "Configuring desktop settings"

Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives `
                           -EnableShowFullPathInTitleBar `
                           -EnableShowProtectedOSFiles `
                           -EnableShowFileExtensions `
                           -EnableShowRecentFilesInQuickAccess
Set-TaskbarOptions -Size Small `
                   -Lock
Disable-BingSearch
Disable-GameBarTips


$ChocolateyApplications = @(
#region Apps - General - Dev
  "googlechrome",
  "firefox",
  "flashplayerplugin",
  "7zip",
  "vlc",
  "sumatrapdf",
  "skype",
  "wox",
#endregion
#region Apps - GUI - Dev
  "notepadplusplus",
  "putty",
  "procexp",
  "fiddler",
  "baretail",                   # Real time log tailing
  "windirstat",
  "tortoisegit",
  "autohotkey",
  "winmerge",
  "linqpad4",
  "diffmerge",
  "winscp",
  "putty",
  "nugetpackageexplorer",
  "commandwindowhere",          # Add an "Open Command Window Here" context menu
#endregion
#region Apps - CLI
  "vim",
  "chocolatey",
  "curl",
  "wget",
  "git-credential-winstore",
  "conemu",                      # Terminal emulator
  "far",                         # Terminal dual pane file manager
  "clink",                       # Readline support for cmd.exe
  "poshgit",                     # Enhanced git support in powershell
  "pester",                      # BDD tests for powershell
  "nssm",                        # Non sucking service manager, run apps as a service
  "nmap",
  "nuget.commandline",
  "poshgit",                    # Git powershell integration
#endregion
#region Apps - Runtimes
  "dotnet4.5"
#endregion
)

Write-BoxstarterMessage "Installing packages via Chocolatey"

$ChocolateyApplications | ForEach-Object { choco install $_ }

choco install git --params="/GitAndUnixToolsOnPath /NoAutoCrlf'"

# Install TaskBar Pinned items
$TaskBarPinnedItems = @(
  "${env:programfiles(x86)}/Google/Chrome/Application/chrome.exe",
  "${env:programfiles(x86)}/vim/vim74/gvim.exe",
  "${env:windir}\system32\WindowsPowerShell\v1.0\PowerShell_ISE.exe",
  "${env:programfiles}\VideoLAN\VLC\vlc.exe"
)
Write-BoxstarterMessage "Setting pinned items to taskbar"
$TaskBarPinnedItems | ForEach-Object { Install-ChocolateyPinnedTaskBarItem $_ }

# Powershell setup
## Necessary for Powershell Install-Module to work

Write-BoxstarterMessage "Trusting Powershell repositories"

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# NuGet is a prerequisite for Install-Module
Write-BoxstarterMessage "Installing OneGet package providers"
Install-PackageProvider -Name NuGet

$PSModulesToInstall = @(
    "Carbon",
    "PSReadline",
    "Posh-SSH",
    "Pester"
)
Write-BoxstarterMessage "Installing Powershell modules"
$PSModulesToInstall | ForEach-Object { Install-PSModule $_ }
# Download powershell help files (like man pages) for local consumption
Write-BoxstarterMessage "Updating Powershell help"
Update-Help