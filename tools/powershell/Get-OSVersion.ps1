<#
   .Synopsis
    Gets the version of the operating system
   .Description
    Gets the version of the operating system such as Windows XP or Windows 7
   .Example
    Get-OSVersion.ps1
    Gets the version of Windows on the local computer
   .Example
    Get-OSVersion.ps1 -computer berlin
    Gets the version of Windows on a remote computer named berlin
   .Inputs
    [string]
   .OutPuts
    [string
   .Notes
    NAME:  Windows 7 Resource Kit
    AUTHOR: Ed Wilson 
    LASTEDIT: 5/20/2009
    KEYWORDS: Get-WmiObject
   .Link
     Http://www.ScriptingGuys.com
#Requires -Version 2.0
#>

Param($computer = "localhost")

Function Get-OSVersion($computer,[ref]$osv)
{
 $os = Get-WmiObject -class Win32_OperatingSystem `
       -computerName $computer
 Switch -regex ($os.Version)
  {
    "5.1.2600" { $osv.value = "Windows XP" }
    "5.1.3790" { $osv.value = "Windows Server 2003" }
    "6.0.6001" 
               {
                 If($os.ProductType -eq 1)
                   {
                    $osv.value = "Windows Vista"
                   } #end if
                 Else
                   {
                    $osv.value = "Windows Server 2008"
                   } #end else
               } #end 6001
     "6.1.7600" {
                 If($os.ProductType -eq 1)
                   {
                    $osv.value = "Windows 7"
                   } #end if
                 Else
                   {
                    $osv.value = "Windows Server 2008 R2"
                   } #end else
               } #end 7600
     DEFAULT { "Version not listed" }
  } #end switch
} #end Get-OSVersion

# *** entry point to script ***
$osv = $null
Get-OSVersion -computer $computer -osv ([ref]$osv)
$osv