#requires -version 3.0
# Derek Yuen <derek.yuen@outlook.com>
# February 2017
#
# Create-LockerProperties.ps1
#

$LockerManagement = "./Locker Management 2 - 2017-02-22.csv"
$headers = "Item","lockerName","deploymentDate","buildingType","zh_HK.region","zh_HK.district","en.street","en.streetNumber"
$lockerName = "test-hk1"

$13box = "locker-711boxes.properties"
$18box = "locker-18boxes.properties"
$36box = "locker-36boxes.properties"
$54box = "locker-54boxes.properties"
$72box = "locker-72boxes.properties"
"locker-certificateId.properties"
"locker-csNumber.properties"
"locker-description.properties"
"locker-location.properties"

Get-Content $LockerManagement | ConvertFrom-Csv -Header $headers | Where-Object { $_.lockerName -eq "$lockerName" } | ConvertTo-Json

