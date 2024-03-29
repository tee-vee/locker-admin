<#
   .Synopsis
    Downloads and installs a Microsoft update for local computer
   .Description
    This script downloads and installs a Microsoft update for local computer.
    You must supply the specific update guid. You may want to use the 
    Get-MissingSoftwareUpdates.ps1 sctipt to identify the update if you do not know it.
   .Example
    DownloadAndInstallMicrosoftUpdate.ps1 -update "71535ae5-039f-482c-b242-6c5046414edf"
    Downloads and installs a specific Microsoft Update on the local comptuer.
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
    [Parameter(Mandatory=$true)]
    [string]
    $update
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

# *** Entry Point to script ***

New-Underline "Downloading update $upadate for $computer"
$UpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
$Searcher = New-Object -ComObject Microsoft.Update.Searcher
$Session = New-Object -ComObject Microsoft.Update.Session

$updateID = $update
$Result = $Searcher.Search("UpdateID='$updateID'")
$Updates = $Result.updates
$UpdateCollection.Add($Updates.Item(0)) | out-null

$Downloader = $Session.CreateUpdateDownloader()
$Downloader.Updates = $UpdateCollection
$Downloader.Download()

$Installer = New-Object -ComObject Microsoft.Update.Installer
$Installer.Updates = $UpdateCollection
$Installer.Install()

