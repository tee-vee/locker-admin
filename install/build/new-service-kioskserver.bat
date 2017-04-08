@ECHO OFF
SET SERVICE=kioskserver
sc.exe query | findstr.exe /I %SERVICE%
IF %ERRORLEVEL% EQU 0 NET STOP %SERVICE% 
IF %ERRORLEVEL% EQU 1 NSSM.EXE install %SERVICE% "D:\kioskserver\kioskserver.exe"
NSSM.EXE set kioskserver DisplayName kioskserver
NSSM.EXE set kioskserver Description LockerLife
NSSM.EXE set kioskserver Application "D:\kioskserver\kioskserver.exe"
REM NSSM.EXE set kioskserver AppParameters
NSSM.EXE set kioskserver AppDirectory "D:\kioskserver"
REM NSSM.EXE set kioskserver AppEnvironmentExtra
NSSM.EXE set kioskserver Start SERVICE_DELAYED_AUTO_START
NSSM.EXE set kioskserver AppStdout "E:\logs\kioskserver-service.log"
NSSM.EXE set kioskserver AppStderr "E:\logs\kioskserver-service.err"
NSSM.EXE set kioskserver AppRotateFiles 1
NSSM.EXE set kioskserver AppRotateOnline 0
NSSM.EXE set kioskserver AppRotateSeconds 86400
REM Replace stdout and stderr files
NSSM.EXE set kioskserver AppStdoutCreationDisposition 4
NSSM.EXE set kioskserver AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM.EXE can't stop kioskserver properly
NSSM.EXE set kioskserver AppStopMethodSkip 0
REM Let's start kioskserver. I assume a correct configuration is already in place
NET.EXE START | findstr.exe /I %SERVICE%
IF %ERRORLEVEL% EQU 1 NET START %SERVICE% 
