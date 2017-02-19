[CmdletBinding()]
Param()
Begin {
    if ($pshome -like '*syswow64*') {
        Write-Verbose 'Restarting script under 64-bit Shell'
        $PSScriptRoot = Split-path -parent $MyInvocation.MyCommand.Definition
        & (Join-Path -Path ($pshome -replace "syswow64", "sysnative") -ChildPath 'powershell.exe') -File `
        (Join-Path -Path $PSScriptRoot -ChildPath $MyInvocation.mycommand) @args
        exit
    }
    
    $sb = New-Object -TypeName 'System.Text.StringBuilder'
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        if ($_.Value -is [switch]) {
            $null = $sb.Append("-$($_.Key) ")
        } else {
            # if the value is an array of objects this won't work
            $null = $sb.Append("-$($_.Key) $($_.Value) ")
        }
    }
    Write-Verbose "Flat version of PSBoundparameters is: $sb"
    
    try {
        $os = [Version]$((Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop).Version)
    } catch {
        Write-Warning -Message 'Failed to query WMI Win32_OperatingSystem Class'
    }        

    # Run only on Windows 7
    if ($os -eq [system.version]'6.1.7601') {
        Write-Verbose "Running an expected OS version $([system.environment]::OSVersion.Version.ToString())"
    } else {
        Write-Warning "Unexpected OS version $([system.environment]::OSVersion.Version.ToString())"
        break
    }
    
    $id = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent();
    
    if (-not($id.IsInRole(544))) {
        Write-Warning  -Message 'Not running as Administrator'
        $WshShell = New-Object -ComObject Shell.Application
        $PSScriptRoot = Split-path -parent $MyInvocation.MyCommand.Definition
        $WshShell.ShellExecute(
            (Join-Path -Path ($pshome -replace 'syswow64','sysnative') -ChildPath 'powershell.exe'),
            "-NoProfile -ExecutionPolicy Bypass -File $(Join-Path -Path $PSScriptRoot -ChildPath $MyInvocation.mycommand) $sb",
            $null,
            'runas'
        )
        exit
    } else {
        Write-Verbose -Message 'Running with administrative privileges'
    }

    # Define our local log file for post-mortem debugging
    $OFHT = @{ 
        Filepath = "$($env:windir)\temp\WMF5-PSinstall.$('{0:yyyyMMddHHmmss}' -f (Get-Date)).log";
        Append = $true ;
        NoClobber = $true ;
        Encoding = 'ascii' ;
    }
} 
Process {
    
    # Avoid install if magic file is found
    if (Test-Path -Path "$($env:systemroot)\NoWMF5.dat" -PathType Leaf) {
        Write-Warning -Message "NoWMF5.dat magic file found in systemroot"
        "$((get-date).ToString('s')) ; NoWMF5.dat magic file found in systemroot" | Out-File @OFHT
        break    
    }    

    # Test if WMF5.0 is installed
    if ($PSVersionTable.PSVersion -gt [version]'5.0') {
        Write-Verbose -Message 'WMF 5.0 already installed'
        "$((get-date).ToString('s')) ; WMF 5.0 already installed" | Out-File @OFHT
        break
    }

    # Registry path that indicates that a PS version was installed and a reboot is pending
    $PSPendingPath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending\*PowerShell*'    
    # Prepare a hashtable for Start-Process
    $SPHT = @{
        NoNewWindow = $true ;
        PassThru = $true ;
        Wait = $true ;
        ErrorAction = 'Stop';
    }

    # Hardcoded download URL
    $DotNetURI = 'http://wsus.ds.download.windowsupdate.com/c/msdownload/update/software/ftpk/2015/01/ndp452-kb2901983-x86-x64-enu_0350e593835125031f36e846ff3b936c09b8d479.exe'
    $WMF4URI   = 'https://download.microsoft.com/download/3/D/6/3D61D262-8549-4769-A660-230B67E15B25/Windows6.1-KB2819745-x64-MultiPkg.msu'
    $WMF5URI   = 'http://go.microsoft.com/fwlink/?LinkId=717504'

    # Test if we already run WM4.0
    if ($PSVersionTable.PSVersion -eq [version]'4.0') {

        if (-not( Get-ChildItem -Path $PSPendingPath -ErrorAction SilentlyContinue)) {
            
            # STAGE 3: WMF4 already installed > install WMF5
            
            $MSU = (Join-Path -Path $($env:systemroot) -ChildPath 'temp\Win7AndW2K8R2-KB3134760-x64.msu')
           
            $WMF5HT = @{
                Uri = $WMF5URI ;
                OutFile = $MSU ;
                UseBasicParsing = $true ;
                UserAgent = 'Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko' ;
            }
            
            try {
                Invoke-WebRequest @WMF5HT -ErrorAction Stop -Verbose:$false
                Write-Verbose -Message 'Successfully downloaded WMF 5.0'
                "$((get-date).ToString('s')) ; Successfully downloaded WMF 5.0" | Out-File @OFHT
            } catch {
                Write-Warning -Message "Failed to download WMF 5.0 because $($_.Exception.Message)"
                "$((get-date).ToString('s')) ; Failed to download WMF 5.0 because $($_.Exception.Message)" | Out-File @OFHT
            }
            #SHA256 077E864CC83739AC53750C97A506E1211F637C3CD6DA320C53BB01ED1EF7A98B

            if ((Get-AuthenticodeSignature -FilePath $MSU -ErrorAction SilentlyContinue).Status.value__ -ne 0) {
                Write-Warning -Message 'Signature from WMF5.0 file downloaded is not valid'
                "$((get-date).ToString('s')) ; Signature from WMF5.0 file downloaded is not valid" | Out-File @OFHT
                break
            }

            Write-Verbose -Message 'Launching the installation of WMF5.0'
            "$((get-date).ToString('s')) ; Launching the installation of WMF5.0" | Out-File @OFHT
            $SPHT.Add('FilePath',"$($env:systemroot)\system32\wusa.exe")
            $SPHT.Add('ArgumentList',@($MSU,'/quiet','/norestart' ))
            try {
                Start-Process @SPHT
            } catch {
                Write-Warning -Message "Failed to start the installation of WMF5.0 because $($_.Exception.Message)"
                "$((get-date).ToString('s')) ; Failed to start the installation of WMF5.0 because $($_.Exception.Message)" |
                Out-File @OFHT
            }                

        } else {
            Write-Warning -Message 'WMF5.0 is installed and a reboot is pending'
            "$((get-date).ToString('s')) ; WMF5.0 is installed and a reboot is pending" | Out-File @OFHT
        }
      
    } else {
    
        # Import Bits cmdlets required for both Stage 1 and 2
        try {
            Import-Module -Name BitsTransfer -Force -Verbose:$false -ErrorAction Stop
        } catch {
            Write-Warning -Message "Failed to load BitsTransfer module because $($_.Exception.Message)"
            "$((get-date).ToString('s')) ; Failed to load BitsTransfer module because $($_.Exception.Message)" | Out-File @OFHT
            break
        }
        
        # Test the .Net Prerequisite
        if (Test-Path -Path "$($env:systemroot)\Microsoft.Net\FrameWork\v4.0.30319\System.Runtime.dll") {

            if( (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4.0\Client' -Name Install).Install -ne 1) {
                Write-Warning -Message 'Double check .Net 4.x prerequisite failed'
                "$((get-date).ToString('s')) ; Double check .Net 4.x prerequisite failed" | Out-File @OFHT
                break
            }
            
            if (-not( Get-ChildItem -Path $PSPendingPath -ErrorAction SilentlyContinue)) {

                # STAGE 2: .Net 4.5.2 already installed > install WMF 4.0
                
                $MSU = Join-Path -Path $($env:systemroot) -ChildPath 'temp\Windows6.1-KB2819745-x64-MultiPkg.msu'
                
                # Download with BITS as we are running PS 2.0 or 3.0 and don't have yet Invoke-WebRequest cmdlet
                try {
                    $job = Start-BitsTransfer -Suspended -Asynchronous -Source $WMF4URI -Destination $MSU -ErrorAction Stop
                    $null = Resume-BitsTransfer -BitsJob $job -Asynchronous -ErrorAction Stop
                } catch {
                    Write-Warning -Message "Failed to initiate BITS transfer because $($_.Exception.Message)"
                    "$((get-date).ToString('s')) ; Failed to initiate BITS transfer because $($_.Exception.Message)" | Out-File @OFHT
                    break
                }
                
                while ($job.JobState -ne 'Transferred') {
                    Write-Progress -activity 'Downloading WMF4.0' -Status 'Percent completed: ' -PercentComplete (
                        $job.BytesTransferred*100/$job.BytesTotal
                    )
                }
                Switch($job.JobState) {
                     'Transferred' {
                        Start-Sleep -Seconds 1
                        Complete-BitsTransfer -BitsJob $job -ErrorAction SilentlyContinue
                        break
                    }
                    'Error' {
                        $job | Format-List
                        break
                    }
                    default {} 
                }
                if ((Get-AuthenticodeSignature -FilePath $MSU -ErrorAction SilentlyContinue).Status.value__ -ne 0) {
                    Write-Warning 'Signature from WMF4.0 file downloaded is not valid'
                    "$((get-date).ToString('s')) ; Signature from WMF4.0 file downloaded is not valid" | Out-File @OFHT
                    break
                }
                # SHA256 FBC0889528656A3BC096F27434249F94CBA12E413142AA38946FCDD8EDF6F4C5

                Write-Verbose -Message 'Launching the installation of WMF4.0'
                "$((get-date).ToString('s')) ; Launching the installation of WMF4.0" | Out-File @OFHT
                $SPHT.Add('FilePath',"$($env:systemroot)\system32\wusa.exe")
                $SPHT.Add('ArgumentList',@($MSU,'/quiet','/norestart'))
                try {
                    Start-Process @SPHT
                } catch {
                    Write-Warning -Message "Failed to start the installation of WMF4.0 because $($_.Exception.Message)"
                    "$((get-date).ToString('s')) ; Failed to start the installation of WMF4.0 because $($_.Exception.Message)" |
                    Out-File @OFHT
                }                    
            } else {
                Write-Warning -Message 'WMF4.0 is installed and a reboot is pending'
                "$((get-date).ToString('s')) ; WMF4.0 is installed and a reboot is pending" | Out-File @OFHT
            }
            
        } else {
        
            # STAGE 1: Install missing .Net 4.5.2
        
            $MSU = Join-Path -Path $($env:systemroot) -ChildPath 'temp\ndp452-kb2901983-x86-x64-enu.exe'
            
            # Download with BITS as we are running PS 2.0 or 3.0 and don't have yet Invoke-WebRequest cmdlet
            try {
                $job = Start-BitsTransfer -Suspended -Asynchronous -Source $DotNetURI -Destination $MSU -ErrorAction Stop
                $null = Resume-BitsTransfer -BitsJob $job -Asynchronous -ErrorAction Stop
            } catch {
                Write-Warning -Message "Failed to initiate BITS transfer because $($_.Exception.Message)"
                "$((get-date).ToString('s')) ; Failed to initiate BITS transfer because $($_.Exception.Message)" | Out-File @OFHT
                break
            }            
            
            while ($job.JobState -ne 'Transferred') {
                Write-Progress -activity 'Downloading .Net 4.5.2' -Status 'Percent completed: ' -PercentComplete (
                    $job.BytesTransferred*100/$job.BytesTotal
                )
            } 
            Switch($job.JobState) {
                 'Transferred' {
                    Start-Sleep -Seconds 1
                    Complete-BitsTransfer -BitsJob $job -ErrorAction SilentlyContinue
                    break
                }
                'Error' {
                    $job | Format-List
                    break
                } 
                default {} 
            }
            if ((Get-AuthenticodeSignature -FilePath $MSU -ErrorAction SilentlyContinue).Status.value__ -ne 0) {
                Write-Warning 'Signature from file downloaded .Net 4.5.2 is not valid'
                "$((get-date).ToString('s')) ; Signature from file downloaded .Net 4.5.2 is not valid" | Out-File @OFHT
                break
            }
            # SHA256  6C2C589132E830A185C5F40F82042BEE3022E721A216680BD9B3995BA86F3781

            Write-Verbose -Message 'Launching a silent installation of .Net 4.5.2 and waiting for it to complete'
            "$((get-date).ToString('s')) ; Launching the installation of .Net 4.5.2 " | Out-File @OFHT
            $SPHT.Add('FilePath',$MSU)
            $SPHT.Add('ArgumentList',@('/q','/norestart','/log',"$($env:SystemRoot)\TEMP\NetFx.4.5.2.log"))
            try {
                Start-Process @SPHT
            } catch {
                Write-Warning -Message "Failed to start the installation of .Net 4.5.2 because $($_.Exception.Message)"
                "$((get-date).ToString('s')) ; Failed to start the installation of .Net 4.5.2 because $($_.Exception.Message)" | 
                Out-File @OFHT
            }
        }
    }
} 
End {}
