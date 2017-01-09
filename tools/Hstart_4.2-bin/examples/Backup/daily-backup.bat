@echo off

set FileDate=%date:~10,4%_%date:~4,2%_%date:~7,2%
set BackupFile=E:\Backup\backup_%FileDate%.7z

del %BackupFile%
"C:\Program Files\7-Zip\7z.exe" a -t7z -mhe=on -mx=1 -pYourSuperPassword %BackupFile% -i@backup_include.txt -xr@backup_exclude.txt

rem Generate temporary script to upload %BackupFile%
echo option batch on > script.tmp
echo option confirm off >> script.tmp
echo open account@domain.com >> script.tmp
echo put %BackupFile% >> script.tmp
echo exit >> script.tmp

rem Execute script
"C:\Program Files\WinSCP\winscp.com" /script=script.tmp

rem Delete temporary script
del script.tmp
