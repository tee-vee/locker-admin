:loop

tasklist /nh /fi "imagename eq iexplore.exe" | find /i "iexplore.exe" >nul && (
	echo Internet Explorer is already running
	timeout 60
) || (
	echo Starting Internet Explorer kiosk mode...
	"C:\Program Files\Internet Explorer\iexplore.exe" -private "file:///C:/IE-Kiosk/KioskHome.html"
)

timeout 5
GOTO loop
