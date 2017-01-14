@echo off


REM add recipient
xml ed -N xmlns:soap="http://www.w3.org/2003/05/soap-envelope" ^
 -N xmlns:act="http://www.axis.com/vapix/ws/action1" ^
 -u "/soap:Envelope/soap:Body/act:AddRecipientConfiguration/act:NewRecipientConfiguration/act:Name/text()" ^
 -v "locker-status" ^
 -u "/soap:Envelope/soap:Body/act:AddRecipientConfiguration/act:NewRecipientConfiguration/act:Parameters/act:Parameter[@Name='email_to']/@Value" ^
 -v "locker-admin@locision.com" template-recipient-email.xml > post-body

curl -k -vv -S -XPOST -H "Content-Type: application/soap+xml; action=http://www.axis.com/vapix/ws/action1/AddRecipientConfiguration" ^
 --digest --user "root:pass" --data "@post-body" --url "http://192.168.1.108/vapix/services"

xml ed -N xmlns:soap="http://www.w3.org/2003/05/soap-envelope" ^
 -N xmlns:act="http://www.axis.com/vapix/ws/action1" ^
 -u "/soap:Envelope/soap:Body/act:AddRecipientConfiguration/act:NewRecipientConfiguration/act:Name/text()" ^
 -v "locker-admin" ^
 -u "/soap:Envelope/soap:Body/act:AddRecipientConfiguration/act:NewRecipientConfiguration/act:Parameters/act:Parameter[@Name='email_to']/@Value" ^
 -v "locker-status@locision.com" template-recipient-email.xml > post-body

curl -k -vv -S -XPOST -H "Content-Type: application/soap+xml; action=http://www.axis.com/vapix/ws/action1/AddRecipientConfiguration" ^
 --digest --user "root:pass" --data "@post-body" --url "http://192.168.1.108/vapix/services"


REM create action rule
start /wait create-action-rule.bat ^
 "test-locker-hk01 camera live stream accessed" ^
 "test-locker-hk01 camera live stream accessed" ^
 "locker-status@locision.com" ^
 "live stream accessed" ^
 "tns1:VideoSource/tnsaxis:LiveStreamAccessed" ^
 "boolean(//SimpleItem[@Name=\"accessed\" and @Value=\"1\"])"

start /wait create-action-rule.bat ^
  "test-locker-hk01 camera system restarted" ^
  "test-locker-hk01 camera system restarted" ^
  "locker-status@locision.com" ^
  "system restarted" ^
  "tns1:Device/tnsaxis:Status/SystemReady" ^
  "boolean(//SimpleItem[@Name=\"ready\" and @Value=\"1\"])"

start /wait create-action-rule.bat ^
  "test-locker-hk01 camera1 disconnected" ^
  "test-locker-hk01 camera1 disconnected" ^
  "locker-status@locision.com" ^
  "camera1 disconnected" ^
  "tns1:VideoSource/tnsaxis:Connections" ^
  "boolean(//SimpleItem[@Name=\"connected\" and @Value=\"0\"]) and boolean(//SimpleItem[@Name=\"channel\" and @Value=\"1\"])"

start /wait create-action-rule.bat ^
  "test-locker-hk01 camera1 problem" ^
  "test-locker-hk01 camera1 problem" ^
  "locker-status@locision.com" ^
  "camera1 problem" ^
  "tns1:VideoSource/tnsaxis:Tampering" ^
  "boolean(//SimpleItem[@Name=\"channel\" and @Value=\"1\"])"
