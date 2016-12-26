@ECHO OFF
NSSM install kioskserver D:\kioskserver\kioskserver.exe
NSSM set kioskserver DisplayName kioskserver
NSSM set kioskserver Description LockerLife
NSSM set kioskserver Application D:\kioskserver\kioskserver.exe
REM NSSM set kioskserver AppParameters
NSSM set kioskserver AppDirectory D:\kioskserver
REM NSSM set kioskserver AppEnvironmentExtra
NSSM set kioskserver Start SERVICE_DELAYED_AUTO_START
NSSM set kioskserver AppStdout E:\logs\kioskserver-service.log
NSSM set kioskserver AppStderr E:\logs\kioskserver-service.err
NSSM set kioskserver AppRotateFiles 1
NSSM set kioskserver AppRotateOnline 0
NSSM set kioskserver AppRotateSeconds 86400
REM Replace stdout and stderr files
NSSM set kioskserver AppStdoutCreationDisposition 4
NSSM set kioskserver AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM can't stop kioskserver properly
NSSM set kioskserver AppStopMethodSkip 0
REM Let's start kioskserver. I assume a correct configuration is already in place
NET start kioskserver
