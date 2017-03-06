:: Derek Yuen <derekyuen@locision.com>
:: setup-locker-stage0.cmd
:: December 2016

@echo off

echo ====================================================
echo          Start Locker Build Process - STAGE 0
echo ====================================================
:: build.cmd debug -- build debug version.
title "LOCKER DEPLOYMENT - STAGE 0"

:: TODO - backup
:: TODO - systempropertiesprotection

:: setup work environment
echo.
echo "%~n0 setup work environment ..."
echo.
set bitsadmin=c:\windows\system32\bitsadmin.exe
set _tmp=C:\temp
set baseurl=http://lockerlife.hk/deploy

:: get environment variables
:: call me maybe?
if not defined _setenv (
    start "BitsAdmin Service Init" %bitsadmin% /reset
    %bitsadmin% /transfer "getenv" %baseurl%/setenv.cmd %_tmp%\setenv.cmd
    cd %_tmp% & call %_tmp%\setenv.cmd
    set _setenv=0
)

cd %_tmp%

:: just in case
start "BitsAdmin Service Init" %bitsadmin% /reset

:: --------------------------------------------------------------------------------------------
:: grab stuff
:: --------------------------------------------------------------------------------------------
:: %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 '%baseurl%' '%_tmp%';}"
:: %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 '%baseurl%' '%_tmp%';}"

%bitsadmin% /transfer "fix-powershell" %baseurl%/fix-powershell.cmd %_tmp%\fix-powershell.cmd
%bitsadmin% /transfer "fix-powershell" %baseurl%/restore-powershell.cmd %_tmp%\restore-powershell.cmd

timeout /t 10 /nobreak 

:: --------------------------------------------------------------------------------------------
:: Dropbox check
:: --------------------------------------------------------------------------------------------

tasklist /fi "IMAGENAME eq Dropbox.exe" | findstr /i Dropbox.exe 
if not errorlevel 0 (
    echo.
    echo "Dropbox not started?"
    echo "please check dropbox?"
    echo "then return here"
    pause
    echo.
) 


:: --------------------------------------------------------------------------------------------
:: Backup Plan
:: --------------------------------------------------------------------------------------------

if not exist "%LOCKERINSTALL%" (
    set BACKUPPLAN=YES
    if not exist "%LOCKERINSTALL%\_drivers" (
        echo.
        echo "%~n0 downloading updates"
        %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 '%baseurl%/_updates.tar.gz' '%_tmp%\_updates.tar.gz';}"
        %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 '%baseurl%/_drivers.zip' '%_tmp%\_drivers.zip';}"
        :: prep updates for stage2
        "c:\program files\7-Zip\7z.exe" e _drivers.zip -aoa -y
        "c:\program files\7-Zip\7z.exe" e _updates.tar.gz -aoa -y
        "c:\program files\7-Zip\7z.exe" e _updates.tar -aoa -y
    )

    echo.
    echo "%~n0 downloading security package"
    %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 '%baseurl%/production-gpo.zip' '%_tmp%\production-gpo.zip';}"

    echo.
    echo "%~n0 downloading dotNet 4.6.2 framework"
    :: check before downloading?
    :: (Get-ItemProperty -Path 'HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue).Version -like '4.5*'
    %REGEXE% query "HKEY_LOCAL_MACHINE\Software\Microsoft\Net Framework Setup\NDP\v4\Full" /v Version
    if Errorlevel 1 (
        :: get .net installer 
        echo.
        %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 '%baseurl%/_pkg/MicrosoftDotNETFramework462OfflineInstallerForWindows7SP1.exe' '%_tmp%\MicrosoftDotNETFramework462OfflineInstallerForWindows7SP1.exe';}"
    )

    echo.
    echo "%~n0 downloading msav"
    %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 '%baseurl%/_pkg/MicrosoftSecurityEssentialsInstallWindows7-32bit-EN.exe' '%_tmp%\MicrosoftSecurityEssentialsInstallWindows7-32bit-EN.exe';}"

    echo.
    echo "%~n0 downloading java"
    %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/_pkg/jre-8u111-windows-i586.exe' 'C:\temp\jre-8u111-windows-i586.exe';}"
    %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/_pkg/jre-install.properties' 'C:\temp\jre-install.properties';}"

    echo.
    echo "%~n0 downloading cleanup"
    %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/fix-powershell.cmd' 'C:\temp\fix-powershell.cmd';}"
    %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://lockerlife.hk/deploy/l2-teamviewer.reg' 'C:\temp\l2-teamviewer.reg';}"
    %bitsadmin% /transfer "Download TeamViewer Settings" %baseurl%/l2-teamviewer.reg %_tmp%\l2-teamviewer.reg

) else (
    :: no need to download anything; just use dropbox
    :: buy time ...
    set BACKUPPLAN=
    echo "%~n0 Locker Deployment Condition = GOOD"
    echo.
    echo "Preparing for next step ..."
    timeout /t 15 /nobreak
)

:: powershell -Command "& {Update-Help -Confirm}"
:: just in case
%bitsadmin% /reset
echo "%~n0 statuscheck: %errorlevel%"
echo.

:: echo "%~n0 creating kiosk user, hiding admin"
:: ---

:: start /min %ProgramData%\chocolatey\bin\RefreshEnv.cmd
:: echo "statuscheck: %errorlevel%"

cd c:\temp

echo.
echo.%time%
:: echo "%~n0 statuscheck: %errorlevel%"

echo.
echo.%time%
echo "%~n0 Fixing powershell runtime"
%hstart% /runas /wait "%USERPROFILE%\Dropbox\locker-admin\install\build\fix-powershell.cmd"

echo.%time%
echo %errorlevel%

echo.
echo ==============================================
echo "STAGE 0 COMPLETED"
echo ==============================================
echo.
echo.
echo CHECKLIST: 
echo.
echo "[] Router WIFI is disabled"
echo "[] Dropbox login using kiosk@lockerlife.hk" 
echo "[] Dropbox file sync is in progress" 
echo.
echo.
echo ==============================================
echo.
pause

echo.
:: echo "installing security policy and kiosk lockdown"
:: hstart.exe /runas /wait "move /Y production-gpo.zip C:\WINDOWS\SYSTEM32"

echo.
echo "%~n0 Preparing for stage2"
:: prep updates for stage2
"c:\program files\7-Zip\7z.exe" e _drivers.zip -aoa -y
"c:\program files\7-Zip\7z.exe" e _updates.tar.gz -aoa -y
"c:\program files\7-Zip\7z.exe" e _updates.tar -aoa -y

:: cleanup function
::cleanup
%hstart% /runas /wait restore-powershell.cmd
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

endlocal
popd
:END
@pause

