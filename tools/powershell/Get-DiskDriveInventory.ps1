<#
   .Synopsis
    Gets detailed disk drive confiuration information
   .Description
    This script gets detailed disk drive confiuration information 
    from local or remote comptuer
   .Example
    Get-DiskDriveInventory.ps1
    Gets detailed disk drive inventory 
   .Example
    Get-DiskDriveInventory.ps1 -computer berlin
    Gets detailed disk drive inventory from remote computer berlin
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

Function get-DiskDriveInventory($computername)
{
 Get-WmiObject -Class Win32_DiskDrive -ComputerName $computername
} # end get-DiskDriveInventory

Filter Where-HasWmiValue
{
   $_.psobject.properties |
   foreach-object `
    {
     If($_.value -AND $_.name -notmatch "__")
      {
        @{ $($_.name) = $($_.value) }
      } #end if
    } #end foreach property
} #end filter Where-HasWmiValue

# *** Entry point to script ***

New-Underline "Obtaining disk drive inventory for $computer"

Get-DiskdriveInventory -computername $computer | Where-HasWmiValue

