<#
   .Synopsis
    Evaluates services on a local or remote machine. 
   .Description
    This script evaluates services on a local or remote machine. 
    It then produces a report that tells how many services are auto,
    how many are manual, and how many are disabled. It then
    counts how many accouts are used: localsystem, localservice,
    networkservice, and user defined accounts. Finally, it
    prints detailed information. An option allows you to display
    the report when it is finished.
     PARAMETER:
      -computer name of computer
      -list required. Evaluates services
      -outfile  creates temp file of report
      -display displays temp report in notedpad
   .Example
    EvaluateServices.ps1  -computer "Berlin" -list
    Creates service report on a remote computer named Berlin
    Displays output to the screen
   .Example
    EvaluateServices.ps1 -list
    Creates service report on local computer. Displays output
    to the screen
   .Example
    EvaluateServices.ps1 -list -outfile -display
    Creates service report on local computer. Writes results
    to a temp file, and displays same in notepad
   .Example
    EvaluateServices.ps1 -list -outfile
    Creates service report on local computer. Writes results
    to a temp file, and displays path to the outfile
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
      $computer=$env:computername,
      [switch]$list,
      [switch]$display,
      [switch]$outfile
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

Function funlist()
{
 $a=$m=$d=0
$lsvc=$lsys=$nsvc=$osn=0
$objWMIService = Get-WmiObject -Class win32_service -computer $computer
foreach ($i in $objWMIService)
{
switch ($i.startmode)
{
 "auto"     { $a++ ; $auto+="$($i.name)`r`n"}
 "manual"   { $m++ ; $manual+="$($i.name)`r`n"}
 "disabled" { $d++ ; $disabled+="$($i.name)`r`n"}
 DEFAULT { }
}
switch -regex ($i.startName)
{
 "localsystem"    { $lsys++ }
 "localservice"   { $lsvc++ }
 "NetworkService" { $nsvc++ }
 DEFAULT           { $osn++ ; $otherServiceNames+="$($i.startName)`r`n"}
}
}
$string = New-Underline("There are $($objWMIService.length) services defined on $computer")
$string +=  @"
The $($objWMIService.length) services on $computer start as follows:
automatic $a Manual $m disabled $d
The automatic services are:
---------------------------
$auto
The manual services are:
------------------------
$manual
The disabled services are:
--------------------------
$disabled
The services start using the following accounts:
 localsystem $lsys times
 localService $lsvc times
 networkService $nsvc times
 Other user id $osn times
"@
if($osn -ne 0)
{
$string+= @"
The other ids in use are listed here:
$otherServiceNames
You should investigate the passwords being used by:
$otherServiceNames
"@
}
if(!$outfile)
 {
  $string
 }
if($outfile -and !$display)
 {
  $local:file = [io.path]::GetTempFileName()
  out-file -filepath $file+".txt" -inputobject $string
  "Report for $computer was written to $local:file"
 }
if($outfile -and $display)
{
  $local:file = [io.path]::GetTempFileName()
  $local:file +=".txt"
  out-file -filepath $file -inputobject $string
  invoke-expression ("notepad $local:file")
 }
} #end function funlist

# *** Entry Point ***

if($list) { funlist ; exit}
if(!$list) { Get-Help $MyInvocation.InvocationName -full; exit }


