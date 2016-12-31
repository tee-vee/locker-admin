echo
echo ==================================
echo
echo  PLEASE LOGIN TO DROPBOX
echo  Use username kiosk@lockerlife.hk
echo
echo ==================================
echo
pause

net stop teamviewer
net start teamviewer

:: restart dropbox

mklink %USERPROFILE%\AppData\Roaming\Microsoft\Windows\startm~1\Programs\startup\LockerLife_TV.exe D:\Locker-Slider\LockerLife_TV.exe
