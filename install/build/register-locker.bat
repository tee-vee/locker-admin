@ECHO ON
REM 
REM

SET SITENAME=test-locker-hk03
SET LOCKERADMIN=%SYSTEMDRIVE%%HOMEPATH%\Dropbox\locker-admin\LOCKER\%SITENAME%
SET LOCKERCFG=locker.properties

SET APIKEY=123456789

SET DATAFILE=%LOCKERADMIN%\config\%LOCKERCFG%
SET STATUSFILE=%LOCKERADMIN%\config\status

SET url=
REM SET url=http://requestb.in/pwsa6kpw
SET url=https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers

REM curl -XPOST -H "Accept: application/json" -H "Content-Type: application/json; charset=utf-8" -H "x-api-key: 123456789" -H "Cache-Control: no-cache" --data @data.json %url%

curl --dns-servers 8.8.8.8 -k -vv -S -XPOST -H "Accept: application/json" -H "Content-Type: application/json" -H "x-api-key: %APIKEY%" -H "Cache-Control: no-cache" --data @%DATAFILE% --url %url%
