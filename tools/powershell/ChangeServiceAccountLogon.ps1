<#
   .Synopsis
    Changes the account and password used by
    a service on a local or remote computer.
    This script also will list all services
    and the service accounts used by
    those accounts. In addition you can use
    this script to stop and to start a service.
    This feature is useful if you want test the
    account you have specified for the service.
    You can use this script to change the service
    account password, by simply supplying the same
    startName for the service, and then providing
    a new password to the -password parameter. To
    ensure the password supplied is correct, make
    sure you stop and start the service. If your
    service takes a while to stop and to start,
    you may wish to supply a value for the -pause
    parameter. This will cause a delay between the
    stopping and the starting of the serice.
    This script supports prototyping by using the
    -whatif switch. This script will support the
    use of unique partial parameter names
   .Description
    Uses Params to allow modification of script at runtime
    Uses funHelp function to display help
    Uses New-Underline function to underline output
   .Example
    ChangeServiceAccountLogon.ps1  -computer "Berlin" -list
    Lists all services and service accounts on a remote computer named Berlin
   .Example
    ChangeServiceAccountLogon.ps1 -servicename bits -password @#$lkj0*^jkl -startname BitsServiceAccount
    Changes the bits service to use a user defined account named BitsServiceAccount with a password of @#$lkj0*^jkl on the local machine
   .Example
    ChangeServiceAccountLogon.ps1 -serv bits -startN localsystem -stop -start -password $null
    Changes the bits service to use the localsystem account. Stops the service, starts the service and tells it to use a system password. Note the use of partial parameter names.
   .Example
    ChangeServiceAccountLogon.ps1 -servicename bits -password @#$lkj0*^jkl -accountname BitsServiceAccount -whatif
    Displays what if: Perform operation change bits service to use the BitsServiceAccount account with a password of @#$lkj0*^jkl
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

param(
      $computer=$env:computername,
      $serviceName,
      $startName,
      $password,
      $pause = 3,
      [switch]$list,
      [switch]$start,
      [switch]$stop,
      [switch]$whatif
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
} #end New-Underline function

Function funWhatIf()
{
 "what if: Perform operation change $serviceName service to use the
 $startName account with a password of $password"
 exit
} #end funWhatIf

Function funError($opName, $errIN)
{ "checking errors from $opName ..."
 switch($errIN)
  {
   0 { New-Underline -strIN "$opName $serviceName was successful" -scolor green }
   2 { New-Underline -strIN "$opName $serviceName reports access denied" -scolor red}
   5 { New-Underline -strIN "$opName $serviceName reports cannot accept control" -scolor red}
   10 { New-Underline -strIN "$opName $serviceName reports already started" -scolor red}
   14 { New-Underline -strIN "$opName $serviceName reports service disabled" -scolor red}
   Default { New-Underline -strIN "$opName $serviceName reports error $errIN" -scolor red }
} #end switch
} #end funerror
Function funList()
{
 New-Underline -strIN "Services on $computer" -scolor Yellow -ucolor cyan
 Get-wmiobject -class Win32_service -computername $computer |
 Format-table -property Name, DisplayName, StartName -autosize
} #end funList

Function funChangeServiceAccount()
{
 if(!$startName) { New-Underline -strIn "Missing start name" -scolor red }
 New-Underline -strin "`nChanging the $ServiceName service on $computer ..." -scolor yellow -ucolor cyan
 $displayname=$pathname=$serviceType=$errorControl=$startmode = $null
 $desktopInteract=$loadOrderGroup=$loadOrderGroupDependencies=$null
 $serviceDependencies = $null
 $service = get-wmiobject -class win32_service -computername $computer `
 -filter "name = '$serviceName'"
 $errRTN = $service.change($displayName,$pathName,$serviceType,$errorControl, `
 $startMode,$desktopInteract,$StartName,$password,$loadOrderGroup,`
 $LoadOrderGroupDependencies,$serviceDependencies)
 funError -opName "change Service Account" -errIN $errRTN.returnvalue
} #end funChangeServiceAccount

Function funStop()
{
 New-Underline -strin "`nStopping $serviceName on $computer ..." -scolor yellow -ucolor cyan
 $service = get-wmiobject -class win32_service -computername $computer `
 -filter "name = '$serviceName'"
 if($service.state -eq 'running')
  {
   $errRTN = $service.stopService()
   start-sleep -sec $pause
   funError -opName "Stop Service Account" -errIN $errRTN.returnValue
  }
 ELSE
  { "$serviceName is not running on $computer. Therefore we can not stop it." }
} #end funStop

Function funStart()
{
 New-Underline -strin "`nStarting $serviceName on $computer ..." -scolor yellow -ucolor cyan
 $service = get-wmiobject -class win32_service -computername $computer `
 -filter "name = '$serviceName'"
 if($service.state -eq 'stopped')
  {
   $errRTN = $service.startService()
   funError -opName "Start Service Account" -errIN $errRTN.returnValue
  }
 ELSE
  { "$serviceName is not stopped on $computer. Therefore we can not start it." }
} #end funStart

# Entry Point
if($whatif) { funWhatIf }
if($list) { funList }
if($serviceName) { funChangeServiceAccount }
if($stop) { funstop }
if($start) { funStart }
