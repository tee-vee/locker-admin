<#
   .Synopsis
    Creates one a share on local computer
   .Description
    Creates share on a local machine using default permissions
    The folder to be shared does not need to exist as the script
    checks for the existance of the folder and will create it if
    it is not present
     PARAMETERS:
     -folderPath  Specifies the path to the folder you wish to share
     -shareName   Specifies the name to assign to the share
     -maxAllowed  [optional] the maximum number of connections
     -description [optional] description of the share (notes, reason etc)
   .Example
    Createshare.ps1 -folderPath "c:\fso" -shareName "fso"
    Creates share of the folder c:\fso and gives it the name fso, 5 people will be allowed to access the share, and it has a description of Created by PowerShell
   .Example
    CreateShare.ps1 -folderPath "c:\fso" -shareName "fso" -maxAllowed 1
    Creates share of the folder c:\fso and gives it the name fso 1 person will be allowed to access the share, and it has a description of Created by PowerShell
   .Example
    CreateShare.ps1 -folderPath "c:\fso" -shareName "fso" -maxAllowed 3 -description "fso share"
    Creates share of the folder c:\fso and gives it the name fso 3 people will be allowed to access the share, and it has a description of fso share
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
  [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
  $folderpath, 
  [Parameter(Mandatory=$true,Position=1)]
  $shareName,
  [int] 
  $maxAllowed=5, 
  [string]
  $description="Created by PowerShell"
) #end param

Function funlookup($intIN)
{
 Switch($intIN)
 {
  0  { "Success" }
  2  { "Access denied" }
  8  { "Unknown failure" }
  9  { "Invalid name" }
  10 { "Invalid level" }
  21 { "Invalid parameter" }
  22 { "Duplicate share" }
  23 { "Redirected path" }
  24 { "Unknown device or directory" }
  25 { "Net name not found" }
  DEFAULT { "$intIN is an Unknown value" }
 } #end switch
} #End function funlookup

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
} #end funLine function

# *** Entry point to script ***

if(!$folderpath) { Get-help $MyInvocation.InvocationName ; exit}
$Type = 0
if(!(Test-Path $folderPath))
 {
  New-Underline("Creating $folderPath ...")
  New-Item -Path $folderPath -type directory
 } #end if
$objWMI = [wmiClass]"Win32_Share"
$folder= $folderPath
$share= $shareName
New-Underline "Creating $share"
$errRTN=$objWMI.create($folder, $share, $Type, $MaxAllowed, $description)
funLookup($errRTN.returnValue)
