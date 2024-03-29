<#
   .Synopsis
    Configures the Windows Software update schedule on local computer
   .Description
    This script configures and displays the current software update schedule.
    Time is the hour specified as 1 or two digits beginning with 1 ending with 23. 
    Day is the number for the day. 0 is everyday, 1 is Monday ...
    Admin rights are required to run this script. 
     PARAMETER
      -day the day to query for the software updates < 0 - 7 >
      0 is every day, 1 Monday, 2 is Tuesday ...
     -time the time to query for software updates < 1 - 23 >
     -query returns the current software update schedule
      for the local computer
     -whatif Prototypes the command
   .Example
    ConfigureSoftwareUpdatesSchedule.ps1  -query
    Queries for the current software update schedule configured on the local computer
   .Example
    ConfigureSoftwareUpdatesSchedule.ps1  -day 0 -time 2
    Configures the local computer to query for new software updates every day at 2:00 AM.
   .Example
    ConfigureSoftwareUpdatesSchedule.ps1  -day 1 -time 20
    Configures the local computer to query for new software updates every Monday at 8:00 PM.
   .Example
    ConfigureSoftwareUpdatesSchedule.ps1  -day 6 -time 19 -whatif
    Displays what if: Perform operation configure software updates for  at 19 on local computer
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
      [int]
      $day,
      [int]
      $time,
      [switch]$query,
      [switch]$whatif
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
Function funWhatIf()
{
 "what if: Perform operation configure software updates
  for day $date at time $time on local computer"
 exit
} #end funWhatIf

Function funConfigureTime()
{
 if(!$blnsetTime)
  {
   $Update = New-object -comobject Microsoft.Update.AutoUpdate
   $UpdateSettings = $Update.Settings
   $UpdateSettings.ScheduledInstallationTime =$Time
   $UpdateSettings.Save()
   $blnSetTime = $true
   if($error.count -eq 0)
    {
     New-Underline -strIN "New Time saved on $env:comptuername for $time" -scolor green -ucolor yellow
    }
   Else
    { New-Underline -strIN "An error occurred" -scolor red -ucolor white ; exit }
  if($day) { funConfigureDay }
  } #end !$blnSetTime
  exit
} #end funConfigureTime

Function funConfigureDay()
{
 if(!$blnSetDay)
  {
   $Update = New-object -comobject Microsoft.Update.AutoUpdate
   $UpdateSettings = $Update.Settings
   $UpdateSettings.ScheduledInstallationDay = $day
   $UpdateSettings.Save()
   $blnSetDay = $true
    if($error.count -eq 0)
     {
      New-Underline -strIN "New day saved on $env:computerName for $day" -scolor green -ucolor yellow
     }
    Else
     { New-Underline -strIN "An error occurred" -scolor red -ucolor white ; exit }
    if($time) { funConfigureTime }
   } #end !$blnSetDay
    exit
} #end funConfigureDay

Function funReportUpdates()
{
 $Update = New-object -comobject Microsoft.Update.AutoUpdate
 $UpdateSettings = $Update.Settings
 $sDay=$updateSettings.ScheduledInstallationDay
 $sTime=$updateSettings.ScheduledInstallationTime
 New-Underline -strIN "Updates on $env:computerName are scheduled for:" -scolor green -ucolor yellow
 "Time: $($sTime) day: $($sday)"
 exit
} #end funConfigureDay

function Test-IsAdministrator
{
    <#
    .Synopsis
        Tests if the user is an administrator
    .Description
        Returns true if a user is an administrator, false if the user is not an administrator        
    .Example
        Test-IsAdministrator
    #>   
    param() 
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $currentUser).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
} #end function Test-IsAdministrator

# *** Entry Point to script ***
if(!(Test-IsAdministrator)) { New-Underline "Admin rights are required" ; exit }
$blnSetTime = $false
$blnSetDay = $false
$error.clear()
if($whatif)    { funWhatIf }
if($query)     { funReportUpdates }
if($day)       { funConfigureDay }
if($day -eq 0) { funConfigureDay }
if($time)      { funConfigureTime }
Get-Help $MyInvocation.InvocationName