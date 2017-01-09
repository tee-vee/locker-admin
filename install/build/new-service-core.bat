@echo off
NSSM install core D:\java\jre\bin\java.exe
NSSM set core DisplayName core
NSSM set core Description LockerLife
NSSM set core Application D:\java\jre\bin\java.exe
NSSM set core AppParameters -Dconfig=D:\status -jar d:\core.jar
NSSM set core AppDirectory D:\java\jre\bin
NSSM set core AppEnvironmentExtra "JAVA_HOME=D:\java\jre"
NSSM set core Start SERVICE_AUTO_START
NSSM set core AppStdout e:\logs\core-service.log
NSSM set core AppStderr e:\logs\core-service.err
NSSM set core AppRotateFiles 1
NSSM set core AppRotateOnline 0
NSSM set core AppRotateSeconds 86400
REM Replace stdout and stderr files
NSSM set core AppStdoutCreationDisposition 4
NSSM set core AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM can't stop core properly
NSSM set core AppStopMethodSkip 0
REM Let's start core. I assume a correct configuration is already in place
NET start core
