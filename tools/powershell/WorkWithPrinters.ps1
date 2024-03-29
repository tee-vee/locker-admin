<#
   .Synopsis
    Manage of printer on a local or remote machine.
   .Description
    This script allows you to manage printers on either a local or remote computer. 
    This script requires admin rights.
   .Example
    PARAMETERS:
    -computer Specifies the name of the computer upon which to run the script
    -printer      printer name
    -action       <list, setDefault, getDefault, test, pause, resume, cancel>
   .Example
    WorkWithPrinters.ps1 -computer MunichServer -action list
    Lists all the printers on a computer named MunichServer
   .Example
    WorkWithPrinters.ps1 -computer MunichServer -action setDefault -printer hp
    Sets a printer whose name is like hp to the default printer on the munich server
    (assumes there is only one printer whose names is like hp. You need to specify
     enough to uniquely identify the printer)
   .Example
    WorkWithPrinters.ps1 -action test -printer hp
    Sends a test page to the printer whose name is like hp on the local server
    (assumes there is only one printer whose names is like hp. You need to specify
     enough to uniquely identify the printer)
   .Example
    WorkWithPrinters.ps1 -action pause -printer hp
    Pauses the printer whose name is like hp on the local server
    (assumes there is only one printer whose names is like hp. You need to specify
     enough to uniquely identify the printer)
   .Example
    WorkWithPrinters.ps1 -action resume -printer hp
    Resumes the printer whose name is like hp on the local server
    (assumes there is only one printer whose names is like hp. You need to specify
     enough to uniquely identify the printer)
   .Example
    WorkWithPrinters.ps1 -action cancel -printer hp
    Cancels all print jobs on the printer whose name is like hp on the local server
    (assumes there is only one printer whose names is like hp. You need to specify
     enough to uniquely identify the printer)
   .Inputs
    [string]
   .OutPuts
    [string]
   .Notes
    NAME:  Windows 7 Resource Kit
    AUTHOR: Ed Wilson
    LASTEDIT: 6/20/2009
    KEYWORDS: printer
   .Link
    Http://www.ScriptingGuys.com
#Requires -Version 2.0
#>
Param(
  [string]$computer = $env:COMPUTERNAME,
  [string]$printer,
  [string]$action
) #end param

# Begin Functions
function funlist()
{
 $Query = "Select name from $class"
 Get-WmiObject -query $Query -computername $computer |
 Select name
 exit
} #end funlist function

function funDefault()
{ "Setting defaults on $printer printer ..."
 $query = "Select * from $class where name like '%$printer%'"
 $default = Get-WmiObject -query $Query -computername $computer
 $rtn=$default.setDefaultPrinter()
 Get-ReturnCodeValue($rtn)
 exit
} #end fundefault function

function funTest()
{ "Printing test page on $printer printer ..."
 $query = "Select * from $class where name like '%$printer%'"
 $default = Get-WmiObject -query $Query -computername $computer
 $rtn=$default.PrintTestPage()
 Get-ReturnCodeValue($rtn) 
 exit
} #end funtest function
 
function funPause()
{ "Pausing $printer printer ..."
 $query = "Select * from $class where name like '%$printer%'"
 $default = Get-WmiObject -query $Query -computername $computer
 $rtn=$default.Pause()
 Get-ReturnCodeValue($rtn)
 exit
} #end funpause function

function funResume()
{ "Resuming $printer printer ... "
 $query = "Select * from $class where name like '%$printer%'"
 $default = Get-WmiObject -query $Query -computername $computer
 $rtn=$default.Resume()
 Get-ReturnCodeValue($rtn)
 exit
} #end funresume function

function funCancel()
{ "Canceling all print jobs on $printer printer ..."
 $query = "Select * from $class where name like '%$printer%'"
 $default = Get-WmiObject -query $Query -computername $computer
 $Rtn=$default.CancelAllJobs()
 Get-ReturnCodeValue($rtn)
 exit
} # end funcancel function

function funGetdefault()
{ "Getting default printer ..."
  $rtn=Get-WmiObject -class win32_printer -computername $computer -filter "default = $true"
  Get-ReturnCodeValue($rtn)
  exit
}

function Get-ReturnCodeVaLUE($RTN)
{
 switch($rtn.ReturnValue)
 {
  0 {"Operation was a success"}
  5 { "Access Denied" }
  Default { "Error $($rtn.ReturnValue) was returned."}
 } #end switch
} # END Function Get-ReturncodeValue
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
$class = "Win32_Printer"
if($action)
{
 switch($action)
  {
   "list" { funlist }
   "setDefault" { funDefault }
   "getDefault" { funGetDefault }
   "Test" { funTest }
   "pause" { funPause }
   "resume" { funResume }
   "cancel" { funCancel }
   "default" { "default behavior. Listing printers." }
  } #end switch
} #end if