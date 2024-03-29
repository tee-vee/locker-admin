<#
   .Synopsis
    Prints the offline files config on a local or remote machine.
   .Description
    Prints the offline files config on a local or remote machine.
   .Example
    Get-SystemRestoreSettings.ps1 -computer MunichServer
    Lists system restore config on a computer named MunichServer
   .Example
    Get-SystemRestoreSettings.ps1
    Lists system restore config on local computer
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
} #end new-underline function

New-Variable -Name SecInDay -option readonly -value 86400
$objWMI = Get-WmiObject -Namespace root\default `
         -Class SystemRestoreConfig -computername $computer
New-Underline "Retrieving system restore information from $computer"

format-table -InputObject $objWMI -property `
  @{
    Label="Max disk utilization" ;
	expression={  "{0:n0}"-f ($_.DiskPercent ) + " %"}
	},
  @{
    Label="Scheduled Backup" ;
	expression={  "{0:n2}"-f ($_.RPGlobalInterval / $SecInDay) + " days"}
	},
  @{
    Label="Max age of backups" ;
	expression={ "{0:n2}"-f ($_.RPLifeInterval / $SecInDay) + " days" }
	}
Remove-Variable -Name SecInDay -Force