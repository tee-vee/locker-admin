@echo off
REM 
REM Derek Yuen <derek.yuen@locision.com>
REM 2016-11-06
REM 
REM email-system-reboot.bat
REM
REM NOTE: debug -vvv -info 

rem set location=%1


mailsend1.19.exe -t locker-admin@lockerlife.hk -f locker-status@locision.com -name "locker-status" -rp pi-admin@locision.com -rt pi-admin@locision.com -ssl -port 465 -auth -smtp hwsmtp.exmail.qq.com -domain locision.com -sub "%COMPUTERNAME% system rebooted" -M "%COMPUTERNAME%-locker rebooted on %DATE% at %TIME%" -user pi-admin@locision.com -pass Locision1707 -q