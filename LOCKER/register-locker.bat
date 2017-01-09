@ECHO ON

REM windows curl supports "--crlf"
REM

REM SET DATAFILE="\@C:\USERS\AAICON\Dropbox\locker-admin\LOCKER\test-locker-hk02\config\locker.properties"
REM SET STATUSFILE="\@C:\USERS\AAICON\Dropbox\locker-admin\LOCKER\test-locker-hk02\config\status"

REM SET DATAFILE="@C:\USERS\AAICON\Dropbox\locker-admin\LOCKER\test-locker-hk03\config\locker.properties"
REM SET STATUSFILE="@C:\USERS\AAICON\Dropbox\locker-admin\LOCKER\test-locker-hk03\config\status"

SET url=https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers

REM "-S" or "--show-error" => "show error; add "-s" to show errors when they occur
rem SET OPTIONS="-vv -S -4 -m 30"

rem ECHO %OPTIONS%

curl -vv -S -XPOST -H "Accept: application/json" -H "Content-Type: application/json" -H "x-api-key: 123456789" -H "Cache-Control: no-cache" --user-agent  --data @data-compressed.json %url%

REM curl -vv -S -XPOST -H "Accept: application/json" -H "Content-Type: text/html" -H "x-api-key: 123456789" -H "Cache-Control: no-cache" --data @data-compressed.json %url%

REM curl -vv -4 -X POST -H "Accept: application/json" -H "Content-Type: text/html; charset=utf-8" -H "x-api-key: 123456789" -H "Cache-Control: no-cache" --data @document.json "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers"
