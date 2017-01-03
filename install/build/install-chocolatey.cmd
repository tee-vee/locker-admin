@echo off

:: Derek Yuen <derekyuen@locision.com>
:: December 2016


::download install.ps1
%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "((new-object net.webclient).DownloadFile('https://chocolatey.org/install.ps1','install.ps1'))"

@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

:: turn off the prompting from Chocolatey asking if you are sure you want to install
chocolatey feature enable -n=allowGlobalConfirmation

choco install git
choco install 7zip
choco install notepadplusplus
choco install boxstarter.common
choco install boxstarter.winconfig
choco install teamviewer
choco install carbon
choco install gow
choco install curl
choco install vim
choco install clink
choco install git
choco install jq
choco install rsync
choco install which
choco install nssm
choco install wget
choco install pswindowsupdate
:: choco install git-credential-manager-for-windows

:: turn off the prompting from Chocolatey asking if you are sure you want to install
chocolatey feature disable -n=allowGlobalConfirmation
