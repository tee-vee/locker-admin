# Derek Yuen <derekyuen@lockerlife.hk>
# February 2017
$errorActionPreference = "SilentlyContinue"
$error.Clear()
$startTime = $endTime = $Message = $logResults = $null

$basename = "PRODUCTION-MONITORING.ps1"

$Env:Path += ";C:\local\bin;C:\$Env:ProgramFiles\GnuWin32\bin"

Get-CimInstance -ClassName Win32_Computersystem

# END OF FILE
