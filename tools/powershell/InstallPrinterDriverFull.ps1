<#
   .Synopsis
    Installs printer driver that is not on system
   .Description
    This script installs a printer driver that is not on system.
    This script requires admin rights.
   .Example
    InstallPrinterDriverFull.ps1 -name "Generic / Text Only" -DriverPath "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\UNIDRV.DLL" `
     -ConfigFile "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\UNIDRVUI.DLL" -DataFile "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTY.GPD" `
     -DependentFiles "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTYRES.DLL", `
      "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTY.INI", `
      "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTY.DLL", `
      "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTYUI.DLL", `
      "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\UNIRES.DLL", `
      "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\TTYUI.HLP", `
      "C:\WINDOWS\System32\spool\DRIVERS\W32X86\3\STDNAMES.GPD"
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
  [Parameter(Mandatory=$true)]
  [string]$name,
  [Parameter(Mandatory=$true)]
  [string]$driverPath,
  [Parameter(Mandatory=$true)]
  [string]$ConfigFile,
  [Parameter(Mandatory=$true)]
  [string]$DataFile,
  [Parameter(Mandatory=$true)]
  [string[]]$DependentFiles
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

New-Underline "Installing $name driver on $env:COMPUTERNAME"

$objWMI = [wmiclass]"Win32_PrinterDriver"
$objDriver=$objWMI.CreateInstance()
$objDriver.name = $name
$objDriver.DriverPath = $driverPath
$objDriver.ConfigFile = $configFile
$objDriver.DataFile = $dataFile
$objDriver.DependentFiles = $dependentFiles
$rtnCode = $objwmi.addPrinterDriver($objDriver)
$rtncode.returnValue
