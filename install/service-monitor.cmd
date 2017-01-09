:: Derek Yuen <derekyuen@locision.com>
:: January 2016
:: based on ge-useast-prod00\ops\windows\2008R2\sbin\serivce-monitor.cmd

@ECHO OFF

:: Get Server name from command line. Be sure to specify it as \\servername
set server=%1

:: Set Variables for Services you can define any service you want here and as many as you want.
:: Just add or remove variables. Make sure the FOR %%A statements all have the same variables.
set s1=core
set s2=datacollection
set s3=kioskserver
set s4=scanner
REM ## set s5=iisadmin

::Setup the counter. I use 1 here because I like to start counting at 1, not 0. It's a kindergarten thing...
set /A count=1

:Service_Stop
::Stop All Services. If it is already stopped, move on.
ECHO.
ECHO. Stop Services
ECHO.

::Make sure the line below has the same variables defined in the beginning.
:: when there were 5 ... FOR %%A IN (%s1% %s2% %s3% %s4% %s5%) DO (
FOR %%A IN (%s1% %s2% %s3% %s4%) DO (
sc %server% query %%A
for /f "tokens=3" %%a in ('sc %server% query %%A^|find "STATE"') do (
if %%a EQU 4 ECHO. %%A SERVICE IS RUNNING
if %%a EQU 4 sc %server% stop %%A
if %%a EQU 4 ping -n 20 127.0.0.1 >nul
if %%a NEQ 4 ECHO. %%A SERVICE IS NOT RUNNING
)
)

:Service_Start
::Start All Services. If it is already running, move on.
ECHO.
ECHO. Start Services
ECHO.
ECHO. This is attempt number %count%
ECHO.

IF %count% EQU 4 GOTO REBOOT
::Make sure the line below has the same variables defined in the beginning.
FOR %%A IN (%s1% %s2% %s3% %s4% %s5%) DO (
for /f "tokens=3" %%a in ('sc %server% query "%%A"^|find "STATE"') do (
if %%a NEQ 4 sc %server% start %%A
if %%a NEQ 4 ECHO Attempting to start %%A on %server%
if %%a NEQ 4 ping -n 20 127.0.0.1 >nul
)
)

:Check_Status
::Check to see if all services are running, if not go back and try again. If so, finish up.
ECHO.
ECHO. Check Service Status
ECHO.

::Make sure the line below has the same variables defined in the beginning.
FOR %%A IN (%s1% %s2% %s3% %s4% %s5%) DO (
sc %server% query %%A
for /f "tokens=3" %%a in ('sc %server% query %%A^|find "STATE"') do (
if %%a EQU 4 ECHO. %%A SERVICE IS RUNNING
if %%a NEQ 4 ECHO. %%A SERVICE IS NOT RUNNING
if %%a NEQ 4 SET /A count=%count%+1
if %%a NEQ 4 ping -n 20 127.0.0.1 >nul
if %%a NEQ 4 GOTO Service_Start
)
)
:END
::Cleanup First. Make sure that you define the same variables as defined in the begining.
set server=
set s1=
set s2=
set s3=
set s4=
:: set s5=
set count=
:: Make sure we bypass the REBOOT Section - Whew! That was close!
GOTO:EOF

:REBOOT
:: Last ditch effort to get the services started.
ECHO.
ECHO. REBOOTING BECAUSE I CANNOT START ALL OF THE SERVICES
ECHO.
REM shutdown /r /m %server% /t 30 /d u:0:0 /c "Unable to start services from IIS Reset Script - FJM"
:: Call it a done deal, clean up, and let's get out of here!
GOTO END


