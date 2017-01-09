# GPOBackupSamp.PS1 
# Script By: Tim B.
# This script Backup all GPOs and save it to a folder named as the current date.
# Change the Path "\\server\c$\Backup\GroupPolicies\$date" to your server path

Import-Module grouppolicy
$date = get-date -format M.d.yyyy
New-Item -Path \\server\c$\Backup\GroupPolicies\$date -ItemType directory
Backup-Gpo -All -Path \\server\c$\Backup\GroupPolicies\$date