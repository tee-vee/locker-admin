@ECHO OFF

call get-mac.bat
call get-boxes.bat
call get-address.bat
call get-nickname.bat

REM the locker-nickname.properties must be at first
REM the locker-status.properties must be at last
SET PART1=locker-nickname.properties
SET PART2=locker-boxes.properties
SET PART3=locker-certificateId.properties
SET PART4=locker-csNumber.properties
SET PART5=locker-description.properties
SET PART6=locker-address.properties
SET PART7=locker-mac.properties
SET PART8=locker-location.properties
SET PART9=locker-status.properties

cat %PART1% %PART2% %PART3% %PART4% %PART5% %PART6% %PART7% %PART8% %PART9%> locker.properties


del /f locker-mac.properties
del /f locker-nickname.properties
del /f locker-address.properties
del /f locker-boxes.properties
