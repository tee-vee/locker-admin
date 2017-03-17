#Requires -Version 3.0

# Derek Yuen <derekyuen@lockerlife.hk>
# March 2017

# reg-test.ps1 -- base tester script for locker-registration

$basename = "register-locker"
$ErrorActionPreference = "Continue"

Write-Host "Set Encoding"
& "$env:windir\system32\chcp" 65001

$OutputEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

if (!($env:sitename)) {
    $env:sitename = $env:computername
}

# locker-cloud api-key
$lockerCloudApiKey = @{ "X-API-KEY" = "123456789" } 

# TeamViewer Check
Write-Host "Teamviewer Setup"
$TVtoken = "Bearer","2034214-P3aa9qGG323SKWVqqKBV"

$TVheader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$TVheader.Add("authorization", $TVtoken)
$TVcontentType = 'application/json; charset=utf-8'

Write-Host "test connectivity to teamviewer api"
$ping = Invoke-RestMethod -Uri "https://webapi.teamviewer.com/api/v1/ping" -ContentType $TVcontentType -Method Get -Headers $TVheader

# get current computer TeamViewer ClientID
$TVclientId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\TeamViewer" -Name ClientID).ClientID

# Note: TeamViewer API calls this "remotecontrol_id"
# changes to device profile require "device_id"
# Need to convert "remotecontrol_id" to "device_id"
# testing -- $TVclientId = "629313250"
Write-Host "Get TeamViewer Profile"
$TVremoteControlId = "r" + $TVclientId
$TVprofileUri = "https://webapi.teamviewer.com/api/v1/devices/?remotecontrol_id=" + $TVremoteControlId
$TVdeviceProfile = Invoke-RestMethod -Method Get -Uri $TVprofileUri -Headers $TVheader

Write-Host "Get LockerManagement Data"
$lockerManagement = "LockerManagement.csv"
if (Test-Path -Path "C:\temp\$lockerManagement") {
    Remove-Item "C:\temp\$lockerManagement" -Force -ErrorAction SilentlyContinue
}
$request = Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/$lockerManagement" -OutFile C:\temp\$lockerManagement

Write-Host "Consume LockerManagement Data"
$lmdata = Get-Content "c:\temp\$lockerManagement" -Encoding UTF8 | Select-Object | ConvertFrom-Csv

#$FdataCheck1 = $lmdata | where { $_.LockerName -eq $env:sitename }
#$FdataCheck2 = $lmdata | where { $_.SIMCardNumber -eq $env:iccid }

# Testing
#$Fdata = $lmdata | where { $_.LockerName -eq "test-hk3" }

# PRODUCTION
$Fdata = $lmdata | where { $_.LockerName -eq $env:computername }
$address = $Fdata.StreetNo + " " + $Fdata.StreetName
$address


# use Google Maps Geocoding API
# Key -> Derek Y Developer Account
# https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=AIzaSyClvw0s2I9miLfAniQ97wb6QkxFlGalho4
#address=$convertedAddress,

Write-Host "Get GPS Coordinates"
[string]$RegionBias = "hk"
[switch]$Sensor = $false
$protocol = "https"
$RawDataFormat = "JSON"

$googleGeocodeApiKey = "AIzaSyClvw0s2I9miLfAniQ97wb6QkxFlGalho4"
$convertedAddress = $Address.Replace(" ","+")
#$url = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&key=$($googleGeocodeApiKey)"
#$url = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&sensor=$($Sensor.ToString().ToLower())&region=$($RegionBias)&key=$($googleGeocodeApiKey)"

# Testing Google Maps GeoCode API
#$geo = Invoke-RestMethod "https://maps.googleapis.com/maps/api/geocode/json?address=2+King+San+Path,+New+Territories,+Hong+Kong&key=$googleGeocodeApiKey"
$geourl = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&key=$($googleGeocodeApiKey)"
$georesponse = Invoke-RestMethod -Uri $geourl -UseBasicParsing
#$geo.results.geometry.location

# because google geocode-api uses lat/lng 
# and we use lat/lon
$location = $georesponse.results.geometry.location | Select-Object @{N='lat'; E={$georesponse.results.geometry.location.lat}}, @{N='lon'; E={$georesponse.results.geometry.location.lng}}


# Testing Google Maps Places API
$googlePlaceApiKey = "AIzaSyBt6QTvw5JEPujtT36s4CE1SV-C3-BhpgM"
$place = Invoke-RestMethod "https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJP4Go7FQHBDQR1CUFeViLOzM&key=$googlePlaceApiKey"


# Import BitsTransfer ...
if (!(Get-Module BitsTransfer)) {
    Import-Module BitsTransfer
} else {
    # BitsTransfer module already loaded ... clear queue
    Get-BitsTransfer | Complete-BitsTransfer
}

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp
#(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
#. C:\99-DeploymentConfig.ps1
#$basename = "00-init"

Write-Host "Create lp object"
$lp = New-Object PSObject 
#$lp = [PSCustomObject]

# $location = @"
# {
#     "lat": 22.3964,
#     "lon": 114.1095
# }
# "@ | ConvertFrom-Json

$description = @"
{
  "en": "null"
}
"@ | ConvertFrom-Json

if ($Fdata.Description) {
    $description | Add-Member -Name "en" -Value $Fdata.Description -MemberType NoteProperty -Force -Verbose 
}
if ($Fdata.DescriptionC) {
    $description | Add-Member -Name "zh_HK" -Value $Fdata.DescriptionC -MemberType NoteProperty -Force -Verbose
    $description | Add-Member -Name "zh_CN" -Value $Fdata.DescriptionC -MemberType NoteProperty -Force -Verbose
}

$lockerProfile = @"
{
    "cameraHost": "192.168.1.108",
    "cameraPassword": "pass",
    "cameras": [
      "1",
      "2"
    ],
    "cameraUsername": "Locision",
    "lockerBoard": 2,
    "lockerHost": "127.0.0.1",
    "lockerPort": 9012,
    "lockerStructure": "001",
    "scannerHost": "127.0.0.1",
    "scannerPort": 23
}
"@ | ConvertFrom-Json

$address = [pscustomobject]@{
    en = [pscustomobject]@{
        building = $Fdata.Building
        city = "Hong Kong"
        country = "CHINA"
        district = $Fdata.District
        room = $Fdata.Room
        street = $Fdata.StreetNo + " " + $Fdata.StreetName
        town = $Fdata.Town
    }
    zh_CN = [pscustomobject]@{
        building = $Fdata.BuildingC
        city = "香港"
        country = "中国"
        district = $Fdata.DistrictC
        room = $Fdata.Room
        street = $Fdata.StreetNoC + " " + $Fdata.StreetNameC
        town = $Fdata.TownC
    }
    zh_HK = [pscustomobject]@{
        building = $Fdata.BuildingC
        city = "香港"
        country = "中國"
        district = $Fdata.DistrictC
        room = $Fdata.Room
        street = $Fdata.StreetNoC + " " + $Fdata.StreetNameC
        town = $Fdata.TownC
    }
} # $address


# boxes
# $boxes = [pscustomobject]@{
#     "boxes" = @( [PScustomObject] @{"bayNum"=1; "boxNum"=1; "owner"="LIKONS"; "size"=0})
#     "boxes" += @([PSCustomObject]@{"bayNum"=1; "boxNum"=2; "owner"="LIKONS"; "size"=0})
# }
# @{bayNum=1; boxNum=2; owner="LIKONS"; size=0}, @{bayNum=1; boxNum=3; owner="LIKONS"; size=0}, @{bayNum=1; boxNum=4; owner="LIKONS"; size=0})
# }      

$boxes = @()
$type = $Fdata.Boxes

if ($type -eq 72) {
    $typeDescription = "Standard Locker, 72 Boxes"
    $col = 8
    $row = 9
} elseif ($type -eq 54) {
    $typeDescription = "Standard Locker, 54 Boxes"
    $col = 6
    $row = 9
} elseif ($type -eq 36) {
    $typeDescription = "Standard Locker, 36 Boxes"
    $col = 4
    $row = 9
} elseif ($type -eq 18) {
    $typeDescription = "Standard Locker, 18 Boxes"
    $col = 2
    $row = 9
} else {
    # $type probably == 13
    # Locker Type == 7-11
    $typeDescription = "Mini Locker, 13 Boxes"
    $col = 2
    # set $row within foreach
}

#$TestAddMember = {

ForEach ($i in (1..$col)) {
    # 7-11 exception (column 1 has only 4 rows; column 2 has 9)
    if ($type -eq 7 -Or $type -eq 13) {
        if ($i -eq 1) {
            $row = 4
        } else {
            $row = 9
        }
    }
    ForEach ($j in (1..$row)) {
        if ($type -eq 7 -Or $type -eq 13) {
            $size = 0
        } else {
            if ($j -eq 1) {
                $size = 3
            } elseif ($j -le 3) {
                $size = 2
            } elseif ($j -le 7) {
                $size = 1
            } elseif ($j -le 9) {
                $size = 2
            }
        }
        $boxes += [pscustomobject]@{
            bayNum = $i
            boxNum = $j
            owner = "LIKONS"
            size = $size
        }
    }
}
#}

$boxes | ConvertTo-Json | Set-Content -Path boxes.json -Force

$xboxes = Get-Content -Path boxes.json -Raw
$xxboxes = [scriptblock]::Create(($xboxes| ConvertFrom-Json))
#Measure-Command $TestAddMember | Format-Table TotalSeconds -Autosize

## Reminder: check if [System.Environment]::MachineName == $env:hostname == $env:sitename
$lp | Add-Member -Name "nickname" -Value "$env:computername" -MemberType NoteProperty -Force
$lp | Add-Member -Name "certificateId" -Value "561b31425b2fac5695c236b2b42244bb55777f25538b5a2cd0f920bb91b2d6d2" -MemberType NoteProperty
$lp | Add-Member -Name "csNumber" -Value "85236672668" -MemberType NoteProperty
$lp | Add-Member -Name "status" -Value 0 -MemberType NoteProperty
$lp | Add-Member -Name "openTime" -Value $Fdata.Availability -MemberType NoteProperty -Force
$lp | Add-Member -Name "location" -Value $location -MemberType NoteProperty
$lp | Add-Member -Name "description" -Value $description -MemberType NoteProperty
$lp | Add-Member -Name "lockerProfile" -Value $lockerProfile -MemberType NoteProperty
#$lp | Add-Member -Name "mac" -Value (Get-WimObject Win32_NetworkAdapter -Filter "MACAddress != NULL").MACAddress -MemberType NoteProperty
#$lp | Add-Member -Name "mac" -Value ((Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "MACAddress != NULL").MACAddress).Replace(':', '-') -MemberType NoteProperty
$lp | Add-Member -Name "mac" -Value (getmac /fo csv | ConvertFrom-Csv | where { -not ( $_.'Transport Name' -eq "Hardware not present")}).'Physical Address' -MemberType NoteProperty
$lp | Add-Member -Name "address" -value $address -MemberType NoteProperty
$lp | Add-Member -Name "boxes" -value $boxes -MemberType NoteProperty

$body = ($lp | ConvertTo-Json)

Write-Host "check object ..."
$lp
$lp.address
$lp.address.zh_HK

$lockercfgfile = "locker-configuration.properties"
#$uri = "https://kv7slzj8yk.execute-api.ap-northeast-1.amazonaws.com/local/lockers"
$uri = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers"

# locker-register
try {
    #$result = Invoke-RestMethod -DisableKeepAlive -body $body -ContentType "application/json; charset=utf-8" -Method Post -Headers @{"X-API-KEY" = "123456789"} -Uri $uri -Verbose -Debug -TimeoutSec 30
    $result = Invoke-RestMethod -DisableKeepAlive -body $body -ContentType "application/json; charset=utf-8" -Method Post -Headers $lockerCloudApiKey -Uri $uri -Verbose -Debug -TimeoutSec 30
    $r2 = $result.lockerId
} catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 

}

# get locker configuration file
try {
    # capture lockerId; append to $uri
    $uri2 = $uri + "/" + $r2
    #$result2 =  Invoke-RestMethod -DisableKeepAlive -ContentType "application/json; charset=utf-8" -Method Get -Headers @{"X-API-KEY" = "123456789"} -Uri $uri2 -Verbose -Debug -TimeoutSec 30
    $result2 =  Invoke-RestMethod -DisableKeepAlive -ContentType "application/json; charset=utf-8" -Method Get -Headers $lockerCloudApiKey -Uri $uri2 -Verbose -Debug -TimeoutSec 30
    $lockercfg = ($result2.configuration | Out-String).Replace(" : ", "=")
    Set-Location "D:\" -Verbose
    $lockercfg | Out-File -Encoding utf8 -FilePath "d:\$lockercfgfile" -Force -Verbose
    
} catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
}

# -- Update TeamViewer Description
# if setting groups:
# disabled: "groupid": "g95467798"
# testing: "groupid": "g95523178",
# production: "groupid": "g95523193",
# deploying: "groupid": "g96017647",
# DEV: "groupid": "g101663132"

# reg all lockers with locker-cloud
# move locker into teamviewer dev group
#     "description": "LockerLife Locker\nLockerName: $fdata.LockerShortName \n Type: $typeDescription\n LockerID: lockerId"

$TVdeviceProfileData = @"
{
    "password": "Locision123",
    "groupid": "g101663132",
}
"@

$TVprofileUri = "https://webapi.teamviewer.com/api/v1/devices/?remotecontrol_id=" + $TVremoteControlId
$TVdeviceProfile = Invoke-RestMethod -Method Get -Uri $TVprofileUri -Headers $TVheader
$TVdeviceUri = "https://webapi.teamviewer.com/api/v1/devices/" + $TVdeviceProfile.devices.device_id
$TVrepsonse = Invoke-RestMethod -Method Put -Uri $TVdeviceUri -Headers $TVheader -ContentType $TVcontentType -Body $TVdeviceProfileData -UseBasicParsing -Verbose

# send email
$ehlo_domain = "locision.com"
$to = "derekyuen@lockerlife.hk"
$replyto = "pi-admin@locision.com"
$from = "locker-deploy@locision.com"
$fromname = "Locker Deployment - Registration"
$returnpath = "pi-admin@locision.com"
$subject = "testing"
#$attach = "c:\temp\speedtest.txt"
$mailbody = "message body"
$mimetype = "text/plain"
#$extargs = " -ehlo -info"
#Send-MailMessage -From $from -To $to -Subject $subject -Body $mailbody -SmtpServer $smtphost -Port $smtpport -UseSsl -Credential (Get-Credential) -Debug
C:\local\bin\mailsend.exe -smtp $env:smtphost -port $env:smtpport -domain $ehlo_domain -t $to -f $from -name -sub $subject -name "locker-deployment: locker registered" -rp $returnpath -rt $replyto -ssl -auth -user $emailUser -pass "Locision1707" -attach $attach -M $mailbody -mime-type $mimetype -v


# rename computer using $LockerShortName
if (!($fdata.LockerShortName -eq $env:computername)) {
    Rename-Computer -NewName $Fdata.LockerShortName
}

# END