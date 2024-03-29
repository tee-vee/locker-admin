<#
   .Synopsis
    Removes a user from local group on local computer
   .Description
    This script removes a user from local group on local computer.
     PARAMETER
      -computer computer from which to remove user from group
      -user user to remove
      -group local group from which to remove user
   .Example
    Remove-LocalUserFromLocalGroup.ps1 -user bob -group test
    Removes local user bob from local group test on local computer.
   .Example
    Remove-LocalUserFromLocalGroup.ps1 -user bob -group test -computer berlin
    Removes local user bob from local group test on remote computer named berlin.
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
    $computer = $env:computername,
    [Parameter(Mandatory=$true)]
    [string]
    $user,
    [Parameter(Mandatory=$true)]
    [string]
    $group
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
New-Underline "Removing user $user from group $group on $computer"
$objGroup = [ADSI]"WinNT://$computer/$group"
$objGroup.remove("WinNT://$computer/$user") 