# Get-IEVersion.ps1
# Written by Bill Stewart (bstewart@iname.com)

#requires -version 2

<#
.SYNOPSIS
Gets the Internet Explorer file version on one or more computers.

.DESCRIPTION
Gets the Internet Explorer file version on one or more computers.

.PARAMETER ComputerName
Specifies the computer name(s). The default is the current computer.

.OUTPUTS
PSobjects with the following properties:
  ComputerName - The computer name
  Path - The path and filename of the Internet Explorer executable
  Version - The version of the Internet Explorer executable
  Error - The error message, if any (null if no error)
#>

param(
  [parameter(ValueFromPipeline=$TRUE)]
    [String[]] $ComputerName=[System.Net.Dns]::GetHostName()
)

begin {
  $HKLM = [UInt32] "0x80000002"
  $IESubKeyName = "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\IEXPLORE.EXE"

  function Get-IEVersion {
    param(
      [String] $computerName
    )
    # Create custom object.
    $outputObject = "" | Select-Object `
      @{Name="ComputerName"; Expression={$computerName}},
      @{Name="Path"; Expression={}},
      @{Name="Version"; Expression={}},
      @{Name="Error"; Expression={}}
    # Step 1: Read App Paths subkey to get path of iexplore.exe.
    try {
      $regProv = [WMIClass] "\\$computerName\root\default:StdRegProv"
    }
    catch [System.Management.Automation.RuntimeException] {
      # Update custom object with error message and return it.
      $outputObject.Error = $_.Exception.InnerException.InnerException.Message
      return $outputObject
    }
    $iePath = ($regProv.GetStringValue($HKLM, $IESubKeyName, "")).sValue
    if ( -not $iePath ) {
      # Update custom object with error message and return it.
      return $outputObject
    }
    $outputObject.Path = $iePath
    # Replace '\' with '\\' when specifying CIM_DataFile key path.
    $iePath = $iePath -replace '\\', '\\'
    # Step 2: Get the CIM_DataFile instance of iexplore.exe.
    try {
      $dataFile = [WMI] "\\$computerName\root\CIMV2:CIM_DataFile.Name='$iePath'"
      # Update custom object with IE file version.
      $outputObject.Version = $dataFile.Version
    }
    catch [System.Management.Automation.RuntimeException] {
      # Update custom object with error message.
      $outputObject.Error = $_.Exception.InnerException.InnerException.Message
    }
    # Return the custom object.
    return $outputObject
  }
}

process {
  foreach ( $computer in $ComputerName ) {
    Get-IEVersion $computer
  }
}
