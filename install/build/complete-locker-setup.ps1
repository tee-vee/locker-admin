:: Derek Yuen <derekyuen@locision.com>
:: complete-locker-setup.cmd
:: December 2016

@echo off

echo ====================================================================
echo          Start Locker Build Process - COMPLETE-LOCKER-SETUP 
echo ====================================================================
:: build.cmd debug -- build debug version.

echo.
echo.%time%
echo.

:: setup work environment
echo.
echo "%~n0 setup work environment ..."
echo.
set bitsadmin=c:\windows\system32\bitsadmin.exe
set tmp=C:\temp
set baseurl=http://www.lockerlife.hk/deploy

:: get environment variables
%bitsadmin% /transfer "getenv" %baseurl%/setenv.cmd %tmp%\setenv.cmd
:: call me maybe?
call setenv.cmd

:: envcheck
echo "LOCKERINSTALL is: %LOCKERINSTALL%"
echo "LOCKERADMIN is: %LOCKERADMIN%"

:: just in case
%bitsadmin% /reset
cd %tmp%

echo ====================================================================
echo
echo     PLEASE LOGIN TO DROPBOX
echo     Use username kiosk@lockerlife.hk
echo
echo ====================================================================
echo
pause

echo %time%
hstart /runas /wait "net stop teamviewer"
hstart /runas /wait "net start teamviewer"

:: restart dropbox

:: mklink %USERPROFILE%\AppData\Roaming\Microsoft\Windows\startm~1\Programs\startup\LockerLife_TV.exe D:\Locker-Slider\LockerLife_TV.exe
:: mklink lockerlife_tv.exe d:\Locker-Slider\LockerLife_TV.exe

echo %time%
hstart /runas /wait "%WINDIR%\System32\XCOPY.EXE /E /R /Y /H /F %USERPROFILE%\Dropbox\locker-admin\install\_gpo\export\production-gpo.zip %WINDIR%\System32"
hstart /runas /wait "move /Y %WINDIR%\System32\GroupPolicy %WINDIR%\System32\GroupPolicy-Backup"
hstart /runas /wait "move /Y %WINDIR%\System32\GroupPolicyUsers %WINDIR%\System32\GroupPolicyUsers-Backup"
cd %WINDIR%\System32
hstart /runas /wait "%PROGRAMFILES%\7-Zip\7z.exe" e -y -bt production-gpo.zip
gpupdate /force 

:: scrub "Recommended programs" options
REM ## HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\filetype\OpenWithList

echo %time%
REM [] DISABLE AERO
ECHO "DISABLE AERO"
hstart /runas "net stop uxsms"

echo %time%
REM [] CLASSIC THEME
ECHO "CLASSIC THEME"
%WINDIR%\System32\rundll32.exe %SystemRoot%\system32\shell32.dll,Control_RunDLL %SystemRoot%\system32\desk.cpl desk,@Themes /Action:OpenTheme /file:"%WINDIR%\Resources\Ease of Access Themes\classic.theme"

echo %time%
:: set background
echo "set background"
%TOOLS%\bginfo.exe %USERPROFILE%\Dropbox\install\build\kiosk-production-black.bgi /TIMER:0 /NOLICPROMPT
:: xcopy /Y "%WPKG%\custom\bg\bg.bmp" "C:\WINDOWS\web\wallpaper\bg.bmp"
:: REG ADD "HKCU\Control Panel\Desktop" /v Wallpaper /f /t REG_SZ /d "%WINDIR%\web\wallpaper\bg.bmp"
:: RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
 
echo %time%
echo "restarting - press any key to confirm or close window to stop shutdown"
pause
%TOOLS%\hstart.exe /runas "%WINDIR%\System32\shutdown.exe /c "complete-locker-setup production sealing" /f /r /t 3"

