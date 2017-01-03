# -----------------------------------------------------------------------------
# Script: LogonScriptWithLogging.ps1
# Author: ed wilson, msft
# Date: 09/07/2013 13:21:14
# Keywords: Designing a Logging Approach
# comments: Overwrite Log
# Windows PowerShell 4.0 Best Practices, Microsoft Press, 2013
# Chapter 18
# -----------------------------------------------------------------------------
$errorActionPreference = "SilentlyContinue"
$error.Clear()
$startTime = $endTime = $Message = $logResults = $null

$logDir = "c:\fso"
if(-not(Test-Path -path $logdir)) 
  { New-Item -Path $logdir -ItemType directory | Out-Null }
$logonLog = Join-Path -Path $logDir -ChildPath "logonlog.txt"

$startTime = (Get-Date).tostring()
$WshNetwork = New-Object -ComObject wscript.network
$WshNetwork.MapNetworkDrive("f:","\\berlin\studentShare")
$message += "`r`nMapping drive f to \\berlin\student share `r`n$($error[0])"
$WshNetwork.SetDefaultPrinter("berlinPrinter")
$message += "`r`nSetting default printer to berlinPrinter `r`n$($error[0])"

$endTime = (Get-Date).tostring()
$logResults = @"
**Starting script: $($MyInvocation.InvocationName) $startTime.
 $message
**Ending logon script $endTime. 
**Total script time was $((New-TimeSpan -Start $startTime `
  -End $endTime).totalSeconds) seconds.
"@
$logResults > $logonLog
