@echo off

echo.
echo "Disable Admin User"
wmic useraccount where name='administrator' set disabled=true
net user administrator /active:no

echo "Results:"
net user administrator
timeout /t 10 /nobreak
