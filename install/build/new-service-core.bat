@ECHO OFF
NSSM.exe install core D:\java\jre\bin\java.exe
NSSM.exe set core DisplayName core
NSSM.exe set core Description LockerLife
NSSM.exe set core Application D:\java\jre\bin\java.exe
NSSM.exe set core AppParameters -Dconfig=D:\locker-configuration.properties -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -jar d:\core.jar
NSSM.exe set core AppDirectory D:\java\jre\bin
NSSM.exe set core AppEnvironmentExtra "JAVA_HOME=D:\java\jre"
NSSM.exe set core Start SERVICE_AUTO_START
NSSM.exe set core AppStdout e:\logs\core-service.log
NSSM.exe set core AppStderr e:\logs\core-service.err
NSSM.exe set core AppRotateFiles 1
NSSM.exe set core AppRotateOnline 0
NSSM.exe set core AppRotateSeconds 86400
REM Replace stdout and stderr files
NSSM.exe set core AppStdoutCreationDisposition 4
NSSM.exe set core AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM can't stop core properly
NSSM.exe set core AppStopMethodSkip 0
REM Let's start core. I assume a correct configuration is already in place
NET start core
