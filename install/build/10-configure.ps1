# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 10-configure
#    -- a bootstrapper to perform local identification tasks and setup for locker registration
#       ie. $sitename 

Disable-UAC
Update-ExecutionPolicy Unrestricted

Install-ChocolateyEnvironmentVariable "iccid" ""
Install-ChocolateyEnvironmentVariable "logs" "E:\logs"
Install-ChocolateyEnvironmentVariable "images" "E:\images"
Install-ChocolateyEnvironmentVariable "imagesarchive" "E:\images\archive"

New-Item -Path "$Env:logs" -ItemType Directory -Force
New-Item -Path "$Env:images" -ItemType Directory -Force
New-Item -Path "$Env:imagesarchive" -ItemType Directory -Force

Write-Host ""
Write-Host ""
Add-Type -AssemblyName Microsoft.VisualBasic
$iccid = [Microsoft.VisualBasic.Interaction]::InputBox('Scan SIM Card', 'LockerLife | Locker Deployment', "")

## $Env:sitename = & "$Env:curl" -Ss -k --url "https://gist.githubusercontent.com/tee-vee/bfa0ea73871ce47e6436beb88b2b77ac/raw/locker-iccid.db" | findstr "$Env:iccid" | awk '{ print $2 }'
$Env:sitename = & "$Env:curl" -Ss -k --url "https://gist.githubusercontent.com/tee-vee/bfa0ea73871ce47e6436beb88b2b77ac/raw/locker-iccid.db" | findstr "$Env:iccid" | %{ $_.Split(' ')[1]; }

Write-Host ""
Write-Host "Locker: $Env:sitename"
Write-Host ""

