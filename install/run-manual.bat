@echo on
REM
REM  Gilbert Zhong, Francis Kwok, Derek Yuen

REM  locker-console startup

REM

REM  NOTES

REM    - ALL locker-console computer production stuff in D: drive

REM    - ALL production program have no version number

REM



set JAVA_EXEC=D:\JAVA\JRE\bin\JAVA.EXE

time /t

D:



REM  [1] START SCANNER

start /min %JAVA_EXEC% -Dconfig=C:\Users\AAICON\Dropbox\locker-admin\LOCKER\test-locker-hk02\config\status -jar scanner.jar

REM  [2] START KIOSKSERVER
cd kioskServer
start /min kioskServer.exe

REM  [3] START core.jar
cd ..
REM return to d: root
start /min %JAVA_EXEC% -Dconfig=C:\Users\AAICON\Dropbox\locker-admin\LOCKER\test-locker-hk02\config\status -verbose -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -jar core.jar

REM  [4] START DATA-COLLECTION-ALL
start /min %JAVA_EXEC% -Dconfig=C:\Users\AAICON\Dropbox\locker-admin\LOCKER\test-locker-hk02\config\status -verbose -jar data-collection.jar


REM 2016-11-25 dky - as requested by Francis
REM cd Locker-Console
REM start /min LockerLife.exe

rem taskkill /f /im LockerLife.exe

REM taskkill /f /im LockerLife_TV.exe

REM start /min startLockerLifeTV.bat

