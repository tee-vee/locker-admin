<#
   .Synopsis
    Displays a listing of services and their dependencies
   .Description
    This script displays a listing of services and their dependencies
   .Example
    ServiceDependencies.ps1 -computer munich
    Displays a listing of services and their dependencies
    on a computer named munich
   .Example
    ServiceDependencies.ps1
    Displays a listing of services and their dependencies
    on the local machine
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
      $computer=$env:COMPUTERNAME
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

# *** Begin Script ***

$dependentProperty = "name", "displayname", "pathname",
                      "state", "startmode", "processID"
$antecedentProperty = "name", "displayname",
                       "state", "processID"

New-Underline "Service Dependencies on $computer"
New-Variable -Name c_padline -value 14 -option constant # allows for length of displayname
Get-WmiObject -Class Win32_DependentService -computername $computer |
Foreach-object `
 {
  "=" * ((([wmi]$_.dependent).pathname).length + $c_padline)
  Write-Host -ForegroundColor blue "This service:"
    [wmi]$_.Dependent |
      format-list -Property $dependentProperty
  Write-Host -ForegroundColor cyan "Depends on this service:"
    [wmi]$_.Antecedent |
      format-list -Property $antecedentProperty
        "=" * ((([wmi]$_.dependent).pathname).length + $c_padline) + "`n"
 }
