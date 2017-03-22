@echo off
c:\local\bin\NSSM.exe install core D:\java\jre\bin\java.exe
c:\local\bin\NSSM.exe set core DisplayName core
c:\local\bin\NSSM.exe set core Description LockerLife
c:\local\bin\NSSM.exe set core Application D:\java\jre\bin\java.exe
c:\local\bin\NSSM.exe set core AppParameters -Dconfig=D:\locker-configuration.properties -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -jar d:\core.jar
c:\local\bin\NSSM.exe set core AppDirectory D:\java\jre\bin
c:\local\bin\NSSM.exe set core AppEnvironmentExtra "JAVA_HOME=D:\java\jre"
c:\local\bin\NSSM.exe set core Start SERVICE_AUTO_START
c:\local\bin\NSSM.exe set core AppStdout e:\logs\core-service.log
c:\local\bin\NSSM.exe set core AppStderr e:\logs\core-service.err
c:\local\bin\NSSM.exe set core AppRotateFiles 1
c:\local\bin\NSSM.exe set core AppRotateOnline 0
c:\local\bin\NSSM.exe set core AppRotateSeconds 86400
REM Replace stdout and stderr files
c:\local\bin\NSSM.exe set core AppStdoutCreationDisposition 4
c:\local\bin\NSSM.exe set core AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM can't stop core properly
c:\local\bin\NSSM.exe set core AppStopMethodSkip 0
REM Let's start core. I assume a correct configuration is already in place
NET start core
