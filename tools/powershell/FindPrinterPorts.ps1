<#
   .Synopsis
    Allows for the management of printer ports on a local or remote machine.
   .Description
    This script enables management of printer ports on a local or remote machine. 
    It does this by listing printer ports within a particular IP address range.
   .Example
    FindPrinterPorts.ps1 -computername MunichServer -network "10"
    Sets a class A network address of 10 on the remote server munich server. Only
    Printer ports assigned to the 10.x.x.x range will be returned
   .Example
    FindPrinterPorts.ps1 -network "192.168"
    Returns printer ports in the 192.168.x.x range on the local machine
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
 [string]
 $computer = $env:computername,
 [Parameter(Mandatory=$true)]
 [string]
 $network
)#end param
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
# *** Entry point to script ***


New-Underline "Below are printer ports on $computer in the $network range:`n"
Get-WmiObject -class Win32_TcpIpPrinterPort -computername $computer |
where-object { $_.name -match $network } | 
ForEach-Object($_){
 if($($_.SNMPEnabled))
 {
  New-Underline "Following printer is SNMP enalbled"
  Write-Host "`t$($_.name), $($_.portNumber), $($_.SNMPCommunity), $($_.SNMPDevIndex)`n"
 } #end if
 ELSE
 {
  Write-Host -foregroundColor yellow "`tFollowing printer is NOT SNMP enabled`n"
  write-host "`t$($_.name), $($_.portNumber)"
 } #end else
} #end foreach