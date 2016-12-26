@echo off                           //Turn off screen text messages


Set "ConsoleProcess=LockerLife.exe"
Set "ConsolePath=D:\Locker-Console"
Set "TvProcess=LockerLife_TV.exe"
Set "TvPath=D:\Locker-Slider"
set "currentTime=%Time: =0%"
set flag=false

tasklist /NH /FI "imagename eq %ConsoleProcess%" 2>nul |find /i "%ConsoleProcess%" >nul
if ERRORLEVEL 1 (
	start /d "%ConsolePath%" %ConsoleProcess%
)


if %currentTime% geq 00:00 if %currentTime% leq 00:05 set flag=true
if %currentTime% geq 04:00 if %currentTime% leq 04:05 set flag=true
if %currentTime% geq 08:00 if %currentTime% leq 08:05 set flag=true
if %currentTime% geq 12:00 if %currentTime% leq 12:05 set flag=true
if %currentTime% geq 16:00 if %currentTime% leq 16:05 set flag=true
if %currentTime% geq 20:00 if %currentTime% leq 20:05 set flag=true


if %flag%==true (
	taskkill /im "%TvProcess%" >nul 2>nul
	timeout /t 3 > nul
	start /d "%TvPath%" %TvProcess%
) else (
	tasklist /NH /FI "imagename eq %TvProcess%" 2>nul |find /i "%TvProcess%" >nul
	if ERRORLEVEL 1 (
		start /d "%TvPath%" %TvProcess%
	)
)