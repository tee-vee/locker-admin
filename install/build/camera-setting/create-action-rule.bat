@echo off

REM argument 1 email message content
REM argument 2 email subject
REM argument 3 to email address
REM argument 4 rule name
REM argument 5 topic expression
REM argument 6 rule trigger value

xml ed -N xmlns:soap="http://www.w3.org/2003/05/soap-envelope" ^
 -N xmlns:act="http://www.axis.com/vapix/ws/action1" ^
 -u "/soap:Envelope/soap:Body/act:AddActionConfiguration/act:NewActionConfiguration/act:Parameters/act:Parameter[@Name='message']/@Value" ^
 -v "%~1" ^
 -u "/soap:Envelope/soap:Body/act:AddActionConfiguration/act:NewActionConfiguration/act:Parameters/act:Parameter[@Name='subject']/@Value" ^
 -v "%~2" ^
 -u "/soap:Envelope/soap:Body/act:AddActionConfiguration/act:NewActionConfiguration/act:Parameters/act:Parameter[@Name='email_to']/@Value" ^
 -v "%~3" template-notification-email.xml > post-body

curl -k -vv -S -XPOST -H "Content-Type: application/soap+xml; action=http://www.axis.com/vapix/ws/action1/AddActionConfiguration" ^
 --digest --user "root:pass" --data "@post-body" --url "http://192.168.1.108/vapix/services" -o response.xml

xml sel -N xmlns:SOAP-ENV="http://www.w3.org/2003/05/soap-envelope" ^
 -N xmlns:aa="http://www.axis.com/vapix/ws/action1" ^
 -t -v "/SOAP-ENV:Envelope/SOAP-ENV:Body/aa:AddActionConfigurationResponse/aa:ConfigurationID/text()" response.xml > tmp

set /p conf_id=<tmp
xml ed -N xmlns:soap="http://www.w3.org/2003/05/soap-envelope" ^
 -N xmlns:act="http://www.axis.com/vapix/ws/action1" ^
 -N xmlns:wsnt="http://docs.oasis-open.org/wsn/b-2" ^
 -N xmlns:tns1="http://www.onvif.org/ver10/topics" ^
 -N xmlns:tnsaxis="http://www.axis.com/2009/event/topics" ^
 -s "/soap:Envelope/soap:Body/act:AddActionRule/act:NewActionRule" -t "elem" -n "act:PrimaryAction" -v "%conf_id%" ^
 -u "/soap:Envelope/soap:Body/act:AddActionRule/act:NewActionRule/act:Name" ^
 -v "%~4" ^
 -u "/soap:Envelope/soap:Body/act:AddActionRule/act:NewActionRule/act:StartEvent/wsnt:TopicExpression" ^
 -v "%~5" ^
 -u "/soap:Envelope/soap:Body/act:AddActionRule/act:NewActionRule/act:StartEvent/wsnt:MessageContent" ^
 -v "%~6" template-rule.xml > post-body

 curl -k -vv -S -XPOST -H "Content-Type: application/soap+xml; action=http://www.axis.com/vapix/ws/action1/AddActionRule" ^
  --digest --user "root:pass" --data "@post-body" --url "http://192.168.1.108/vapix/services" -o response.xml

exit;
