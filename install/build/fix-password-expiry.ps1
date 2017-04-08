# Derek Yuen <derekyuen@lockerlife.hk>


$ErrorActionPreference = "Continue"
$basename = "fix-password-expiry"


Write-Host "LockerLife Deployment Team - Tools"

# Disable-UAC

Write-Host "${basename}: Set Sound Volume to minimum"
$SetSystemVolumeObj = New-Object -com wscript.shell

## vol down
$SetSystemVolumeObj.SendKeys([char]174)
$SetSystemVolumeObj.SendKeys([char]174)
$SetSystemVolumeObj.SendKeys([char]174)
$SetSystemVolumeObj.SendKeys([char]174)
$SetSystemVolumeObj.SendKeys([char]173)                     # mute

Write-Host "${basename}: System settings update"
net.exe accounts /maxpwage:UNLIMITED
Start-Process -FilePath "C:\Windows\System32\net.exe" -ArgumentList "accounts /maxpwage:UNLIMITED" -Verbose


# User: kiosk
Write-Host "${basename}: Kiosk User Setting Update"
net.exe user kiosk locision123 /active:yes /passwordchg:no /expires:never /times:all

Start-Process -FilePath "C:\Windows\System32\net.exe" -ArgumentList "user kiosk locision123 /active:yes /passwordchg:no /expires:never /times:all" -Verbose -NoNewWindow


# User: AAICON
Write-Host "${basename}: aaicon user profile update"
net.exe user AAICON Locision123 /active:yes /expires:never /times:all
Start-Process -FilePath "C:\Windows\System32\net.exe" -ArgumentList "user AAICON Locision123 /active:yes /expires:never /times:all" -Verbose -NoNewWindow


Write-Host "${basename}: Disable Admin user"
net.exe user Administrator /active:no
Start-Process -FilePath "C:\Windows\System32\net.exe" -ArgumentList "user Administrator /active:no" -Verbose -NoNewWindow


Write-Host "${basename}: Check"
net.exe user kiosk
net.exe user aaicon

Write-Host "${basename}: Done" -ForegroundColor Green

Start-Sleep -Seconds 10


# Enable-UAC