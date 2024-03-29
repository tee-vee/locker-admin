<#
   .Synopsis
    Changes the start mode of a service, then attempts to start same.
   .Description
    This script will change the start mode of a service, then attempt to start the service. 
    This script must be run as an administrator.
   .Example
    ChangeModeThenStart.ps1 -computer berlin -service bits
    Changes the start mode of the bits mode to manual, then starts the service. 
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
  [Parameter(mandatory=$true)]
  $Service,     
  $Computer = $env:COMPUTERNAME
)
function EvalRTN($rtn)
{
Switch ($rtn.returnvalue)
  {
   0 { Write-Host -foregroundcolor green "No errors for $strCall" }
   2 { Write-Host -foregroundcolor red "$strService service reports" `
       " access denied" }
   5 { Write-Host -ForegroundColor red "$strService service can not" `
       " accept control at this time" }
   10 { Write-Host -ForegroundColor red "$strService service is already" `
         " running" }
   14 { Write-Host -ForegroundColor red "$strService service is disabled" }
   DEFAULT { Write-Host -ForegroundColor red "$strService service reports" `
             " ERROR $($rtn.returnValue)" }
  }
  $rtn=$strCall=$null
}

# *** Entry point to script ***

$objWmiService = Get-Wmiobject -Class Win32_Service -computer $Computer `
  -filter "name = '$Service'"
if( $objWMIService.state -ne 'running' -AND $objWMIService.startMode -eq 'Disabled')
  {
   Write-Host "The $Service service is disabled. Changing to manual ..."
   $rtn = $objWmiService.ChangeStartMode("Manual")
   $strCall = "Changing service to Manual"
   EvalRTN($rtn)
   if($rtn.returnValue -eq 0)
     {
      Write-Host "The $Service service is not running. Attempting to start ..."
      $rtn = $objWMIService.StartService()
      $strCall = "Starting service"
   EvalRTN($rtn)
      }
   }
ELSEIF($objWMIService.state -ne 'running')
  {
   Write-Host "The $Service service is not running. Attempting to start ..."
   $rtn = $objWMIService.StartService()
   $strCall = "Starting service"
   EvalRTN($rtn)
  }
ELSEIF($objWMIService.state -eq 'running')
  {
   Write-Host "The $Service service is already running"
  }
ELSE
  {
  }

