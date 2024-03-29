<#
   .Synopsis
    Gets errors from the application, system, and security log on local or remote computer
   .Description
    This script gets errors from the event log on local or remote computer.
    The name of the computer, log, and the number of events to search is configurable via cmd line.
    By default searchs 200 events from the application log. 
   .Example
    GetEventLogErrors.ps1
    Gets all errors from most recent 200 application log entries on local computer
   .Example
    GetEventLogErrors.ps1 -max 5 -computer berlin
    Gets all errors from the most recent 5 application log entries on remote computer berlin.
   .Example
    GetEventLogErrors.ps1 -max 5 -computer berlin -log system
    Gets all errors from the most recent 5 system log entries on remote computer berlin.
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
 $computer = $env:COMPUTERNAME,
 [int]
 $max = 200,
 [string]
 $log = "application"
)#end param

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

# *** Entry Point to Script ***

New-Underline "Searching $max entries for errors from $log log on $computer"
Get-EventLog -LogName application -Newest $max -computer $computer|
Where-Object { $_.entryType -eq "error" } |
format-list timegenerated, source, eventID, message, data 
