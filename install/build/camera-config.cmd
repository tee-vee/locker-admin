:: Derek Yuen <derekyuen@lockerlife.hk>
:: January 2017
:: -
:: camera-config.ps1 - call from stage2 of locker build

:: globals
set camera_user=root
set camera_pass=pass

:: Find camera
:: set curl=%LOCKERTOOLS%\curl.exe
:: set upnpscan=


:: capture upnpscan output; try all IP addresses
set camera_ip=192.168.1.145
set camera_url=http://%camera_ip%


:: Get server report
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/serverreport.cgi"


:: list all params in "Network" group
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=list&group=Network"

:: enable and configure https
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&HTTPS.AllowSSLV3=no"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&HTTPS.Ciphers=AES256-SHA:AES128-SHA:DES-CBC3-SHA"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&HTTPS.Enabled=yes"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&HTTPS.Port=443"

:: set image I/O text overlay
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Image.I0.Text.BGColor=black"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Image.I0.Text.ClockEnabled=yes"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Image.I0.Text.Color=white"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Image.I0.Text.DateEnabled=yes"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Image.I0.Text.Position=top"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Image.I0.Text.String=%HOSTNAME%"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Image.I0.Text.TextEnabled=yes"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Image.I0.Text.TextSize=small"


:: set network services
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&root.Network.FTP.Enabled=no"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&root.Network.SSH.Enabled=no"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&root.Network.IPv6.Enabled=yes"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&root.Properties.HTTPS.HTTPS=yes"


:: set time
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Time.ObtainFromDHCP=no"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Time.SyncSource=NTP"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Time.DST.Enabled=no"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Time.POSIXTimeZone=CST-8"
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Time.NTP.Server=hk.pool.ntp.org"


:: check number of configured inputs
::  example response:   Input.NbrOfInputs=N
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=list&group=Input.NbrOfInputs"


:: check number of configured outputs 
::  example response:   Output.NbrOfOutputs=N
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=list&group=Output.NbrOfOutputs"


:: retrieve information on I/O Port N
::  example response:
::                      root.IOPort.I0.Configurable=yes
::                      root.IOPort.I0.Direction=output
::                      root.IOPort.I0.Input.Name=Input 1
::                      root.IOPort.I0.Input.Trig=closed
::                      root.IOPort.I0.Output.Name=Output 1
::                      root.IOPort.I0.Output.Active=open
::                      root.IOPort.I0.Output.Button=actinact
::                      root.IOPort.I0.Output.PulseTime=0
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=list&group=IOPort.I0"


:: check port status of one or more ports
::  example response:   port1=0
::                      port2=0
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/io/port.cgi?check=1,2"

:: check if port N is active
::  example response:   port3=inactive
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/io/port.cgi?checkactive=3"

:: check if port 1 is configurable
:: returns IOPort.I1.Configurable=yes or no
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=list&group=IOPort.I1.Configurable"

:: enable overlay text
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/param.cgi?action=update&Image.I0.Text.TextEnabled=yes"


:: Restart 
curl -v -k --digest --user "%camera_user%:%camera_pass%" --url "%camera_url%/axis-cgi/restart.cgi"


