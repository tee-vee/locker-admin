<#
   .Synopsis
    Obtains max page faults generated by processes on local or remote comptuer
   .Description
    This script obtains max page faults generated by processes on local or remote comptuer
   .Example
    FindMaxPageFaults.ps1
    Lists top 5 (default) processes generating pagefaults on local computer
   .Example
    FindMaxPageFaults.ps1 -max 3
    Lists top 3 processes generating pagefaults on local computer
   .Example
    FindMaxPageFaults.ps1 -max 10 -computer berlin
    Lists top 10 processes generating pagefaults on remote computer berlin
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
 [Parameter(position=0,valuefrompipeline=$true)]
 [string]
 [alias("CN")]
 $computer=$env:computername,
 [int]
 $max = 5
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
} #end New-underline function

# *** Entry point to script ***
New-Underline "Getting top page faults for $computer"
Get-WmiObject -Class win32_process -computername $computer| 
Sort-Object -property pagefaults | 
Select-Object -Property * -Last 5 |
Format-table -property name, pagefaults -AutoSize