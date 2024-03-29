<#
   .Synopsis
    Lists the members of the Domain Admins group. 
   .Description
    This script lists the members of the domain admins group. 
    It will translate group memberships, and nested group memberships and produce a list
    of the members of the Domain Admins group and how they obtain that
    membership by printing the group that contains the user account.
    Groups that are members of the Domain Admins group are also printed
    out as well as how they obtain their membership. Additionally, the
    distinguished name of each user and group is displayed.
   .Example
    FindAdmin.ps1  -query
    Lists the members of the domain admins group on
    the current domain
   .Example
    FindAdmin.ps1  -query -domain nwtraders.com
    Lists the members of the domain administrators group on
    the nwtraders.com domain
   .Example
    FindAdmin.ps1  -query -group "cn=mytest,ou=myou"
    Lists the members of the mytest group in the myou
    organizational unit in the default domain
   .Example
    FindAdmin.ps1  -query -domain nwtraders.com -whatif
    Displays what if: Perform operation query domain admins members
    for the nwtraders.com domain
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
      $domain = ($env:userDnsDomain).tolower(),
      [string]
      $group,
      [switch]$query,
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
} #end New-Underline function

Function funWhatIf()
{
 "what if: Perform operation query $group members for $domain domain"
 exit
} #end funWhatIf

Function funQueryGroup($group)
{
 $objGroup=[adsi]"LDAP://$group"
   $script:groupMembership += $objGroup.member
   foreach($member in $objGroup.member)
    {
     $objMember = [adsi]"LDAP://$member"
           $script:usersAndGroups += @{$objMember.name=$objGroup.name}
        if($objMember.objectCategory -match "person")
          {
            $script:memberUsers += @{$objMember.name=$objGroup.name}
          } #end if person
       If($objMember.objectCategory -match "group")
         {
           $script:memberGroups += @{$objMember.name=$objGroup.Name}
           funQueryGroup($objMember.distinguishedname)
         } #end if match group
  } #end foreach
} #end funQueryGroup

Function funOutPut()
{
 New-Underline("Group $group Membership is:")
 $groupMembership
 "`n"
 New-Underline("users who are members of $group  are: ")
 $memberUsers
 "`n"
 New-Underline("groups who are members of $group are: ")
 $memberGroups
 "`n"
 New-Underline("users and groups are:")
 $usersAndGroups
 "`n"
} #end funoutput

# *** Entry Point to script

$script:groupMembership = $script:memberUsers=$script:memberGroups= $null
$script:usersAndGroups=$null
if($domain)
   {
    $domain = $domain -replace("^","dc=")
    $domain = $domain -replace("\.",",dc=")
   }
if($group)     { $group = "$group,$domain" }
if(!$group) { $group = "cn=domain admins,cn=users,$domain" }
if($query)     { funQueryGroup($group) ; funoutput}
if($whatif)    { funWhatIf ; exit }
if(!$query) { Get-Help $MyInvocation.InvocationName ; exit }
