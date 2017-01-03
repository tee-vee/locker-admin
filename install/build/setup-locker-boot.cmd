:: Derek Yuen <derekyuen@locision.com>
:: setup-locker-boot.cmd / setup-locker-boot.exe
:: December 2016

@echo off

echo ====================================================
echo          Start Locker Build Process - BOOT
echo ====================================================
:: build.cmd debug -- build debug version.
title "LOCKER DEPLOYMENT - INIT"

echo.
echo.%time%
echo.

:: --------------------------------------------------------------------------------------------
:: setup work environment
:: --------------------------------------------------------------------------------------------
echo.
echo "%~n0 setup work environment ..."
echo.
set bitsadmin=c:\windows\system32\bitsadmin.exe
set tmp=C:\temp
set baseurl=http://www.lockerlife.hk/deploy

:: get environment variables
%bitsadmin% /transfer "getenv" %baseurl%/setenv.cmd %tmp%\setenv.cmd
:: call me maybe?
call setenv.cmd


:: --------------------------------------------------------------------------------------------
:: envcheck
:: --------------------------------------------------------------------------------------------
echo "LOCKERINSTALL is: %LOCKERINSTALL%"
echo "LOCKERADMIN is: %LOCKERADMIN%"

:: just in case
%bitsadmin% /reset
cd %tmp%


:: --------------------------------------------------------------------------------------------
:: grab stuff
:: --------------------------------------------------------------------------------------------
echo.
echo "%~n0: Downloading hstart"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 10 'http://www.lockerlife.hk/deploy/hstart.exe' 'C:\temp\hstart.exe';}"

echo.
echo "%~n0: Downloading psexec"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 10 'http://www.lockerlife.hk/deploy/psexec.exe' 'C:\temp\psexec.exe';}"
echo.
echo "%~n0: Downloading software management"
REM %bitsadmin% /transfer "get-choco" %baseurl%/install-chocolatey.cmd %tmp%\install-chocolatey.cmd
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 10 'http://www.lockerlife.hk/deploy/install-chocolatey.cmd' 'C:\temp\install-chocolatey.cmd';}"

echo "%~n0: Downloading Dropbox"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 10 'http://www.lockerlife.hk/deploy/Dropbox16.4.30OfflineInstaller.exe' 'C:\temp\Dropbox16.4.30OfflineInstaller.exe';}"

echo.
echo "%~n0: downloading system mods"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 10 'http://www.lockerlife.hk/deploy/enable-UAC.cmd' 'C:\temp\enable-UAC.cmd';}"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 10 'http://www.lockerlife.hk/deploy/disable-UAC.cmd' 'C:\temp\disable-UAC.cmd';}"

echo.
echo "%~n0: downloading setup-locker-stage0-2"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 10 'http://www.lockerlife.hk/deploy/setup-locker-stage0.cmd' 'C:\temp\setup-locker-stage0.cmd';}"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 10 'http://www.lockerlife.hk/deploy/setup-locker-stage1.cmd' 'C:\temp\setup-locker-stage1.cmd';}"
:: %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 10 'http://www.lockerlife.hk/deploy/setup-locker-stage2.cmd' 'C:\temp\setup-locker-stage2.cmd';}"

echo "%~n0: clear bitsadmin service"
%bitsadmin% /reset

:: --------------------------------------------------------------------------------------------
:: powershell -Command "& {Update-Help -Confirm}"
:: --------------------------------------------------------------------------------------------

echo.
echo "%~n0: disable UAC"
:: New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -PropertyType "DWord"
hstart.exe /D="C:\temp" /nouac /delay=2 /runas /wait disable-UAC.cmd
echo "%~n0 statuscheck: %errorlevel%"
echo.

:: hstart.exe /D="C:\temp" /nouac /delay=2 /runas /wait net user administrator /active:yes

:: [] INSTALL PACKAGE MANAGEMENT
echo.
echo "%~n0: installing base software"
hstart.exe /nouac /runas /wait install-chocolatey.cmd
echo "%~n0 statuscheck: %errorlevel%"
echo.

:: [] REFRESH ENV
::start "RefreshEnv" /min %ProgramData%\chocolatey\bin\RefreshEnv.cmd

echo.
echo "%~n0: Fixing powershell runtime execution policy"
:: hstart.exe /runas /wait fix-powershell.cmd
echo.


:: --------------------------------------------------------------------------------------------
:: installing dropbox
:: --------------------------------------------------------------------------------------------
echo.
echo "%~n0: Installing dropbox
hstart.exe /runas /nouac /wait "Dropbox16.4.30OfflineInstaller.exe /S"
echo "%~n0 statuscheck: %errorlevel%"
echo.

echo.
echo ====================================
echo.
echo  PLEASE LOGIN TO DROPBOX
echo  Use username: kiosk@lockerlife.hk
echo.  
echo  After login, close Dropbox window!
echo.
echo ====================================
echo.
pause

echo.
echo.
echo "%~n0 Network connection check after explorer.exe reload"
ping -n 10 127.0.0.1
echo.

echo.
echo.
echo "%~n0 Pausing for dropbox sync"
echo.

:: --------------------------------------------------------------------------------------------
:: run setup-locker-stage0-2
:: --------------------------------------------------------------------------------------------
echo.
echo "%~n0: Starting setup-locker-stage0"
hstart.exe /runas /wait setup-locker-stage0.cmd
echo "%~n0 stage 0 status check: %errorlevel%"
echo.

echo.
echo "%~n0: Starting setup-locker-stage1"
hstart.exe /runas /wait setup-locker-stage1.cmd
echo "%~n0 Stage 1 status check: %errorlevel%"
echo.

echo.
echo "%~n0: Starting setup-locker-stage2"
hstart.exe /runas /wait "%USERPROFILE%\Dropbox\locker-admin\install\build\setup-locker-stage2.cmd"
echo "stage 2 status check: %errorlevel%"
echo.


:: %USERPROFILE%\Dropbox\locker-admin\tools\BootUpdCmd20.exe 

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

echo.
echo.
echo.
echo "===================================="
echo.
echo.  
echo  "REMINDER: SEND EMAIL TO LOCKER-ADMIN@LOCKERLIFE.HK"
echo  "WRITE NOTE ABOUT DEPLOYMENT"
echo  "SEE SAMPLE: http://lockerlife.hk/deploy"
echo.
echo.
echo "===================================="
echo.

endlocal
:END
@pause
