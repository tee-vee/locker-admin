:: test script
@echo off
set input=%~1
for /f %%i in ('forfiles /P %USERPROFILE%\Dropbox\locker-admin\LOCKER /M %input% /S /c "cmd /c echo @relpath"') do set rawpath=%%i
CALL :dequote rawpath
echo %rawpath%

for /f "tokens=2 delims=\" %%A in ("%rawpath%") do (
    set name=%%~nxA
)
echo sitename: %name%


:dequote
for /f "delims=" %%A in ('echo %%%1%%') do set %1=%%~A
GOTO :eof