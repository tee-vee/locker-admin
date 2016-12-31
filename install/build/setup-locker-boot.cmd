:: Derek Yuen <derekyuen@locision.com>
:: setup-locker-boot.cmd / setup-locker-boot.exe
:: December 2016

@echo off

echo ====================================================
echo          Start Locker Build Process - BOOT
echo ====================================================
:: build.cmd debug -- build debug version.
setlocal

:: setup work environment
echo.
echo "setup work environment ..."
setlocal
set bitsadmin=c:\windows\system32\bitsadmin.exe
set tmp=C:\temp
set baseurl=http://www.lockerlife.hk/deploy
set ps=C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
c:
mkdir %tmp%
cd %tmp%
echo "%n0: Setup work environment ... done"

:: just in case
%bitsadmin% /reset

:: grab stuff
echo.
echo "%n0: Downloading hstart"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/hstart.exe' 'C:\temp\hstart.exe';}"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/_pkg/Dropbox16.4.30OfflineInstaller.exe' 'C:\temp\Dropbox16.4.30OfflineInstaller.exe';}"

echo.
echo "%n0: Downloading psexec"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/psexec.exe' 'C:\temp\psexec.exe';}"

echo.
echo "downloading software management"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/install-chocolatey.cmd' 'C:\temp\install-chocolatey.cmd';}"

echo.
echo "downloading system mods"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/enable-UAC.cmd' 'C:\temp\enable-UAC.cmd';}"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/disable-UAC.cmd' 'C:\temp\disable-UAC.cmd';}"

echo.
echo "downloading setup-locker-stage0"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/setup-locker-stage0.cmd' 'C:\temp\setup-locker-stage0.cmd';}"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/setup-locker-stage1.cmd' 'C:\temp\setup-locker-stage1.cmd';}"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/setup-locker-stage2.cmd' 'C:\temp\setup-locker-stage2.cmd';}"

:: powershell -Command "& {Update-Help -Confirm}"
echo "%n0: clear bitsadmin service"
%bitsadmin% /reset

:: just prompt to run an elevated shell
::   OLD-> Start-Process -FilePath "c:\temp\locker-setup\setup-locker-stage1.cmd" -Verb runAs
::   OLD-> Start-Process -FilePath "c:\temp\locker-setup\test2.cmd" -Verb runAs

:: 
echo.
echo "%n0: disable UAC"
:: New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -PropertyType "DWord"
hstart.exe /delay=2 /runas /wait disable-UAC.cmd

:: [] INSTALL PACKAGE MANAGEMENT
echo.
echo "%n0: installing base software"
hstart.exe /runas /wait install-chocolatey.cmd

:: [] REFRESH ENV
start /min %ProgramData%\chocolatey\bin\RefreshEnv.cmd


echo "%n0: Fixing powershell runtime execution policy"
hstart.exe /runas /wait fix-powershell.cmd

echo.
echo "%n0: installing dropbox
hstart.exe /runas /wait "Dropbox16.4.30OfflineInstaller.exe /S"

echo
echo ====================================
echo
echo  PLEASE LOGIN TO DROPBOX
echo  Use username: kiosk@lockerlife.hk
echo
echo
echo ====================================
echo
pause

hstart.exe /runas /wait setup-locker-stage0.cmd
echo %errorlevel%

:: cleanup function
:: echo.
:: echo "enable UAC"
:: hstart.exe /delay=2 /runas /wait enable-UAC.cmd
:: hstart.exe /runas /wait restore-powershell.cmd

:: del /q %tmp%\*.ps1
:: del /q %tmp%\*.txt
:: del /q %tmp%\*.exe
:: del /q %tmp%\*.cmd
:: del /q %tmp%\*.bat
:: del /q %tmp%\*.zip
:: del /q %tmp%\*.reg
:: rmdir /S /Q %tmp%\_gpo
:: rmdir /S /Q %tmp%\_updates
:: rmdir /S /Q %tmp%\chocolatey

echo
echo ====================================
echo
echo  off to stage 1
echo  REMINDER: SEND EMAIL TO LOCKER-ADMIN@LOCKERLIFE.HK
echo  WRITE NOTE ABOUT DEPLOYMENT
echo  SEE SAMPLE: http://lockerlife.hk/deploy
echo

 

endlocal
popd
:END
@pause
