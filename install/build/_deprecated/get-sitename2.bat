set /p sernum= Scan the serial number barcode label:  
REM extract last 6 chars from serial number & prepend text
set sernum=new_text%sernum:~-6%

