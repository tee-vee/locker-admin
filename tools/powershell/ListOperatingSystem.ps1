<#
   .Synopsis
    Lists details of the operating system  on a local
    or remote machine.
   .Description
    This script lists details of the operating system on a
    local or on a remote comptuer.  This includes information about
    the version of windows, the free physical memory,
    free virtual memory, the os architecture, the os
    language, and the service pack in effect
   .Example
    ListOperatingSystem.ps1  -computer "Berlin"
    Lists operating system information from a remote
    computer named Berlin
   .Example
    ListOperatingSystem.ps1 
    Lists operating system information from the local machine
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
param(
      [Parameter(Position=1,ValueFromPipeline=$true)]
      [string]
      [Alias("VN")]
      $computer=$env:computerName
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
} #end new-UnderLine function

Function funQueryComputer()
{
 get-wmiobject -class win32_operatingsystem -computername $computer |
 foreach-object `
  {
   New-UnderLine("operating system details on $computer")
   $_.psobject.properties |
   foreach-object `
    {
     If($_.value)
      {
       if ($_.name -match "__"){}
       ELSE
        {
         $operatingsystem+=@{ $($_.name) = $($_.value) }
        } #end else
      } #end if
    } #end foreach property
    $operatingsystem ; $operatingsystem.clear()
  } #end foreach operating system
 exit
} #end funQueryComputer
# *** Entry Point to script ***

funQuerycomputer 

