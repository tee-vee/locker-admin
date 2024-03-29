<#
   .Synopsis
    Displays a grouped listing of service status on local or remote comptuer
   .Description
    This script displays a grouped listing of service status on local or 
    remote comptuer
   .Example
    GetServiceStatus.ps1
    Displays listing of status of services on local computer
    GetServiceStatus.ps1 -computer berlin
    Displays listing of status of services on remote computer berlin
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
   $computer = $env:COMPUTERNAME
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
} #end New-UnderLine function

# *** Entry point to script ***

New-Underline "Obtaining service status from $computer"
Get-Service -ComputerName $computer |
Sort-Object status -descending |
foreach {
  if ( $_.status -eq "stopped")
   {Write-Host $_.name $_.status -ForegroundColor red}
  elseif ( $_.status -eq "running" )
   {Write-Host $_.name $_.status -ForegroundColor green}
  else
   {Write-Host $_.name $_.status -ForegroundColor yellow}
} 
