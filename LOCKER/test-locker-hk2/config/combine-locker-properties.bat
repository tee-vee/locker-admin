@ECHO OFF

call getmac-copy.bat

SET PART1=locker.properties.part1
SET PART2=locker.properties.part2


cat %PART1% %PART2% > locker.properties
 
