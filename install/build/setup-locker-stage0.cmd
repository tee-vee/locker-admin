@ECHO OFF

:: Derek Yuen <derekyuen@locision.com>
:: setup-locker-stage0.cmd
:: December 2016


echo ====================================================
echo          Start Locker Build Process - STAGE 0
echo ====================================================
:: build.cmd debug -- build debug version.

echo "stage0"
echo "stage0"
echo "stage0"
echo "stage0"
echo "stage0"

:: backup
:: systempropertiesprotection

:: setup work environment
echo.
echo "setup work environment ..."
setlocal
set bitsadmin=c:\windows\system32\bitsadmin.exe
set tmp=C:\temp
set baseurl=http://www.lockerlife.hk/deploy

c:
pushd \temp
cd c:\temp
if not exist "%tmp%\_gpo" mkdir %tmp%\_gpo
if not exist "%tmp%\_updates" mkdir %tmp%\_updates

echo "setup work environment ... done"


:: CALL :cleanup

:: check for required exe or die

:: just in case
start c:\windows\system32\bitsadmin.exe /reset
echo %errorlevel%

:: grab stuff
:: %bitsadmin% /rawreturn /transfer "get-hstart" %baseurl%/hstart.exe %tmp%\hstart.exe
:: %bitsadmin% /transfer "fix-powershell" %baseurl%/fix-powershell.cmd %tmp%\fix-powershell.cmd
:: %bitsadmin% /transfer "get-choco" %baseurl%/install-chocolatey.cmd %tmp%\install-chocolatey.cmd
:: %bitsadmin% /transfer "tv-reg" %baseurl%/l2-teamviewer.reg %tmp%\l2-teamviewer.reg
%bitsadmin% /transfer "locker-stage1" %baseurl%/setup-locker-stage1.cmd %tmp%\setup-locker-stage1.cmd
:: %bitsadmin% /transfer "fix-powershell" %baseurl%/restore-powershell.cmd %tmp%\restore-powershell.cmd

::powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 '%baseurl%' '%tmp%';}"
::powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 '%baseurl%' '%tmp%';}"

echo.
echo "downloading updates"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/_updates.tar.gz' 'C:\temp\_updates.tar.gz';}"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/_drivers.zip' 'C:\temp\_drivers.zip';}"

echo.
echo "downloading security package"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/production-gpo.zip' 'C:\temp\_gpo\production-gpo.zip';}"

echo "downloading dotNet 4.6.2 framework"
:: check before downloading?
:: (Get-ItemProperty -Path 'HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue).Version -like '4.5*'
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/_pkg/MicrosoftDotNETFramework462OfflineInstallerForWindows7SP1.exe' 'C:\temp\MicrosoftDotNETFramework462OfflineInstallerForWindows7SP1.exe';}"
echo "downloading msav"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/_pkg/MicrosoftSecurityEssentialsInstallWindows7-32bit-EN.exe' 'C:\temp\MicrosoftSecurityEssentialsInstallWindows7-32bit-EN.exe';}"
echo "downloading java"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/_pkg/jre-8u111-windows-i586.exe' 'C:\temp\jre-8u111-windows-i586.exe';}"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/_pkg/jre-install.properties' 'C:\temp\jre-install.properties';}"
echo "downloading cleanup"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/fix-powershell.cmd' 'C:\temp\fix-powershell.cmd';}"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/l2-teamviewer.reg' 'C:\temp\l2-teamviewer.reg';}"
echo "downloading locker stage setup"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/setup-locker-stage1.cmd' 'C:\temp\setup-locker-stage1.cmd';}"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/setup-locker-stage2.cmd' 'C:\temp\setup-locker-stage2.cmd';}"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/setup-windowsupdate.ps1' 'C:\temp\setup-windowsupdate.ps1';}"
powershell -Command "& {Import-Module BitsTransfer;Start-BitsTransfer -retryInterval 60 'http://www.lockerlife.hk/deploy/restore-powershell.cmd' 'C:\temp\restore-powershell.cmd';}"

:: powershell -Command "& {Update-Help -Confirm}"
:: just in case
%bitsadmin% /reset
echo %errorlevel%

:: just prompt to run an elevated shell
::   OLD-> Start-Process -FilePath "c:\temp\locker-setup\setup-locker-stage1.cmd" -Verb runAs
::   OLD-> Start-Process -FilePath "c:\temp\locker-setup\test2.cmd" -Verb runAs

:: stage1 (add kiosk user, setup kiosk user environment)
echo "creating kiosk user, hiding admin"
start /min %ProgramData%\chocolatey\bin\RefreshEnv.cmd
echo %errorlevel%

cd c:\temp

hstart.exe /runas /wait setup-locker-stage1.cmd
echo %errorlevel%

echo "Fixing powershell runtime"
hstart.exe /runas /wait fix-powershell.cmd

:: [] INSTALL PACKAGE MANAGEMENT
echo "installing base software"
hstart.exe /runas /wait install-chocolatey.cmd
echo %errorlevel%

echo
echo ==================================
echo
echo  PLEASE LOGIN TO DROPBOX
echo  Use username kiosk@lockerlife.hk
echo
echo ==================================
echo
pause


echo "installing security policy and kiosk lockdown"
hstart.exe /runas /wait move /Y _gpo/production-gpo.zip C:\WINDOWS\SYSTEM32

echo "preparing for stage2"
:: prep updates for stage2
"c:\program files\7-Zip\7z.exe" e _drivers.zip
"c:\program files\7-Zip\7z.exe" e _updates.tar.gz
"c:\program files\7-Zip\7z.exe" e _updates.tar

:: stage2 (full locker build)
echo "start stage2"
hstart.exe /runas /wait setup-locker-stage2.cmd

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
