@echo off
title %~nx0
cls


set "outputFolder=C:\Temp"
if /i not exist "%outputFolder%" md "%outputFolder%"
>> "%outputFolder%\%~n0.log" 2>&1 (
call :START ) & endlocal & goto:eof


:START
echo %date% %time% - %~nx0 started
set RESTART=0
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" (
    if not defined PROCESSOR_ARCHITEW6432 (
        set BITNESS=x86
    ) else (
        set BITNESS=x64
    )
) else (
    set BITNESS=x64
)


:NETFX45
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319\SKUs\.NETFramework,Version=v4.5" 2>NUL
if %ERRORLEVEL% equ 0 (
    echo .NET Framework 4.5 is already installed
    goto WMF4
)
echo Installing .NET Framework 4.5
start /wait %~dp0dotnetfx45_full_x86_x64.exe /q /log %outputFolder%\netfx45.htm /norestart
if %ERRORLEVEL% equ 0 goto WMF4
if %ERRORLEVEL% equ 1641 goto WMF4
if %ERRORLEVEL% equ 3010 (
    goto WMF4
) else (
    echo There was an error [%ERRORLEVEL%] during the .NET Framework 4.5 installation
    echo Check the logs for more details
    echo Windows Management Framework 4.0 installation aborted!
    goto EXIT
)


:WMF4
reg query "HKLM\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine" /v PowerShellVersion 2>&1 | find "4.0" 2>&1>NUL
if %ERRORLEVEL% equ 0 (
    echo Windows Management Framework 4.0 is already installed
    goto EXIT
)

echo Installing Windows Management Framework 4.0 (%BITNESS%)
start /wait wusa.exe %~dp0Windows6.1-KB2819745-%BITNESS%-MultiPkg.msu /quiet /norestart
if %ERRORLEVEL% equ 0 (
    echo Windows Management Framework 4.0 installed successfully
    set RESTART=1
    goto EXIT
)
if %ERRORLEVEL% equ 3010 (
    echo Windows Management Framework 4.0 installed successfully - restart required
    set RESTART=1
    goto EXIT
)
if %ERRORLEVEL% equ 2359302 (
    echo Windows Management Framework 4.0 is already installed
) else (
    echo There was an error [%ERRORLEVEL%] during the Windows Management Framework 4.0 installation
    echo Check the logs for more details
)


:EXIT
echo. & echo %date% %time% - %~nx0 ended & echo.

if %RESTART% equ 1 shutdown.exe -r -f -t 0
