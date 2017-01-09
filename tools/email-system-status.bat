@echo off
REM 
REM Derek Yuen <derek.yuen@locision.com>
REM 2016-11-06
REM 
REM email-system-status.bat
REM
REM NOTE: debug -vvv -info 

d:\bin\mailsend1.19.exe -t pi-admin@locision.com -f locker-status@locision.com -name "locker-status" -rp pi-admin@locision.com -rt pi-admin@locision.com -ssl -port 465 -auth -smtp hwsmtp.exmail.qq.com -domain locision.com -sub "test-locker STATUS: OK" -M "test-locker OS STATUS: OK" -user pi-admin@locision.com -pass Locision1707 -q