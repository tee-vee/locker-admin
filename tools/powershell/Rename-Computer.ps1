function Rename-Computer {
<#
.Synopsis
    Rename-Computer
.Description
    Computer with specified name.
.Parameter Computer
    Computer name to be be renamed (original name).
.Parameter NewName
    New name for the computer.
.Parameter UserD
    User account used to make the connection with the domain.
    The domain can be specified as "/ud:domain\user". If domain is omitted, then the computer's domain is assumed.
    To be used with PasswordD parameter, if PasswordD is omitted, it is automatically assigned a value of *.
.Parameter PasswordD
    Password of the user account specified by /UserD. A * means to prompt for the password
.Parameter UserO
    User account used to make the connection with the machine to be renamed. If omitted, then the currently logged on user's account is used. The user's domain can be specified as "/uo:domain\user". If domain is omitted, then a local computer account is assumed.
    To be used with PasswordO parameter, if PasswordO is omitted, it is automatically assigned a value of *.
.Parameter PasswordO
    Password of the user account specified by /UserO. A * means to prompt for the password
.Parameter Force
    As noted above, this command can adversely affect some services running on the computer. The user will be prompted for confirmation unless the /FORCE switch is specified.
.Parameter Reboot
    Specifies that the machine should be shutdown and automatically rebooted after the Rename has completed. The number of seconds before automatic shutdown can also be provided. Default is 30 seconds
.Parameter SecurePasswordPrompt
    Use secure credentials popup to specify credentials. This option should be used when smartcard credentials need to be specified. This option is only in effect when the password value is supplied as *
.Notes
    Written By:  Michael H Moore
    Created On:  11/01/2011
    Edited On:   11/30/2011
    Created For: Mohawk Industries
#>

[CmdletBinding()]
param(
    [Parameter(Position=0, Mandatory=$true)] [alias("CN", "ComputerName", "Name")]
    [String]
    [ValidateNotNullOrEmpty()]
    $Computer,
    [Parameter(Position=1, Mandatory=$true)]
    [String]
    [ValidateNotNullOrEmpty()]
    $NewName,
    [Parameter(Mandatory=$false)] [alias("ud")]
    [String]
    [ValidateNotNullOrEmpty()]
    $UserD,
    [Parameter(Mandatory=$false)] [alias("pd")]
    [String]
    [ValidateNotNullOrEmpty()]
    $PasswordD,
    [Parameter(Mandatory=$false)] [alias("uo")]
    [String]
    [ValidateNotNullOrEmpty()]
    $UserO,
    [Parameter(Mandatory=$false)] [alias("po")]
    [String]
    [ValidateNotNullOrEmpty()]
    $PasswordO,
    [Parameter(Mandatory=$false)] [alias("F")]
    [Switch]
    $Force,
    [Parameter(Mandatory=$false)] [alias("r")]
    [Switch]
    $Reboot,
    [Parameter(Mandatory=$false)] [alias("spp")]
    [Switch]
    $SecurePasswordPrompt
    )

Process
{   
    $Command = "RenameComputer", "$Computer", "/NewName:$NewName"
    
    if ($UserD.length -gt 0)
        {
        $Command = $Command + "/UserD:$UserD"

        if ($PasswordD.length -eq 0)
            {
            $Command = $Command + "/PasswordD:*"
            }
        else
            {
            $Command = $Command + "/PasswordD:$PasswordD"
            }
        }
        
    if ($UserP.length -gt 0)
        {
        $Command = $Command + "/UserO:$UserO"
        
        if ($PasswordO.length -eq 0)
            {
            $Command = $Command + "/PasswordO:*"
            }
        else
            {
            $Command = $Command + "/PasswordO:$PasswordO"
            }
        }
        
    if ($Force)
        {
        $Command = $Command + "/Force"
        }
        
    if ($Reboot)
        {
        $Command = $Command + "/Reboot"
        }
        
    if ($SecurePasswordPrompt)
        {
        $Command = $Command + "/SecurePasswordPrompt"
        }
    
    netdom $Command
}
}