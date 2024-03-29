<#
   .Synopsis
    Lists services that accept a pause command
   .Description
    This script lists services that accept a pause command
   .Example
   .Example
    AcceptPause.ps1
    Displays Services that accept a pause
   .Inputs
    none
   .OutPuts
    [string]
   .Notes
    NAME:  Windows 7 Resource Kit
    AUTHOR: Ed Wilson
    LASTEDIT: 5/20/2009
    KEYWORDS:
   .Link
     Http://www.ScriptingGuys.com
#Requires -Version 2.0
#>
Param(
 $computer = $env:COMPUTERNAME
)
"The following services accept a pause"
Get-WmiObject -Class win32_service -computername $computer |
Where-Object { $_.acceptpause -eq "true" } |
Select-Object name
