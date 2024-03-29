<#
   .Synopsis
    Gets updates installed on local computer
   .Description
    This script gets updates installed on local computer. It does
    not download or install updates, it lists them.
   .Example
    Get-MicrosoftUpdates.ps1 -NumberofUpdates 1 
    Gets one up date for local computer
   .Example
    Get-MicrosoftUpdates.ps1 -all
    Lists all updates for local computer
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
    $NumberOfUpdates,
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
} #end New-Underline function

Function Get-MicrosoftUpdates
{ 
  Param(
        $NumberOfUpdates,
        [switch]$all
       )
  $Session = New-Object -ComObject Microsoft.Update.Session
  $Searcher = $Session.CreateUpdateSearcher()
  if($all)
    {
      $HistoryCount = $Searcher.GetTotalHistoryCount()
      $Searcher.QueryHistory(1,$HistoryCount) |
      Format-List -property title, description, date, `
      @{Label="updateID";Expression = { $_.UpdateIdentity.UpdateID } }, `
      @{Label="Revision";Expression = { $_.UpdateIdentity.revisionnumber } }
    } #end if all
  Else 
    { 
      $Searcher.QueryHistory(1,$NumberOfUpdates) 
    } #end else
} #end Get-MicrosoftUpdates



# *** entry point to script ***
if(!($all -OR $NumberOfUpdates)) { Get-Help $MyInvocation.InvocationName ; exit }
New-Underline "Obtaining listing of Microsoft Updates for $computer"
if($all) { Get-MicrosoftUpdates -all }
if($numberOfUpdates) { Get-MicrosoftUpdates -numberOfUpdates $numberOfUpdates }



