<#
   .Synopsis
    Defrags fixed disks 
   .Description
    Defragments fixed disks on local or remote computer
   .Example
    Start-Defrag.ps1
    Defragments all fixed disks on local comptuer
   .Example
    Start-Defrag.ps1 -computer berlin
    Defragments all fixed disks on remote computer named berlin
   .Example
    Start-Defrag.ps1 -computer -details
    Defragments all fixed disks on local computer. Displays detailed
    fragmentation report.
   .Inputs
    string
   .OutPuts
    string
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
   $computer=$env:COMPUTERNAME,
   [switch]$details
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

Function Start-Defrag($computer)
{
 $wmi = Get-WmiObject -class win32_volume -ComputerName $computer -Filter "Drivetype = 3"
  Foreach ($i in $wmi)
   {
    New-Underline "Defraging $($i.DriveLetter) on $computer"
    $rtn = $i.Defrag($true)
    Get-DefragError($rtn.returnValue)
    if($rtn.returnValue -eq 0)
       {
        if($details)
          { Get-DefragResult($rtn.DefragAnalysis) }
       }
   } #end foreach
} # end Start-Defrag

Function Get-DefragError($err)
{
 Switch($err)
 {
  0 {"Success"}
  1 {"Access Denied"}
  2 {"Not Supported"}
  3 {"Volume Dirty Bit Is Set"}
  4 {"Not Enough Free Space"}
  5 {"Corrupt Master File Table Detected"}
  6 {"Call Canceled"}
  7 {"Call Cancellation Request Too Late"}
  8 {"Defrag Engine Is Already Running"}
  9 {"Unable To Connect To Defrag Engine"}
  10 {"Defrag Engine Error"}
  11 {"Unknown Error"}
  Default { "Unable to determine problem" }
 } #end switch
} #end Get-DefragError function

Function Get-DefragResult($defragResult)
{
 $defragResult | Format-List -property [a-z]*
} #end Get-DefragResult

# *** Entry point to script ***
if(Get-OsMode -eightSix) { New-Underline "This script does not run in x86 mode" ; exit }
If(-not (Test-IsAdministrator)) { New-Underline "Admin rights are required for this script" ; exit }
Start-Defrag -computer $computer
