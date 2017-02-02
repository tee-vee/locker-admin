@ECHO OFF

(echo "mac":[ && getmac /nh /fo csv | findstr /v "Hardware" | gawk -F, "{ print $1\",\" }" && echo ],) > locker-mac.properties
