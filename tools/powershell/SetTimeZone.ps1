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

Param
(
	[Parameter(Mandatory=$true,ParameterSetName='FriendlyName')]
	[Alias('friendly')][String]$TimeZoneFriendlyName,
	[Parameter(Mandatory=$true,ParameterSetName='ShowTimeZone')]
	[Alias('sh')][Switch]$ShowTimeZone
)
	
If($ShowTimeZone)
{
	$TimeZoneInfo = Invoke-Expression "tzutil.exe /l"
	For($i=0; $i -le $TimeZoneInfo.Count; $i++)
	{
		If($i%3 -eq 0)
		{
			$Obj = New-Object -TypeName PSObject
			$Obj | Add-Member -MemberType NoteProperty -Name TimeZone -Value $TimeZoneInfo[$i]
			$Obj | Add-Member -MemberType NoteProperty -Name FriendlyName -Value $TimeZoneInfo[$i+1]
			$Obj
		}
	}
}

If($TimeZoneFriendlyName)
{
	Invoke-Expression "tzutil.exe /s ""$TimeZoneFriendlyName"""
}