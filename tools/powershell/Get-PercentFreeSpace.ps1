<#
   .Synopsis
    Gets percentage of free space for each drive
   .Description
    This script gets percentage of free space for each drive
   .Example
    Get-PercentFreeSpace.ps1
    Gets percent of free space on all drives on local computer
   .Example
    Get-PercentFreeSpace.ps1 -computer berlin
    Gets percent of free space on all drives on remote computer berlin
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
 [string[]]
 $computer = $env:COMPUTERNAME
)

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

Function Get-PercentFreeSpace($aryComputer)
{
 foreach($computer in $arycomputer)
 {
  New-UnderLine("Drives on $computer computer:")
  $volumeSet = Get-WmiObject -Class win32_volume -computer $computer `
  -filter "drivetype = 3"
  foreach($volume in $volumeSet)
   { 
    $drive=$volume.driveLetter 
    [int]$free=$volume.freespace/1GB
    [int]$capacity=$volume.capacity/1GB
    "Analyzing  drive $drive $($volume.label) on $($volume.__server)"
   if($capacity -ge 1)
      {
       "`t`t Percent free space on drive $drive " +  "{0:N2}" -f `
       (($free/$capacity)*100)
      }
   } #end foreach volume
 } #end foreach computer
} #end function

# *** Entry point to script ***

Get-PercentFreeSpace -aryComputer $computer
