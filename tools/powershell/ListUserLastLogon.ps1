<#
   .Synopsis
    Description
    This script will list the lastlogon date of a
    specific user onto a local or remote domain.
   .Description
    This script will list the lastlogon date of a
    specific user onto a local or remote domain. The
    script will allow multiple users to be supplied
    for the -users parameter. All users who have logged
    on will have their last logon dates displayed if the
    script is run with the -all parameter. The user name
    must be supplied must be the logon name, not the
    display name. This script supports prototyping by
    using the -whatif switch.
     PARAMETERS:
     -domain the domain to query for user information
     -user the user or users to query for lastlogon time.
      Users who have never logged on will not have a time
      displayed. This value must be the user logon /
      sAMAccountName value
     -all displays all users lastlogon time
     -whatif Prototypes the command
   .Example
    ListUserLastLogon.ps1  -all
    Displays all users lastlogon value from the current
    domain.
   .Example
    ListUserLastLogon.ps1  -all -domain "dc=nwtraders,dc=com"
    Displays all users lastlogon value from the nwtraders.com
    domain. The quotation marks are required when using this syntax
   .Example
    ListUserLastLogon.ps1  -users mytestuser -domain nwtraders.com
    Displays lastlogon value for the user named mytestuser from the
    nwtraders.com domain.
   .Example
    ListUserLastLogon.ps1  -users mytestuser -domain 192.168.2.5
    Displays lastlogon value for the user named mytestuser from the
    nwtraders.com domain. The IP address 192.168.2.5 resolves to one of
    the Domain Controlers
   .Example
    ListUserLastLogon.ps1  -users mytestuser, auser -domain nwtraders
    Displays lastlogon value for the user named mytestuser, and the user
    named auser from the nwtraders.com domain. The nwtraders name resolves
    to nwtraders.com
   .Example
    ListUserLastLogon.ps1  -users mytestuser, auser -domain berlin
    Displays lastlogon value for the user named mytestuser, and the user
    named auser from the nwtraders domain. It queries directly to the
    Domain Controller named berlin
   .Example
    ListUserLastLogon.ps1 -users mytestuser -domain nwtraders.com -whatif
    Displays what if: Perform operation obtain lastlogon time for user
    mytestuser from the nwtraders.com domain
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
      $domain,
      $users,
      [switch]$all,
      [switch]$whatif
      ) #end param
      
# Begin Functions

Function funWhatIf()
{
 "what if: Perform operation obtain lastlogon time for user $user from
  the $domain domain"
 exit
} #end funWhatIf

function funGetAllUsers()
{
 $attribute = "lastlogon"
 $searcher = new-object DirectoryServices.DirectorySearcher([ADSI]"$domain")
 $searcher.filter = "(&(objectClass=user)(objectCategory=person))"
 $users = $searcher.findall()
   foreach($user in $users)
    {
     if($user.properties.item("$attribute") -ne 0)
       {
        $attributeValue = [datetime]::FromFileTime([int64]::Parse($user.properties.item($attribute)))
        "$($user.properties.item(`"name`")) $attributeValue"
       } #end if user
    } #end foreach user
} #end funGetAllUsers

function funGetUsers()
{
 $attribute = "lastlogon"
 $searcher = new-object DirectoryServices.DirectorySearcher([ADSI]"$domain")
 ForEach($suser in $users)
  {
   $searcher.filter = "(&(objectClass=user)(sAMAccountName=$suser))"
   $colusers = $searcher.findall()
     foreach($user in $colUsers)
      {
       if($user.properties.item("$attribute") -ne 0)
       {
        $attributeValue = [datetime]::FromFileTime([int64]::Parse($user.properties.item($attribute)))
        "$($user.properties.item(`"name`")) $attributeValue"
       } #end if user
      } #end foreach user
  } #end foreach suser
} #end funGetUsers

# *** Entry Point to script ***
if($domain) { $domain = "LDAP://$domain" }
if($whatif)    { funWhatIf }
if($users)      { funGetUsers }
if($all)       { funGetAllUsers }
