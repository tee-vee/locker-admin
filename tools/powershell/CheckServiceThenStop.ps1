<#
   .Synopsis
    Checks to see if a service will accept a stop prior to stopping 
   .Description
    This script checks to see if a service will accept a stop command prior to attempting to stop it. Evaluates return code.
   .Example
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
  $Service,     
  $Computer = $env:computername
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
} #end function New-UnderLine

# *** Entry point to script ***
$objWmiService = Get-Wmiobject -Class Win32_Service -computer $Computer -filter "name = '$Service'"
if( $objWMIService.Acceptstop )
 {
  New-UnderLine "stopping the $Service service now ..."
  $rtn = $objWMIService.stopService()
  Switch ($rtn.returnvalue)
  {
   0 { Write-Host -foregroundcolor green "$strService stopped" }
   2 { Write-Host -foregroundcolor red "$strService service reports" `
       " access denied" }
   5 { Write-Host -ForegroundColor red "$strService service can not" `
       " accept control at this time" }
   10 { Write-Host -ForegroundColor red "$strService service is already" `
         " stopped" }
   DEFAULT { Write-Host -ForegroundColor red "$strService service reports" `
             " ERROR $($rtn.returnValue)" }
  }
 }
ELSE
 {
  Write-Host "$strService will not accept a stop request"
 }
