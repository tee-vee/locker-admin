<#
   .Synopsis
    Displays service configuration information from
    a local or remote computer.
   .Description
    This script displays service configuration information from
    a local or remote computer.
   .Example
    MonitorService.ps1  -computer "Berlin" -running
    Displays only running service information from a remote
    computer named Berlin
   .Example
    MonitorService.ps1 -stopped
    Displays stopped service configuration information from
    the local computer
   .Example
    MonitorService.ps1 -list
    Displays service configuration information from the
    local computer
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
      $computer="localhost",
      [switch]$list,
      [switch]$running,
      [switch]$stopped
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
Function funService()
{
 New-UnderLine("Performing Service test on $computer...")
 "**** SERVICE TEST ****"
 Get-wmiobject -query $query -computername $computer |
  foreach-object `
    {
      $_.psobject.properties |
	 foreach-object `
          {
           If($_.value)
	     {
	      if($_.name -notmatch "__")
	        {
		 $aryProp +=@{ $($_.name)=$($_.value) }
	        } #end if _name
	     } #end if _value
          } #end foreach property
            " " ; $aryProp
            $aryProp.clear()
    } #end foreach service
 exit
} #end funService
Function funEval($strIN)
{
 switch($strIN)
  {
   "running" { $query = "Select * from win32_service where state = 'running'" ; funservice }
   "stopped" { $query = "Select * from win32_service where state = 'stopped'" ; funservice }
   "list" { $query = "Select * from win32_service" ; funservice }
} #end switch
} #end funEval

# Entry Point
if($list)    { funeval("list") }
if($running) { funeval("running") }
if($stopped) { funeval("stopped") }
if(!$list) { Get-Help $MyInvocation.InvocationName -full; exit }
