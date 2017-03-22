@ECHO OFF
c:\local\bin\NSSM.exe install data-collection D:\java\jre\bin\java.exe
c:\local\bin\NSSM.exe set data-collection DisplayName data-collection
c:\local\bin\NSSM.exe set data-collection Description LockerLife
c:\local\bin\NSSM.exe set data-collection Application D:\java\jre\bin\java.exe
c:\local\bin\NSSM.exe set data-collection AppParameters -Dconfig=D:\locker-configuration.properties -jar D:\data-collection.jar
c:\local\bin\NSSM.exe set data-collection AppDirectory D:\java\jre\bin
c:\local\bin\NSSM.exe set data-collection AppEnvironmentExtra "JAVA_HOME=D:\Java\jre"
c:\local\bin\NSSM.exe set data-collection Start SERVICE_DELAYED_AUTO_START
c:\local\bin\NSSM.exe set data-collection AppStdout e:\logs\data-collection-service.log
c:\local\bin\NSSM.exe set data-collection AppStderr e:\logs\data-collection-service.err
c:\local\bin\NSSM.exe set data-collection AppRotateFiles 1
c:\local\bin\NSSM.exe set data-collection AppRotateOnline 0
c:\local\bin\NSSM.exe set data-collection AppRotateSeconds 86400
REM Replace stdout and stderr files
c:\local\bin\NSSM.exe set data-collection AppStdoutCreationDisposition 4
c:\local\bin\NSSM.exe set data-collection AppStderrCreationDisposition 4
REM Disable WM_CLOSE, WM_QUIT in the Shutdown options. Without it, NSSM can't stop data-collection properly
c:\local\bin\NSSM.exe set data-collection AppStopMethodSkip 0
REM Let's start data-collection. I assume a correct configuration is already in place
NET START data-collection
