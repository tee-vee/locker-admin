:: Derek Yuen <derekyuen@locision.com>
:: January 2017

:: set curl=%LOCKERTOOLS%\curl.exe
set camera_ip=192.168.1.145
set camera_url=http://%camera_ip%
set camera_user=root
set camera_pass=pass


curl -v -k --digest --user "%camera_user%:%camera_pass%" %camera_url%/axis-cgi/admin/restart.cgi 
