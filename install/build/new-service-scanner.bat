@ECHO OFF
NSSM install scanner D:\java\jre\bin\java.exe 
NSSM set scanner DisplayName scanner
NSSM set scanner Description LockerLife
NSSM set scanner Application D:\java\jre\bin\java.exe
NSSM set scanner AppParameters -Dconfig=D:\status -jar D:\scanner.jar
NSSM set scanner AppDirectory D:\java\jre\bin
NSSM set scanner AppEnvironmentExtra "JAVA_HOME=D:\JAVA\JRE"
NSSM set scanner Start SERVICE_AUTO_START
NSSM set scanner AppStdout E:\LOGS\scanner-service.log
NSSM set scanner AppStderr E:\LOGS\scanner-service.err
NSSM set scanner AppRotateFiles 1
NSSM set scanner AppRotateOnline 0
NSSM set scanner AppRotateSeconds 86400
REM Replace stdout and stderr files
NSSM set scanner AppStdoutCreationDisposition 4
NSSM set scanner AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM can't stop scanner properly
NSSM set scanner AppStopMethodSkip 0
REM Let's start scanner. I assume a correct configuration is already in place
NET START scanner
