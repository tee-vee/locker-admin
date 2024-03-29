<#
   .Synopsis
    Scans for a specific update, or updates on a local
    or remote machine. The script will also produce a
    listing of all updates installed on the machine. The
    script supports prototyping by using the -whatif
    parameter. Note: the script needs admin rights on the
    machine to which it is targeting. Also ensure the
    firewall has enabled remote admin:
    netsh firewall set service remoteadmin
   .Description
    This script scans for a specific update on a local
    or remote machine. The script will also produce a
    listing of all updates installed on the machine. The
    script supports prototyping by using the -whatif
    parameter. Note: the script needs admin rights on the
    machine to which it is targeting. Also ensure the
    firewall has enabled remote admin:
    netsh firewall set service remoteadmin
   .Example
    ScanForSpecificUpdate.ps1  -computer "Berlin" -all
    Creates a list of all installed updates on a remote
    computer named Berlin
   .Example
    ScanForSpecificUpdate.ps1  -security
    Creates a list of all installed security updates on the
    local machine
   .Example
    ScanForSpecificUpdate.ps1  -update kb945008, KB943078
    Creates a list of installed updates on the local machine
    that match update ID's kb945008, KB943078. If the update
    has not been installed nothing is returned
   .Example
    ScanForSpecificUpdate.ps1 -update kb945008, KB943078 -whatif
    Displays what if: Perform operation query for updates kb945008, KB943078
    on localhost
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
      [Parameter(Position=1)]
      $computer=$env:COMPUTERNAME,
      [string[]]
      $update,
      [switch]$all,
      [switch]$security,
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
} #end funLine function

Function funWhatIf()
{
 if($update)
  {
   "what if: Perform operation query for updates $update on $computer"
  }
 if($all)
  {
   "what if: Perform operation query for all updates on $computer"
  }
 if($security)
  {
   "what if: Perform operation query for security updates on $computer"
  }
 exit
} #end funWhatIf

Function funUpdate()
{
 foreach($sUpdate in $update)
  {
   Get-wmiobject -class win32_quickFixEngineering -computername $computer `
   -filter "hotFixID = ""$supdate""" |
   format-table -property HotFixID, InstalledBy, Description
  }
  exit
} #end funUpdate

Function funALL()
{
 Get-wmiobject -class win32_quickFixEngineering -computername $computer |
 sort-object -property HotFixID |
 format-table -property HotFixID, InstalledBy, Description
 exit
} #end funAll

Function funSec()
{
 Get-wmiobject -class win32_quickFixEngineering -computername $computer `
 -filter "Description like '%security%'" |
 sort-object -property HotFixID |
 format-table -property HotFixID, InstalledBy, Description
 exit
} #end funSec

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
New-Underline "Scanning for updates on $computer"

if($whatif)    { funWhatIf }
if($update)    { funUpdate }
if($all)       { funall }
if($security)   { funsec }
