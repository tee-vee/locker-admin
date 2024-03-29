<#
   .Synopsis
    Gets disk volume label on remote or local computer
   .Description
    This script gets disk volume label on remote or local computer.
   .Example
    Get-VolumeLabel.ps1 -disk C: 
    Gets volume label of disk c on local computer
   .Example
    Get-VolumeLabel.ps1 -disk C: -computername berlin
    Gets volume label of disk c on remote computer berlin
   .Inputs
    [string]
   .OutPuts
    OutPuts
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
   [string]
   [Parameter(Mandatory=$true)]
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

Function Get-VolumeLabel($disk,$computername)
{
 $wmi = get-WmiObject -class Win32_Logicaldisk -computername $computername -filter "DeviceID = '$disk'"
 If($wmi.VolumeName) { $wmi.volumeName }
 Else { "No volume label found. You can use the Set-volumeLabel script to set a volume label." }
}

# *** Entry point to script ***
New-Underline "Getting disk label for $disk from $computerName"

Get-VolumeLabel -disk $disk -computername $computername
