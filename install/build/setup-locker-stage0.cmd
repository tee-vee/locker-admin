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
set tmp=C:\temp
set baseurl=http://www.lockerlife.hk/deploy

:: get environment variables
%bitsadmin% /transfer "getenv" %baseurl%/setenv.cmd %tmp%\setenv.cmd
:: call me maybe?
call setenv.cmd

:: just in case
%bitsadmin% /reset
cd %tmp%

:: check for required exe or die

:: just in case
start "BitsAdmin Service Init" %bitsadmin% /reset
echo "bitsadmin completion status: %errorlevel%"

:: --------------------------------------------------------------------------------------------
:: grab stuff
:: --------------------------------------------------------------------------------------------
%bitsadmin% /transfer "fix-powershell" %baseurl%/fix-powershell.cmd %tmp%\fix-powershell.cmd
:: %bitsadmin% /transfer "tv-reg" %baseurl%/l2-teamviewer.reg %tmp%\l2-teamviewer.reg
:: %bitsadmin% /transfer "fix-powershell" %baseurl%/restore-powershell.cmd %tmp%\restore-powershell.cmd

:: %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 '%baseurl%' '%tmp%';}"
:: %ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 '%baseurl%' '%tmp%';}"

echo.
echo "%~n0 downloading updates"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 'http://www.lockerlife.hk/deploy/_updates.tar.gz' 'C:\temp\_updates.tar.gz';}"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 'http://www.lockerlife.hk/deploy/_drivers.zip' 'C:\temp\_drivers.zip';}"

echo.
echo "%~n0 downloading security package"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 'http://www.lockerlife.hk/deploy/production-gpo.zip' 'C:\temp\production-gpo.zip';}"

echo.
echo "%~n0 downloading dotNet 4.6.2 framework"
:: check before downloading?
:: (Get-ItemProperty -Path 'HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue).Version -like '4.5*'
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 'http://www.lockerlife.hk/deploy/_pkg/MicrosoftDotNETFramework462OfflineInstallerForWindows7SP1.exe' 'C:\temp\MicrosoftDotNETFramework462OfflineInstallerForWindows7SP1.exe';}"

echo.
echo "%~n0 downloading msav"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 'http://www.lockerlife.hk/deploy/_pkg/MicrosoftSecurityEssentialsInstallWindows7-32bit-EN.exe' 'C:\temp\MicrosoftSecurityEssentialsInstallWindows7-32bit-EN.exe';}"

echo.
echo "%~n0 downloading java"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 'http://www.lockerlife.hk/deploy/_pkg/jre-8u111-windows-i586.exe' 'C:\temp\jre-8u111-windows-i586.exe';}"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 'http://www.lockerlife.hk/deploy/_pkg/jre-install.properties' 'C:\temp\jre-install.properties';}"

echo.
echo "%~n0 downloading cleanup"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 'http://www.lockerlife.hk/deploy/fix-powershell.cmd' 'C:\temp\fix-powershell.cmd';}"
%ps% -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 30 'http://www.lockerlife.hk/deploy/l2-teamviewer.reg' 'C:\temp\l2-teamviewer.reg';}"

:: powershell -Command "& {Update-Help -Confirm}"
:: just in case
%bitsadmin% /reset
echo "%~n0 statuscheck: %errorlevel%"
echo.

:: just prompt to run an elevated shell
::   OLD-> Start-Process -FilePath "c:\temp\locker-setup\setup-locker-stage1.cmd" -Verb runAs
::   OLD-> Start-Process -FilePath "c:\temp\locker-setup\test2.cmd" -Verb runAs

:: echo "%~n0 creating kiosk user, hiding admin"
:: ---

:: start /min %ProgramData%\chocolatey\bin\RefreshEnv.cmd
:: echo "statuscheck: %errorlevel%"

cd c:\temp

echo.
echo.%time%
echo "LOCKERINSTALL is: %LOCKERINSTALL%"
echo "LOCKERADMIN is: %LOCKERADMIN%"

:: hstart.exe /runas /wait "%USERPROFILE%\Dropbox\locker-admin\install\build\setup-locker-stage1.cmd"
:: echo "%~n0 statuscheck: %errorlevel%"

echo.
echo.%time%
echo "%~n0 Fixing powershell runtime"
hstart.exe /runas /wait "%USERPROFILE%\Dropbox\locker-admin\install\build\fix-powershell.cmd"

echo.%time%
echo %errorlevel%

echo.
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
hstart.exe /runas /wait restore-powershell.cmd
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

endlocal
popd
:END
@pause

