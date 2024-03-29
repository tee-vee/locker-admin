<#
   .Synopsis
    Calculates average processor utilization on local or remote computer
   .Description
    This script calculates average percent processor utilization on local or remote computer
   .Example
    Get-ProcessorUtilization.ps1 
    Calculates the average processor utilization on local computer for 3 seconds,
    3 cycles with 1 second delay between cycles
   .Example
    Get-ProcessorUtilization.ps1 -delay 2
    Calculates the average processor utilization on local computer for 6 seconds,
    3 cycles with 2 second delay between cycles
   .Example
    Get-ProcessorUtilization.ps1 -delay 2 -reps 4
    Calculates the average processor utilization on local computer for 8 seconds,
    4 cycles with 2 second delay between cycles
   .Example
    Get-ProcessorUtilization.ps1 -delay 2 -computer berlin
    Calculates the average processor utilization on remote computer berlin for 6 seconds,
    3 cycles with 2 second delay between cycles
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
    [int]
    $delay = 1,
    [int]
    $reps = 3
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

Function CreateEmptyArray($ubound)
{
 [int[]]$script:aryProp = [array]::CreateInstance("int",$ubound)
} #end CreateEmptyArray

Function GetWmiPerformanceData($computer,$delay,$reps)
{
 For($i = 0 ; $i -le $reps -1 ; $i++)
  {
   $aryProp[$i] +=([wmi]"\\$computer\root\cimv2:$class.$key='$instance'").$Property
   Write-Progress -Activity "Obtaining Processor info" -Status "% complete: " `
   -PercentComplete $i
   Start-Sleep -Seconds $delay
  } #end for
}#end GetWmiPerformanceData

Function EvaluateObject()
{
 $aryProp | 
 Measure-Object -Average -Maximum -Minimum |
 Format-Table -Property `
  @{ Label = "Data Points" ; Expression = {$_.count} }, 
  average, Maximum, Minimum -autosize
} #End EvaluateObject


# *** Entry Point to script ***
New-Underline "Getting Percent processor utilization over $($delay*$reps) seconds on $computer"

$class = "Win32_PerfFormattedData_PerfOS_Processor"
$key = "name"
$instance = "_Total"
$property = "PercentProcessorTime"

CreateEmptyArray($reps)
GetWmiPerformanceData -computer $computer -delay $delay -reps $reps
EvaluateObject


