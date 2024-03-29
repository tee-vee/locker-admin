<#
   .Synopsis
    Gets members of local group
   .Description
    This script gets the members of the local group
   .Example
    Get-LocalGroupMembers.ps1 -group test
    Gets the members of the local test group on local computer
   .Example
    Get-LocalGroupMembers.ps1 -computer berlin -group test
    Gets the members of the local test group on remote computer berlin
   .Inputs
    [string]
   .OutPuts
    OutPuts
   .Notes
    NAME:  Windows 7 Resource Kit
    AUTHOR: Ed Wilson 
    LASTEDIT: 6/10/2009
    KEYWORDS:
   .Link
     Http://www.ScriptingGuys.com
#Requires -Version 2.0
#>

Param(
   [Parameter(Position=0,ValueFromPipeline=$true)]
   [String]
   [Alias("CN")]
   $computer=$env:COMPUTERNAME,
   [Parameter(Mandatory=$true)]
   [string]
   $group
)# end param

# Begin Functions here
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

Function Get-LocalGroupMembers($computer, $group)
{
   $group =[ADSI]"WinNT://$computer/$group" 
   $members = @($group.psbase.Invoke("Members")) 
   $members | 
   Foreach { $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)} 
} #end get-LocalGroupMembers

# *** Entry point to script ***
$userCount = $null
New-Underline "Obtaining members of $computer $group group"
Try
 {
  $ErrorActionPreference = "stop" 
  $rtnUsers = Get-LocalGroupMembers -computer $computer -group $group 
 }
Catch {New-Underline -sColor red -strIN "unable to find group $group on $computer" ; exit}
$userCount = $rtnUsers.length
$userCount = ($rtnUsers | Measure-Object).count
If($userCount)
 { 
  New-Underline -sColor blue -char "-" -strIN "There are $($userCount) users in the $group group."
  Get-LocalGroupMembers -computer $computer -group $group
 }
Else
 { "There are no users in the $group group" }