<#
   .Synopsis
    Gets service information from local or remote comptuer
   .Description
    Gets detailed service information from local or remote comptuer
   .Example
    GetMultipleServices.ps1 -services rpcss,eventsystem
    Gets detailed service information on rpcss and on the eventSystem services
    on local computer
   .Example
    GetMultipleServices.ps1 -services rpcss,eventsystem -computer berlin
    Gets detailed service information on rpcss and on the eventSystem services
    on remote computer named berlin
   .Inputs
    [string[]]
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
 [Alias("CN")]
 $computer = $env:COMPUTERNAME,
 [Parameter(Mandatory=$true)]
 [string[]]
 $services
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
} #end New-Underline function

# *** Entry point to script ***

New-Underline "Obtaining detailed service information from $computer"
foreach($Service in $Services)
{
New-Underline "Service Info for: $Service"
 Get-Service -Name $Service |
 Format-list -property *
}

