dir /b | findstr /r "^[0-9]*$" > temp.txt

set /p boxes=<temp.txt

del /f temp.txt

for /f %%i in ('type %boxes%') do set boxes=%%i

set boxes=..\..\locker-%boxes%.properties

copy /y %boxes% locker-boxes.properties

echo %boxes%
