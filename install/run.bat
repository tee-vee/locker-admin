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

rem start /min java -jar scanner-all-1.0.jar
rem timeout 5 > NUL

REM  [2] START KIOSKSERVER
rem cd kioskServer
rem start /min kioskServer.exe
rem timeout 5 > NUL

REM  [3] START core.jar
rem cd ..
REM return to d: root
rem start /min java -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -jar core.jar
rem timeout 30 > NUL

REM  [4] START DATA-COLLECTION-ALL
rem start /min java -jar data-collection-all-1.0.jar
rem timeout 5 > NUL

REM 2016-11-25 dky - as requested by Francis
d:
cd d:\Locker-Console
start LockerLife.exe
timeout 1 > NUL
cd d:\locker-slider
start LockerLife_TV.exe

