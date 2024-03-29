<#
   .Synopsis
    Displays the processor architecture from a local or remote computer
   .Description
    This script displays the processor architecture from a local or remote computer
   .Example
    Get-ProcessorArchitecture.ps1 -computerName Berlin
    Displays the processor architecture from a remote computer named berlin
   .Example
    Get-ProcessorArchitecture.ps1 
    Displays the processor architecture from local computer  
   .Inputs
    [string]
   .OutPuts
    [string]
   .Notes
    NAME:  Windows 7 Resource Kit
    AUTHOR: Ed Wilson 
    LASTEDIT: 6/1/2009
    KEYWORDS:
   .Link
     Http://www.ScriptingGuys.com
     Get-WmiObject
     Win32_Processor
#Requires -Version 2.0
#>

Param(
  [Parameter(Position=1,ValueFromPipeLine=$true)]
  [string]
  [alias("CN")]
  $Computer = $env:COMPUTERNAME
) #end param

Function Get-ProcessorArchitecture
{
  switch ($args) 
  {
    0 {"X86"}
	1 {"MIPS"}
	2 {"Alpha"}
	3 {"PowerPC"}
	6 {"Intel Itanium"}
	9 {"X64"}
	default {"unable to determine processor type"}
  }
} #end Get-ProcessorArchitecture

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

# *** Entry Point to Script ***

New-UnderLine "The processor on $env:computername is: "
Get-ProcessorArchitecture (Get-WmiObject -class win32_processor -computerName $computer).Architecture 
