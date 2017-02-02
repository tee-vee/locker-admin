Write-Host "Disabling Touch Screen"
devcon status "USB\VID_0EEF&PID_C000"
devcon disable "USB\VID_0EEF&PID_C000"
