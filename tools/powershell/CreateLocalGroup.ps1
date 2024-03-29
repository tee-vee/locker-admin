<#
   .Synopsis
    Creates a local group on either a local or remote machine.
   .Description
    This script creates a local group on either a local or a remote computer.
    Requires admin rights to create a group.
     PARAMETERS:
     -computer Specifies the name of the computer upon which to run the script
     -group    Name of group to create
     -description
   .Example
    CreateLocalGroup.ps1 -computer MunichServer -group MyGroup
    Creates a local group called MyGroup on a computer named MunichServer
   .Example
    CreateLocalGroup.ps1 -group Mygroup
    Creates a local group called MyGroup on local computer
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
  [Parameter(Position=0,ValuefromPipeline=$true)]
  [string]
  [alias("cn")]
  $computer=$env:computername,
  [Parameter(Mandatory=$true)]
  [string]
  $group,
  [string]
  $description = "created by script"
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
} #end function New-Underline

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

# *** Entry point to script ***
If(-not (Test-IsAdministrator)) { New-Underline "Admin rights are required for this script" ; exit }
Try
 {
  $error.Clear()
  $adsi = [ADSI]"WinNT://$computer"
  $objgroup = $adsi.Create("Group", $group)
  $objgroup.SetInfo()
  $objgroup.description = $description
  $objgroup.SetInfo()
  }
Catch {"an error occurred"}
Finally
 {  
  if($error.count -eq 0)
   { New-Underline("Created $group with description $description on $computer") }
   ELSE
   { 
    New-Underline("Unable to create $group with description $description on $computer")
    New-Underline("Please ensure you are running with admin rights")
   } #end else
 } #end finally

