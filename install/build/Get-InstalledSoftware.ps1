function Get-InstalledSoftware {
    <#
 .SYNOPSIS
 Retrieve installed software from the registry

 .DESCRIPTION
 Retrieve installed software from the registry

 .PARAMETER ComputerName
 Name of the computer to check

.INPUTS
 System.String

.OUTPUTS
 System.Management.Automation.PSObject.

.EXAMPLE
 PS> Get-InstalledSoftware -Computer Server01

 .EXAMPLE
 PS> "Server01","Server02" | Get-InstalledSoftware

#>
    [CmdletBinding()][OutputType('System.Management.Automation.PSObject')]

    Param
    (

        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$ComputerName

    )

    begin {

        $OutputObject = @()
    }

    process {

        try {
            foreach ($Computer in $ComputerName){

                $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('Localmachine',$Computer)
                $UninstallTopKey = $Registry.OpensubKey("Software\Microsoft\Windows\CurrentVersion\Uninstall",$false)
                $UninstallSubKeys = $UninstallTopKey.GetSubKeyNames()

                ForEach ($SubKey in $UninstallSubKeys){

                    $Path = "Software\Microsoft\Windows\CurrentVersion\Uninstall\$SubKey"
                    $SubKeyValues = $Registry.OpensubKey($Path,$false)

                    $DisplayName = $SubKeyValues.GetValue('DisplayName')

                    if ($DisplayName){

                        $Object = [pscustomobject]@{

                            ComputerName = $Computer
                            DisplayName = $DisplayName
                            DisplayVersion = $SubKeyValues.GetValue('DisplayVersion')
                            UninstallString = $SubKeyValues.GetValue('UninstallString')
                            Publisher = $SubKeyValues.GetValue('Publisher')
                            InstallDate = $SubKeyValues.GetValue('InstallDate')

                        }
                    }

                    $OutputObject += $Object

                }
            }
        }
        catch [Exception]{

            throw "Unable to get registry data....."
        }
    }
    end {
        Write-Output $OutputObject
    }
}
