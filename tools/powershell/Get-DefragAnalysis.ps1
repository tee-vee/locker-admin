
<#
   .Synopsis
    Performs a defrag analysis of hard drive
   .Description
    This script Performs a defrag analysis of hard drive on local or remote computer.
    This script requires administrator rights.
   .Example
    Get-DefragAnalysis.ps1
    Performs defrag analysis of hard drive on local computer
   .Example
    Get-DefragAnalysis.ps1 -cn berlin
    Performs defrag analysis of hard drive on remote computer berlin
   .Inputs
    [string]
   .OutPuts
    OutPuts
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
   [Parameter(Position=0,ValueFromPipeline=$true)]
   [String]
   [Alias("CN")]
   $Computer=$env:COMPUTERNAME
)# end param

# Begin Functions here
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


Function Get-OsMode
{
  <#
   .Synopsis
    This function will determine if the script is running on a 64 bit OS or
    on a 32 bit OS. In addition, it will check for x86 mode on a 64 bit OS. 
   .Description
    This function will determine if the script is running on a 64 bit OS or
    on a 32 bit OS. In addition, it will check for x86 mode on a 64 bit OS. 
   .Example
    Get-OsMode -sixFour
    Returns true if a 64 bit OS running on 64 bit hardware and the PowerShell
    console is running in 64 bit mode. 
   .Example
    Get-OsMode -eightSix
    Returns true if a 64 bit OS running on 64 bit hardware but the PowerShell
    console is running in x86 mode. 
   .Example
    Get-OsMode -threeTwo
    Returns true if a 32 bit OS running on 32 bit hardware and the PowerShell
    console is running in 32 bit mode. 
   .Example
    Get-OsMode -sixFour
    Returns true if a 64 bit OS running on 64 bit hardware and the PowerShell
    console is running in 64 bit mode. 
   .Example
    if(Get-OsMode -eightSix) { "This script does not run in x86 mode" ; exit }
    Checks to see if the script is running on a 64 bit OS and hardware, but 
    PowerShell has been started in X86 mode. If it has, a message is displayed
    and the script exits. If not, nothing happens.
   .Parameter sixFour
    Causes a check to be made for 64 bit OS, 64 bit hardware, and PowerShell
    running in 64 bit mode (normal operation). 
   .Parameter eightSix
    Causes a check to see if have 64 bit OS, 64 bit hardware, and PowerShell 
    running in X86 mode.
   .Parameter threeTwo
    Causes a check to see if have a 32 bit OS, 32 bit hardware, and PowerShell
    running in X86 (normal for 32 bit).
   .Notes
    NAME:  Get-OsMode
    AUTHOR: ed wilson, msft
    LASTEDIT: 04/13/2011 21:21:39
    KEYWORDS: Operating System, Version Information
    HSG: 
   .Link
     Http://www.ScriptingGuys.com
 #Requires -Version 2.0
 #>
 Param(
 [switch]$sixFour,
 [switch]$eightSix,
 [switch]$threeTwo
 )#end param
 
 Set-StrictMode -Version Latest
 
 $osArch = ([wmi]"root\cimv2:Win32_OperatingSystem=@").osarchitecture
 $cpuWidth = ([wmi]"root\cimv2:Win32_processor.deviceID='CPU0'").AddressWidth
 $shellEnv = $env:PROCESSOR_ARCHITECTURE

 if($sixFour)
   { 
    if($osarch -match '64' -AND $cpuWidth -match '64' -AND $shellEnv -match '64') 
      { $true } else { $false }
   }#end 64bit
 if($eightSix)
   {
    if($osarch -match '64' -AND $cpuWidth -match '64' -AND $shellEnv -match '86') 
      { $true } else { $false }
    }#end x86mode
 if($threeTwo)
   {
    if($osarch -match '32' -AND $cpuWidth -match '32' -AND $shellEnv -match '86') 
      { $true } else { $false }
   }#end 32bit
 } #end function Get-OsMode 

Function get-DefragAnalysis($computer,$filePath)
{
  Foreach($scomputer in $Computer)
{
 Get-WmiObject -Class win32_volume -Filter "DriveType = 3" `
       -ComputerName $scomputer | 
 ForEach-Object `
 -Begin { "Testing $scomputer" } `
 -Process { 
   "Testing drive $($_.name) for fragmentation. Please wait ..."
   $RTN = $_.DefragAnalysis()
  "Defrag report for $computer" >> "$FilePath\Defrag$computer.txt"
  "Report for Drive $($_.Name)" >> "$FilePath\Defrag$computer.txt"
  "Report date: $(Get-Date)" >> "$FilePath\Defrag$computer.txt"
  "--------------------------------" >> "$FilePath\Defrag$computer.txt"
   $RTN.DefragAnalysis | 
   Format-List -Property [a-z]* >> "$FilePath\Defrag$computer.txt"
} `
 -END { 
        New-Underline "Completed testing $computer" 
        "Report stored at $FilePath\Defrag$computer.txt"
      }
 } #end foreach computer
} #end function get-defraganalysis

# *** Entry point to script ***
if(Get-OsMode -eightSix) { New-Underline "This script does not run in x86 mode" ; exit }
If(-not (Test-IsAdministrator)) { New-Underline "Admin rights are required for this script" ; exit }
$FilePath = [io.path]::GetTempPath()
Get-DefragAnalysis -computer $Computer -filepath $filepath

