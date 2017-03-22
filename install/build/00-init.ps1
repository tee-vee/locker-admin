# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 00-init - make directories, setup system-only user accounts (no LockerLife customizations)
$host.ui.RawUI.WindowTitle = "00-init"

$basename = "00-init"
$ErrorActionPreference = "Continue"
#$PSDefaultParameterValues += @{'Get*:Verbose' = $true}
#$PSDefaultParameterValues += @{'*:Confirm' = $false}


# --------------------------------------------------------------------------------------------
Write-Host "$basename - Lets start"
# --------------------------------------------------------------------------------------------
$timer = Start-TimedSection "00-init"

## Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
    Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    1..5 | % { Write-Host }
    exit
}

# backup
$previousHour = [DateTime]::Now.AddHours(-1)
#if (((Get-ComputerRestorePoint)[-1]).CreationTime -gt $previousHour)

Enable-ComputerRestore -Drive "C:\" -Confirm:$false
Checkpoint-Computer -Description "Before 00 init"


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

if (Test-Path "C:\local\lib\WASP.dll") {
    Import-Module "C:\local\lib\WASP.dll"
}

if (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
    # chocolatey already installed .. check for old version pin
    C:\ProgramData\chocolatey\bin\choco.exe pin remove --name chocolatey
}

choco feature enable -n=allowGlobalConfirmation

cinst dotnet4.5.1 --ignore-checksums
cinst powershell
(new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex

choco feature disable -n=allowGlobalConfirmation

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1
$basename = "00-init"

SetConsoleWindow
$host.ui.RawUI.WindowTitle = "00-init"

# close previous IE windows ...
if (Get-Process -Name iexplore -ErrorAction SilentlyContinue) {
    Stop-Process -Name iexplore
}

# remove limitations
Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

# Start Time and Transcript
Start-Transcript -Path "$Env:temp\$basename.log"
$StartDateTime = Get-Date
Write-Host "Script started at $StartDateTime" -ForegroundColor Green

#--------------------------------------------------------------------
Write-Host "$basename - System eligibility check"
#--------------------------------------------------------------------

# Checking for Compatible OS
Write-Host "Checking if OS is Windows 7"

$BuildNumber = Get-WindowsBuildNumber
if ($BuildNumber -le 7601) {
    # Windows 7 RTM=7600, SP1=7601
    WriteSuccess "PASS: OS is Windows 7 (RTM 7600/SP1 7601)"
} else {
    WriteErrorAndExit "`t FAIL: Windows version $BuildNumber detected and is not supported. Exiting"
}

# --------------------------------------------------------------------------------------------
Write-Host "$basename - START - Update Root Certificates from Microsoft ..."
# --------------------------------------------------------------------------------------------
#certutil.exe -syncWithWU -f $env:temp


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Update-Help"
# --------------------------------------------------------------------------------------------
# powershell.exe -NoProfile -command "& {Update-Help}"


# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Setup D drive ..."
# --------------------------------------------------------------------------------------------

WriteInfo "$basename --- Debug..."
Get-WmiObject Win32_Volume | Where-Object { $_.filesystem -Match "ntfs" } | sort { $_.name } | Foreach-Object {
    Write-Output "$(echo $_.name) [$(echo $_.label)]"
}

WriteInfo "$basename --- Checking if VM ..."
if ((Get-WmiObject -Class Win32_ComputerSystem).Model -eq "VMware Virtual Platform") {
    #New-Item -ItemType Directory -Path "C:\mnt\d" -Force
    #New-Item -ItemType Directory -Path "C:\mnt\e" -Force
    #c:\windows\system32\cmd.exe /c 'subst d: "C:\mnt\d"'
    #c:\windows\system32\cmd.exe /c 'subst e: "C:\mnt\e"'
    if (!(Test-Path -Path "D:\done.txt")) {
        WriteInfoHighlighted "$basename -- Prepare D drive"

        $diskpartD = @"
select disk=1
clean
create partition primary
select partition=1
format FS=NTFS UNIT=4096 LABEL="LOCKERLIFEAPP" QUICK
assign letter=D
"@
        Set-Content -Path C:\diskpartD.txt -Value $diskpartD
        diskpart.exe /s C:\diskpartD.txt
        New-Item -ItemType File -Path "D:\done"
    }

    if (!(Test-Path -Path "e:\done")) {
        Write-Host "$basename -- Prepare E drive"

        $diskpartE = @"
select disk=2
clean
create partition primary
select partition=1
format FS=NTFS LABEL="logs" QUICK
assign letter=E
"@
        Set-Content -Path C:\diskpartE.txt -Value $diskpartE
        diskpart.exe /s C:\diskpartE.txt
        New-Item -ItemType File -Path "E:\done"
    }
}

# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Camera Discovery ..."
# --------------------------------------------------------------------------------------------

if (Test-Path -Path "C:\local\bin\upnpscan.exe") {

    # logic too tricky to implement ... just do it by force
    $CameraDiscover = (C:\local\bin\upnpscan.exe -m -iA | Select-String LOCATION).ToString().Split(" ")
    if (!([uri]$CameraDiscover[1])) {
        Start-Sleep -Seconds 2 ; 	$CameraDiscover = (C:\local\bin\upnpscan.exe -m -iA | Select-String LOCATION).ToString().Split(" ") 
    }
    if (!([uri]$CameraDiscover[1])) {
        Start-Sleep -Seconds 2 ; 	$CameraDiscover = (C:\local\bin\upnpscan.exe -m -iA | Select-String LOCATION).ToString().Split(" ") 
    }
    if (!([uri]$CameraDiscover[1])) {
        Start-Sleep -Seconds 2 ; 	$CameraDiscover = (C:\local\bin\upnpscan.exe -m -iA | Select-String LOCATION).ToString().Split(" ") 
    }
    if (!([uri]$CameraDiscover[1])) {
        Start-Sleep -Seconds 2 ; 	$CameraDiscover = (C:\local\bin\upnpscan.exe -m -iA | Select-String LOCATION).ToString().Split(" ") 
    }
    if (!([uri]$CameraDiscover[1])) {
        Start-Sleep -Seconds 2 ; 	$CameraDiscover = (C:\local\bin\upnpscan.exe -m -iA | Select-String LOCATION).ToString().Split(" ") 
    }

    # if uPnP Scan success ... found upnp device - now need to verify if it is axis camera ...
    if ($CameraDiscover[1]) {
        $uri = ([uri]$CameraDiscover[1]).AbsoluteURI
        [xml]$xx = Invoke-WebRequest -Uri $uri -DisableKeepAlive -UseBasicParsing
        # if manufacturer = AXIS, yay!
        if ($xx.root.device.manufacturer = "AXIS") {
            WriteSuccess "$basename --- found camera"
            Write-Host "$basename --- found camera"

            # try defaults
            $CameraDefaultUser = "root"
            $CameraDefaultPass = ConvertTo-SecureString -String "pass" -AsPlainText -Force

            # just use $cred ...
            $cred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $CameraDefaultUser, $CameraDefaultPass
            # $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

            # AXIS F34 Network Camera - $xx.root.device.modelDescription
            Install-ChocolateyEnvironmentVariable "CameraUrl" "NULL"
            $env:CameraUrl = $xx.root.device.presentationURL

            Install-ChocolateyEnvironmentVariable "CameraIpAddress" "0.0.0.0"
            $env:CameraIpAddress = ([Uri]"$env:CameraUrl").Host

            Install-ChocolateyEnvironmentVariable "CameraManufacturer" "NULL"
            $env:CameraManufacturer = "$xx.root.device.manufacturer"

            Install-ChocolateyEnvironmentVariable "CameraSerialNumber" "NULL"
            $env:CameraSerialNumber = "$xx.root.device.serialNumber"

            # "AXIS F34"
            Write-Host "$basename --- Camera IP Address: " ([Uri]$CameraDiscover[1]).Host
            Write-Host "$basename --- Camera friendlyName: " $xx.root.device.friendlyName
            Write-Host "$basename --- Camera modelName: " $xx.root.device.modelName
            Write-Host "$basename --- Camera modelDescription: " $xx.root.device.modelDescription
            Write-Host "$basename --- Camera serialNumber: " $xx.root.device.serialNumber

            $CameraUrl = $xx.root.device.presentationURL

            # Test ...
            #Invoke-WebRequest -UseBasicParsing -Uri $env:CameraUrl

            Write-Host "$basename --- Testing - Rebooting Camera ..."
            $CameraUrlReboot = $CameraUrl + "axis-cgi/restart.cgi"
            Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlReboot"
            if ($?) {
                Write-Host "$basename --- Camera reboot successful ... Proceed to additional configuration"
                $CameraUrlJpg = $CameraUrl + "jpg/image.jpg"
                Invoke-WebRequest -Credential $cred -Uri $CameraUrlJpg -OutFile "e:\images\image.jpg"

                Write-Host "$basename --- Camera Config - Get server report"
                $CameraUrlSrvRpt = $CameraUrl + "axis-cgi/serverreport.cgi"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlSrvRpt"

                Write-Host "$basename --- Camera Config - List all params in Network group"
                $CameraUrlCfg = $CameraUrl + "axis-cgi/param.cgi?action=list&group=Network"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlCfg"

                Write-Host "$basename --- Camera Config - Set network services ..."
                $CameraUrlFtp = $CameraUrl + "axis-cgi/param.cgi?action=update&root.Network.FTP.Enabled=no"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlFtp"

                $CameraUrlSsh = $CameraUrl + "axis-cgi/param.cgi?action=update&root.Network.SSH.Enabled=no"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlSsh"

                $CameraUrlIpV6 = $CameraUrl + "axis-cgi/param.cgi?action=update&root.Network.IPv6.Enabled=yes"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlIpV6"
                #Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$env:CameraUrl/axis-cgi/param.cgi?action=update&root.Properties.HTTPS.HTTPS=yes"

                Write-Host "$basename --- Camera Config - Set time"
                $CameraUrlTime1 = $CameraUrl + "axis-cgi/param.cgi?action=update&Time.ObtainFromDHCP=no"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlTime1"

                $CameraUrlTime2 = $CameraUrl + "axis-cgi/param.cgi?action=update&Time.SyncSource=NTP"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlTime2"

                $CameraUrlTime3 = $CameraUrl + "axis-cgi/param.cgi?action=update&Time.DST.Enabled=no"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlTime3"

                $CameraUrlTime4 = $CameraUrl + "axis-cgi/param.cgi?action=update&Time.POSIXTimeZone=CST-8"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlTime4"

                $CameraUrlTime5 = $CameraUrl + "axis-cgi/param.cgi?action=update&Time.NTP.Server=hk.pool.ntp.org"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlTime5"

                #Write-Host "$basename --- Camera Config - Enable and configure https"
                #Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrl/axis-cgi/param.cgi?action=update&HTTPS.AllowSSLV3=no"
                #Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrl/axis-cgi/param.cgi?action=update&HTTPS.Ciphers=AES256-SHA:AES128-SHA:DES-CBC3-SHA"
                #Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrl/axis-cgi/param.cgi?action=update&HTTPS.Enabled=yes"
                #Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrl/axis-cgi/param.cgi?action=update&HTTPS.Port=443"

                Write-Host "$basename --- Camera Config - set image text overlay"
                $CameraUrlOverlay = $CameraUrl + "axis-cgi/param.cgi?action=update&Image.I0.Text.BGColor=black"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlOverlay"

                $CameraUrlOverlay = $CameraUrl + "axis-cgi/param.cgi?action=update&Image.I0.Text.ClockEnabled=yes"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlOverlay"

                $CameraUrlOverlay = $CameraUrl + "axis-cgi/param.cgi?action=update&Image.I0.Text.Color=white"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlOverlay"

                $CameraUrlOverlay = $CameraUrl + "axis-cgi/param.cgi?action=update&Image.I0.Text.DateEnabled=yes"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlOverlay"

                $CameraUrlOverlay = $CameraUrl + "axis-cgi/param.cgi?action=update&Image.I0.Text.Position=top"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlOverlay"

                $CameraUrlOverlay = $CameraUrl + "axis-cgi/param.cgi?action=update&Image.I0.Text.String=$env:COMPUTERNAME"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlOverlay"

                $CameraUrlOverlay = $CameraUrl + "axis-cgi/param.cgi?action=update&Image.I0.Text.TextEnabled=yes"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlOverlay"

                $CameraUrlOverlay = $CameraUrl + "axis-cgi/param.cgi?action=update&Image.I0.Text.TextSize=small"
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlOverlay"

                # done, now reboot camera
                Invoke-WebRequest -UseBasicParsing -Credential $cred -Uri "$CameraUrlReboot"
            }
        } else {
            Write-Host "$basename -- No Axis camera found ... Skipping camera setup" 
        }
    } else {
        Write-Host "$basename -- device detected but not a camera" 
    }
} else {
    Write-Host "$basename -- tools missing, try again later ..." 
}


#--------------------------------------------------------------------
Write-Host "$basename - General Windows Configuration"
#--------------------------------------------------------------------
Write-Host "$basename -- HARDWARE CONFIGURATION"
Write-Host "$basename -- Disable hibernate"
Start-Process 'powercfg.exe' -Verb RunAs -ArgumentList '/h off' -Wait

#power plan type (0=power saver, 1=high performance, 2=balanced)
#powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c fea3413e-7e05-4911-9a71-700331f1c294 245d8541-3943-4422-b025-13a784f679b7 1
#powercfg -setdcvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c fea3413e-7e05-4911-9a71-700331f1c294 245d8541-3943-4422-b025-13a784f679b7 1

# sets the power configuration to High Performance -- does this really work?
#powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

#monitor timeout
#powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
#powercfg -setdcvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0

#multimedia settings (0=take no action, 1=prevent computer from sleeping, 2=enable away mode)
#powercfg -setacvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 2
#powercfg -setdcvalueindex 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 2

## SAMPLE ...
#$RegistryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
#$Name = "NoLockScreen"
#$value = "1"
#
#if(!(Test-Path $registryPath)) {
#	New-Item -Path $RegistryPath -Force | Out-Null
#	New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
# }
#else {
#		New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
#        }
#
#Get-ItemProperty $RegistryPath

# --------------------------------------------------------------------------------------------
Write-Host "$basename - SOFTWARE CONFIGURATION"
# --------------------------------------------------------------------------------------------

# Write-Host "$basename -- Update boot screen"
# & "$Env:local\bin\BootUpdCmd20.exe" "$Env:local\etc\build\lockerlife-boot-custom.bs7"

Write-Host "$basename -- Hide boot"
Start-Process 'bcdedit.exe' -Verb RunAs -ArgumentList '/set bootux disabled' -Wait -Passthru

Write-Host "$basename -- disable boot startup repair mode for current mode"
Start-Process "bcdedit.exe" -Verb RunAs -ArgumentList "/set {current} bootstatuspolicy ignoreallfailures" -Wait

Write-Host "$basename -- Set Boot startup repair mode as disabled as default"
# undo: bcdedit /deletevalue {current} bootstatuspolicy
Start-Process 'bcdedit.exe' -Verb RunAs -ArgumentList '/set {default} recoveryenabled No' -Wait
Start-Process 'bcdedit.exe' -Verb RunAs -ArgumentList '/set {default} bootstatuspolicy ignoreallfailures' -Wait


### Disable memory dumps (system crashes, BSOD)
Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 0
Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "LogEvent" -Value 0
Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "SendAlert" -Value 0
Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "AutoReboot" -Value 1

# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Configure Windows Time Services"
# stop windows time service
Stop-Service w32time

# Get existing type, run the following command and look for Type
#Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters"
(Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name NtpServer).NtpServer
# Get NTP server status
# Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer"
# Enable NTP
reg add "HKLM\system\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer" /v Enabled /t REG_DWORD /d 0x1 /f

Write-Host "$basename -- Set Time Zone"
tzutil.exe /s "China Standard Time"
w32tm.exe /tz
Write-Host "$basename -- Set Nearby NTP Servers"
& "$Env:SystemRoot\System32\w32tm.exe" /config /reliable:YES /syncfromflags:manual /manualpeerlist:"stdtime.gov.hk 0.asia.pool.ntp.org 3.asia.pool.ntp.org"
w32tm.exe /resync /rediscover /nowait
Start-Service w32time
Set-Service -Name w32time -StartupType Automatic -Status Running
w32tm.exe /query /status /verbose

Write-Host "$basename -- Set Language and Region"
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sLanguage -Value ENU
Set-ItemProperty -Path "HKCU:\Control Panel\International\Geo" -Name Nation -Value 104

Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value 506

# Disable Location Tracking
#Write-Host "$basename - Disabling Location Tracking..."
Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" -Name "SensorPermissionState" -Value 0
Set-RegistryKey -Path "HKLM:\System\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0

# group policy enable debug log
# The resulting log file “gpsvc.log” can be found $env:WINDIR\debug\usermode
#Set-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Diagnostics" -Name GPSvcDebugLevel -Value "00030002" 


Write-Host "$basename -- Set Sound Volume to minimum"
$obj = new-object -com wscript.shell
$obj.SendKeys([char]173)

#  Disable user from enabling the startup sound

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name DisableStartupSound -Value 1
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupSound /t REG_DWORD /d 1 /f

# Somehow setting DisableStartupSound = 0 here actually disables the sound
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" -Name DisableStartupSound -Value 0
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v DisableStartupSound /t REG_DWORD /d 0 /f

# And finally, change the sound scheme to No Sound:
# Set the sound scheme to No Sound
# reg add "HKCU\AppEvents\Schemes" /t REG_SZ /d ".None" /f 2>nul >nul

Write-Host "$basename -- Set File Associations"
Install-ChocolateyFileAssociation ".err" "${Env:SystemRoot}\System32\notepad.exe"

Write-Host "$basename - Before login ..."
Write-Host "$basename - set logon UI Background image"
# enable custom logon background
#HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background" -Name OEMBackground -Value 1 -Force
WriteInfoHighlighted "."

# Disable Welcome logon screen & require CTRL+ALT+DEL
reg ADD "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v LogonType /t REG_DWORD /d 0 /f
reg ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableCAD /t REG_DWORD /d 0 /f

# Interactive logon: Do not display last user name
reg ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v dontdisplaylastusername /t REG_DWORD /d 1 /f

# suppress errors (production) - need watchdog
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Windows" /v ErrorMode /t REG_DWORD /d 2 /f

### Set PopUp Error Mode to "Neither"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Windows" -Name ErrorMode -Value 2
# REG add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v DontShowUI /t REG_DWORD /d 1 /f

# Disable Error Reporting
# Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PCHealth\ErrorReporting" -Name "DoReport" -Value 0 -Force

# Turn off Windows SideShow
#Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Sideshow" -Name "Disabled" -Value 1
reg ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Slideshow" /v Disabled /d 1 /f

New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Network\NewNetworkWindowOff" -Force

# --------------------------------------------------------------------
Write-Host "$basename - After login ..."
# --------------------------------------------------------------------
New-Item -ItemType File "C:\local\bin\autologon.bat" -Force

# Windows Explorer Settings through Choco
#Set-WindowsExplorerOptions -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess
Set-TaskbarOptions -Size Small -Lock -Combine Full -Dock Bottom

# Disable All Balloon Tips
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name 'EnableBalloonTips' -Value 0
reg ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v EnableBalloonTips /t REG_DWORD /d 0 /f
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoSMBalloonTip" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name 'FolderContentsInfoTip' -Value 0
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "tips" -Force
Set-RegistryKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\tips" -Name "Show" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\tips" -Name 'Show' -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name 'StartButtonBalloonTip' -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name 'ShowInfoTip' -Value 0

# Disable Getting Started Welcome Screen at Logon
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoWelcomeScreen" -Value 1


# disable language bar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoSaveSettings" -Value 0


Write-Host "$basename --  Adjust UI for Best Performance"
reg LOAD "hku\temp" "$env:USERPROFILE\..\Default User\NTUSER.DAT"
reg ADD "HKEY_USERS\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f
# Set-ItemProperty -Path "HKEY_USERS:\.DEFAULT\Control Panel\Colors" -Name Background -Value "0 0 0" -Force

reg UNLOAD "hku\temp"

# Force Classic Control Panel
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v ForceClassicControlPanel /d 1 /f
# do not highlight newly installed programs
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Advanced" /v Start_NotifyNewApps /d 0 /f

# --------------------------------------------------------------------
WriteInfo "$basename --- Setup Default User Registry"
$defaultUserHivePath = $env:SystemDrive + "\Users\Default\NTUSER.DAT"
$userLoadPath = "HKU\TempUser"

# Load Default User Registry Hive
reg load $userLoadPath $defaultUserHivePath | Out-Host
# Create PSDrive
$psDrive = New-PSDrive -Name HKUDefaultUser -PSProvider Registry -Root $userLoadPath

#Set-ItemProperty -Path "HKUDefaultUser:\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name 'VisualFXSetting' -Value 2

# Reduce menu show delay
Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0

# Disable cursor blink
Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Desktop" -Name "CursorBlinkRate" -Value "-1"
Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Desktop" -Name "DisableCursorBlink" -Value 1

# do not highlight newly installed programs
#Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_NotifyNewApps" -Value 0

# force classic control panel 
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ForceClassicControlPanel" -Value 1

# Force off-screen composition in IE
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Internet Explorer\Main" -Name "Force Offscreen Composition" -Value 1

# Disable screensavers
# Set-ItemProperty -Path "HKUDefaultUser:\Software\Policies\Microsoft\Windows\Control Panel\Desktop" -Name "ScreenSaveActive" -Value 0
# Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Desktop\" -Name "ScreenSaveActive" -Value 0
# Set-ItemProperty -Path "Registry::\HKEY_USERS\.DEFAULT\Control Panel\Desktop" -Name "ScreenSaveActive" -Value 0

# Don't show window contents when dragging
Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Desktop" -Name "DragFullWindows" -Value 0

# Don't show window minimize/maximize animations
Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 0

# Disable font smoothing
Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Desktop" -Name "FontSmoothing" -Value 0
Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Desktop" -Name "FontSmoothingType" -Value 2

# Disable most other visual effects
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewAlphaSelect" -Value 0
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAnimations" -Value 0
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewWatermark" -Value 0
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value 0
Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x01,0x80))
Set-ItemProperty -Path "HKUDefaultUser:\Control Panel\Colors" -Name "Background" -Value "0 0 0"

# Don't cache thumbnails
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisableThumbnailCache" -Value 1

# Disable Action Center Icon
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAHealth" -Value 1

# Disable Network Icon
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCANetwork" -Value 1

# Disable IE Persistent Cache
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "MaxConnectionsPer1_0Server" -Value 0
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Feeds" -Name "SyncStatus" -Value 0

# Set Internet Explorer's Simultaneous Downloads From 2 to 10 Connections
Set-ItemProperty -Path "HKUDefaultUser:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Cache" -Name "Persistent" -Value 0


# Remove PSDrive
$psDrive = Remove-PSDrive HKUDefaultUser

# # Clean up references not in use
# $variables = Get-Variable | Where { $_.Name -ne "userLoadPath" } | foreach { $_.Name }
# foreach($var in $variables) {
#     Remove-Variable $var 
# }
[gc]::collect()
# Unload Hive
REG unload $userLoadPath | Out-Host


Write-Host "$basename - Set UI to Classic Theme"
#& "$Env:SystemRoot\System32\rundll32.exe" "$Env:SystemRoot\system32\shell32.dll,Control_RunDLL" "$Env:SystemRoot\system32\desk.cpl" desk,@Themes /Action:OpenTheme /file:"$Env:SystemRoot\Resources\Ease of Access Themes\classic.theme"
Start-Process -Wait -FilePath "rundll32.exe" -ArgumentList "$env:SystemRoot\system32\shell32.dll,Control_RunDLL $env:SystemRoot\system32\desk.cpl desk,@Themes /Action:OpenTheme /file:""C:\Windows\Resources\Ease of Access Themes\classic.theme"""
# close Personalization window ...

(New-Object -ComObject Shell.Application).Windows() | Where-Object { $_.LocationName -eq "Personalization" } | ForEach-Object { $_.quit() }
(New-Object -ComObject Shell.Application).Windows() | Where-Object { $_.LocationName -eq "Personalization" } | ForEach-Object { $_.quit() }
(New-Object -ComObject Shell.Application).Windows() | Where-Object { $_.LocationName -eq "Personalization" } | ForEach-Object { $_.quit() }
(New-Object -comObject Shell.Application).Windows() | Where-Object {$_.LocationName -eq "Control Panel"} | ForEach-Object {$_.quit()}


Write-Host "$basename - Set Desktop Background to solid colors"
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies" -Name System -Force
#Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value "" -Force
#New-Item -Path "HKEY_USERS:\.DEFAULT\Control Panel\Desktop" -Name Wallpaper
#Set-ItemProperty -Path "HKEY_USERS:\.DEFAULT\Control Panel\Desktop" -Name Wallpaper -Value "" -Force

Write-Host "$basename - Set Desktop Background color"
Set-ItemProperty "HKCU:\Control Panel\Colors" -Name Background -Value "0 0 0" -Force

#Write-Host "$basename -- Set Desktop Wallpaper"
#Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name Wallpaper -Value "C:\local\etc\pantone-process-black-c.jpg" -Force
#Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name Wallpaper -Value "" -Force
#Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name WallpaperStyle -Value 2 -Force

#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$Env:SystemRoot\Web\Wallpaper\YOUR_FILE.bmp" /f
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d "2" /f
#REG ADD "hku\.DEFAULT\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d "0" /f

# Disable Lock screen
#Write-Host "$basename -- Disabling Lock screen..."
#If (!(Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization")) {
#    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -ErrorAction SilentlyContinue
#}
#Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen" -Type DWord -Value 1

# Enable Lock screen
# Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Personalization" -Name "NoLockScreen"

WriteInfo "$basename - Set lock screen background image"
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows" -Name Personalization -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" -Name "LockScreenImage" -Value "C:\local\etc\pantone-process-black-c.jpg" -Force

#Set the Screen Saver Settings
#REG ADD "HKU\.DEFAULT\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 1 /f
#reg add "HKU\.DEFAULT\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 1 /f
#reg add "HKU\.DEFAULT\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d 900 /f
#reg add "HKU\.DEFAULT\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d "$env:SystemRoot\System32\YOUR_FILE.scr" /f


#[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation] "DisableStartupSound"=dword:00000001
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" /v DisableStartupSound /t REG_DWORD /d 1 /f
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\BootAnimation" "DisableStartupSound" 1 -Force
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupSound /t REG_DWORD /d 1 /f
Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DisableStartupSound" 1 -Force

# Do Not Highlight newly installed programs
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_NotifyNewApps /t reg_dword /d 0 /f
#--------------------------------------------------------------------
# Enable Action Center
# Remove-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter"
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled"

# Disable Action Center
Write-Host "$basename - Disabling Action Center..."
If (!(Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) {
    New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" | Out-Null
}

Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0


# --------------------------------------------------------------------
# Enable Autoplay
# Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 0

# Disable Autoplay
Write-Host "$basename - Disabling Autoplay..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Type DWord -Value 1

#--------------------------------------------------------------------
# Disable Autorun for all drives
Write-Host "$basename - Disabling Autorun for all drives..."
If (!(Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Type DWord -Value 255

# Enable Autorun for all drives
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun"

#--------------------------------------------------------------------
# Disable Sticky keys prompt
Write-Host "$basename - Disabling Sticky keys prompt..."
Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name Flags -Type String -Value 506 -Force

# Enable Sticky keys prompt
# Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Type String -Value "510"

#--------------------------------------------------------------------
# Hide Search button / box
#Write-Host "$basename - Hiding Search Box / Button..."
#Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type DWord -Value 0 -Force

# Show Search button / box
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode"

#--------------------------------------------------------------------
# Hide Task View button
Write-Host "$basename - Hiding Task View button..."
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type DWord -Value 0 -Force

# Show Task View button
# Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton"

#--------------------------------------------------------------------
# Show large icons in taskbar
#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons"

# Show small icons in taskbar
Write-Host "$basename - Showing small icons in taskbar ..."
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarSmallIcons" -Type DWord -Value 1 -Force

# ;Adjust the system tray icons – 0 = Display inactive tray icons
#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer]
#“EnableAutoTray”=dword:00000000

# ;Clear Most Frequently Used items
#[-HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\{75048700-EF1F-11D0-9888-006097DEACF9}]
#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\{75048700-EF1F-11D0-9888-006097DEACF9}]
#@=""

# ;Show/Hide desktop icons
#; Internet Explorer = {871C5380-42A0-1069-A2EA-08002B30309D}
#; User’s Files = {450D8FBA-AD25-11D0-98A8-0800361B1103}
#; Network = {208D2C60-3AEA-1069-A2D7-08002B30309D}

# ; 0 = Display
# ; 1 = Hide

#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons]
#[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel]
#“{871C5380-42A0-1069-A2EA-08002B30309D}”=dword:00000001
#“{450D8FBA-AD25-11D0-98A8-0800361B1103}”=dword:00000000
#“{20D04FE0-3AEA-1069-A2D8-08002B30309D}”=dword:00000000
#“{208D2C60-3AEA-1069-A2D7-08002B30309D}”=dword:00000000


# --------------------------------------------------------------------
# Hide Computer shortcut from desktop
#   ; Computer = {20D04FE0-3AEA-1069-A2D8-08002B30309D}
#Remove-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"

#Remove-ItemProperty -Path "[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel]" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
#Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"

# --------------------------------------------------------------------
# Remove Desktop icon from computer namespace
#Write-Host "Removing Desktop icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" -Recurse

# Add Desktop icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"


# --------------------------------------------------------------------
# Remove Documents icon from computer namespace
#Write-Host "$basename - Removing Documents icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" -Recurse
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" -Recurse

# Add Documents icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}"


# --------------------------------------------------------------------
# Remove Downloads icon from computer namespace
#Write-Host "Removing Downloads icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" -Recurse
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" -Recurse


# Add Downloads icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}"

#--------------------------------------------------------------------
# Remove Music icon from computer namespace
#Write-Host "$basename -- Removing Music icon from computer namespace..."
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" -Recurse
#Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" -Recurse


# Add Music icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}"


#--------------------------------------------------------------------
# Remove Pictures icon from computer namespace
# Write-Host "$basename -- Removing Pictures icon from computer namespace..."
# Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" -Recurse
# Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" -Recurse

# Add Pictures icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}"

#--------------------------------------------------------------------
# Remove Videos icon from computer namespace
# Write-Host "$basename -- Removing Videos icon from computer namespace..."
# Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" -Recurse -ErrorAction SilentlyContinue
# Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" -Recurse -ErrorAction SilentlyContinue

# Add Videos icon to computer namespace
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}"
# New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}"

#--------------------------------------------------------------------
# shorten shutdown wait time - WaitToKillServiceTimeout
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control" /v Start /t REG_DWORD /d 4 /f
Set-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "Start" -Value 4

# --------------------------------------------------------------------
# Internet Explorer customizations ...
REG ADD "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Internet Explorer\Main" /v DisableFirstRunCustomize /t REG_DWORD /d 1 /f
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\Main" /v "Start Page" /t REG_SZ /d "http://lockerlife.hk/deploy" /f

#--------------------------------------------------------------------
Write-Host "$basename -- Windows Networking Configuration"

Write-Host "$basename -- speed up network copies"
& "$Env:SystemRoot\System32\netsh.exe" int tcp set glocal autotuninglevel=disabled

Write-Host "$basename -- disable the network location prompt"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\NetworkList\Signatures\FirstNetwork" /v Category /t REG_DWORD /d 00000001 /f

Write-Host "$basename -- disable netbios"
wmic nicconfig where TcpipNetbiosOptions=0 call SetTcpipNetbios 2
wmic nicconfig where TcpipNetbiosOptions=1 call SetTcpipNetbios 2

## Windows Firewall
WriteInfoHighlighted "$basename -- Configure Windows Firewall"
WriteInfoHighlighted "$basename -- turn on firewall"
& "$Env:SystemRoot\System32\netsh.exe"  advfirewall set allprofiles state on

## QUERY FIREWALL RULES
#& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall show rule name=all

## set logging
& "$Env:SystemRoot\System32\netsh.exe" advfirewall set currentprofile logging filename "e:\logs\firewall-cur.log"
& "$Env:SystemRoot\System32\netsh.exe" advfirewall set allprofiles logging filename "e:\logs\firewall-all.log"

## set applications
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Allow Java" dir=in action=allow program="D:\java\jre\java.exe"
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Allow Kioskserver" dir=in action=allow program="D:\kioskserver\kioskserver.exe"
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall set rule group="Remote Desktop" new enable=Yes

## set rulesets
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Open Port 23" dir=in action=allow protocol=TCP localport=23
#netsh advfirewall firewall delete rule name="Open Server Port 23" protocol=tcp localport=23
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Open Port 8080" dir=in action=allow protocol=TCP localport=8080
#netsh advfirewall firewall delete rule name="Open Server Port 8080" protocol=tcp localport=8080
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Open Port 8081" dir=in action=allow protocol=TCP localport=8081
#netsh advfirewall firewall delete rule name="Open Server Port 8081" protocol=tcp localport=8081
& "$Env:SystemRoot\System32\netsh.exe" advfirewall firewall add rule name="Open Port 9012" dir=in action=allow protocol=TCP localport=9012


# --------------------------------------------------------------------------------------------
# Enable Remote Desktop for locker deployment
# REG ADD "HKLM\System\Currentcontrolset\control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
# Allow connections from computers running any version of Remote Desktop (less secure)
# REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f

## Disable Remote Assistance
#Write-Host "$basename - Disabling Remote Assistance..."
#Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0
#

# --------------------------------------------------------------------------------------------
# Disable Remote Assistance
Write-Host "$basename -- Disabling Remote Assistance..."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Type DWord -Value 0 -Force


#--------------------------------------------------------------------
Write-Host "$basename - Make some directories"
#--------------------------------------------------------------------

# important directories - create directories as early as possible ...
"E:\images\archive","$Env:SystemRoot\System32\oobe\info\backgrounds","$env:local\status","$env:local\lib","$env:local\logs","$env:local\src","$env:local\gpo","$env:local\etc","$Env:local\drivers","$Env:local\bin","$Env:imagesarchive","$Env:images","~\Documents\WindowsPowerShell","~\Desktop\LockerDeployment","~\Documents\PSConfiguration","D:\locker-libs","$Env:_tmp","$Env:logs" | ForEach-Object {
    if (!( Test-Path "$_" )) {
        New-Item -ItemType Directory -Path "$_"
    }
} # ForEach-Object ...

# --------------------------------------------------------------------------------------------
Write-Host "$basename - Make some Files"
# --------------------------------------------------------------------------------------------

"~\Documents\PSConfiguration\Microsoft.PowerShell_profile.ps1" | ForEach-Object {
    #New-Item -Path "~\Documents\PSConfiguration\Microsoft.PowerShell_profile.ps1" -ItemType File | Out-Null
    if (!( Test-Path "$_" )) {
        New-Item -ItemType File -Path "$_" -Force 
    }
} # ForEach-Object ...

# --------------------------------------------------------------------------------------------
Write-Host "$basename - Get some basic tools"
# --------------------------------------------------------------------------------------------

$downloadList = @(
    "new-service-core.bat",
    "new-service-datacollection.bat",
    "new-service-kioskserver.bat",
    "new-service-scanner.bat",
    "makecert.exe",
    "pvk2pfx.exe",
    "mailsend.exe",
    "Bginfo.exe",
    "Autologon.exe",
    "curl.exe",
    "speedtest-cli.exe",
    "devcon.exe",
    "hstart.exe",
    "nircmd.exe",
    "nircmdc.exe",
    "nssm.exe",
    "sendEmail.exe",
    "UPnPScan.exe",
    "du.exe",
    "LGPO.exe",
    "BootUpdCmd20.exe",
    "psexec.exe"
)
ForEach ($downloadTools in $downloadList) {
    # better if we used Get-FileHash to check, but no time to write good code ...
    if (!(Test-Path "$env:local\bin\$downloadTools")) {
        Invoke-WebRequest -Method Get -Uri "http://lockerlife.hk/deploy/bin/$downloadTools" -OutFile "$env:local\bin\$downloadTools" -Verbose
    } else {
        Write-Host "$basename -- Skipping $downloadTools" 
    }
}
#commit the downloaded files


Write-Host "$basename -- GAC Update ..."
Invoke-WebRequest -Uri "https://msdnshared.blob.core.windows.net/media/MSDNBlogsFS/prod.evol.blogs.msdn.com/CommunityServer.Components.PostAttachments/00/08/92/01/09/update-Gac.ps1" -Outfile "$Env:local\bin\update-Gac.ps1"

Write-Host "$basename -- Download System Settings Files ..."
"2017-01-gpo.zip","kiosk-production-black.bgi","lockerlife-boot.bs7","lockerlife-boot-custom.bs7","pantone-classic-blue.bmp","pantone-classic-blue.jpg","pantone-process-black-c.bmp","pantone-process-black-c.jpg","production-admin.bgi","production-kiosk.bgi","PRODUCTION-201701-TEAMVIEWER-HOST.reg","production-gpo.zip" | ForEach-Object {
    # better if we used Get-FileHash, but no time to write good code ...
    if (!(Test-Path "$env:local\etc\$_")) {
        Invoke-WebRequest -Method Get -Uri "http://lockerlife.hk/deploy/etc/$_" -OutFile "$env:local\etc\$_" -Verbose
    } else {
        WriteInfoHighlighted "$basename -- Skipping $_" 
    }
} # ForEach-Object ...

"WASP.dll" | ForEach-Object {
    # better if we used Get-FileHash, but no time to write good code ...
    if (!(Test-Path "$_")) {
        #Start-BitsTransfer -Source "http://lockerlife.hk/deploy/lib/$_" -Destination "$env:local\lib\$_" -DisplayName "LockerLifeLocalLib" -Description "Download LockerLife Local Libraries $_" -TransferType Download -RetryInterval 60
        Invoke-WebRequest -Method Get -Uri "http://lockerlife.hk/deploy/lib/$_" -OutFile "$env:local\lib\$_" -Verbose
    } else {
        WriteInfoHighlighted "$basename -- Skipping $_" 
    }
} # ForEach-Object

Write-Host "$basename -- Download Installers ..."
"jre-8u111-windows-i586.exe","jre-install.properties","Windows6.1-KB2889748-x86.msu","402810_intl_i386_zip.exe" | ForEach-Object {
    # better if we used Get-FileHash, but no time to write good code ...
    if (!(Test-Path "$_")) {
        Start-BitsTransfer -Source "http://lockerlife.hk/deploy/_pkg/$_" -Destination "$Env:_tmp\$_" -DisplayName "LockerLifeInstaller" -Description "Download LockerLife Installer $_" -TransferType Download -RetryInterval 60
    } else {
        WriteInfoHighlighted "$basename -- Skipping $_" 
    }
}
# commit the downloaded files
Get-BitsTransfer | Complete-BitsTransfer


Write-Host "$basename -- Download DRIVERS ..."
"printer.zip","printer-filter.zip","printer-test.zip" | ForEach-Object {
    # better if we used Get-FileHash, but no time to write good code ...
    if (!(Test-Path "$_")) {
        Start-BitsTransfer -Source "http://lockerlife.hk/deploy/drivers/$_" -Destination "c:\local\drivers\$_" -DisplayName "LockerLifeInstaller" -Description "Download LockerLife System Drivers $_" -TransferType Download -RetryInterval 60
    } else {
        WriteInfoHighlighted "$basename -- Skipping $_" 
    }
}
# commit the downloaded files
Get-BitsTransfer | Complete-BitsTransfer


# fix if vm
if (Test-Path "C:\Wallpaper") {
    Copy-Item -Path "C:\Wallpaper\autologon.bat" -Destination "C:\Wallpaper\autologon2.bat" -Force
    Copy-Item -Path "C:\autoexec.bat" -Destination "C:\Wallpaper\autologon.bat" -Force
}

# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Disable Windows Services"
# --------------------------------------------------------------------------------------------

#"ShellHWDetection", # Shell Hardware Detection
#"SNMPTRAP", # SNMP Trap
#"SysMain", # Superfetch

$disableServices = @(
    "SensrSvc", # Adaptive Brightness
    "ALG", # Application Layer Gateway Service
    "BDESVC", # BitLocker Drive Encryption Service
    "wbengine", # Block Level Backup Engine Service
    "bthserv", # Bluetooth Support Service
    "PeerDistSvc", # BranchCache
    "Browser", # Computer Browser
    "UxSms", # Desktop Window Manager Session Manager - Disable only if Aero not necessary
    "DPS", # Diagnostic Policy Service
    "WdiServiceHost", # Diagnostic Service Host
    "WdiSystemHost", # Diagnostic System Host
    "TrkWks", # Distributed Link Tracking Client
    "EFS", # Encrypting File System (EFS)
    "Fax", # Fax - Not present in Windows 7 Enterprise
    "fdPHost", # Function Discovery Provider Host
    "FDResPub", # Function Discovery Resource Publication
    "HomeGroupListener", # HomeGroup Listener - Not present in Windows 7 Enterprise
    "HomeGroupProvider", # HomeGroup Provider
    "UI0Detect", # Interactive Services Detection
    "iphlpsvc", # IP Helper
    "Mcx2Svc", # Media Center Extender Service
    "MSiSCSI", # Microsoft iSCSI Initiator Service
    "netprofm", # Network List Service
    "NlaSvc", # Network Location Awareness
    "CscService", # Offline Files
    "WPCSvc", # Parental Controls
    "wercplsupport", # Problem Reports and Solutions Control Panel Support
    "SstpSvc", # Secure Socket Tunneling Protocol Service
    "wscsvc", # Security Center
    "SSDPSRV", # SSDP Discovery
    "TapiSrv", # Telephony
    "Themes", # Themes - Disable only if you want to run in Classic interface
    "SDRSVC", # Windows Backup
    "WcsPlugInService", # Windows Color System
    "wcncsvc", # Windows Connect Now - Config Registrar
    "WerSvc", # Windows Error Reporting Service
    "ehRecvr", # Windows Media Center Receiver Service
    "ehSched", # Windows Media Center Scheduler Service
    "WMPNetworkSvc", # Windows Media Player Network Sharing Service
    "WSearch", # Windows Search
    "idsvc", # Windows CardSpace Service
    "vmictimesync",
    "vmicvss",
    "vmickvpexchange",
    "vmicshutdown",
    "upnphost", # UPnP Device Host
    "vmicheartbeat"
)
foreach ($service in $disableServices) {
    if (Get-Service $service -ErrorAction SilentlyContinue) {
        Stop-Service -Name $service -Force
        # sc.exe config $service start= disabled
        # Start-Process "C:\Windows\system32\sc.exe" -ArgumentList "config SensrSvc start= disabled" -PassThru -NoNewWindow -Wait
        Set-Service -Name $service -StartupType Disabled
    }
}

# --------------------------------------------------------------------------------------------
Write-Host "$basename - Disable built-in scheduled tasks we do not need"
# --------------------------------------------------------------------------------------------
$tasksToDisable = @(
    "microsoft\windows\Maintenance\WinSAT",
    "microsoft\windows\Ras\MobilityManager",
    "microsoft\windows\SideShow\AutoWake",
    "microsoft\windows\SideShow\GadgetManager",
    "microsoft\windows\SideShow\SessionAgent",
    "microsoft\windows\SideShow\SystemDataProviders",
    "microsoft\windows\Windows Media Sharing\UpdateLibrary"
)
foreach ($task in $tasksToDisable) {
    schtasks.exe /change /tn $task /Disable
    Start-Sleep -Seconds 2
}

# --------------------------------------------------------------------------------------------
Write-Host "$basename -- LockerLife Scheduled Tasks"

# run system health report every day at 11pm
#SCHTASKS /Create /SC weekly /D MON,TUE,WED,THU,FRI /TN MyDailyBackup /ST 23:00 /TR c:\local\bin\scheduled\health-report.cmd /RU taskbot /RP TaskBotPassW0rd


# --------------------------------------------------------------------------------------------
Write-Host "$basename - Manage System User Accounts (no lockerlife accounts)"
# --------------------------------------------------------------------------------------------

# Unpin from taskbar
#Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Windows Media Player.lnk"

WriteInfoHighlighted "$basename - DISABLE GUEST USER"
# https://technet.microsoft.com/en-us/library/ff687018.aspx
net.exe user guest /active:no

WinSAT.exe -v forgethistory

Write-Host "$basename -- Enable Administrator"
net.exe USER Administrator /active:yes
net.exe USER Administrator Locision123
#net user administrator /active:no

if (Get-CimInstance win32_useraccount | where { $_.Name -eq "AAICON" }) {
    #$U = Get-WmiObject -class Win32_UserAccount | where { $_.Name -eq "AAICON" }
    WriteInfo "$basename -- AAICON user exists"
    WriteInfoHighlighted "$basename -- force Update AAICON Password ..."
    net user AAICON Locision123
} else {
    Write-Host "$basename -- fixing AAICON user account ..."
    #Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user AAICON Locision123' -NoNewWindow
    #& "c:\local\bin\autologon.exe" AAICON Locision123
    #[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
    #"AutoAdminLogon"="1"
    #"DefaultUserName"="admnistrator"
    #"DefaultPassword"="P@$$w0rd"
    #"DefaultDomainName"="contoso"
    #Start-ChocolateyProcessAsAdmin -statements $args -exeToRun $vcdmount
    net.exe user AAICON Locision123
    net.exe user AAICON Locision123 /add /expires:never /passwordchg:no
    
}

# add taskbot account
if (!(Get-CimInstance win32_useraccount | where { $_.Name -eq "taskbot" })) {

    #Start-Process "$Env:SystemRoot\System32\net.exe" -ArgumentList 'user /add kiosk locision123 /active:yes /comment:"LockerLife Kiosk" /fullname:"LockerLife Kiosk" /passwordchg:no' -NoNewWindow
    & net.exe user /add taskbot TaskBotPassW0rd /active:yes /comment:"Sweep sweep" /fullname:"Cleaning Robot" /passwordchg:no /Y
    net.exe user /add taskbot TaskBotPassW0rd /active:yes /comment:"Sweep sweep" /fullname:"Cleaning Robot" /passwordchg:no /Y

    # create profile for taskbot

    # do not let taskbot interactive login because he is only background use
    #reg add new key HKEY_LOCAL_MACHINE\Software\Microsoft\WindowsNT\CurrentVersion\Winlogon /v SpecialAccounts
    # reg add new key HKEY_LOCAL_MACHINE\Software\Microsoft\WindowsNT\CurrentVersion\Winlogon /v UserList /t REG_DWORD
    #HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList


    $taskbotUser = "taskbot"
    $taskbotPass = ConvertTo-SecureString -String "TaskBotPassW0rd" -AsPlainText -Force

    # just use $cred ...
    $taskbotCred = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList "$taskbotUser, $taskbotPass"

    # [] auto create user profile (super quick, super dirty!)
    # redundant because user profile creation isn't always guranteed ...
    Write-Host "$basename -- Create taskbot user profile"
    #Start-Process -Credential $taskbotCred cmd.exe -ArgumentList "/c dir"
    #Start-Process -Credential $taskbotCred -LoadUserProfile cmd.exe -ArgumentList "/c dir"
    Invoke-Expression "psexec -accepteula -nobanner -u taskbot -p TaskBotPassW0rd cmd /c dir"
}


# Change LogonUI wallpaper
Copy-Item "$Env:local\etc\pantone-process-black-c.jpg" -Destination "$Env:SystemRoot\System32\oobe\info\backgrounds\logon-background-black.jpg" -Force | Out-Null
Copy-Item "$env:local\etc\pantone-process-black-c.jpg" -Destination "$Env:SystemRoot\System32\oobe\info\backgrounds\backgroundDefault.jpg" -Force | Out-Null
#Copy-Item "$env:local\etc\pantone-process-black-c.bmp" -Destination "$Env:SystemRoot\System32\oobe\background.bmp" -Force | Out-Null
#Copy-Item "$env:local\etc\pantone-process-black-c.jpg" -Destination "$Env:SystemRoot\Web\Wallpaper\Windows\img0.jpg" -Force | Out-Null


# --------------------------------------------------------------------------------------------
# Group Policy for Windows Security ...
Write-Host "$basename -- GPO"
Set-Location -Path "$Env:SystemRoot\System32"

# make backup of GroupPolicy directories
#c:\programdata\chocolatey\tools\7za a -t7z "$Env:SystemRoot\System32\GroupPolicy-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicy\"
#c:\programdata\chocolatey\tools\7za a -t7z "$Env:SystemRoot\System32\GroupPolicyUsers-BACKUP.7z" "$Env:SystemRoot\System32\GroupPolicyUsers\"

# Use New-GPO ?
#New-GPO NoDisplay | Set-GPRegistryValue -key “HKCU\Software\Microsoft\Windows\CurrentVersion\Policies \System” -ValueName NoDispCPL -Type DWORD -value 1 | New-GPLink -target “ou=executive,dc=sample,dc=com”

# --------------------------------------------------------------------------------------------

choco feature enable -n=allowGlobalConfirmation

if (Test-Path "C:\ProgramData\chocolatey\bin\choco.exe") {
    # chocolatey already installed .. check for old version pin
    C:\ProgramData\chocolatey\bin\choco.exe pin remove --name chocolatey
}
cinst chocolatey
cinst Boxstarter

choco feature disable -n=allowGlobalConfirmation



Breathe
# --------------------------------------------------------------------------------------------
Write-Host "$basename -- Installing Telnet Client (dism/windowsfeatures)"
cinst TelnetClient -source windowsfeatures

Write-Host "$basename -- Begin -- Remove unnecessary Windows components"
dism /online /disable-feature /featurename:InboxGames /NoRestart
dism /online /disable-feature /featurename:FaxServicesClientPackage /NoRestart
dism /online /disable-feature /featurename:WindowsGadgetPlatform /NoRestart
dism /online /disable-feature /featurename:OpticalMediaDisc /NoRestart
dism /online /disable-feature /featurename:Xps-Foundation-Xps-Viewer /NoRestart
Write-Host "$basename -- End -- Remove unnecessary Windows components"


# --------------------------------------------------------------------------------------------
Write-Host "$basename - Cleanup"
# --------------------------------------------------------------------------------------------
if (Get-Process -Name iexplore -ErrorAction SilentlyContinue) {
    Stop-Process -Name iexplore
}

# Cleanup Desktop
CleanupDesktop
Create-DeploymentLinks
cleanmgr.exe /verylowdisk

# touch $Env:local\status\00-init.done file
# echo date/time into file, add lines ...
New-Item -ItemType File -Path "$env:local\status\$basename.done" -Force | Out-Null

Write-Host "$basename -- Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript


Invoke-RestMethod -Uri "https://api.github.com/zen"
Write-Host "."

Stop-TimedSection $timer

# --------------------------------------------------------------------
Write-Host "$basename - Next stage ..."
# --------------------------------------------------------------------

START http://boxstarter.org/package/url?http://lockerlife.hk/deploy/00-bootstrap.ps1

#$wshell = New-Object -ComObject wscript.shell;
#$wshell.AppActivate('title of the application window')
#Sleep 1
#$wshell.SendKeys('~')
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait('~');

#END OF FILE
