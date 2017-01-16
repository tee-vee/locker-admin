# Derek Yuen <derekyuen@lockerlife.hk>


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
#Disable-UAC
#Update-ExecutionPolicy Unrestricted


# Small taskbar
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom
