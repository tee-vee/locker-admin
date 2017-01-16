# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 10-configure
#    -- a bootstrapper to perform local identification tasks and setup for locker registration
#       ie. $sitename

# Skipping 10 lines because if running when all prereqs met, statusbar covers powershell output

 1..10 |% { Write-Host ""}

#############
# Functions #
#############
function WriteInfo($message) {
    Write-Host $message
}

function WriteInfoHighlighted($message) {
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

function  Get-WindowsBuildNumber {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return [int]($os.BuildNumber)
}


##############
# Lets start #
##############

# Start Time and Transcript
Start-Transcript -Path "$Env:_tmp\10-configure.log"
$StartDateTime = get-date
WriteInfo "Script started at $StartDateTime"

& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

Disable-UAC
Update-ExecutionPolicy Unrestricted

Install-ChocolateyEnvironmentVariable "iccid" "NULL"
Install-ChocolateyEnvironmentVariable "hostname" "NULL"
Install-ChocolateyEnvironmentVariable "sitename" "NULL"
Install-ChocolateyEnvironmentVariable "logs" "E:\logs"
Install-ChocolateyEnvironmentVariable "images" "E:\images"
Install-ChocolateyEnvironmentVariable "imagesarchive" "E:\images\archive"

Write-Host ""
New-Item -Path "$Env:logs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:images" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -Path "$Env:imagesarchive" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

Write-Host ""
Write-Host ""
Add-Type -AssemblyName Microsoft.VisualBasic
$Env:iccid = [Microsoft.VisualBasic.Interaction]::InputBox('Scan SIM Card', 'LockerLife Locker Deployment', "")

Write-Host ""
Write-Host "$Env:iccid"
Write-Host "$Env:hostname"
Write-Host "$Env:sitename"


# $Env:sitename = & "$Env:curl" -Ss -k --url "https://gist.githubusercontent.com/tee-vee/bfa0ea73871ce47e6436beb88b2b77ac/raw/locker-iccid.db" | findstr "$Env:iccid" | awk '{ print $2 }'
$Env:sitename = & "$Env:curl" -Ss -k --url "https://gist.githubusercontent.com/tee-vee/bfa0ea73871ce47e6436beb88b2b77ac/raw/locker-iccid.db" | Select-String "$Env:iccid" | Out-String | %{ $_.Split(' ')[1]; } | foreach { $_ -replace "`r|`n","" }

Write-Host ""
Write-Host "$Env:iccid"
Write-Host "$Env:hostname"
Write-Host "$Env:sitename"


if (!$Env:sitename) {
    WriteError "This SIM card is not authorized for use with LockerLife Locker Deployment"
    WriteError "Send email to locker-admin@lockerlife.hk for further assistance."
    WriteErrorAndExit "Exiting"
    New-Item -Path C:\DEPLOYMENT-UNAUTHORIZED -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
    ## function call to send error email

} else {
    # --------------------------------------------------------------------------------------------
    # get MAC address for cloud registration
    # REQUIRES: ALL NETWORK PORT MAC ADDRESS (INCLUDING WIRELESS)
    # WARNING: MUST GET NETWORK MAC ADDRESS *BEFORE* DISABLE WIRELESS INTERFACES
    # --------------------------------------------------------------------------------------------

    #WriteInfo "---"
    #WriteInfoHighlighted "GET MAC ADDRESS FOR CLOUD REGISTRATION"
    #Set-Location -Path "$Env:local\src\LOCKER\$Env:sitename"
    #New-Item -Path "$Env:local\src\LOCKER\$Env:sitename\config\tmp" -ItemType Directory -ErrorAction SilentlyContinue
    #& cmd /c mklink getmac-copy.bat "$Env:local\src\build\getmac-copy.bat"
    #mklink combine-locker-properties.bat %LOCKERINSTALL%\build\combine-locker-properties.bat
    #CALL combine-locker-properties.bat
    #move locker.properties.part1 %_tmp%
    #move locker.properties.part2 %_tmp%

    if ($Env:sitename -like 'UFO*')
    {
      # rename as UFO
      Install-ChocolateyEnvironmentVariable "UfoIccid" "NULL"
      $Env:UfoIccid = $Env:iccid.SubString($Env:iccid.Length-5)
      Write-Host "$Env:UfoIccid"
      Rename-Computer -NewName "UFO-$Env:UfoIccid" -Restart
    }
    else
    {
      Uninstall-ChocolateyEnvironmentVariable -VariableName 'UfoIccid'
      Rename-Computer -NewName "$Env:sitename" -Restart
    }

    Add-Computer -WorkGroupName "LOCKERLIFE.HK"
    WriteSuccess ""
    WriteSuccess ""
    WriteSuccess "SIM ICCID $Env:iccid authorized for LockerLife Locker Deployment"
    WriteSuccess "Locker sitename: $Env:sitename"
    WriteSuccess ""
    WriteSuccess "Proceeding to Stage 2"
    WriteSuccess ""
}

if (Test-PendingReboot) { Invoke-Reboot }

#############
# finishing #
#############

# Internet Explorer: All:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 255

# Internet Explorer:History:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 1

# Internet Explorer:Cookies:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 2

# Internet Explorer: Temp Internet Files:
RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8

# Internet Explorer: Form Data:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 16

# Internet Explorer: Passwords:
#RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 32

# Internet Explorer: All:
# rundll32.exe InetCpl.cpl,ClearMyTracksByProcess 4351

Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\register-locker.lnk" -TargetPath "$env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?http://lockerlife.hk/deploy/10-configure.ps1" -Description "register-locker"


WriteInfo "Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript
WriteSuccess "Press any key to continue..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL

#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?http://lockerlife.hk/deploy/20-setup.ps1
