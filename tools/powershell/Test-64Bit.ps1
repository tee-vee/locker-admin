<#
   .Synopsis
    Detects the version (64 bit / 32 bit) of PowerShell that is running.
   .Description
    This script detects the version of Windows Powershell that is running.
    The value that is returned is either true or false, depending on the switch
    used when the script is launched.  This information is vital when working
    on a 64 bit version of Windows, and attempting to run a script that uses a 
    32 bit com object. 
   .Example
    Test-64Bit.ps1 -ThirtyTwoBit
    Returns true on a 32 bit version of Powershell, false on a 64 bit.
   .Example
    Test-64Bit.ps1 -SixtyFourBit
    Returns true on a 64 bit version of Powershell, false on a 32 bit.
   .Example
    Test-64Bit.ps1 -S
    Returns true on a 64 bit version of Powershell, false on a 32 bit.
   .Example
    if(.\Test-64Bit.ps1 -s) { "sixty four" }
    Displays "sixty four" if run in a 64 bit version of Powershell. This 
    illustrates using the Test-64bit.ps1 script in another script to check
    operating system version.
   .Inputs
    "none"
   .OutPuts
    [boolean]
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
 [switch]$SixtyFourBit,
 [switch]$ThirtyTwoBit
)#end param

Function Test-64
 { If($env:PROCESSOR_ARCHITECTURE -match '64') { $true } ELSE { $false }}

Function Test-32
 { if($env:PROCESSOR_ARCHITECTURE -match '86') { $true } ELSE { $false} }
 
# *** Entry Point to Script *** 

if($SixtyFourBit) { Test-64 }
if($ThirtyTwoBit) { Test-32 }
