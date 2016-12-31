@echo off


::download install.ps1
%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "((new-object net.webclient).DownloadFile('https://chocolatey.org/install.ps1','install.ps1'))"

@powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

choco install -y git
choco install -y 7zip
choco install -y boxstarter.common
choco install -y boxstarter.winconfig
choco install -y teamviewer
choco install -y carbon
choco install -y gow
choco install -y curl
choco install -y vim
choco install -y clink
choco install -y git
choco install -y jq
choco install -y rsync
choco install -y which
choco install -y nssm
choco install -y wget
choco install -y pswindowsupdate
