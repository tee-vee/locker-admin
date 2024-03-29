<#
   .Synopsis
    Displays a listing of services that are set to automatic, but are not presently running
   .Description
    This script displays a listing of services that are set to automatic, but are not presently running
   .Example
    AutoServicesNotRunning.ps1
    Displays a listing of services that are set to automatic, but are not presently running on local computer
   .Example
    AutoServicesNotRunning.ps1 -computer munich
    Displays a listing of all non running services that are set to automatically start on a computer named munich
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
Param($computer=$env:computername)
$wmi = Get-WmiObject -Class win32_service -computername $computer `
   -filter "state <> 'running' and startmode = 'auto'"
if($wmi -eq $null)
  { "No automatic services are stopped" }
Else
  {
   "There are $($wmi.count) automatic services stopped.
          The list follows ... "
	foreach($service in $wmi) { $service.name }
   }

