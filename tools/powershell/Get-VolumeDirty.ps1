<#
   .Synopsis
    Gets volume dirty status from local or remote computer
   .Description
    This script gets volume dirty status from local or remote computer
   .Example
    Get-VolumeDirty.ps1
    Gets volume dirty status from all drives on local computer
   .Example
    Get-VolumeDirty.ps1 -computer berlin
    Gets volume dirty status from all drives on remote computer berlin
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
   $computer=$env:COMPUTERNAME
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

Function Get-VolumeDirty($computername)
{
 Get-WmiObject -class win32_logicaldisk -computername $computername -filter "drivetype = 3" |
 ForEach-Object { 
  "Drive $($_.name) volume dirty: $($_.volumeDirty)"
 }
} #end function Get-VolumeDirty

# *** Entry point to script ***
New-UnderLine "Querying volume dirty on $Computer"
Get-VolumeDirty -computername $computer

