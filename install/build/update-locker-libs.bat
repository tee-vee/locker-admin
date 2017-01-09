@echo off

REM UPDATE LOCKER-LIBS

setlocal enableDelayedExpansion

set URL=https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers/libs

curl %URL% >
for /F %%x in ('curl %URL% | jq ".[].url"') do (
	echo %%x
)