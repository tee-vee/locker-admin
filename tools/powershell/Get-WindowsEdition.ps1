<#
   .Synopsis
    Gets the version of Windows that is installed on the local computer
   .Description
    Gets the version of Windows that is installed on the local computer. This 
    is information such as Windows 7 Enterprise.
   .Example
    Get-WindowsEdition.ps1
    Displays version of windows on local computer. 
   .Inputs
    none
   .OutPuts
    [string]
   .Notes
    NAME:  Get-WindowsVersion.ps1
    AUTHOR: Ed Wilson 
    LASTEDIT: 5/20/2009
    KEYWORDS: Windows 7 Resource Kit
   .Link
     Http://www.ScriptingGuys.com
#Requires -Version 2.0
#>


$strPattern = "version"
$text = net config workstation

switch -regex ($text) 
{
  $strPattern { Write-Host $switch.current }
}
