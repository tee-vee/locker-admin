#--------------------------------------------------------------------------------- 
#The sample scripts are not supported under any Microsoft standard support 
#program or service. The sample scripts are provided AS IS without warranty  
#of any kind. Microsoft further disclaims all implied warranties including,  
#without limitation, any implied warranties of merchantability or of fitness for 
#a particular purpose. The entire risk arising out of the use or performance of  
#the sample scripts and documentation remains with you. In no event shall 
#Microsoft, its authors, or anyone else involved in the creation, production, or 
#delivery of the scripts be liable for any damages whatsoever (including, 
#without limitation, damages for loss of business profits, business interruption, 
#loss of business information, or other pecuniary loss) arising out of the use 
#of or inability to use the sample scripts or documentation, even if Microsoft 
#has been advised of the possibility of such damages 
#--------------------------------------------------------------------------------- 

#requires -version 2.0

Function Get-OSCTPMChip
{
<#
 	.SYNOPSIS
        Get-OSCTPMChip is an advanced function which can be list TPM chip status.
		
    .DESCRIPTION
        Get-OSCTPMChip is an advanced function which can be list TPM chip status.
		
	.PARAMETER	<ComputerName <string[]>
		Specifies the computers on which the command runs. The default is the local computer. 
		
	.PARAMETER  <Credential>
		Specifies a user account that has permission to perform this action. 
		
    .EXAMPLE
        C:\PS> Get-OSCTPMChip
		
		This command lists TPM chip status.
		
    .EXAMPLE
		C:\PS> $cre = Get-Credential
        C:\PS> Get-OSCFolderPermission -ComputerName "APP" -Credential $cre
		
		This command lists TPM chip status on the APP remote computer.
#>

	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$false,ValueFromPipeline=$true)]
		[Alias("CN")][String[]]$ComputerName=$Env:COMPUTERNAME,
		[Parameter(Mandatory=$false)]
		[Alias('Cred')][System.Management.Automation.PsCredential]$Credential
	)
	
	Foreach($CN in $ComputerName)
	{
		#test server connectivity
		$PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
		If($PingResult)
		{
			If($Credential)
			{
				
				$TPMStatusInfo = Invoke-Command -ComputerName $CN -Credential $Credential `
				-ScriptBlock {Get-WmiObject -Class Win32_TPM -EnableAllPrivileges -Namespace "root\CIMV2\Security\MicrosoftTpm"}
				$TPMStatusInfo | Add-Member -Name ComputerName -Value $CN -MemberType NoteProperty
				$TPMStatusInfo | Select-Object ComputerName,IsActivated_InitialValue,IsEnabled_InitialValue,IsOwned_InitialValue,`
				ManufacturerId,ManufacturerVersion,ManufacturerVersionInfo,PhysicalPresenceVersionInfo,SpecVersion
			}
			Else
			{

				$TPMStatusInfo = Get-WmiObject -Class Win32_TPM -EnableAllPrivileges -Namespace "root\CIMV2\Security\MicrosoftTpm"
				$TPMStatusInfo | Add-Member -Name ComputerName -Value $CN -MemberType NoteProperty
				$TPMStatusInfo | Select-Object ComputerName,IsActivated_InitialValue,IsEnabled_InitialValue,IsOwned_InitialValue,`
				ManufacturerId,ManufacturerVersion,ManufacturerVersionInfo,PhysicalPresenceVersionInfo,SpecVersion
			}
		}
		Else
		{
			Write-Host "Cannot ping to $CN, please check the network connection"
		}
	}
}