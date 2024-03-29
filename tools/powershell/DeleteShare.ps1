<#
   .Synopsis
    Deletes share on local or remote computer
   .Description
    This script deletes a share on a local or on a remote computer. 
     PARAMETERS:
     -shareName   Specifies the name of the share
     -computerName  [optional] the name of computer containing share
   .Example
    DeleteShare.ps1 -shareName "fso"
    Deletes a share named fso on local computer
   .Example
    DeleteShare.ps1 -shareName "fso" -computerName "london"
    Deletes a share named fso on a remote computer named london
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
   [Parameter(Mandatory=$true)]
   [string]
   $shareName,
   [string] 
   $computerName=$env:COMPUTERNAME
) # end param

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

# *** Entry point to script ***

if(!$sharename) { Get-help $MyInvocation.InvocationName ; exit}
New-Underline("Delete share $sharename on $computername")
$wmiClass = "Win32_Share"
$objWMI= Get-WmiObject -Class $wmiClass -computername $computerName -filter "Name = '$shareName'"
$objWMI.delete()
