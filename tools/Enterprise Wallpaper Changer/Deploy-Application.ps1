<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
	Deploy-Application.ps1
.EXAMPLE
	Deploy-Application.ps1 -DeployMode 'Silent'
.EXAMPLE
	Deploy-Application.ps1 -AllowRebootPassThru -AllowDefer
.EXAMPLE
	Deploy-Application.ps1 -DeploymentType Uninstall
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'NonInteractive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $true
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'TP'
	[string]$appName = 'TP Wallpaper'
	[string]$appVersion = '3.0.0.0'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '20/10/2015'
	[string]$appScriptAuthor = 'Topaz Paul'
	##*===============================================
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.5'
	[string]$deployAppScriptDate = '08/17/2015'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
        . "$scriptDirectory\SupportFiles\Get-ApplicationInfo.ps1"
        . "$scriptDirectory\SupportFiles\Get-PendingReboot.ps1"
        . "$scriptDirectory\SupportFiles\Get-loggedonuser.ps1"
        . "$scriptDirectory\SupportFiles\Get-MSHotfix.ps1"
		. "$scriptDirectory\SupportFiles\Get-NetworkAddress.ps1"
		. "$scriptDirectory\SupportFiles\Set-FolderIcon.ps1"
        . "$scriptDirectory\SupportFiles\Set-WPFunctions.ps1"
        . "$scriptDirectory\SupportFiles\Get-ScreenResolution.ps1"
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		
		
		Show-InstallationWelcome -CloseApps "TPwallpaper"

        
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'


        if($is64Bit){	
        
            if (Test-Path -Path "$envProgramFilesX86\TPWallpaper"){
        
                Remove-Folder -Path "$envProgramFilesX86\TPWallpaper"  -ContinueOnError:$true
        
            }
        
            New-Folder -Path "$envProgramFilesX86\TPWallpaper"	

            $wallpaperFiles = (Get-ChildItem -Path "$dirFiles").Name
        
            if([Version]($PSVersionTable.Psversion) -lt [Version]'4.0'){

                Copy-Item $dirFiles\* "$envProgramFilesX86\TPWallpaper" -ErrorAction SilentlyContinue
            
            } else {
        
                ForEach($wallpaperFile in $wallpaperFiles){

                    Copy-File -Path "$dirFiles\$wallpaperFile" -Destination "$envProgramFilesX86\TPWallpaper\$wallpaperFile"

                }
            }

            Set-RegistryKey -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" -Name 'TPWallpaper' -Value "$envProgramFilesX86\TPWallpaper\TPwallpaper.exe"

            Set-RegistryKey -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "$envProgramFilesX86\TPWallpaper\TPwallpaper.exe" -Value "HIGHDPIAWARE"
        
        } Else {

            if (Test-Path -Path "$envProgramFiles \TPWallpaper"){
        
                Remove-Folder -Path "$envProgramFiles\TPWallpaper"  -ContinueOnError:$true
        
            }
        
            New-Folder -Path "$envProgramFiles\TPWallpaper"	

            $wallpaperFiles = (Get-ChildItem -Path "$dirFiles").Name
        
            if([Version]($PSVersionTable.Psversion) -lt [Version]'4.0'){

                Copy-Item $dirFiles\* "$envProgramFiles\TPWallpaper" -ErrorAction SilentlyContinue
            
            } else {
        
                ForEach($wallpaperFile in $wallpaperFiles){

                    Copy-File -Path "$dirFiles\$wallpaperFile" -Destination "$envProgramFiles\TPWallpaper\$wallpaperFile"

                }
            }

            Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run" -Name 'TPWallpaper' -Value "$envProgramFiles\TPWallpaper\TPwallpaper.exe"

            Set-RegistryKey -Key "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "$envProgramFiles\TPWallpaper\TPwallpaper.exe" -Value "HIGHDPIAWARE"

        }

		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
 
            If (!(Test-Path ("HKLM:\SOFTWARE\TPSoftwareInventory"))){New-Item -path "HKLM:\SOFTWARE\TPSoftwareInventory"}

            If (!(Test-Path ("HKLM:\SOFTWARE\TPSoftwareInventory\TPWallpaper"))){
        
                New-Item -path "HKLM:\SOFTWARE\TPSoftwareInventory\TPWallpaper" -Force -ErrorAction SilentlyContinue
        
            } Else {

                Remove-Item -path "HKLM:\SOFTWARE\TPSoftwareInventory\TPWallpaper" -Force -ErrorAction SilentlyContinue

                New-Item -path "HKLM:\SOFTWARE\TPSoftwareInventory\TPWallpaper" -Force -ErrorAction SilentlyContinue

            }

		    Set-ItemProperty "HKLM:\SOFTWARE\TPSoftwareInventory\TPWallpaper" -Name "Version" -Value $appVersion -Force -ErrorAction SilentlyContinue
		
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

        Show-InstallationWelcome -CloseApps "TPwallpaper"

        Remove-RegistryKey -Key "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" -Name 'TPWallpaper' -ContinueOnError:$true

        Remove-RegistryKey -Key "HKLM:\Software\Wow6432Node\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "$envProgramFilesX86\TPWallpaper\TPwallpaper.exe" -ContinueOnError:$true

        Remove-RegistryKey -Key "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name 'TPWallpaper' -ContinueOnError:$true

        Remove-RegistryKey -Key "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "$envProgramFiles\TPWallpaper\TPwallpaper.exe" -ContinueOnError:$true
		
        New-PSDrive HKU Registry HKEY_USERS

        $arrusers = gwmi -Class win32_userprofile

        foreach($arruser in $arrusers){

            Remove-RegistryKey -Key "HKU:$($arruser.SID)\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name 'TPWallpaper' -ContinueOnError:$true

            Remove-RegistryKey -Key "HKU:$($arruser.SID)\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "$envProgramFilesX86\TPWallpaper\TPwallpaper.exe" -ContinueOnError:$true

            Remove-RegistryKey -Key "HKU:$($arruser.SID)\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" -Name "$envProgramFiles\TPWallpaper\TPwallpaper.exe" -ContinueOnError:$true

        }

        if (Test-Path -Path "$envProgramFilesX86\TPWallpaper"){
        
            Remove-Folder -Path "$envProgramFilesX86\TPWallpaper"  -ContinueOnError:$true
        
        }	

		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		Execute-Process -Path "$dirFiles\TPwallpaper-Windows-Default.exe" -Parameters  "`"$envWinDir\Web\Wallpaper\Windows\img0.jpg`" `"Stretched`"" -WindowStyle 'Hidden'
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		If (Test-Path ("HKLM:\SOFTWARE\TPSoftwareInventory\TPWallpaper")){
        
            Remove-Item -path "HKLM:\SOFTWARE\TPSoftwareInventory\TPWallpaper" -Force -ErrorAction SilentlyContinue
        
        }
		
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	#Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}