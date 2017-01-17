:: Derek Yuen <derekyuen@lockerlife.hk>
:: January 2017
:: UPDATE LOCKER-LIBS

@echo off

REM ## setlocal enableDelayedExpansion
setlocal

set CURLOPTS=-RSs
set JQOPTS='.[].url'
set XARGSOPTS=-P %NUMBER_OF_PROCESSORS%

set LOCKERCLOUDHOST=770txnczi6.execute-api.ap-northeast-1.amazonaws.com
set LOCKERCLOUDLIBPATH=/dev/lockers/libs

set LOCKERLIBS=D:\locker-libs
set LIBLIST=locker-libs-list.txt
set LIBTIMESTAMP=locker-libs-timestamps.txt

:: locate locker-libs first
:: send output to locker-lib
curl -RSs --url https://%LOCKERCLOUDHOST%%LOCKERCLOUDLIBPATH% | jq '.[].url' > %LOCKERLIBS%\%LIBLIST%

:: create timestamps file
:: fetch Last-Modified header for specific file; only donwload if-modified
REM ## cat %LIBLIST% | xargs %XARGSOPTS% -n 1 curl -LR


:: download
REM ## (e.g. cat or type %LIBLIST% | xargs -n 1 curl -LO )
cat %LIBLIST% | xargs %XARGSOPTS% -n 1 curl -LO
