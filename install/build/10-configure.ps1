# Derek Yuen <derekyuen@lockerlife.hk>
# January 2017

# 10-configure -- perform local identification tasks and setup for locker registration
$host.ui.RawUI.WindowTitle = "LockerLife Locker Deployment 10-configure"
$basename = $MyInvocation.MyCommand.Name


# source DeploymentConfig
(New-Object Net.WebClient).DownloadString("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1") > C:\local\etc\99-DeploymentConfig.ps1
. C:\local\etc\99-DeploymentConfig.ps1

Disable-MicrosoftUpdate
Disable-UAC
Update-ExecutionPolicy Unrestricted

# Skipping 10 lines because if running when all prereqs met, statusbar covers powershell output
 1..10 |% { Write-Host ""}


##############
# Lets start #
##############

& "$Env:SystemRoot\System32\taskkill.exe" /t /im iexplore.exe /f

# Start Time and Transcript
Start-Transcript -Path "$Env:_tmp\10-configure.log"
$StartDateTime = get-date
Write-Host "Script started at $StartDateTime"

Write-Host ""
Write-Host ""
Add-Type -AssemblyName Microsoft.VisualBasic
$Env:iccid = [Microsoft.VisualBasic.Interaction]::InputBox('Scan SIM Card', 'LockerLife Locker Deployment', "")

Write-Host ""
# add line for scanning locker serial number
$Env:lockerserialnumber = [Microsoft.VisualBasic.Interaction]::InputBox('Scan Locker Serial Barcode', 'LockerLife Locker Deployment', "")

Write-Host "--"
Write-Host "hostname - $Env:hostname"
Write-Host "iccid - $Env:iccid"
Write-Host "serial number - $Env:lockerserialnumber"


# $Env:sitename = & "$Env:curl" -Ss -k --url "https://gist.githubusercontent.com/tee-vee/bfa0ea73871ce47e6436beb88b2b77ac/raw/locker-iccid.db" | findstr "$Env:iccid" | awk '{ print $2 }'
$Env:sitename = & "$Env:curl" -Ss -k --url "https://gist.githubusercontent.com/tee-vee/bfa0ea73871ce47e6436beb88b2b77ac/raw/locker-iccid.db" | Select-String "$Env:iccid" | Out-String | %{ $_.Split(' ')[1]; } | foreach { $_ -replace "`r|`n","" }


Write-Host ""
Write-Host "iccid - $Env:iccid"
Write-Host "hostname - $Env:hostname"
Write-Host "sitename - $Env:sitename"
Write-Host "serial number - $Env:lockerserialnumber"


if (!$Env:sitename) {
    WriteError "*** WARNING *** WARNING *** WARNING *** WARNING *** WARNING ***"
    WriteError "This SIM card is not authorized for LockerLife Locker Deployment"
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

    #Write-Host "---"
    #Write-Host "GET MAC ADDRESS FOR CLOUD REGISTRATION"
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
    Write-Host ""
    Write-Host ""
    Write-Host "SIM ICCID $Env:iccid authorized for LockerLife Locker Deployment"
    Write-Host "Locker sitename: $Env:sitename"
    Write-Host ""
    Write-Host "Proceeding to Stage 2"
    Write-Host ""
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

Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\register-locker.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/10-configure.ps1" -Description "register-locker"
Install-ChocolateyShortcut -ShortcutFilePath "$env:Public\Desktop\setup-locker.lnk" -TargetPath "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -Arguments "http://boxstarter.org/package/url?$Env:deployurl/20-setup.ps1" -Description "setup-locker"


Write-Host "Script finished at $(Get-date) and took $(((get-date) - $StartDateTime).TotalMinutes) Minutes"
Stop-Transcript
Write-Host "Mistake with Locker registration? Double-click the register-locker icon on the desktop..."
Write-Host "`t Or Continue to the next step ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL

#& "$Env:ProgramFiles\Internet Explorer\iexplore.exe" -extoff http://boxstarter.org/package/url?$Env:deployurl/20-setup.ps1
