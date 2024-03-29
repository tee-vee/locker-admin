<#
   .Synopsis
    Lists the amount of free disk space on hard drive
    on a local or remote machine. 
   .Description
    This script lists the amount of free disk space on hard drive
    on a local or remote machine. You can specify a
    drive, or drives by name, or list free space on all drives.
   .Example
    ListFreeSpace.ps1  -computer "Berlin" -all
    Lists free disk space on all fixed drives on a remote
    computer named Berlin
   .Example
    ListFreeSpace.ps1  -computer "Berlin" -drive c:
    Lists free disk space on the "c" drive on a remote
    computer named Berlin
   .Example
    ListFreeSpace.ps1 -drive c:,d:
    Lists free disk space on the "c" drive and on the
    "d" drive. It then totals the free space, total space
    and percent free for the two drives
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
      [string]
      $computer=$env:computerName,
      [string[]]
      $drive,
      [switch]$all
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
Function funDrive()
{
 foreach($sdrive in $drive)
  {
   $sdrive = Get-Wmiobject -class win32_volume -computername $computer `
           -filter "DriveLetter = '$sdrive'"
   New-UnderLine -strIN "`n$computer $($sdrive.DriveLetter) drive freespace report"
   Format-List -inputobject $sdrive -property Name,
    @{ Label="Freespace:" ; expression={ "{0:n2}"-f ($sdrive.Freespace / 1gb) + " GB" } },
    @{ Label="Totalspace:" ; expression={ "{0:n2}"-f ($sdrive.Capacity / 1gb) + " GB" } },
    @{ Label="Percent Free:" ; expression={ "{0:p2}"-f (($sdrive.freespace / 1gb) / ($sdrive.Capacity/ 1gb))  } }
     [double]$totalFreespace += $sdrive.Freespace
     [double]$totalTotalSpace += $sdrive.Capacity
  } #end foreach drive
   New-UnderLine -strIN "`n$computer Drive Totals freespace report"
   ""
   "Total Freespace: " + "{0:n2}"-f ($TotalFreeSpace / 1gb) + " GB"
   "Total Diskspace:" + "{0:n2}"-f ($TotalTotalSpace / 1gb) + " GB"
   "Total PercentFree: " + "{0:p2}"-f (($totalFreeSpace / 1gb) / ($totalTotalSpace/ 1gb))
exit
} #end funDrive
Function funAll()
{
 New-UnderLine -strIN "`n$computer all drive freespace report"
 Get-WmiObject -class win32_volume -computername $computer |
 Sort-object -property driveletter |
 format-table -autosize -property driveletter,
 @{ Label="Freespace:" ; expression={ "{0:n2}"-f ($_.Freespace / 1gb) + " GB" } },
 @{ Label="Totalspace:" ; expression={ "{0:n2}"-f ($_.Capacity / 1gb) + " GB" } },
 @{ Label="Percent Free:" ; expression={ "{0:p2}"-f (($_.freespace / 1gb) / ($_.Capacity/ 1gb))  } }
 exit
} #end funAll

# *** Entry Point to script ***

if($all)    { funall }
if($drive) { funDrive }
if(!($drive)) { Get-help $MyInvocation.InvocationName -full ; exit }
