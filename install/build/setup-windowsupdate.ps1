$WUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings
$WUSettings
$WUSettings = (New-Object -com "Microsoft.Update.AutoUpdate").Settings

REM
REM NotificationLevel  :
REM     0 = Not configured;
REM     1 = Disabled;
REM     2 = Notify before download;
REM     3 = Notify before installation;
REM     4 = Scheduled installation;
REM

$WUSettings.NotificationLevel=1
$WUSettings.save()

REM [] DISABLE BINGSEARCH
Disable-BingSearch
Disable-GameBarTips
Update-Help

Set-TaskBarOptions -Lock -Size small -Verbose
