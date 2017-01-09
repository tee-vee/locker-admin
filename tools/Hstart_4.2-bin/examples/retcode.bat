@echo off

set SecLast=%time:~7,1%

IF %SecLast% GTR 5 GOTO :Error

:Success
echo This batch file will return the SUCCESS CODE (0) when you close Notepad.
echo.
echo Run it a few times from now until you get the ERROR CODE (Hstart test).
exit /B 0

:Error
echo This batch file will return the ERROR CODE (-15) when you close Notepad.
echo.
echo Run it a few times from now until you get the SUCCESS CODE (Hstart test).
exit /B -15
