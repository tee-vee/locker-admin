:: Derek Yuen <derekyuen@locision.com>
:: setenv.cmd -- call me maybe?
:: January 2017

@echo off

:: setup work environment
echo.
echo "%~n0 setup work environment ..."
set bitsadmin=%WINDIR%\system32\bitsadmin.exe
set hstart=%WINDIR%\system32\hstart.exe
set tmp=C:\temp
set ps=%WINDIR%\System32\WindowsPowerShell\v1.0\powershell.exe
SET HOME=%USERPROFILE%
SET TOOLS=%USERPROFILE%\Dropbox\locker-admin\tools
SET LOCKERINSTALL=%USERPROFILE%\Dropbox\locker-admin\install
SET LOCKERADMIN=%USERPROFILE%\Dropbox\locker-admin\LOCKER\%SITENAME%
SET LOCKERCFG=locker.properties
SET LOG=E:\LOGS
SET LOGS=E:\LOGS
SET SETUPLOGS=%LOGS%\locker-setup

c:
mkdir %tmp%
mkdir c:\temp
cd %tmp%

echo.
echo "%~n0: Setup work environment ... done"
echo.

