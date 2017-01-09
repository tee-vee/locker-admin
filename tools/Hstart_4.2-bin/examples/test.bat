@echo off

set TestFile=%TEMP%\hstart_test.txt

echo Simple Batch File (Hstart Test) > %TestFile%
echo. >> %TestFile%
echo The current date is: %DATE% >> %TestFile%
echo The current time is: %TIME% >> %TestFile%

notepad.exe %TestFile%

del %TestFile%
