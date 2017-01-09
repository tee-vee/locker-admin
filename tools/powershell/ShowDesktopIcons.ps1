## ==============================================
## Show Desktop Icons
## ==============================================

$ErrorActionPreference = "SilentlyContinue"
If ($Error) {$Error.Clear()}
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
If (Test-Path $RegistryPath) {
	$Res = Get-ItemProperty -Path $RegistryPath -Name "HideIcons"
	If (-Not($Res)) {
		New-ItemProperty -Path $RegistryPath -Name "HideIcons" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	$Check = (Get-ItemProperty -Path $RegistryPath -Name "HideIcons").HideIcons
	If ($Check -NE 0) {
		New-ItemProperty -Path $RegistryPath -Name "HideIcons" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
}
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons"
If (-Not(Test-Path $RegistryPath)) {
	New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "HideDesktopIcons" -Force | Out-Null
	New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons" -Name "NewStartPanel" -Force | Out-Null
}
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
If (-Not(Test-Path $RegistryPath)) {
	New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons" -Name "NewStartPanel" -Force | Out-Null
}
If (Test-Path $RegistryPath) {
	## -- My Computer
	$Res = Get-ItemProperty -Path $RegistryPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
	If (-Not($Res)) {
		New-ItemProperty -Path $RegistryPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	$Check = (Get-ItemProperty -Path $RegistryPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}")."{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
	If ($Check -NE 0) {
		New-ItemProperty -Path $RegistryPath -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	## -- Control Panel
	$Res = Get-ItemProperty -Path $RegistryPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}"
	If (-Not($Res)) {
		New-ItemProperty -Path $RegistryPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	$Check = (Get-ItemProperty -Path $RegistryPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}")."{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}"
	If ($Check -NE 0) {
		New-ItemProperty -Path $RegistryPath -Name "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	## -- User's Files
	$Res = Get-ItemProperty -Path $RegistryPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}"
	If (-Not($Res)) {
		New-ItemProperty -Path $RegistryPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	$Check = (Get-ItemProperty -Path $RegistryPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}")."{59031a47-3f72-44a7-89c5-5595fe6b30ee}"
	If ($Check -NE 0) {
		New-ItemProperty -Path $RegistryPath -Name "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	## -- Recycle Bin
	$Res = Get-ItemProperty -Path $RegistryPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}"
	If (-Not($Res)) {
		New-ItemProperty -Path $RegistryPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	$Check = (Get-ItemProperty -Path $RegistryPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}")."{645FF040-5081-101B-9F08-00AA002F954E}"
	If ($Check -NE 0) {
		New-ItemProperty -Path $RegistryPath -Name "{645FF040-5081-101B-9F08-00AA002F954E}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	## -- Network
	$Res = Get-ItemProperty -Path $RegistryPath -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}"
	If (-Not($Res)) {
		New-ItemProperty -Path $RegistryPath -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
	$Check = (Get-ItemProperty -Path $RegistryPath -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}")."{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}"
	If ($Check -NE 0) {
		New-ItemProperty -Path $RegistryPath -Name "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" -Value "0" -PropertyType DWORD -Force | Out-Null
	}
}
If ($Error) {$Error.Clear()}