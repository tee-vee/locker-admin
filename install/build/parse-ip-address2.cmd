@ECHO OFF
 
FOR /f "tokens=3" %%I IN (
'netsh interface ip show address "Local Area Connection" ^| findstr "IP Address"'
) DO SET ipAddress=%%I
 
REM "Office 1"
IF NOT x%ipAddress:10.130=%==x%ipAddress% (
ECHO "Office 1" + %ipAddress%
ECHO "do_something_else" )
 
REM "Office 2"
IF NOT x%ipAddress:10.140=%==x%ipAddress% (
ECHO "Office 2" + %ipAddress%
ECHO "do_something_else" )