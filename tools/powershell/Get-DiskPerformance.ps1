<#
   .Synopsis
    Gets disk performance from local or remote computer
   .Description
    This script gets disk performance from local or remote computer.
    This script requires admin rights. 
    Parameters:
    -computer name of computer
    -numreps number of test cycles
    -sleep number of seconds to pause between test cycles. 
   .Example
    Get-DiskPerformance.ps1
    Gets disk performance from local computer
   .Example
    Get-DiskPerformance.ps1 -computer berlin
    Gets disk performance from remote computer berlin
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
 [string]
 $computer=$env:COMPUTERNAME,
 [int]
 $numreps = 3,
 [int]
 $sleep = 2
)
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

# *** Entry point to computer ***

$n1=$d1=$n2=$d2=$r1=$r2=$w1=$w2=$null
New-Underline "Obtaining disk performance from $computer"

for ($i=1 ; $i -le $numReps ; $i++)
{ 
$wmiPerf=Get-WmiObject -class win32_perfrawdata_perfdisk_logicaldisk `
  -Filter "name = '_Total'" -computername $computer
[double]$n1 = $wmiperf.percentIdleTime
[double]$r1 = $wmiperf.percentDiskTime
[double]$d1 = $wmiperf.TimeStamp_Sys100NS
Start-Sleep -Seconds $sleep
$wmiPerf=Get-WmiObject -class win32_perfrawdata_perfdisk_logicaldisk `
  -Filter "name = '_Total'" -computername $computer
[double]$n2 = $wmiperf.percentIdleTime
[double]$r2 = $wmiperf.percentDiskTime
[double]$d2 = $wmiperf.TimeStamp_Sys100NS
"rep $i . counting to rep $numrep ..."
$PercentIdleTime = (1 - (($N2 - $N1)/($D2-$D1)))*100
  "`tPercent Disk idle time is: " + "{0:N2}" -f $PercentIdleTime
$PercentDiskTime = (1 - (($r2 - $r1)/($D2-$D1)))*100
  "`tPercent Disk time is:      " + "{0:N2}" -f $PercentDiskTime
}
