cscript c:\Windows\system32\Printing_Admin_Scripts\en-US\prnport.vbs -a -r IP_192.168.36.28 -h 192.168.36.28 -o raw -n 9100
cscript c:\Windows\system32\Printing_Admin_Scripts\en-US\prnmngr.vbs -a -p "SHARP MX-M350N Manhattan" -r "IP_192.168.36.28" -m "SHARP MX-M350N"

cscript c:\Windows\system32\Printing_Admin_Scripts\en-US\prnport.vbs -a -r IP_192.168.36.43 -h 192.168.36.43 -o raw -n 9100
cscript c:\Windows\system32\Printing_Admin_Scripts\en-US\prnmngr.vbs -a -p "HP LJ3015 - Brooklyn" -r "IP_192.168.36.43" -m "HP LaserJet P3011/P3015 PCL6"

cscript c:\Windows\system32\Printing_Admin_Scripts\en-US\prnport.vbs -a -r IP_192.168.36.44 -h 192.168.36.44 -o raw -n 9100
cscript c:\Windows\system32\Printing_Admin_Scripts\en-US\prnmngr.vbs -a -p "HP LJ3015 - Queens" -r "IP_192.168.36.44" -m "HP LaserJet P3011/P3015 PCL6"

cscript c:\Windows\system32\Printing_Admin_Scripts\en-US\prnport.vbs -a -r IP_192.168.36.45 -h 192.168.36.45 -o raw -n 9100
cscript c:\Windows\system32\Printing_Admin_Scripts\en-US\prnmngr.vbs -a -p "HP LJ3015 - Jamaica" -r "IP_192.168.36.45" -m "HP LaserJet P3011/P3015 PCL6"

control printers
exit
