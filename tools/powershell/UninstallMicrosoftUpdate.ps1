<#
   .Synopsis
    Uninstalls a specific Microsoft Update from local computer
   .Description
    This script uninstalls a specific Microsoft Update from local computer. It also
    Lists the installed updates and their associated update ID's. Requires Admin. To
    use this script, you should always list the updates first. Read the information 
    about the update to see if you should perform the uninstall. Keep in mind, that
    if the notes about the update state the update cannot be removed once it is 
    installed, then this script will not be able to uninstall it. 
   .Example
    UninstallMicrosoftUpdate.ps1 -updateID "71535ae5-039f-482c-b242-6c5046414edf" -Uninstall
   .Example
    UninstallMicrosoftUpdate.ps1 -list
    Lists installed updates and their associated update ID's. These numbers are used to uninstall
    an update. 
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
    [string]
    $updateId,
    [switch]$list,
    [switch]$Uninstall
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

Function Get-InstalledUpdateGuids
{
 "Searching for installed updates and their guid. This can take a while."
 $UpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
 $Searcher = New-Object -ComObject Microsoft.Update.Searcher 
 $Result = $Searcher.Search("UpdateID != '12345678-1234-1234-1234-123456789123'")
 $Result.updates |
 Where-Object { $_.IsInstalled } |
 Format-List -property title, Description, `
      @{Label="updateID";Expression = { $_.Identity.UpdateID } }, `
      @{Label="Revision";Expression = { $_.Identity.revisionnumber } }
} #end function Get-InstalledUpdateGuids

Function Remove-InstalledUpdate([string]$updateID)
{
  New-Underline "Uninstalling update $update on $computer"
  $UpdateCollection = New-Object -ComObject Microsoft.Update.UpdateColl
  $Searcher = New-Object -ComObject Microsoft.Update.Searcher

  $Result = $Searcher.Search("UpdateID = '$updateID'")
  $Updates = $Result.updates
  $UpdateCollection.Add($Updates.Item(0)) | out-null
  $Installer = New-Object -ComObject Microsoft.Update.Installer
  $Installer.Updates = $UpdateCollection 
  #$installer
  Try
   { 
    $InstallResult = $Installer.UnInstall() 
    switch ($installResult.ResultCode)
     {
      0 { "Not Started" }
      1 { "In progress" }
      2 { "succeed" }
      3 { "Succeeded with Errors" }
      4 { "Failed. Try Control Panel to remove this update." }
      5 { "Aborted. Try Control Panel to remove this update." }
      Default { "Unable to install. Use Control Panel" }
     } #end switch
   } #end try
  Catch
    { "Unable to uninstall update. Use Control Panel" ; exit }
} #end Remove-InstalledUpdate

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
if($list) { get-installedUpdateguids ; exit }
if(!($updateID)) { "update ID is required." ; exit }
if($uninstall) { Remove-InstalledUpdate -updateID $updateID ; exit }




