<#
   .Synopsis
    Produces a listing of printer ports on a local or remote machine.
   .Description
    This script produces a listing of printer ports on a local or remote machine.
   .Example
    Get-PrinterPorts.ps1
    Produces a listing of printer ports on a local or remote machine.
   .Example
    Get-PrinterPorts.ps1 -computer MunichServer
    Lists all the printer ports on a computer named MunichServer
   .Inputs
    [string]
   .OutPuts
    [string]
   .Notes
    NAME:  Windows 7 Resource Kit
    AUTHOR: Ed Wilson
    LASTEDIT: 6/20/2009
    KEYWORDS: Printer
   .Link
     Http://www.ScriptingGuys.com
#Requires -Version 2.0
#>
Param(
  [string]$computer = $env:COMPUTERNAME
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
} #end New-UnderLine function

Filter HasWmiValue
{
  ""
   $_.psobject.properties |
   foreach-object `
    {
     If(
        $_.value -AND $_.name -notmatch "__" -AND $_.name -notmatch "Scope" `
         -AND $_.name -notmatch "Path" -AND $_.name -notmatch "Options" `
         -AND $_.name -notmatch "Properties" -AND $_.name -notmatch "Qualifiers"
       )
      {
        @{ $($_.name) = $($_.value) }
      } #end if
    } #end foreach property
} #end filter HasWmiValue

# *** Entry point to script ***
New-underline "Obtaining printer ports from $computer"
$class = "Win32_TcpIpPrinterPort"
Get-WmiObject -Class $class -computername $computer |
HasWmiValue