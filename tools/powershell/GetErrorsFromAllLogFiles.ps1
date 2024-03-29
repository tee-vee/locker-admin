<#
   .Synopsis
    Retrieves all errors from classic event logs
   .Description
    This script retrieves errors from classic event logs on a
    local or remote computer. By default it only retrieves errors
    from the most recent 20 entries. 
   .Example
    GetErrorsFromAllLogFiles.ps1
    Gets 20 most recent errors from all classic event logs on local computer
   .Example
    GetErrorsFromAllLogFiles.ps1 -computer berlin
    Gets 20 errors from classic event logs on remote computer berlin
   .Example
    GetErrorsFromAllLogFiles.ps1 -newest 10
    Gets 10 most recent errors from all classic event logs on local computer
   .Inputs
    [string]
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
 [string]
 $computer=$env:COMPUTERNAME,
 [int]
 $newest = 20
) #end param

# Begin Functions
function New-Underline
{
<#
.Synopsis
 Creates an underline the length of the input string
.Example
 New-Underline -strIN "Hello world"
.Example
 New-Underline -strIn "Morgen welt" -char "-" -sColor "blue" -uColor "yellow"
.Example
 "this is a string" | New-Underline
.Notes
 NAME:
 AUTHOR: Ed Wilson
 LASTEDIT: 5/20/2009
 KEYWORDS:
.Link
 Http://www.ScriptingGuys.com
#>
[CmdletBinding()]
param(
      [Parameter(Mandatory = $true,Position = 0,valueFromPipeline=$true)]
      [string]
      $strIN,
      [string]
      $char = "=",
      [string]
      $sColor = "Green",
      [string]
      $uColor = "darkGreen",
      [switch]
      $pipe
 ) #end param
 $strLine= $char * $strIn.length
 if(-not $pipe)
  {
   Write-Host -ForegroundColor $sColor $strIN
   Write-Host -ForegroundColor $uColor $strLine
  }
  Else
  {
  $strIn
  $strLine
  }
} #end funLine function

# *** Entry point to script ***

$ErrorActionPreference = "stop"
$logs = 'application', 'system','security'
New-UnderLine "Retrieving errors from the $newest newest event log entries from $computer."
Try
 {
  ForEach($log in $logs)
   {
    Write-Host "The following are errors from the $log log file"
    Get-EventLog -LogName $log -Newest $newest -computername $computer |
    Where-Object { $_.entryType -eq "Error" } |
    format-list -Property time, source, eventID, message, data
   } #end foreach
 } #end try
CATCH 
 {
  [System.Security.SecurityException]
  New-Underline -scolor Red -ucolor Red -strin "You need admin rights to query security log"
  New-Underline -scolor blue -ucolor blue -strin "Security log on $computer not queried."
 } #end catch
Finally
 { $ErrorActionPreference = "Continue" }
