# Derek Yuen <derekyuen@lockerlife.hk>
# February 2017
$errorActionPreference = "SilentlyContinue"
$error.Clear()
$startTime = $endTime = $Message = $logResults = $null


$basename = "PRODUCTION-MAINTENANCE.ps1"

$Env:Path += ";C:\local\bin;C:\$Env:ProgramFiles\GnuWin32\bin"

Write-Host "$basename"


# END OF FILE
