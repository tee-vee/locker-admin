<#
   .Synopsis
    Checks the status of a service before attempting to start
   .Description
    Checks the status of a service before attempting to start. If the service is running, it points this out. This requires admin rights.
   .Example
    CheckServicethenStart.ps1 -service bits 
    Checks the status of the bits on the local computer, then starts it if it is not already running.
   .Example
    CheckServicethenStart.ps1 -service bits -computer berlin
    Checks the status of the bits on the berlin computer, then starts it if it is not already running.
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

Param($computer = $env:computername, 
  [Parameter(Mandatory=$true)]
  $Service
) #end param

Get-Service -name $Service -computername $computer |
foreach-object { 
 if ($_.status -ne "running")
  {
   Write-Host "starting $strService ..."
   Start-Service -Name $Service
  } #end if
  ELSE
   {
    Write-Host "$strService is already started"
   } #end else
} #end foreach
