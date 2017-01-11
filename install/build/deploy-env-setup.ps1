# Derek Yuen <derekyuen@lockerlife.hk>
# deploy-env-setup.txt 
# LockerLife Locker Deployment
# January 2017
# 
# deploy-env-setup.txt 
# Note: Restart is desirable in this situation ... 
# to prevent restart, /package/nr/url?
# http://boxstarter.org/package/url?https://gist.githubusercontent.com/locker-admin/8468c4bc904185f93d3e7bcd43b67234/raw/29b431c48fc083be6529468e9a9e27759a24f137/deploy-env-setup.txt
# Origin: https://gist.githubusercontent.com/locker-admin/8468c4bc904185f93d3e7bcd43b67234/raw/29b431c48fc083be6529468e9a9e27759a24f137/deploy-env-setup.txt

## set globals
Write-BoxstarterMessage -nologo ""

$Boxstarter.RebootOk=$true # Allow reboots?
$Boxstarter.NoPassword=$false # Is this a machine with no login password?
$Boxstarter.AutoLogin=$true # Save my password securely and auto-login after a reboot

Update-ExecutionPolicy Unrestricted

choco feature enable --name=allowGlobalConfirmation

## base required packages (in proper install order)
cinst git.install -params '"/WindowsTerminal /GitOnlyOnPath /NoAutoCrlf"'
cinst powershell -version 3.0.20121027
cinst curl
cinst gow
cinst teamviewer
cinst nssm
cinst wget
cinst vim
cinst jq
cinst microsoftsecurityessentials -allow-empty-checksums -allow-empty-checksums-secure
# cinst ie11 -allow-empty-checksums -allow-empty-checksums-secure
cinst pstools
cinst TelnetClient -source windowsfeatures
#cinst 7zip
choco install 7zip.commandline
choco feature disable -name=allowGlobalConfirmation

## Set extensions
Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar

if (Test-PendingReboot) { Invoke-Reboot -RebootOk }

