@echo off                           //Turn off screen text messages

Set "TvProcess=LockerLife_TV.exe"
Set "TvPath=E:\Project Mapping\LockerLifeBundle\LockerLife\Slider\bin\Debug"
set "currentTime=%Time: =0%"
set flag=false

if %currentTime% geq 00:00 if %currentTime% leq 00:30 set flag=true
if %currentTime% geq 08:00 if %currentTime% leq 08:30 set flag=true
if %currentTime% geq 16:00 if %currentTime% leq 16:30 set flag=true

REM if %flag%==true (
	REM taskkill /im "%TvProcess%" >nul 2>nul
	REM timeout /t 3 > nul
	REM start /d "%TvPath%" %TvProcess%
REM ) else (
	REM tasklist /NH /FI "imagename eq %TvProcess%" 2>nul |find /i "%TvProcess%" >nul
	REM if ERRORLEVEL 1 (
		start /d "%TvPath%" %TvProcess%
	REM )
REM )
