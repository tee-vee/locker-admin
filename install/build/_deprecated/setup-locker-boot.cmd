:: Derek Yuen <derekyuen@locision.com>
:: setup-locker-boot.cmd / setup-locker-boot.exe
:: December 2016

@echo off

echo ====================================================
echo          Start Locker Build Process - BOOTSTRAP
echo ====================================================
:: build.cmd debug -- build debug version.
title "LOCKER DEPLOYMENT - BOOTSTRAP"

echo.
echo.%time%
echo.


:: --------------------------------------------------------------------------------------------
:: setup work environment
:: --------------------------------------------------------------------------------------------
echo.
echo "%~n0 setup work environment ..."
echo.
set bitsadmin=%windir%\system32\bitsadmin.exe
set _tmp=C:\temp
set baseurl=http://lockerlife.hk/deploy

:: get environment variables
REM ## %bitsadmin% /transfer "getenv" %baseurl%/setenv.cmd %_tmp%\setenv.cmd
:: call me maybe? 
call setenv.cmd


:: --------------------------------------------------------------------------------------------
:: envcheck
:: --------------------------------------------------------------------------------------------
echo "LOCKERINSTALL is: %LOCKERINSTALL%"
echo "LOCKERADMIN is: %LOCKERADMIN%"

:: just in case
%bitsadmin% /reset
cd %_tmp%

:: --------------------------------------------------------------------------------------------
:: enable administrator
hstart.exe /D="C:\temp" /nouac /delay=2 /runas /wait net user administrator /active:yes


:: --------------------------------------------------------------------------------------------
:: Temporarily stop antivirus 
:: --------------------------------------------------------------------------------------------
%windir%\System32\sc.exe stop MsMpSvc
%windir%\System32\timeout.exe /t 5 /nobreak
%windir%\System32\sc.exe stop MsMpSvc

:: --------------------------------------------------------------------------------------------
:: let's try git
:: --------------------------------------------------------------------------------------------

:: check for git
REM ## if not exist "%git%" (

:: okay, no git. let's install - first we need a install config:

REM ## 	set _gitconfig=%_tmp%\git-install.inf
REM ##     set gitinstall=Git-2.11.0-32-bit.exe
REM ## 
REM ##     type NUL > %_gitconfig%
REM ## 	echo "[Setup]" >> %_gitconfig%
REM ## 	echo "Lang=default" >> %_gitconfig%
REM ## 	echo "Dir=C:\Program Files\Git" >> %_gitconfig%
REM ## 	echo "Group=Git" >> %_gitconfig%
REM ## 	echo "NoIcons=0" >> %_gitconfig%
REM ## 	echo "SetupType=default" >> %_gitconfig%
REM ## 	echo "Components=assoc,assoc_sh" >> %_gitconfig%
REM ## 	echo "Tasks=" >> %_gitconfig%
REM ## 	echo "PathOption=Cmd" >> %_gitconfig%
REM ## 	echo "SSHOption=OpenSSH" >> %_gitconfig%
REM ## 	echo "CRLFOption=CRLFCommitAsIs" >> %_gitconfig%
REM ## 	echo "BashTerminalOption=ConHost" >> %_gitconfig%
REM ## 	echo "PerformanceTweaksFSCache=Enabled" >> %_gitconfig%
REM ## 	echo "UseCredentialManager=Disabled" >> %_gitconfig%
REM ## 	echo "EnableSymlinks=Disabled" >> %_gitconfig%
REM ## 	echo "EnableBuiltinDifftool=Disabled" >> %_gitconfig%
REM ##     
REM ##     %bitsadmin% /transfer "get git" %baseurl%\%gitinstall% %_tmp%\%gitinstall%
REM ##     
REM ##         
REM ## 	set _gitconfig=
REM ## )


:: --------------------------------------------------------------------------------------------
:: grab stuff
:: --------------------------------------------------------------------------------------------


if not exist "C:\temp\hstart.exe" (
    echo.
    echo "%~n0: Downloading hstart.exe"
    start "get hstart" %bitsadmin% /transfer "Download hstart.exe" %baseurl%/hstart.exe %_tmp%\hstart.exe
    REM ## %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/hstart.exe' 'C:\temp\hstart.exe';}"
    set hstart=C:\temp\hstart.exe
)

:: 2017-01 dky - changeover to boxstarter deployment
REM ## if not exist "C:\temp\psexec.exe" (
REM ##     echo.
REM ##     echo "%~n0: Downloading psexec"
REM ##      %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/psexec.exe' 'C:\temp\psexec.exe';}"
REM ##      start "psexec" %bitsadmin% /transfer "Download psexec" %baseurl%/psexec.exe %_tmp%\psexec.exe
REM ## )

:: 2017-01 dky - changeover to boxstarter deployment
REM ## echo.
REM ## echo "%~n0: Downloading software management"
REM ## start "choco" %bitsadmin% /transfer "get-choco" %baseurl%/install-chocolatey.cmd %_tmp%\install-chocolatey.cmd
REM ## %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/install-chocolatey.cmd' 'C:\temp\install-chocolatey.cmd';}"

echo.
echo "%~n0: downloading system mods"
REM ## %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/enable-UAC.cmd' 'C:\temp\enable-UAC.cmd';}"
REM ## %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/disable-UAC.cmd' 'C:\temp\disable-UAC.cmd';}"
start "download system mods" %bitsadmin% /transfer "Downloading System Mods1" %baseurl%/enable-UAC.cmd %_tmp%\enable-UAC.cmd
start "download system mods2" %bitsadmin% /transfer "Downloading System Mods2" %baseurl%/disable-UAC.cmd %_tmp%\disable-UAC.cmd

REM ## if not exist "C:\temp\Dropbox16.4.30OfflineInstaller.exe" (
REM ##     echo "%~n0: Downloading Dropbox"
REM ##    REM ## %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/Dropbox16.4.30OfflineInstaller.exe' 'C:\temp\Dropbox16.4.30OfflineInstaller.exe';}"
REM ##    start "download dropbox" /wait %bitsadmin% /transfer "Downloading Dropbox" %baseurl%/Dropbox16.4.30OfflineInstaller.exe %_tmp%\Dropbox16.4.30OfflineInstaller.exe
REM ## )

echo.
echo "%~n0: downloading setup-locker-stage0-2"
REM ## %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/setup-locker-stage0.cmd' 'C:\temp\setup-locker-stage0.cmd';}"
REM ## %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/setup-locker-stage1.cmd' 'C:\temp\setup-locker-stage1.cmd';}"
:: %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/setup-locker-stage2.cmd' 'C:\temp\setup-locker-stage2.cmd';}"
start "download stage0" %bitsadmin% /transfer "Downloading stage0" %baseurl%/setup-locker-stage0.cmd %_tmp%\setup-locker-stage0.cmd
start "download stage1" %bitsadmin% /transfer "Downloading stage1" %baseurl%/setup-locker-stage1.cmd %_tmp%\setup-locker-stage1.cmd
start "download stage2" %bitsadmin% /transfer "Downloading stage2" %baseurl%/setup-locker-stage2.cmd %_tmp%\setup-locker-stage2.cmd

echo "%~n0: clear bitsadmin service"
%bitsadmin% /reset

:: --------------------------------------------------------------------------------------------
:: powershell -Command "& {Update-Help -Confirm}"
:: --------------------------------------------------------------------------------------------

echo.
echo "%~n0: disable UAC"
:: New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -PropertyType "DWord"
%hstart% /D="C:\temp" /nouac /delay=2 /runas /wait disable-UAC.cmd
echo "%~n0 statuscheck: %errorlevel%"
echo.

echo.
echo "%~n0: Fixing powershell runtime execution policy"
:: hstart.exe /runas /wait fix-powershell.cmd
echo.


:: --------------------------------------------------------------------------------------------
:: installing dropbox
:: --------------------------------------------------------------------------------------------
REM ## echo.
REM ## echo "%~n0: Installing dropbox
REM ## %hstart% /runas /nouac /wait "Dropbox16.4.30OfflineInstaller.exe /S"
REM ## echo "%~n0 statuscheck: %errorlevel%"
REM ## echo.


:: --------------------------------------------------------------------------------------------
:: installing package management / base software
:: --------------------------------------------------------------------------------------------
echo.
echo "%~n0: installing base software"
%hstart% /nouac /runas /wait install-chocolatey.cmd
echo "%~n0 statuscheck: %errorlevel%"
echo.

:: [] REFRESH ENV
::start "RefreshEnv" /min %ProgramData%\chocolatey\bin\RefreshEnv.cmd


:: --------------------------------------------------------------------------------------------
:: Dropbox check
:: --------------------------------------------------------------------------------------------

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

timeout /t 5 /nobreak
ping -n 10 www.dropbox.com

:: Check Dropbox
if not exist "%LOCKERTOOLS%" (
    echo.
    echo "1st Try" 
    echo "Please check Dropbox login"
    timeout /t 10
    if not exist "%USERPROFILE%\Dropbox\locker-admin" (
        echo.
        echo "2nd Try"
        echo "No Dropbox - locker setup problems"
        echo "please fix dropbox first!"
        exit /b -1
    )
) else (
    timeout /t 5
    echo.
    if exist "%USERPROFILE%\Dropbox\locker-admin\install" (
        echo "Looks REALLY good!"
        echo "A short one minute pause to let dropbox sync"
        timeout /t 60 /nobreak
        set BACKUPPLAN=
    )
)

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
:: just prompt to run an elevated shell


echo.
echo "%~n0: Starting setup-locker-stage0"
REM ## Start-Process -FilePath "c:\temp\locker-setup\setup-locker-stage0.cmd" -Verb runAs

if not defined BACKUPPLAN (
    :: IF CONDITION IS NORMAL (ie NO BACKUPPLAN DEFINED)
    setlocal
    echo "%~n0: Build Environment Condition = GOOD"
    %hstart% /runas /wait %LOCKERINSTALL%\build\setup-locker-stage0.cmd
    echo "%~n0 stage 0 status check: %errorlevel%"
    echo.

    echo.
    echo "%~n0: Starting setup-locker-stage1"
    REM ## Start-Process -FilePath "c:\temp\locker-setup\setup-locker-stage1.cmd" -Verb runAs
    %hstart% /runas /wait %LOCKERINSTALL%\build\setup-locker-stage1.cmd
    echo "%~n0 Stage 1 status check: %errorlevel%"
    echo.

    echo.
    echo "%~n0: Starting setup-locker-stage2"
    %hstart% /runas /wait "%LOCKERINSTALL%\build\setup-locker-stage2.cmd"
    echo "stage 2 status check: %errorlevel%"
    echo.
    endlocal
) else (
    :: IF CONDITION NOT NORMAL (i.e. BACKUPPLAN DEFINED)
    setlocal
    echo.
    echo "%~n0: Build Environment Condition = POOR"
    %hstart% /runas /wait %_tmp%\setup-locker-stage0.cmd
    echo "%~n0 stage 0 status check: %errorlevel%"
    echo.

    echo.
    echo "%~n0: Starting setup-locker-stage1"
    REM ## Start-Process -FilePath "c:\temp\locker-setup\setup-locker-stage1.cmd" -Verb runAs
    %hstart% /runas /wait %_tmp%\setup-locker-stage1.cmd
    echo "%~n0 Stage 1 status check: %errorlevel%"
    echo.

    echo.
    echo "today's advice:"
    curl https://api.github.com/zen & echo.
    echo.

    echo.
    echo "%~n0: Starting setup-locker-stage2"
    %hstart% /runas /wait "%LOCKERINSTALL%\build\setup-locker-stage2.cmd"
    echo "stage 2 status check: %errorlevel%"
    echo.

    echo.
    echo "today's advice:"
    curl https://api.github.com/zen & echo.
    echo.

    endlocal
)



REM ## %USERPROFILE%\Dropbox\locker-admin\tools\BootUpdCmd20.exe 

:: cleanup function
:: echo.
:: echo "enable UAC"
:: hstart.exe /delay=2 /runas /wait enable-UAC.cmd
:: hstart.exe /runas /wait restore-powershell.cmd

:: del /q %_tmp%\*.ps1
:: del /q %_tmp%\*.txt
:: del /q %_tmp%\*.exe
:: del /q %_tmp%\*.cmd
:: del /q %_tmp%\*.bat
:: del /q %_tmp%\*.zip
:: del /q %_tmp%\*.reg
:: rmdir /S /Q %_tmp%\_gpo
:: rmdir /S /Q %_tmp%\_updates
:: rmdir /S /Q %_tmp%\chocolatey

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
