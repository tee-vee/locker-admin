#requires -version 3.0
# Derek Yuen <derek.yuen@outlook.com>
# February 2017
#
# logon-kiosk.ps1
#       - set a default logon script for kiosk user that always runs at kiosk user logon

$errorActionPreference = "SilentlyContinue"
$error.Clear()
# $startTime = $endTime = $Message = $logResults = $null

# $logDir = "c:\fso"
# if(-not(Test-Path -path $logdir)) 
#   { New-Item -Path $logdir -ItemType directory | Out-Null }
# $logonLog = Join-Path -Path $logDir -ChildPath "logonlog.txt"

# $startTime = (Get-Date).tostring()
# $WshNetwork = New-Object -ComObject wscript.network
# $WshNetwork.MapNetworkDrive("f:","\\berlin\studentShare")
# $message += "`r`nMapping drive f to \\berlin\student share `r`n$($error[0])"
# $WshNetwork.SetDefaultPrinter("berlinPrinter")
# $message += "`r`nSetting default printer to berlinPrinter `r`n$($error[0])"

# $endTime = (Get-Date).tostring()
# $logResults = @"
# **Starting script: $($MyInvocation.InvocationName) $startTime.
#  $message
# **Ending logon script $endTime. 
# **Total script time was $((New-TimeSpan -Start $startTime `
#   -End $endTime).totalSeconds) seconds.
# "@
# $logResults > $logonLog
