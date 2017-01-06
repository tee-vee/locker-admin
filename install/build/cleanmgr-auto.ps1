Write-Verbose 'Clearing CleanMgr.exe automation settings.'
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*' -Name StateFlags0001 -ErrorAction SilentlyContinue | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue

Write-Verbose 'Enabling Update Cleanup. This is done automatically in via a scheduled task in Windows 10.'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -Name StateFlags0001 -Value 2 -PropertyType DWord

Write-Verbose 'Enabling Temporary Files Cleanup.'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files' -Name StateFlags0001 -Value 2 -PropertyType DWord

Write-Verbose 'Starting CleanMgr.exe...'
Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -WindowStyle Hidden -Wait

Write-Verbose 'Waiting for CleanMgr and DismHost processes. Second wait neccesary as CleanMgr.exe spins off separate processes.'
Get-Process -Name cleanmgr,dismhost -ErrorAction SilentlyContinue | Wait-Process

$UpdateCleanupSuccessful = $false
if (Test-Path $env:SystemRoot\Logs\CBS\DeepClean.log) {
    $UpdateCleanupSuccessful = Select-String -Path $env:SystemRoot\Logs\CBS\DeepClean.log -Pattern 'Total size of superseded packages:' -Quiet
}

if ($UpdateCleanupSuccessful) {
    Write-Verbose 'Rebooting to complete CleanMgr.exe Update Cleanup....'
    SHUTDOWN.EXE /r /f /t 0 /c 'Rebooting to complete CleanMgr.exe Update Cleanup....'
}

    
#more info here:
#http://support.microsoft.com/kb/253597
 
#ensure we're running on windows 8.1 first
if ((Get-CimInstance win32_operatingsystem).version -eq '6.3.9600') {
 
#Capture current free disk space on Drive C
$FreespaceBefore = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB
 
#Set StateFlags0012 setting for each item in Windows 8.1 disk cleanup utility
if&nbsp; (-not (get-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -name StateFlags0012 -ErrorAction SilentlyContinue)) {
set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Archive Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Queue Files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files' -name StateFlags0012 -type DWORD -Value 2
set-itemproperty -path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files' -name StateFlags0012 -type DWORD -Value 2
}
 
cleanmgr /sagerun:12
 
do {
"waiting for cleanmgr to complete. . ."
start-sleep 5
} while ((get-wmiobject win32_process | where-object {$_.processname -eq 'cleanmgr.exe'} | measure).count)
 
$FreespaceAfter = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB
 
"Free Space Before: {0}" -f $FreespaceBefore
"Free Space After: {0}" -f $FreespaceAfter

