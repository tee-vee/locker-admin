@echo off                           //Turn off screen text messages

Set "ConsoleProcess=LockerLife.exe"
Set "ConsolePath=E:\Project Mapping\LockerLifeBundle\LockerLife\LockerLife\bin\Debug"

REM tasklist /NH /FI "imagename eq %ConsoleProcess%" 2>nul |find /i "%ConsoleProcess%" >nul
REM if ERRORLEVEL 1 (
	start /d "%ConsolePath%" %ConsoleProcess%
REM )

