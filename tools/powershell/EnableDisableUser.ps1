<#
   .Synopsis
    Enables or Disables a local user on either a local or remote machine.
   .Description
    This script enables or disables a local user on either a local or remote computer.
    Requires admin rights.
     PARAMETERS:
     -computer Specifies the name of the computer upon which to run the script
     -a(ction) Action to perform < e(nable) d(isable) >
     -user     Name of user to modify
     -password password of user. Requried when action is enable
   .Example
    EnableDisableUser.ps1 -computer MunichServer -user myUser -password Passw0rd^&! -a e
    Enables a local user called myUser on a computer named MunichServer
    with a password of Passw0rd^&!
   .Example
    EnableDisableUser.ps1 -user myUser -a d
    Disables a local user called myUser on the local machine
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
 [string]
 $computer = $env:computerName,
 [string]
 $a,
 [Parameter(Mandatory=$true)]
 [string]
 $user,
 [string]
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
} #end funLine function

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
$EnableUser = 512 # ADS_USER_FLAG_ENUM enumeration value from SDK
$DisableUser = 2  # ADS_USER_FLAG_ENUM enumeration value from SDK
if(!$user)
      {
       $(Throw 'A value for $user is required.')
	  }
$ObjUser = [ADSI]"WinNT://$computer/$user"
switch($a)
{
 "e" {
      if(!$password)
	    {
		  $(Throw 'a value for $password is required.')
	    }
      $objUser.setpassword($password)
      $objUser.description = "Enabled Account"
      $objUser.userflags = $EnableUser
      $objUser.setinfo()
	 }
 "d" {
      $objUser.description = "Disabled Account"
      $objUser.userflags = $DisableUser
      $objUser.setinfo()
	 }
 DEFAULT
        {
		 "You must supply a value for the action."
		}
} #end switch