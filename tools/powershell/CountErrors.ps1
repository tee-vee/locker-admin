<#
   .Synopsis
    Counts the errors in the specified event log on a local or remote computer
   .Description
    This script counts the errors in the event log specified from the command line.
    This script works on classic event logs such as: system, application, security. 
    Admin rights are required for the security log. It impersonates the logged on user.
   .Example
    countErrors.ps1 -log application
    Counts errors from application log on local computer
   .Example
    countErrors.ps1 -log system -computer berlin
    Counts errors from the system log on remote computer berlin
   .Example
    countErrors.ps1 -log security
   .Inputs
    [string]
   .OutPuts
    [string]
   .Notes
    NAME:  Windows 7 Resource Kit
    AUTHOR: Ed Wilson
    LASTEDIT: 5/31/2009
    KEYWORDS:
   .Link
     Http://www.ScriptingGuys.com
#Requires -Version 2.0
#>
Param(
 [Parameter(Mandatory=$true,Position = 0,valueFromPipeline=$true)]
 [Alias("log")]
 [string]
 $strLog,
 [string]
 [Alias("cn")]
 $computer = $env:computername
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

if(!$strLog) { Get-Help $MyInvocation.InvocationName ;exit}
$i = 0
Get-EventLog -logname $strLog -computername $computer |
foreach { if ($_.entryType -eq "error") { $i++ } }
New-Underline("There are $i errors recorded in the $strLog log on computer $computer")