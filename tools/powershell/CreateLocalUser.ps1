<#
   .Synopsis
    Creates a local user on a local or remote machine.
   .Description
    This script allows you to enter from both the command
    line and from a csv text file. It supports prototyping
    of the command via the -whatif parameter. Using this
    script you can set the user name, password, and description.
    The user is an enabled user upon completion of the script.
    It does not, however, allow you to bypass security restrictions
    governing password policy. The password must meet the requisite
    complexity requirements. By default this script will add the
    user to the local users group. Requires Admin rights.
     PARAMETERS:
     -computer computer upon which to run the command
     -user Name of the user to create. Required
     -password Password for the new user. Required
     -description of user account
     -group the name of the local group to add the user to
      by default the user is added to the local users group
      but the group can be any valid local group
     -text reads user, password, and description from a
      csv file with these exact headings. The format is:
      user, password, description
      testuser1, P@ssw0rd11, "from script"
      When the -text parameter is used, the -user, -password
      and -description parameters are ignored and the values
      in the script are utilized
     -whatif Prototypes the command. Works with both command line input and text input
   .Example
    CreateLocalUser.ps1 -computer MunichServer -user myUser -password Passw0rd^&!
    Creates a local user called myUser on a computer named MunichServer with a password of Passw0rd^&!
   .Example
    CreateLocalUser.ps1 -user myUser -password Passw0rd^&!
    Creates a local user called myUser on local computer with a password of Passw0rd^&!
   .Example
    CreateLocalUser.ps1 -user newAdmin -password Passw0rd^&! -group administrators -description newadmin
    Creates a local user called newAdmin on local computer with a password of Passw0rd^&! The user is added to the local administrators group, with description newadmin.
   .Example
    CreateLocalUser.ps1 -text c:\fso\users.txt
    Creates users listed in text file. The file looks like this:
      User,password,description
      bob,P@ssword,"from Text"
      teresa,P@ssword,"from Text"
      edwin,P@ssword,"from Text"
   .Example
    CreateLocalUser.ps1  -user myuser -password Password -whatif
    Displays what if: Perform operation create user myuser with password Password on computer localhost
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
      [string]
      $computer=$env:computername,
      [string]
      $user,
      [string]
      $password,
      [string]
      $description="scripted user",
      [string]
      $group = "users",
      [string]
      $text,
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
} #end function New-Underline

Function funWhatIf()
{
 if($text)
  {
   if(test-path $text)
    {
     $user=import-csv -path $text
     foreach($strUser in $user)
      {
       $user = $struser.user
       $password = $struser.password
       $description =  $struser.description
       "what if: Perform operation create user $user with password
       $password and description of $description on computer $computer"
      } #end foreach
     exit
    } #end if test-path
  } #end if $text
 ELSE
  {
   "what if: Perform operation create user $user with password
   $password and description of $description on computer $computer"
  }
 exit
} #end funWhatIf

Function funCreateLocalUser($computer,$user,$password,$description,$group)
{
 $erroractionpreference = "SilentlyContinue"
 $error.clear()
 Clear-Host
 $OBJou = [ADSI]"WinNT://$computer,computer"
 $objUser = $objOU.Create("User", $user)
 $objUser.setpassword($password)
 $objUser.put("description",$description)
 $objUser.SetInfo()
 $objGroup = [ADSI]"WinNT://$computer/$group"
 $objGroup.add("WinNT://$computer/$user")
 $objGroup.SetInfo()
 funError
} #end funCreateLocalUser

Function funText()
{
 if(Test-Path $text)
  {
   $user = import-csv -path $text
   foreach($strUser in $user)
    {
     $erroractionpreference = "SilentlyContinue"
     $error.clear()
     $user = $struser.user
     $password = $struser.password
     $description =  $struser.description
     Clear-Host
     $OBJou = [ADSI]"WinNT://$computer,computer"
     $objUser = $objOU.Create("User", $user)
     $objUser.setpassword($password)
     $objUser.put("description",$description)
     $objUser.SetInfo()
     $objGroup = [ADSI]"WinNT://$computer/$group"
     $objGroup.add("WinNT://$computer/$user")
     $objGroup.SetInfo()
     funError
    } #end foreach $user
   exit
  } #end if test-path
 ELSE
  {
    New-Underline -strin "Unable to locate $text" -scolor red -ucolor red
    exit
  } #end else
} #end funText

Function funError()
{
 if($error.count -ne 0)
  {
  New-Underline -strIN "$($error.count) errors occurred on the operation." -scolor red -ucolor red
   For($i = 0 ; $i -le $error.count  -1; $i++)
    {
     New-Underline("Error $i details follow:")
     $error[$i].categoryInfo
     $error[$i].invocationinfo
     $error[$i].exception
    } #end for
   $error.clear()
  } #end if
 Else
  { New-Underline "There are no errors" }
} #end funError

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
if($whatif)    { funWhatIf ; exit}
if($text)      { funText ; exit}
if(!$user) { Get-help $MyInvocation.InvocationName ; exit }
funCreateLocalUser -computer $computer -user $user -group $group -description $description -password $password
