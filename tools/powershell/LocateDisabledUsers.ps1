<#
   .Synopsis
    Locates disabled users a local or remote domain by
    supplying the netbios name of the domain.
   .Description
    This script locates disabled users a local or remote domain by
    supplying the netbios name of the domain.
    The script can query multiple domains by accepting
    more than one value for the -domain parameter. The
    script also supports using -whatif to prototype the
    command prior to execution
   .Example
    LocateDisabledUsers.ps1
    Queries disabled user accounts. The domain queried is
    the local logged on users domain from the machine
    that launched the script
   .Example
    LocateDisabledUsers.ps1 -domain nwtraders, contoso
    Queries disabled user accounts in the nwtraders domain and
    in the contoso domain. The script is executed locally
   .Example
    LocateDisabledUsers.ps1 -domain nwtraders -whatif
    Displays what if: Perform operation locate disabled
    users from the nwtraders domain.The query will execute
    from the localhost computer
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
      $domain=$env:userdomain,
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
} #end New-UnderLine function

Function funWhatIf()
{
 foreach($sDomain in $Domain)
  {
   "what if: Perform operation locate disabled users from the $sDomain domain"
  }
 exit
} #end funWhatIf

Function funQuery()
{
 Foreach($sDomain in $domain)
  {
   $strOutput = Get-WmiObject -Class win32_useraccount -filter `
   "domain = ""$sDomain"" AND disabled = 'true'"
   $count = ($strOutput | Measure-Object).count
   If($count -eq 0)
    {
     New-UnderLine -scolor green -ucolor darkyellow -strIN `
     "There are no disabled accounts in the $sDomain"
    } #end if
   ELSE
    {
     New-UnderLine -scolor red -ucolor darkyellow -strIN `
     "$count disabled in the $sDomain domain -- List follows:"
     format-table -property name, sid -AutoSize -inputobject $strOutput
    } #end else
  } #end foreach
 exit
} #end funquery

# *** Entry Point to script ***
if($whatif)   { funWhatIf }
funQuery
