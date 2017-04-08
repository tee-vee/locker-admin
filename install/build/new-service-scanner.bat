@ECHO OFF
SET SERVICE=scanner
sc.exe query | findstr.exe /I %SERVICE%
IF %ERRORLEVEL% EQU 0 NET STOP %SERVICE% 
IF %ERRORLEVEL% EQU 1 NSSM.EXE install %SERVICE% "D:\java\jre\bin\java.exe"
NSSM.EXE set scanner DisplayName scanner
NSSM.EXE set scanner Description LockerLife
NSSM.EXE set scanner Application "D:\java\jre\bin\java.exe"
NSSM.EXE set scanner AppParameters "-Dconfig=D:\locker-configuration.properties -jar D:\scanner.jar"
NSSM.EXE set scanner AppDirectory D:\java\jre\bin
NSSM.EXE set scanner AppEnvironmentExtra "JAVA_HOME=D:\JAVA\JRE"
NSSM.EXE set scanner Start SERVICE_AUTO_START
NSSM.EXE set scanner AppStdout E:\LOGS\scanner-service.log
NSSM.EXE set scanner AppStderr E:\LOGS\scanner-service.err
NSSM.EXE set scanner AppRotateFiles 1
NSSM.EXE set scanner AppRotateOnline 0
NSSM.EXE set scanner AppRotateSeconds 86400
REM Replace stdout and stderr files
NSSM.EXE set scanner AppStdoutCreationDisposition 4
NSSM.EXE set scanner AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM.EXE can't stop scanner properly
NSSM.EXE set scanner AppStopMethodSkip 0
REM Let's start scanner. I assume a correct configuration is already in place
NET.EXE START | findstr.exe /I %SERVICE%
IF %ERRORLEVEL% EQU 1 NET START %SERVICE% 
