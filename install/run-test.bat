@echo off
REM
REM  Gilbert Zhong, Francis Kwok, Derek Yuen

REM  locker-console startup

REM

REM  NOTES

REM    - ALL locker-console computer production stuff in D: drive

REM    - ALL production program have no version number

REM




REM  [1] START SCANNER

REM start /min java -jar scanner-all-1.0.jar
REM timeout 5 > NUL


REM  [2] START KIOSKSERVER
REM cd kioskServer
REM start /min kioskServer.exe
REM timeout 5 > NUL


REM  [3] START core.jar
REM cd ..
REM return to d: root
REM start /min java -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -jar core.jar
REM timeout 30 > NUL


REM  [4] START DATA-COLLECTION-ALL
REM start /min java -jar data-collection-all-1.0.jar
REM timeout 5 > NUL

REM 2016-11-25 dky - as requested by Francis
REM cd Locker-Console
REM start /min LockerLife.exe
taskkill /f /im LockerLife.exe

REM taskkill /f /im LockerLife_TV.exe

REM start /min startLockerLifeTV.bat

