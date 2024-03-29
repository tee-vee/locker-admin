<#
   .Synopsis
    Lists shared printers on remote computer, allows to add printer 
    connection to local computer
   .Description
    This script will list shared printers on a remote comptuer. 
    It also gives you the ability to add a printer connection 
    from the remote computer to your computer. It requires admin
    rights.
   .Example
    ListSharedPrintersAddPrintConnection.ps1 -printerpath "\\berlin\testprinter"
    Adds shared testprinter from computer berlin to local computer
   .Example
    ListSharedPrintersAddPrintConnection.ps1 -computer  berlin -list
    Lists shared printers from computer berlin
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
  $computer=$env:COMPUTERNAME,
  [string] 
  $printerPath, 
  [switch]$list
) #end param

# begin functions

Function Add-PrinterConnection([string]$printerPath)
{
 Write-Host -foregroundcolor cyan "Adding printer $printerpath"
  $printClass = [wmiclass]"win32_printer"
  $printClass.AddPrinterConnection($printerPath)
} #end Add-PrinterConnection

Function Get-Printer($computer)
{
 Get-WmiObject -class Win32_Printer -computer $computer
} #end Get-Printer

Function Format-Printer($printObject)
{
 Write-Host -foregroundcolor cyan "Shared printers on $computer"
 $printObject | 
 Where-Object { $_.sharename } |
 Format-Table -property sharename, location, comment -autosize -wrap
} #end Format-Printer

Function Get-SuccessCode($code)
{
 if($code.ReturnValue -eq 0)
  { Write-Host -foregroundcolor green "Add Printer connection suceeded!" }
 Else
  { Write-Host -foregroundcolor red "Add Printer connection failed with $($code.returnvalue)" }
} #end get-successcode

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
# *** Entry Point to Script ***
If(-not (Test-IsAdministrator)) { New-Underline "Admin rights are required for this script" ; exit }
if($list) { Format-Printer(Get-Printer($computer)) ; exit }
if($printerPath) 
  { Get-SuccessCode -code (Add-PrinterConnection($printerPath))  ; exit }