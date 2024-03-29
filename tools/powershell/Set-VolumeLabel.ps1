<#
   .Synopsis
    Sets disk volume label on remote or local computer
   .Description
    This script sets disk volume label on remote or local computer.
    This script requires administrative rights.
   .Example
    Set-VolumeLabel.ps1 -disk C: -label "Drive C"
    Sets volume label of disk c to drive c on local computer
   .Example
    Set-VolumeLabel.ps1 -disk C: -label "Drive C" -computername berlin
    Sets volume label of disk c to drive c on remote computer berlin
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
   $computerName=$env:COMPUTERNAME,
   [string]
   [Parameter(Mandatory=$true)]
   $disk,
   [string]
   [Parameter(Mandatory=$true)]
   $label
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

Function Set-VolumeLabel($disk,$label,$computername)
{
 $wmi = get-WmiObject -class Win32_Logicaldisk -computername $computername -filter "DeviceID = '$disk'"
 $wmi.VolumeName = $label
 $wmi.Put()
}

# *** Entry point to script ***
If(-not (Test-IsAdministrator)) { New-Underline "Admin rights are required for this script" ; exit }
New-Underline "Setting disk $disk to label $label"
Set-VolumeLabel -disk $disk -label $label -computername $computername
