<#
   .Synopsis
    Sets the volume autocheck on specified disk drive
   .Description
    This script sets the volume autocheck on specified disk drive on local 
    or remote computer. This will cause check disk to run at next boot up 
    if the volumedirty bit is set to true.
    This script must be run as administrator. 
   .Example
    Set-VolumeAutoCheck.ps1 -disk c:
    Sets the volume autocheck on the c: drive of local computer
   .Example
    Set-VolumeAutoCheck.ps1 -disk c: -computername berlin
    Sets the volume autocheck on the c: drive of remote computer berlin
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
   [Parameter(Position=0,ValueFromPipeline=$true)]
   [String]
   [Alias("CN")]
   $computerName=$env:COMPUTERNAME,
   [Parameter(Mandatory=$true)]
   [string[]]
   $disk
)# end param

# Begin Functions here
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
} #end New-Underline function

Function Set-VolumeAutoCheck($disk,$computername)
{
 ([wmiclass]"\\$computername\root\cimv2:Win32_logicaldisk").ScheduleAutoChk($disk)
} #end function Set-VolumeAutoCheck

# *** Entry point to script ***

New-Underline "Setting volume dirty on $disk on $computerName"
Set-VolumeAutoCheck -disk $disk -computername $computername

