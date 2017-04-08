@ECHO OFF
SET SERVICE=data-collection
sc.exe query | findstr.exe /I %SERVICE%
IF %ERRORLEVEL% EQU 0 NET STOP %SERVICE% 
IF %ERRORLEVEL% EQU 1 NSSM.exe install data-collection "D:\java\jre\bin\java.exe"
NSSM.exe set data-collection DisplayName data-collection
NSSM.exe set data-collection Description LockerLife
NSSM.exe set data-collection Application "D:\java\jre\bin\java.exe"
NSSM.exe set data-collection AppParameters "-Dconfig=D:\locker-configuration.properties -jar D:\data-collection.jar"
NSSM.exe set data-collection AppDirectory "D:\java\jre\bin"
NSSM.exe set data-collection AppEnvironmentExtra "JAVA_HOME=D:\Java\jre"
NSSM.exe set data-collection Start SERVICE_DELAYED_AUTO_START
NSSM.exe set data-collection AppStdout "e:\logs\data-collection-service.log"
NSSM.exe set data-collection AppStderr e":\logs\data-collection-service.err"
NSSM.exe set data-collection AppRotateFiles 1
NSSM.exe set data-collection AppRotateOnline 0
NSSM.exe set data-collection AppRotateSeconds 86400
REM Replace stdout and stderr files
NSSM.exe set data-collection AppStdoutCreationDisposition 4
NSSM.exe set data-collection AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM can't stop data-collection properly
NSSM.exe set data-collection AppStopMethodSkip 0
REM Let's start data-collection. I assume a correct configuration is already in place
NET.EXE START | findstr.exe /I %SERVICE%
IF %ERRORLEVEL% EQU 1 NET START %SERVICE% 
