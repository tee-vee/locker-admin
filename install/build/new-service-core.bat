@ECHO OFF
SET SERVICE=core
sc.exe query | findstr.exe /I %SERVICE%
IF %ERRORLEVEL% EQU 0 NET STOP %SERVICE% 
IF %ERRORLEVEL% EQU 1 NSSM.exe install %SERVICE% "D:\java\jre\bin\java.exe"
NSSM.exe set %SERVICE% DisplayName %SERVICE%
NSSM.exe set %SERVICE% Description LockerLife
NSSM.exe set %SERVICE% Application "D:\java\jre\bin\java.exe"
NSSM.exe set %SERVICE% AppParameters "-Dconfig=D:\locker-configuration.properties -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -jar d:\core.jar"
NSSM.exe set %SERVICE% AppDirectory "D:\java\jre\bin"
NSSM.exe set %SERVICE% AppEnvironmentExtra "JAVA_HOME=D:\java\jre"
NSSM.exe set %SERVICE% Start SERVICE_AUTO_START
NSSM.exe set %SERVICE% AppStdout "e:\logs\core-service.log"
NSSM.exe set %SERVICE% AppStderr "e:\logs\core-service.err"
NSSM.exe set %SERVICE% AppRotateFiles 1
NSSM.exe set %SERVICE% AppRotateOnline 0
NSSM.exe set %SERVICE% AppRotateSeconds 86400
REM Replace stdout and stderr files
NSSM.exe set %SERVICE% AppStdoutCreationDisposition 4
NSSM.exe set %SERVICE% AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM can't stop core properly
NSSM.exe set %SERVICE% AppStopMethodSkip 0
REM Let's start core. I assume a correct configuration is already in place
NET.EXE START | findstr.exe /I %SERVICE%
IF %ERRORLEVEL% EQU 1 NET START %SERVICE% 
