<#
   .Synopsis
    Lists local users and their description 
   .Description
    This script lists local users and their description 
   .Example
    Get-LocalUsers.ps1
    Displays a table of local user names and their description
   .Example
    Get-LocalUserss.ps1 -computer berlin
    Displays a table of local user names and their description 
    from remote computer berlin
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
    [Parameter(Position=0)]
    [string]
    $computer = $env:computername
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
} #end New-Underline function

# *** Entry Point to script ***
New-Underline "Users and descriptions from $computer"
$winnt = [ADSI](”WinNT://” + $computer + “,computer”)
$winnt.psbase.children |
where-object{ $_.psbase.schemaclassname -eq “user” } |
Format-Table -Property name, description -AutoSize -Wrap
