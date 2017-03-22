@ECHO OFF

(echo "mac":[ && getmac /nh /fo csv | gawk -F, "{ print $1\",\" }" && echo ],}) > locker.properties.part2

