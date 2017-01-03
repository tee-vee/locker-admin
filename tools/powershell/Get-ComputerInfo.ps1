<#
    .Title
    14s-CNT390-InceNewman-Get-ComputerInfo
    .Description
	Collection of functions that retrieve information on the inputted computer. Get-ComputerInfo is dependent on the following functions: Get-DisksToQuery, ExportTo-HTML, Get-IPConfig, Get-DiskDrive, Get-ActiveUser, Get-Users, Get-BiosInfo, Get-SystemInfo, Get-OSInfo. All of these functions are in this file.
    .Authors
    Mark Ince & Ben Newman
	.Version
	Ver 3.0. 
    Version 3, last edit by Mark I.
	.Items to implement
	Get uptime
	Create -Full paramter for Get-ComputerInfo function. Add Win32_LogonSession. See http://msdn.microsoft.com/en-us/library/aa394189(v=vs.85).aspx
	Add Win32_Process. Can be used to get all of the running processes on a computer.
	#>
####Start of functions. I know I could dot source several different files, but I prefer to keep them together.
##Begin ExportTo-HTML function
function ExportTo-HTML
<#
.SYNOPSIS
This function exports the object from Get-ComputerInfo to an html file.
.DESCRIPTION
This function exports the object from Get-ComputerInfo to an html file. 
.EXAMPLE
Get-ComputerInfo | ExportTo-HTML
Creates an html file from the output of Get-ComputerInfo on the local host. Default path is userprofile.
.EXAMPLE
Get-Content pcs.txt | Get-ComputerInfo | ExportTo-HTML -Filter -Path C:\
Creates an html file from the output of Get-ComputerInfo on all of the pcs in the pcs.txt file. Only creates output for pcs that have either less than or equal to 25% hard drive space remaining or are using 90% or more RAM. -Path sets the output file to C:\ in this example. 
.PARAMETERS
-collection
	#>
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$False,
		ValueFromPipeline=$True,
		Position=0)]
		$collection,
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True,
		Position=1)]
		$path=$env:userprofile,		
		[Parameter(Mandatory=$False)]
		[switch]
		$Filter
	)	
	PROCESS
	{
		$timestamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
		If ($Filter -eq $True)
		{
			$criticalpc = $collection | Where-Object {$_.PercentFree -le 25 -or $_.PercentMemoryUsed -ge 90}
			$collection = $null
			$collection = $criticalpc
		}
		#$ErrorActionPreference = "SilentlyContinue" #Duct taping PowerShell's mouth shut here becuase it throws error about collection being null but still creates the html file.'
		#PCInfo
		$name = $collection | Select-Object -property PCName,DateDataCollected,DomainorWorkgroup,OS,'OS Version',Architecture,LastBootUpTime,UptimeInHours | ConvertTo-HTML -Fragment -PreContent '<div class="comp"><h2>Computer Information</h2>' -PostContent '</div>'| Out-String
		#DiskInfo
		$disk = $collection | Select-Object -property DriveLetter,'Capacity (GB)','Free Space (GB)',PercentFree
		If ($disk.PercentFree -le 25)
		{
		$disk = $collection | Select-Object -property DriveLetter,'Capacity (GB)','Free Space (GB)',PercentFree| ConvertTo-HTML -Fragment -PreContent '<div class="flag"><h2>Disk Information</h2>' -PostContent '</div>'| Out-String			
		}
		else
		{
		$disk = $collection | Select-Object -property DriveLetter,'Capacity (GB)','Free Space (GB)',PercentFree | ConvertTo-HTML -Fragment -PreContent '<div class="disk"><h2>Disk Information</h2>' -PostContent '</div>'| Out-String
		}
		$user = $collection | Select-Object -property LoggedonUser, 'All Users' | ConvertTo-HTML -Fragment -PreContent '<div class="user"><h2>User Information</h2>' -PostContent '</div>' | Out-String
		#UserInfo
		$bios = $collection | Select-Object -property Serial,Model,Manufacturer,BiosDescription | ConvertTo-HTML -Fragment -PreContent '<div class="bios"><h2>Bios Information</h2>' -PostContent '</div>' | Out-String
		#BiosInfo
		$ram = $collection | Select-Object -property 'Memory (GB)','usedMemory (GB)',PercentMemoryUsed
		If ($ram.PercentMemoryUsed -ge 90)
		{
		$ram = $collection | Select-Object -property 'Memory (GB)','usedMemory (GB)',PercentMemoryUsed | ConvertTo-HTML -Fragment -PreContent '<div class="flag"><h2>Memory Information</h2>' -PostContent '</div>' | Out-String			
		}
		else
		{
		$ram = $collection | Select-Object -property 'Memory (GB)','usedMemory (GB)',PercentMemoryUsed | ConvertTo-HTML -Fragment -PreContent '<div class="ram"><h2>Memory Information</h2>' -PostContent '</div>' | Out-String
		}
		#RamInfo
		$nic = $collection | Select-Object -property 'NIC Name','MAC Address','IP Address' | ConvertTo-HTML -Fragment -PreContent '<div class="nic"><h2>Network Configuration</h2>' -PostContent '</div>' | Out-String
		#IPconfig
		$pcname = @'
		<h1>Report for PC {0} gathered on {1}</h1>
		'@ -f $collection.PCName,$collection.DateDataCollected
		$finalFile = $pcname + $name + $disk + $user + $bios + $ram + $nic + '<hr>'
		$finalfilecoll += $finalFile
	}
	END
	{
		$prehtml = '<html><head><title>Computer Report</title><style>body {background-color:WhiteSmoke;}h1, h2 {text-align:center;}.info{font:12px arial,sans-serif;color:DarkGreen;height:83%;width:83%;margin: auto;}.info table {border-collapse: collapse; margin:auto; }td, th {  width: 4rem;  height: 2rem;  border: 1px solid #ccc;  text-align: center;}.info h1 {text-align:center;}.info table th, td {color:ForestGreen;}.flag table td {color:red;}</style><body><div class="info">'
		$endhtml = '</div></body></html>'
		If ($Filter -eq $True)
		{
			$prehtml + $finalfilecoll + $endhtml | Out-File $path\ReportCriticalPCs$timestamp.htm
			invoke-item $path\ReportCriticalPCs$timestamp.htm #Comment out if you don't want the file to be launched in the browser, i.e. using this function as a scheduled task.
		}
		else
		{
			$prehtml + $finalfilecoll + $endhtml | Out-File $path\Report$timestamp.htm
			invoke-item $path\Report$timestamp.htm #Comment out if you don't want the file to be launched in the browser, i.e. using this function as a scheduled task.
		}
	}
}
###End of ExportTo-HTML function
###invoke-item .\Report$timestamp.htm
###Begin Get-IPConfig function
function Get-IPConfig 
{
	<#
	.SYNOPSIS
	Retrieve information on active network connections on computer(s) specified. If only the PCName is returned, it failed to connect to the computer.
	.DESCRIPTION
	Retrieves network adapter information and IP Address settings on computer(s) specified. Leverages Win32_NetworkAdapter and Win32_NetworkAdapterConfiguration. For more info on these two Classes, see
	http://msdn.microsoft.com/en-us/library/aa394216(v=vs.85).aspx
	and
	http://msdn.microsoft.com/en-us/library/aa394217(v=vs.85).aspx
	.EXAMPLE
	Get-IPConfig FAMILY
	.EXAMPLE
	Get-IPConfig FAMILY, ARMRI
	.PARAMETER ComputerName
	The computer name to query
#>
	[CmdletBinding()] #states that this function should act just like a cmdlet
	param(
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True)]
		[string[]]$ComputerName	
	)
	PROCESS #Any lines coming down the pipeline, I process here, and here is the code we’re going to run against those.
	{
		ForEach ($PC in $ComputerName) 
		{
			$netAdapter = Get-WmiObject Win32_NetworkAdapter -computer $PC | Where-Object {$_.PhysicalAdapter -eq $True}
			$netIPAdd = Get-WmiObject Win32_NetworkAdapterConfiguration -computer $PC | Where-Object {$_.IPEnabled -eq $True}
			$IPConf = New-Object -TypeName PSObject
			$IPConf | Add-Member -MemberType NoteProperty -Name PCName -Value $PC
			$IPConf | Add-Member -MemberType NoteProperty -Name NetworkAdapterName -Value $netAdapter.Name
			$IPConf | Add-Member -MemberType NoteProperty -Name NetworkAdapterMACAddress -Value $netAdapter.MacAddress
			$IPConf | Add-Member -MemberType NoteProperty -Name IPAddress -Value $netIPAdd.IPAddress
			$IPConf | Add-Member -MemberType NoteProperty -Name DefaultGateway -Value $netIPAdd.DefaultIPGateway
			[array]$IPConfMulti += $IPConf
		} #End of ForEach Loop
		$IPConfMulti
	} #End of PROCESS
} #End of function
####
#End of Get-IPConfig function
####
###Start of Get-DiskDrive. Look into passing a variable of wmiobject from earlier diskquery function to this function.
function Get-DiskDrive 
{
	<#
	.SYNOPSIS
	This function returns capacity and freespace in gigs and percent free on computer specified.
	.DESCRIPTION
	This function returns capacity and freespace in gigs and percent free on computer specified. By default it returns the system drive. Mutliple drive letters can be entered for the drive parameter. Leverages Win32_LogicalDisk. For more information, see
	http://msdn.microsoft.com/en-us/library/aa394173(v=vs.85).aspx
	.EXAMPLE
	Get-DiskDrive Family C:
	.EXAMPLE
	Get-DiskDrive Family C:,K:,Z:
	.PARAMEters -ComputerName -drive
	#>
		[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True)]
		[string[]]$ComputerName,
		[string[]]$drive = $env:SystemDrive #Defaults this variable to the system drive.
	)
	PROCESS 
	{
		ForEach ($PC in $ComputerName) 
		{
			ForEach ($d in $drive) 
			{
				$disks = Get-WmiObject Win32_LogicalDisk -computer $PC -Filter "DeviceID = '$d'"
				$seldisk = New-Object -TypeName PSObject
				If ($disks.__CLASS -like "") 
				{ #If statement checking for failed connection. Allows rest of computers to be checked.
					$failure = "Couldn't connect to $PC"
					$seldisk | Add-Member -MemberType NoteProperty -Name PCName -Value $PC
					$seldisk | Add-Member -MemberType NoteProperty -Name Failed -Value $failure
				} #End if
				else 
				{
					$seldisk | Add-Member -MemberType NoteProperty -Name PCName -Value $PC
					$seldisk | Add-Member -MemberType NoteProperty -Name DriveLetter -Value $disks.DeviceID
					$seldisk | Add-Member -MemberType NoteProperty -Name CapacityinGB -Value ([Math]::Round( ($disks.Size / 1GB) , 2 ) )
					$seldisk | Add-Member -MemberType NoteProperty -Name FreeSpaceinGB -Value ([Math]::Round( ($disks.FreeSpace / 1GB) , 2 ) )
					$seldisk | Add-Member -memberType NoteProperty -name PercentFree -value ([Math]::Round(($disks.FreeSpace / $disks.Size)*100))
				} #End else
				[array]$diskcoll += $seldisk
			} #End of nested loop

		} #End of ForEach
		$diskcoll
	} #End of PROCESS
} #End of function
######
#End of Get-DiskDrive function.
####
##Begin Get-ActiveUser
####
Function Get-ActiveUser 
{
		<#
	.SYNOPSIS
	Retrieves list of users that have logged on to computer and the active user for the specified computer(s).
	.DESCRIPTION
	Retrieves list of users that have logged on to computer and the active user for the specified computer(s). User Name is returned for all users that have logged on to the PC locally and the active local user. Leverages Win32_UserProfile. For more information see,
	http://msdn.microsoft.com/en-us/library/ee886409(v=vs.85).aspx
	.EXAMPLE
	Get-LoggedUsers Family
	.PARAMETER ComputerName
	The computer name to query
#>
		[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True)]
		[string[]]$ComputerName
	)
	PROCESS 
	{
		ForEach ($PC in $ComputerName) 
		{
			$actuser = Get-WmiObject Win32_UserProfile -computer $PC
			$loggedinuser = $actuser | Where-Object {$_.Special -eq $False -and $_.Loaded -eq $True}
			if($loggedinuser -notlike "")
			{
			$currentuser = $loggedinuser.LocalPath.Substring(9)
			$currentuser = $currentuser -join ", "
			}
			else
			{
				$currentuser = 'N/A'
			}
			$activeuser = New-Object -TypeName PSObject
			$activeuser | Add-Member -MemberType NoteProperty -Name LoggedinUser -Value $currentuser
			$activeuser	
		}
	}
}
##Get-Users Function
Function Get-Users 
{
	<#
	.SYNOPSIS
	Retrieves list of users that have logged on to computer and their domain for specified computer(s).
	.DESCRIPTION
	Retrieves list of users that have logged on to computer and their domain for specified computer(s).
	Display User, Domain, and Domain/User.
	.EXAMPLE
	Get-LoggedUsers Family
	.EXAMPLE
	Get-LoggedUsers Family,ARMRI
	.PARAMETER ComputerName
	The computer name to query
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True)]
		[string[]]$ComputerName	
	)
	PROCESS	
	{
		ForEach ($PC in $ComputerName) 
		{
			$userobj = Get-WmiObject Win32_SystemUsers -computer $PC
			ForEach ($item in $userobj) 
			{
				$item.PartComponent -match ".*Name=(?<username>.*),.*Domain=(?<domain>.*).*" | Out-Null #stipping down to user and domain using RegEx.
				$quotedb = '"' #Creating a variable for -replace operation.
				$usernoquotes = $matches.username -replace $quotedb,"" #removing quotes from username
				$domainnoquotes = $matches.domain -replace $quotedb,"" #removing quotes from domain/computer
				$user = New-Object -TypeName PSObject #creating custom object to hold results
				$user | Add-Member -MemberType NoteProperty -Name User -Value $usernoquotes #adding username to object
				$user | Add-Member -MemberType NoteProperty -Name Domain -Value $domainnoquotes #adding domain to object
				$userdom = $user.Domain + "\" + $user.User #concentating domain with \ and user.
				$user | Add-Member –MemberType NoteProperty –Name 'Domain\Username' –Value $userdom #adding domain\UserName to object.
				[array]$userdomains += $user #Creating an array to store the multiple results
			} #End ForEach loop for users
		} #End ForEach loop for multiple computers
		$userdomains #displaying the array
	} #End PROCESS Block
} #End Function
####
###Begin Get-BiosInfo Function###
Function Get-BiosInfo 
{
<#
.SYNOPSIS
	This function returns the serial number and description of the BIOS on the computer(s) specified.
.DESCRIPTION
	This function returns the serial number and description of the BIOS on the computer(s) specified. Leverages Win32_BIOS. This function is used for error checking when Get-ComputerInfo is run. For more information see here,
	http://msdn.microsoft.com/en-us/library/aa394077(v=vs.85).aspx
.EXAMPLE
	Get-BiosInfo Family
.EXAMPLE
	Get-BiosInfo Family, 
.PARAMETERS -ComputerName
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$True, # It is mandatory (required).
		ValueFromPipeline=$True)] # It takes input from the pipeline.
		[string[]]$ComputerName	 # It takes an array of strings as input
	)
	PROCESS 
	{
		ForEach ($PC in $ComputerName) 
		{
			$bios = Get-WmiObject Win32_Bios -computer $PC
			If ($bios.__CLASS -like "") 
			{ #If statement checking for failed connection. Allows rest of computers to be checked.
				$failure = "Failed to connect to $PC"
				$failure
			}
			else 
			{
			$serial = $bios.SerialNumber
			$descr = $bios.Description
			$biosinfo = New-Object -TypeName PSObject
			$biosinfo | Add-Member -MemberType NoteProperty -Name PCName -Value $PC
			$biosinfo | Add-Member -MemberType NoteProperty -Name Serial -Value $serial
			$biosinfo | Add-Member -MemberType NoteProperty -Name Description -Value $descr
			[array]$biosinfomulti += $biosinfo
			}			
		}
		$biosinfomulti
	}
}
###End of Get-BiosInfo function
####
###Being Get-SystemInfo
Function Get-SystemInfo 
{
			<#
	.SYNOPSIS
	This function returns the Name, Domain or Workgroup if not joined to a domain, Model and manufacturer of specified computer(s).
	.DESCRIPTION
	This function returns the Name, Domain or Workgroup if not joined to a domain, Model and manufacturer of specified computer(s) from Win32_ComputerSystem.
	.EXAMPLE
	Get-SystemInfo Family
	.EXAMPLE
	Get-SystemInfo Family
	.PARAMETERS -ComputerName
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True)]
		[string[]]$ComputerName	
	)
	PROCESS 
	{
		ForEach ($PC in $ComputerName) 
		{
			$sys = Get-WmiObject Win32_ComputerSystem -computer $PC
			$name = $sys.Name
			$domain = $sys.Domain
			$model = $sys.Model
			$mfr = $sys.Manufacturer
			$sysinfo = New-Object -TypeName PSObject
			$sysinfo | Add-Member -MemberType NoteProperty -Name Name -Value $name
			$sysinfo | Add-Member -MemberType NoteProperty -Name DomainOrWorkGroup -Value $domain 
			$sysinfo | Add-Member -MemberType NoteProperty -Name Model -Value $model
			$sysinfo | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $mfr
			[array]$sysinfomulti += $sysinfo
		}
		$sysinfomulti
	}
}
###End of Get-SystemInfo
####
###Being Get-OSInfo
Function Get-OSInfo 
{
<#
.SYNOPSIS
	This function returns the Name of the OS, the OS Version, OS Architechture (32-bit or 64-bit), Last Boot Up Time, and Free RAM of specified computer(s).
.DESCRIPTION
	This function returns the Name of the OS, the OS Version, OS Architechture (32-bit or 64-bit), Last Boot Up Time, and Free RAM of specified computer(s) from Win32_OperatingSystem.
.EXAMPLE
	Get-SystemInfo Family
.EXAMPLE
	Get-SystemInfo Family,ARMRI
.PARAMETERS -ComputerName
#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$True,
		ValueFromPipeline=$True)]
		[string[]]$ComputerName	
	)
	PROCESS 
	{
		ForEach ($PC in $ComputerName) 
		{
			$osin = Get-WmiObject Win32_OperatingSystem -computer $PC
			$lastboot = $osin.ConvertToDateTime($osin.LastBootUpTime)
			$ver = $osin.version
			$capt = $osin.caption
			$arct = $osin.OSArchitecture
			$freemem = $osin.FreePhysicalMemory
			$osinfo = New-Object -TypeName PSObject
			$osinfo | Add-Member -MemberType NoteProperty -Name PCName -Value $PC
			$osinfo | Add-Member -MemberType NoteProperty -Name OS -Value $capt
			$osinfo | Add-Member -MemberType NoteProperty -Name OSVersion -Value $ver
			$osinfo | Add-Member -MemberType NoteProperty -Name Architecture -Value $arct
			$osinfo | Add-Member -MemberType NoteProperty -Name LastBootTime -Value $lastboot
			$osinfo | Add-Member -MemberType NoteProperty -Name FreePhysicalMemory -Value $freemem
			[array]$osinfomulti += $osinfo
		}
		$osinfomulti
	}
}
###End of Get-OSInfo
####
###Begin Get-ComputerInfo
function Get-ComputerInfo 
{
<#
.SYNOPSIS
    This function takes a computer name as input, and returns a custom object with several potentially interesting properties. Primarily, this leverages WMI.
.DESCRIPTION
	This function retrieves the following information about the computer specified or all the computers from a file. Date information collected, the Computer Name from WMI Object Win32_ComputerSystem. Make,Model,Name of PC, physical memory, x64/x86,domain/workgroup, network adapters (MAC etc). Requires these functions: Get-DisksToQuery, ExportReportTo-HTML, Get-IPConfig, Get-DiskDrive, Get-ActiveUser, Get-Users, Get-BiosInfo, Get-SystemInfo, Get-OSInfo.
.EXAMPLE
	Get-ComputerInfo FAMILY 
	where family is the name of the computer to query.
.EXAMPLE
	Get-Content names.txt | Get-ComputerInfo 
	where names.txt is a list of computers to query one at a time located in the active PS directory. names.txt was created through Get-ADComputer with appropriate filtering. This cmdlet should be able to be piped to this function as well.
.EXAMPLE
	Get-ComputerInfo FAMILY -export
	Exports the array created to an html file that is displayed in the default browser.
.EXAMPLE
	Get-ComputerInfo 
	Gets the information from the current computer.
.EXAMPLE
	Get-ComputerInfo -Path C:\Temp -Export
	Creates the html page report of the information in the C:\Temp directory.
.PARAMETER ComputerName
	The computer name to query.
#>
	[CmdletBinding(SupportsShouldProcess=$true,
        ConfirmImpact="Low")]	
	param
	(	
		[Parameter(
		ValueFromPipeline=$True,
		ValueFromPipelinebyPropertyName=$True, 
		#It can came from pipeline from an object with appropriate propertname(Either the SetName or any of the aliases.)
		Position=0, 
		#If -ComputerName is not added, makes the parameter accepted as first position.
		ParameterSetName="ComputerName", 
		#Setting the parameter to a name. Can only be one name.
		HelpMessage="Enter a computer name or names separated by a comma.")] 
		#Adding a help message when nothing is inputted after Get-Printers.
		[alias("CN","MachineName","PCName","Name")]
		[string[]]$ComputerName = $ENV:ComputerName,
		[Parameter(Mandatory=$False,
		ValueFromPipeline=$False,
		Position=1)]
		$path=$env:userprofile,							
		[parameter(Mandatory=$false)]
		[switch]
		$Export,
		[switch]
		$Filter		
	)
	PROCESS 
	{
		ForEach ($PC in $ComputerName) 
		{#Runs loop on each computername entered into $ComputerName. Works for one entry or multiple from a file.
			$date = Get-Date -UFormat "%Y.%m.%d" # e.g. 2013.12.31; sorts best this way. Always save the date you collected this info!
			Write-Debug "Querying $PC"
			#Write-Progress ala Write-Host "Querying $PC"
			Write-Verbose "Querying $PC"
			#query WMI, first query should be followed by an If to determine if a valid WMI response was received, and skip subsequent queries if not
			#Last known logged on users (e.g. from running processes), historical logged on users (C:\users),
			#Notable WMI classes: Win32_bios, Win32_ComputerSystem win32_LoggedOnUser, win32_SystemUsers, win32_logicalDisk		
			$compSystem = Get-SystemInfo $PC
			#Model is required to have a value. If model returns no value, it means the computer could not be connected to so adding it to a collection of failed of computers that failed to return information.
			If($compSystem.model -like "")
			{
				$errorcatch = $True
			}
			else
			{
				$errorcatch = $False
			}
			If($errorcatch -eq $False)
			{
				Write-Verbose "Querying WMI Objects"
				$NetConfig = Get-IPConfig $PC
				#$diskstoget = Get-DisksToQuery $PC #If you want more than Drive C: to be returned.
				$disk = Get-DiskDrive $PC #$diskstoget
				$uptimedate = Get-Date
				$user = Get-Users $PC
				$useronline = Get-ActiveUser $PC
				$bios = Get-BiosInfo $PC
				$OS = Get-OsInfo $PC 
				$RAM = Get-WmiObject Win32_PhysicalMemory -computer $PC
				$totalRAM = ($RAM | Measure-Object 'Capacity' -Sum).Sum
				$allusers = $user[($user.length-1)..0].'Domain\Username' -join ", "
				$nics = $NetConfig.NetworkAdapterName -join ", "
				$macs = $NetConfig.NetworkAdapterMACAddress -join ", "
				$ipadds = $NetConfig.IPAddress -join ", " 
				$diskstring = $disk
				# $diskstring = Get-Content -raw .\test.txt
				#Query teamviewer ID if possible
				#reg query doesn't seem to work in my environment...network path not found	
				#Write-Progress ala Write-Host "Parsing results"
				Write-Verbose "Pasring results"
				Write-Debug "Parse Results?"
				#Create a custom object to contain all these results
				$result = New-Object -TypeName PSObject	
				#Start populating the custom object with results
				# Future potential: move more parsing off to function prettify-results
				# $result | Add-Member -MemberType NoteProperty -Name -Value 
				$result | Add-Member -MemberType NoteProperty -Name 'PCName' -Value $compSystem.name
				$result | Add-Member -MemberType NoteProperty -Name 'DateDataCollected' -Value $date
				$result | Add-Member -MemberType NoteProperty -Name DomainOrWorkgroup -Value $compSystem.domainorworkgroup
				$result | Add-Member -MemberType NoteProperty -Name Serial -Value $bios.Serial #Serial can be blank in case of replaced motherboards.
				$result | Add-Member -MemberType NoteProperty -Name Model -Value $compSystem.model
				$result | Add-Member -MemberType NoteProperty -Name Manufacturer -Value $compSystem.manufacturer
				$result | Add-Member -MemberType NoteProperty -Name BiosDescription -Value $bios.Description #Can include BIOS revision and date
				$result | Add-Member -MemberType NoteProperty -Name LastBootUpTime -Value $OS.LastBootTime
				$result | Add-Member -MemberType NoteProperty -Name UptimeInHours -Value ([MATH]::Round(($uptimedate - $OS.LastBootTime).TotalHours, 2))
				$result | Add-Member -MemberType NoteProperty -Name 'OS' -Value $OS.OS #E.g. Windows 7 Enterprise
				$result | Add-Member -MemberType NoteProperty -Name 'OS Version' -Value $OS.OSVersion #e.g. 6.1.7601
				$result | Add-Member -MemberType NoteProperty -Name Architecture -Value $OS.Architecture #x64 or x86
				$result | Add-Member -MemberType NoteProperty -Name LoggedOnUser -Value $useronline.LoggedinUser #User or users logged into the pc.
				$result | Add-Member -MemberType NoteProperty -Name 'All users' -Value $allusers #All users who have logged into the pc.
				$result | Add-Member -MemberType NoteProperty -Name HardDrivesInfo -Value $diskstring
				$result | Add-Member -MemberType NoteProperty -Name 'DriveLetter' -Value $diskstring.DriveLetter
				$result | add-member -memberType NoteProperty -name 'Capacity (GB)' -value $diskstring.CapacityinGB
				$result | add-member -memberType NoteProperty -name 'Free Space (GB)' -value $diskstring.FreeSpaceinGB
				$result | Add-Member -memberType NoteProperty -name PercentFree -value $diskstring.PercentFree
				$result | add-member -memberType NoteProperty -name 'Memory (GB)' -value ( ( $totalRAM ) / 1GB )
				$result | add-member -memberType NoteProperty -name 'usedMemory (GB)' -value ([Math]::Round( ( $totalRAM - $OS.FreePhysicalMemory * 1024) / 1GB , 2 ) )
				$result | add-member -memberType NoteProperty -name PercentMemoryUsed -value ([Math]::Round(($result.'usedMemory (GB)' / $result.'Memory (GB)')*100))
				#Memory 'Capacity' value is in bytes, see http://msdn.microsoft.com/en-us/library/aa394347(v=vs.85).aspx, but OS.FreePhysicalMemory is in kilobytes, see http://msdn.microsoft.com/en-us/library/aa394239(v=vs.85).aspx
				$result | add-member -memberType NoteProperty -name 'NIC Name' -value $nics 
				$result | add-member -memberType NoteProperty -name 'MAC Address' -value $macs 
				$result | add-member -memberType NoteProperty -name 'IP Address' -value $ipadds
				#Return our result
				[array]$collection += $result
			} #End if
			elseif($errorcatch -eq $True) 
			{
				Write-Verbose "Failed to communicate with $PC"
				$fail = New-Object -TypeName PSObject
				$fail | Add-Member -MemberType NoteProperty -Name 'PCName' -Value $PC -Force
				$fail | Add-Member -MemberType NoteProperty -Name 'DateDataCollected' -Value "NA" -Force
				$fail | Add-Member -MemberType NoteProperty -Name DomainOrWorkgroup -Value "NA" -Force
				$fail | Add-Member -MemberType NoteProperty -Name Serial -Value "NA" -Force #Serial can be blank in case of replaced motherboards.
				$fail | Add-Member -MemberType NoteProperty -Name Model -Value "NA" -Force
				$fail | Add-Member -MemberType NoteProperty -Name Manufacturer -Value "NA" -Force
				$fail | Add-Member -MemberType NoteProperty -Name BiosDescription -Value "NA" -Force #Can include BIOS revision and date
				$fail | Add-Member -MemberType NoteProperty -Name LastBootUpTime -Value "NA" -Force
				$fail | Add-Member -MemberType NoteProperty -Name UptimeInHours -Value -Force
				$fail | Add-Member -MemberType NoteProperty -Name 'OS' -Value "NA" -Force #E.g. Windows 7 Enterprise
				$fail | Add-Member -MemberType NoteProperty -Name 'OS Version' -Value "NA" -Force #e.g. 6.1.7601
				$fail | Add-Member -MemberType NoteProperty -Name Architecture -Value "NA" -Force #x64 or x86
				$fail | Add-Member -MemberType NoteProperty -Name LoggedOnUser -Value "NA" -Force #User or users logged into the pc.
				$fail | Add-Member -MemberType NoteProperty -Name 'All users' -Value "NA" -Force #All users who have logged into the pc.
				$fail | Add-Member -MemberType NoteProperty -Name HardDrivesInfo -Value "NA" -Force
				$fail | Add-Member -MemberType NoteProperty -Name 'DriveLetter' -Value "NA" -Force
				$fail | add-member -memberType NoteProperty -name 'Capacity (GB)' -value "NA" -Force
				$fail | add-member -memberType NoteProperty -name 'Free Space (GB)' -value "NA" -Force
				$fail | Add-Member -memberType NoteProperty -name PercentFree -value "NA" -Force
				$fail | add-member -memberType NoteProperty -name 'Memory (GB)' -value "NA" -Force
				$fail | add-member -memberType NoteProperty -name 'usedMemory (GB)' -value "NA" -Force
				$fail | add-member -memberType NoteProperty -name PercentMemoryUsed -value "NA" -Force
				$fail | add-member -memberType NoteProperty -name 'NIC Name' -value "NA" -Force
				$fail | add-member -memberType NoteProperty -name 'MAC Address' -value "NA" -Force 
				$fail | add-member -memberType NoteProperty -name 'IP Address' -value "NA" -Force
				$collection += $fail
			}#End If
		} #End ForEach loop
			If ($Filter -eq $True)
			{
				#ExportReportTo-HTML $collection -Filter	
				$collection = $collection | Where-Object {$_.PercentFree -le 25 -or $_.PercentMemoryUsed -ge 90}
			}
				$collection
	} #End PROCESS
	END
	{
		<#If ($Sortable -eq $Ture and $Export -eq $True)
		{
			$collection | ExportTo-HTML
		}#>
		If ($Export -eq $True -and $Filter -eq $True)
		{
			$collection | ExportTo-HTML -Path $Path -Filter
		}
		Elseif ($Export -eq $True)
		{
			$collection | ExportTo-HTML -Path $Path #Exports results as an html file that opens in the default browser.
		}
	}
} #End function
#####
#End#
#####