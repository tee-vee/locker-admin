@ECHO OFF
setlocal enabledelayedexpansion
SET /A errno=0

set "SIMICCID="
set SIMICCID=

REM if %1 is NUL then display error msg "need to run setup-locker.bat <SCAN SIM CARD BARCODE>" and exit 1

SET TMP="C:\TEMP" 
SET TMPSITENAME="C:\TEMP\sitename"
SET TMPFULLPATH="C:\TEMP\lockertmp"
SET LOCKERADMINPATH=%HOMEPATH%\Dropbox\locker-admin
SET LOCKERCONFIGS=%HOMEPATH%\Dropbox\locker-admin\LOCKER
SET LOCKERTOOLS=%HOMEPATH%\Dropbox\locker-admin\tools
SET LOCKERINSTALL=%HOMEPATH%\Dropbox\locker-admin\install
SET LOCKERBUILD=%LOCKERINSTALL%\build

IF EXIST %TMPSITENAME% del /f %TMPSITENAME%
IF EXIST %TMPFULLPATH% del /f %TMPFULLPATH%

IF [%1]==[] (
    ECHO --arg1 not provided
    ECHO setup-locker.bat REQUIRES 4G SIM CARD SCAN OF ICCID
    EXIT /B -1
) else (
    SET SIMICCID=%1
    echo -percent-one %1%
    echo -simiccid "%SIMICCID%"
    REM ## FIND SITENAME USING SIMICCID
    pushd %LOCKERCONFIGS%
    REM for /f "tokens=*" %%a in ('dir /b /s %SIMICCID%') do echo %%a > %TMPFILE%

    forfiles /p "%LOCKERCONFIGS%" /s /m %1 /c "cmd /c echo @relpath" > %TMPFULLPATH%
    cat %TMPFULLPATH%
    
    tr -d '\n' < %TMPFULLPATH%
    
    awk -F"\\" "{ print $2 }" %TMPFULLPATH% > %TMPSITENAME%
    cat %TMPSITENAME%

    )
    popd
)

del /f %TMPSITENAME%
del /f %TMPFULLPATH%
endlocal
