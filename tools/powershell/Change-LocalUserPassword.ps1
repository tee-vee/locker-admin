<#
   .Synopsis
    Sets local user password on one or more computers
   .Description
    This script sets local user password on one or more computers
    It can read a text file of comptuer names (one per line) and 
    connect to those computers to change a local user password. 
    This script requires admin rights.
     PARAMETERS
      -computer name of the computer
      -path path to the computer list. Causes script to use file for 
            computer name
      -user the name of the user whose password is to be reset
      -password the password to user
   .Example
    Change-LocalUserPassword.ps1 -user administrator -password NewPassword
    Changes the local administrator password to NewPassword on local computer
   .Example
    Change-LocalUserPassword.ps1 -user bob -password NewPassword
    Changes the local user bob password to NewPassword on local computer
   .Example
    Change-LocalUserPassword.ps1 -user administrator -password NewPassword 
    -path c:\computerlist.txt
    Changes the local administrator password to NewPassword on each computer in 
    the c:\computerlist.txt file. 
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
    $path,
    [string]
    [Parameter(Mandatory=$true)]
    $user,
    [string]
    [Parameter(Mandatory=$true)]
    $password
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
If(-not (Test-IsAdministrator)) { New-Underline "Admin rights are required for this script" ; exit }
if($path)
{
 $computers = Get-Content -path $path
 Foreach($Computer in $computers)
  {
   New-Underline "Setting $user password on $computer"
   $de = [adsi]"WinNT://$computer/$user,user"
   $de.SetPassword($Password)
   $de.SetInfo()
  } #end foreach
} #end if
Else
{
   New-Underline "Setting $user password on $computer"
   $de = [adsi]"WinNT://$computer/$user,user"
   $de.SetPassword($Password)
   $de.SetInfo()
}