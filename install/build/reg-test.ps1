#Requires -Version 3.0

# Derek Yuen <derekyuen@lockerlife.hk>
# March 2017

# reg-test.ps1 -- base tester script for locker-registration

$basename = "register-locker"
$ErrorActionPreference = "Stop"

Write-Host "Set Encoding"
& "$env:windir\system32\chcp" 65001

$OutputEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8

# locker check - use sim card?
# Ask Dropbox API

# #$authtoken "5nHPkEeCXnAAAAAAAAAAJI71YUOYRZgv4PeQ1h1ZHGmCHnbnosmjFdqkg5NPSggL"
# $authtoken = "5nHPkEeCXnAAAAAAAAAAIyI533NP8-Y1zXEK7m2LOvAk4-HC0jGOZLKjEoGcq2gU"
# $token = "Bearer " + $authtoken
# # Search Dropbox locker-admin
# $uri = "https://api.dropboxapi.com/2/files/search"
# $token = "Bearer " + $authtoken
# $body = '{"path":"/locker-admin/locker","query":"' +  $env:iccid + '"}'
# $yy = Invoke-RestMethod -Uri $uri -Headers @{ "Authorization" = $token } -Body $body -ContentType 'application/json' -Method Post


# speedtest
#if (Test-Path -Path "c:\local\bin\speedtest-cli.exe") {
#    c:\local\bin\speedtest-cli.exe
#}

# check services ...
c:\local\bin\NSSM.exe set data-collection AppParameters -Dconfig=D:\locker-configuration.properties -jar D:\data-collection.jar
c:\local\bin\NSSM.exe set scanner AppParameters -Dconfig=D:\locker-configuration.properties -jar D:\scanner.jar
c:\local\bin\NSSM.exe set core AppParameters -Dconfig=D:\locker-configuration.properties -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -jar d:\core.jar

Get-Service -Verbose data-collection
Get-Service -Verbose scanner
Get-Service -Verbose core

Stop-Service -Verbose data-collection
Stop-Service -Verbose scanner
Stop-Service -Verbose core

$sdkUri = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/latest/sdk"
$headers = @{ "X-API-KEY" = "123456789" } 
$sdkResponse = Invoke-RestMethod -Method Get -Headers $headers -Uri $sdkUri

$sdkVersions = @( "core", "scanner", "dataCollection")
foreach ($sdk in $sdkVersions) {
    $sdkResponse.$sdk.version | Out-File -Encoding utf8 -FilePath "D:\$sdk.version.txt"
}

Invoke-RestMethod -Method Get -Headers $headers -Uri $sdkUri -Verbose

if (!(Get-Service -Name kioskserver -ErrorAction SilentlyContinue)) {
    WriteInfoHighlighted "$basename -- INSTALL KIOSKSERVER AS SERVICE"
    #CALL %LOCKERINSTALL%\build\new-service-kioskserver.bat
    #CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-kioskserver.bat
    Start-Process -FilePath $Env:local\bin\new-service-kioskserver.bat -Verb RunAs -Wait
    Write-Host "."
} else {
    Write-Host "Kioskserver service installed."
    Restart-Service -Name "kioskserver" -Verbose
    c:\local\bin\NSSM.exe rotate kioskserver
}


# Algorithm       Hash                                                                   Path
# ---------       ----                                                                   ----
# SHA256          8C3046E962A6D633814706E11C4D91AF36EA833F78DC18F5A1E0F61EB4F73F19       D:\core.jar
# SHA256          07B93CE8D41B40AA4E0061C12976DB789293C5C1200DB4286ADBDF16BB23C852       D:\data-collection.jar
# SHA256          59410FB0AC13F2971F38117CE54BAD991EFB0AF38C780069C41F4F9141B1472B       D:\scanner.jar


#$installedSdkVer = unzip -p scanner.jar META-INF/MANIFEST.MF | Select-String "Implementation-Version"

$lockerJarName = "scanner"
$lockerJarFile = "$lockerJarName.jar"

#  Add lockerJar File Hash for check 
if ($lockerJarName -eq "core") {
    # get updated new-service batch script
    Remove-Item -Path "c:\local\bin\new-service-$lockerJarName.bat" -Verbose -ErrorAction Continue
    Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/bin/new-service-$lockerJarName.bat" -OutFile "c:\local\bin\new-service-$lockerJarName.bat" -Verbose

    $lockerJarHash = "8C3046E962A6D633814706E11C4D91AF36EA833F78DC18F5A1E0F61EB4F73F19"
    Write-Host "$lockerJarName lockerJarHash - $lockerJarHash"
    Stop-Service -Name $lockerJarName -Verbose
    Remove-Item -Path "D:\$lockerJarFile" -Force -Verbose
    Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.$lockerJarName.url -OutFile "D:\$lockerJarFile" -ContentType "application/octet-stream" -Verbose
    if ((Get-FileHash -Path "D:\$lockerJarFile" -Algorithm SHA256).Hash -ne $lockerJarHash) {
        Remove-Item -Path "D:\$lockerJarFile" -Force -Verbose
        Invoke-WebRequest -Method Get -Headers $headers -Uri "$sdkResponse.$lockerJarName.url" -OutFile "D:\$lockerJarFile" -ContentType "application/octet-stream" -Verbose
        Get-FileHash -Path "D:\$lockerJarFile" -Algorithm SHA256
    }
    $out = Start-Process -FilePath "C:\local\bin\new-service-$lockerJarName.bat" -Verb RunAs
    Start-Service -Name $lockerJarName -Verbose
    c:\local\bin\NSSM.exe rotate core

} elseif ($lockerJarName -eq "data-collection") {
    # get updated new-service batch script
    Remove-Item -Path "c:\local\bin\new-service-datacollection.bat" -Verbose -ErrorAction Continue
    Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/bin/new-service-datacollection.bat" -OutFile "c:\local\bin\new-service-datacollection.bat" -Verbose

    # data-collection is "datacollection" at LockerCloud API endpoint
    $lockerJarHash = "07B93CE8D41B40AA4E0061C12976DB789293C5C1200DB4286ADBDF16BB23C852"
    Write-Host "$lockerJarName lockerJarHash - $lockerJarHash"
    Stop-Service -Name $lockerJarName -Verbose
    Remove-Item -Path "D:\$lockerJarFile" -Force -Verbose
    Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.datacollection.url -OutFile "D:\$lockerJarFile" -ContentType "application/octet-stream" -Verbose
    if ((Get-FileHash -Path "D:\$lockerJarFile" -Algorithm SHA256).Hash -ne $lockerJarHash) {
        Remove-Item -Path "D:\$lockerJarFile" -Force -Verbose
        Invoke-WebRequest -Method Get -Headers $headers -Uri "$sdkResponse.$lockerJarName.url" -OutFile "D:\$lockerJarFile" -ContentType "application/octet-stream" -Verbose
        Get-FileHash -Path "D:\$lockerJarFile" -Algorithm SHA256
    }
    $out = Start-Process -FilePath "C:\local\bin\new-service-datacollection.bat" -Verb RunAs
    Start-Service -Name $lockerJarName -Verbose
    c:\local\bin\NSSM.exe rotate data-collection

} elseif ($lockerJarName -eq "scanner") {
    # get updated new-service batch script
    Remove-Item -Path "c:\local\bin\new-service-$lockerJarName.bat" -Verbose -ErrorAction Continue
    Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/bin/new-service-$lockerJarName.bat" -OutFile "c:\local\bin\new-service-$lockerJarName.bat" -Verbose

    $lockerJarHash = "59410FB0AC13F2971F38117CE54BAD991EFB0AF38C780069C41F4F9141B1472B"
    Write-Host "$lockerJarName lockerJarHash - $lockerJarHash"
    Stop-Service -Name $lockerJarName -Verbose
    Remove-Item -Path "D:\$lockerJarFile" -Force -Verbose
    Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.$lockerJarName.url -OutFile "D:\$lockerJarFile" -ContentType "application/octet-stream" -Verbose
    if ((Get-FileHash -Path "D:\$lockerJarFile" -Algorithm SHA256).Hash -ne $lockerJarHash) {
        Remove-Item -Path "D:\$lockerJarFile" -Force -Verbose
        Invoke-WebRequest -Method Get -Headers $headers -Uri "$sdkResponse.$lockerJarName.url" -OutFile "D:\$lockerJarFile" -ContentType "application/octet-stream" -Verbose
        Get-FileHash -Path "D:\$lockerJarFile" -Algorithm SHA256
    }
    $out = Start-Process -FilePath "C:\local\bin\new-service-$lockerJarName.bat" -Verb RunAs
    Start-Service -Name $lockerJarName -Verbose
    c:\local\bin\NSSM.exe rotate scanner

} else {
    Write-Host "unknown locker jar ... not possible!"
}


# $lockerJarName = "data-collection"
# $lockerJarFile = "$lockerJarName.jar"
# if (!(Get-Service -Name "data-collection" -ErrorAction SilentlyContinue)) {
#     WriteInfoHighlighted "$basename -- INSTALL DATA-COLLECTION AS SERVICE"
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.dataCollection.url -OutFile "D:\data-collection.jar" -ContentType "application/octet-stream" -Verbose
#     Start-Process -FilePath $Env:local\bin\new-service-datacollection.bat -Verb RunAs -Wait
# } else {
#     Write-Host "data-Collection service installed."
#     Stop-Service -Name "data-collection" -Verbose
#     Move-Item -Path "D:\$lockerJarFile" -Destination "D:\data-collection.jar.old" -Force
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.dataCollection.url -OutFile "D:\$lockerJarFile" -ContentType "application/octet-stream" -Verbose
#     if ((Get-FileHash -Path "D:\$lockerJarFile" -Algorithm SHA256) -ne "07B93CE8D41B40AA4E0061C12976DB789293C5C1200DB4286ADBDF16BB23C852") {
#         Remove-Item -Path "D:\$lockerJarFile" -Force -Verbose
#         Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.scanner.url -OutFile "D:\$lockerJarFile" -ContentType "application/octet-stream" -Verbose
#     }
#     Start-Service -Name "data-collection" -Verbose
#     c:\local\bin\NSSM.exe set data-collection AppParameters -Dconfig=D:\locker-configuration.properties -jar D:\data-collection.jar
#     c:\local\bin\NSSM.exe rotate data-collection
# }


# if (!(Get-Service -Name core -ErrorAction SilentlyContinue)) {
#     WriteInfoHighlighted "$basename -- INSTALL CORE AS SERVICE"
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.core.url -OutFile "D:\core.jar" -ContentType "application/octet-stream" -Verbose
#     ## CALL %USERPROFILE%\Dropbox\locker-admin\install\build\new-service-core.bat
#     Start-Process -FilePath $Env:local\bin\new-service-core.bat -Verb RunAs -Wait
#     Write-Host "."
# } else {
#     Write-Host "core service installed."
#     Stop-Service -Name core -Verbose
#     Move-Item -Path "D:\core.jar" -Destination "D:\core.jar.old" -Force
#     Invoke-WebRequest -Method Get -Headers $headers -Uri $sdkResponse.core.url -OutFile "D:\core.jar" -ContentType "application/octet-stream" -Verbose
#     Get-FileHash -Path "D:\core.jar" -Algorithm SHA256
#     Start-Service -Name core -Verbose
#     c:\local\bin\NSSM.exe set core AppParameters "-Dconfig=D:\locker-configuration.properties -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -jar d:\core.jar"
#     c:\local\bin\NSSM.exe rotate core

# }


# locker-properties setup
# get LockerManagement Data
Write-Host "Get LockerManagement Data"
$lockerManagement = "LockerManagement.csv"
if (Test-Path -Path "C:\temp\$lockerManagement") {
    Remove-Item "C:\temp\$lockerManagement" -Force -ErrorAction SilentlyContinue
}
$request = Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/$lockerManagement" -OutFile C:\temp\$lockerManagement

Write-Host "Reading LockerManagement Data"
$lmdata = Get-Content "c:\temp\$lockerManagement" -Encoding UTF8 | Select-Object | ConvertFrom-Csv

# Get Site ... 
#$Fdata = $lmdata | Where-Object { $_.LockerShortName -eq "test-hk3" }
$Fdata = $lmdata | Where-Object { $_.LockerShortName -ieq $env:computername }


if (!$Fdata) {
    # Try using sim iccid
    $iccid = (Get-ChildItem -Path "C:\local\status\8985*")[0].Name
    Write-Host "Site not found - please check computername or sitename"
    exit
}


# locker-properties: location (lat/lon)
Write-Host "Get GPS Coordinates"
# use Google Maps Geocoding API
# Key -> Derek Y Developer Account
$googlePlaceApiKey = "AIzaSyBt6QTvw5JEPujtT36s4CE1SV-C3-BhpgM"
[string]$RegionBias = "hk"
[switch]$Sensor = $false
$protocol = "https"
$RawDataFormat = "JSON"
[string]$language = "en"

$googleGeocodeApiKey = "AIzaSyClvw0s2I9miLfAniQ97wb6QkxFlGalho4"

# massage address for google ... 
$geocodeAddress = $Fdata.GpsRef + " " + $Fdata.StreetNo + " " + $Fdata.StreetName + " " + $Fdata.District
$geocodeAddress = $geocodeAddress.Replace("NULL","")
$geocodeAddress = $geocodeAddress.TrimEnd(" ") 
$convertedAddress = $geocodeAddress.Replace(" ","+")
#$url = "https://maps.googleapis.com/maps/api/geocode/json?address=1600+Amphitheatre+Parkway,+Mountain+View,+CA&key=AIzaSyClvw0s2I9miLfAniQ97wb6QkxFlGalho4"
#$url = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&key=$($googleGeocodeApiKey)"
#$url = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&sensor=$($Sensor.ToString().ToLower())&region=$($RegionBias)&key=$($googleGeocodeApiKey)"
$geourl = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&key=$($googleGeocodeApiKey)"
$geourlTW = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&language=zh-TW&key=$($googleGeocodeApiKey)"
$geourlCN = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/geocode/$($RawDataFormat.ToLower())?address=$($convertedAddress)&region=$($RegionBias)&language=zh-CN&key=$($googleGeocodeApiKey)"
$placeUrl = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=$googlePlaceApiKey"
$placeUrlTW = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&language=zh-TW&key=$googlePlaceApiKey"
$placeUrlCN = "$($Protocol.ToLower())://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&language=zh-CN&key=$googlePlaceApiKey"

try {
    #[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls11
    #[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    #$geo = Invoke-RestMethod "https://maps.googleapis.com/maps/api/geocode/json?address=2+King+San+Path,+New+Territories,+Hong+Kong&key=$googleGeocodeApiKey"
    $georesponse = Invoke-RestMethod -Uri $geourl -Method Get -ContentType $TVcontentType
    $georesponseTW = Invoke-RestMethod -Uri $geourlTW -Method Get -ContentType $TVcontentType
    $georesponseCN = Invoke-RestMethod -Uri $geourlCN -Method Get -ContentType $TVcontentType

    #$geo.results.geometry.location

    if (!($georesponse)) {
        $georesponse = c:\local\bin\curl.exe --url "$geourl"
    }

    # # approximate can be okay too!
    # if ($georesponse.results.geometry | where { $_.location_type -eq "ROOFTOP" }) {
    #     Write-Host "found exact match ..."
    #     $location = $georesponse.results.geometry | where { $_.location_type -eq "ROOFTOP" }
    # } else {
    #     Write-Host "GPS may not be completely accurate ... check georesponse and address immediately"
    #     $location = $georesponse.results.geometry
    # }

    # how many responses ?
    if (($georesponse.results).Count -gt 2) {
        Write-host "multiple locations found ... check georesponse and location before registering locker"
        # because google geocode-api uses lat/lng - and we use lat/lon
        $location = $georesponse.results.geometry.location | Select-Object @{N='lat'; E={($georesponse.results)[0].geometry.location.lat}}, @{N='lon'; E={($georesponse.results)[0].geometry.location.lng}}

    } else {
        Write-Host "one result found"
        # because google geocode-api uses lat/lng - and we use lat/lon
        $location = $georesponse.results.geometry.location | Select-Object @{N='lat'; E={$georesponse.results.geometry.location.lat}}, @{N='lon'; E={$georesponse.results.geometry.location.lng}}

    }

    # because google geocode-api uses lat/lng - and we use lat/lon 
    #$location = $georesponse.results.geometry.location | Select-Object @{N='lat'; E={$georesponse.results.geometry.location.lat}}, @{N='lon'; E={$georesponse.results.geometry.location.lng}}

    # store place_id - useful later
    $placeId = $georesponse.results.place_id

    # Testing Google Places API for address verification (based on building name) -- FUTURE
    #$place = Invoke-RestMethod "https://maps.googleapis.com/maps/api/place/details/json?placeid=ChIJP4Go7FQHBDQR1CUFeViLOzM&key=$googlePlaceApiKey" -Method Get -ContentType $TVcontentType
    #$place = Invoke-RestMethod -Uri $placeUrl -Method Get -ContentType $TVcontentType

} catch {
    Write-Host "StatusCode:" $_.Exception
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription

}


# # BAD IDEA ... FIXME ASAP - $location not set; set a value
# $location = @"
# {
#     "lat": 22.3964, "lon": 114.1095
# }
# "@ | ConvertFrom-Json



# locker-properties: description 
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

# locker-properties: lockerProfile
# find camera
if (($env:CameraIpAddress -eq "0.0.0.0") -or (!$env:CameraIpAddress)) {
    $findCam = (C:\local\bin\upnpscan.exe -m | Select-String LOCATION).ToString().Split(" ")
    $env:CameraIpAddress = ([uri]$findCam[1]).Host
} else {
    Write-Host "Unable to find camera ..."
    Write-Host "Unable to find camera ..."
    Write-Host "Unable to find camera ... setting to 192.168.1.200"
    $env:CameraIpAddress = "192.168.1.200"
}

$lockerProfile = @"
{
    "cameraHost": "$env:CameraIpAddress",
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

# locker-properties: address
$address = [pscustomobject]@{
    en = [pscustomobject]@{
        room = $Fdata.Floor
        building = $Fdata.Building
        street = $Fdata.StreetNo + " " + $Fdata.StreetName
        town = $Fdata.Town
        district = $Fdata.District
        city = "Hong Kong"
        country = "CHINA"
    }
    zh_CN = [pscustomobject]@{
        room = $Fdata.FloorC
        building = $Fdata.BuildingC
        street = $Fdata.StreetNoC + " " + $Fdata.StreetNameC
        town = $Fdata.TownC
        district = $Fdata.DistrictC
        city = "香港"
        country = "中国"
    }
    zh_HK = [pscustomobject]@{
        room = $Fdata.FloorC
        building = $Fdata.BuildingC
        street = $Fdata.StreetNoC + " " + $Fdata.StreetNameC
        town = $Fdata.TownC
        district = $Fdata.DistrictC
        city = "香港"
        country = "中國"
    }
} # $address


# locker-properties: boxes
$boxes = @()
$type = $Fdata.Boxes

if (!$type) {
    Write-Host "no type found - cannot continue locker registration - exit"
    exit
}

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

$boxes | ConvertTo-Json | Set-Content -Path boxes.json -Force
$xboxes = Get-Content -Path boxes.json -Raw
$xxboxes = [scriptblock]::Create(($xboxes| ConvertFrom-Json))
#Measure-Command $TestAddMember | Format-Table TotalSeconds -Autosize

# lp -> locker properties
Write-Host "Create locker.properties profile"
$lp = New-Object PSObject
#$lp = [PSCustomObject]

## Reminder: check if [System.Environment]::MachineName == $env:hostname == $env:sitename
$lp | Add-Member -Name "nickname" -Value "$env:computername" -MemberType NoteProperty -Force
$lp | Add-Member -Name "certificateId" -Value "561b31425b2fac5695c236b2b42244bb55777f25538b5a2cd0f920bb91b2d6d2" -MemberType NoteProperty
$lp | Add-Member -Name "csNumber" -Value "85236672668" -MemberType NoteProperty
#$lp | Add-Member -Name "status" -Value 0 -MemberType NoteProperty
$lp | Add-Member -Name "openTime" -Value $Fdata.Availability -MemberType NoteProperty -Force
$lp | Add-Member -Name "location" -Value $location -MemberType NoteProperty
$lp | Add-Member -Name "description" -Value $description -MemberType NoteProperty
$lp | Add-Member -Name "lockerProfile" -Value $lockerProfile -MemberType NoteProperty
#$lp | Add-Member -Name "mac" -Value ((Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "MACAddress != NULL").MACAddress).Replace(':', '-') -MemberType NoteProperty
$lp | Add-Member -Name "mac" -Value (getmac /fo csv | ConvertFrom-Csv | Where-Object { -not ( $_.'Transport Name' -eq "Hardware not present")}).'Physical Address' -MemberType NoteProperty
$lp | Add-Member -Name "address" -value $address -MemberType NoteProperty
$lp | Add-Member -Name "boxes" -value $boxes -MemberType NoteProperty

$body = ($lp | ConvertTo-Json)

Write-Host "backup locker.properties to file ..."
$lp | Out-File -Encoding utf8 -FilePath "D:\locker.properties.txt" -Force
$lp

#$lp.address
#$lp.address.zh_HK

$lockercfgfile = "locker-configuration.properties"
#$uri = "https://kv7slzj8yk.execute-api.ap-northeast-1.amazonaws.com/local/lockers"
$uri = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers"
$lockerCloudApiKey = @{ "X-API-KEY" = "123456789" }

try {
    #"application/json; charset=utf-8"
    #$result = Invoke-RestMethod -DisableKeepAlive -body $body -ContentType "application/json; charset=utf-8" -Method Post -Headers @{"X-API-KEY" = "123456789"} -Uri $uri -Verbose -Debug -TimeoutSec 30
    $result = Invoke-RestMethod -DisableKeepAlive -body $body -ContentType "application/json; charset=utf-8" -Method Post -Headers $lockerCloudApiKey -Uri $uri -Verbose -Debug -TimeoutSec 30
    $r2 = $result.lockerId
} catch {
    # set-location d:
    # curl --url $uri -H "X-API-KEY: 123456789" -H "Content-Type: application/json" -d "@locker.properties.txt"
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__

}

try {
    # capture lockerId; append to $uri
    $uri2 = $uri + "/" + $r2
    $result2 =  Invoke-RestMethod -DisableKeepAlive -ContentType "application/json; charset=utf-8" -Method Get -Headers $lockerCloudApiKey -Uri $uri2 -Verbose -Debug -TimeoutSec 30
    $lockercfg = ($result2.configuration | Out-String).Replace(" : ", "=")
    Set-Location "D:\" -Verbose
    $lockercfg | Out-File -Encoding utf8 -FilePath "d:\$lockercfgfile" -Force -Verbose

} catch {
    Write-Host "StatusCode:" $_.Exception
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
}

# Update TeamViewer
Write-Host "Teamviewer Setup"

# Groups:
#   disabled: "groupid": "g95467798"
#   testing: "groupid": "g95523178",
#   production: "groupid": "g95523193",
#   deploying: "groupid": "g96017647",
#   DEV: "groupid": "g101663132"

# get current computer TeamViewer ClientID
$TVclientId = (Get-ItemProperty -Path "HKLM:\SOFTWARE\TeamViewer" -Name ClientID).ClientID

# teamviewer api setup

$TVheader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$TVtoken = "Bearer","2034214-P3aa9qGG323SKWVqqKBV"
$TVheader.Add("authorization", $TVtoken)
$TVcontentType = 'application/json; charset=utf-8'
$TVdeviceProfileData = @"
{
    "alias": "$($fdata.LockerName)",
    "password": "Locision123",
    "groupid": "g101663132",
    "description": "LockerLife Locker\nComputerName: $($Fdata.LockerName)\nType: $typeDescription"
}
"@


Write-Host "test connectivity to teamviewer api"
$ping = Invoke-RestMethod -Uri "https://webapi.teamviewer.com/api/v1/ping" -ContentType $TVcontentType -Method Get -Headers $TVheader

if ($ping.token_valid -eq "True") {

    # Note: TeamViewer API calls this "remotecontrol_id"
    # changes to device profile require "device_id"
    # Need to convert "remotecontrol_id" to "device_id"
    # testing -- $TVclientId = "629313250"
    Write-Host "Get TeamViewer Profile"
    $TVremoteControlId = "r" + $TVclientId
    $TVprofileUri = "https://webapi.teamviewer.com/api/v1/devices/?remotecontrol_id=" + $TVremoteControlId
    $TVdeviceProfile = Invoke-RestMethod -Method Get -Uri $TVprofileUri -Headers $TVheader

    # move locker into teamviewer dev group
    $TVprofileUri = "https://webapi.teamviewer.com/api/v1/devices/?remotecontrol_id=" + $TVremoteControlId
    $TVdeviceProfile = Invoke-RestMethod -Method Get -Uri $TVprofileUri -Headers $TVheader
    $TVdeviceUri = "https://webapi.teamviewer.com/api/v1/devices/" + $TVdeviceProfile.devices.device_id
    $TVrepsonse = Invoke-RestMethod -Method Put -Uri $TVdeviceUri -Headers $TVheader -ContentType $TVcontentType -Body $TVdeviceProfileData -Verbose

} else {
    Write-Host "Unable to connect to TeamViewer API"
}


start-service data-collection
start-service scanner
start-service core

c:\local\bin\nssm.exe rotate data-collection
c:\local\bin\nssm.exe rotate scanner
c:\local\bin\nssm.exe rotate core


get-service data-collection
get-service scanner
get-service core

# pull down new locker-console (purple screen)
set-location d:
New-Item -ItemType Directory -Path "D:\backup"
copy-item -Recurse -path "d:\Locker-Console" -Destination "D:\backup"
Invoke-WebRequest -Uri "http://lockerlife.hk/deploy/app/production-Locker-Console.zip" -OutFile "d:\Locker-Console"


# send email

$ehlo_domain = "lockerlife.hk"
$to = "derekyuen@lockerlife.hk"
# $cc = "derekyuen@lockerlife.hk"
$replyto = "postmaster@lockerlife.hk"
$from = "postmaster@lockerlife.hk"
$fromname = "Locker Deployment - Registration"
$returnpath = "postmaster@lockerlife.hk"
$subject = "testing"
#$attach = "c:\temp\speedtest.txt"
$mailbody = "message body"
$mimetype = "text/plain"


# $SMTPServer = "ns62.hostingspeed.net"
# $SMTPPort = "587"
# $Username = "postmaster@lockerlife.hk"
# $Password = "Locision123"

# $body = "Insert body text here"
# #$attachment = "C:\test.txt"

# $message = New-Object System.Net.Mail.MailMessage
# $message.subject = $subject
# $message.body = $body
# $message.to.add($to)
# $message.cc.add($cc)
# $message.from = $username
# $message.attachments.add($attachment)

# $smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
# $smtp.EnableSSL = $true
# $smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
# $smtp.send($message)
# write-host "Mail Sent"
#$extargs = " -ehlo -info"
#Send-MailMessage -From $from -To $to -Subject $subject -Body $mailbody -SmtpServer ns62.hostingspeed.net -Port $smtpport -UseSsl -Credential (Get-Credential) -Debug
#C:\local\bin\mailsend.exe -smtp $env:smtphost -port $env:smtpport -domain $ehlo_domain -t $to -f $from -name -sub $subject -name "locker-deployment: locker registered" -rp $returnpath -rt $replyto -ssl -auth -user $emailUser -pass "Locision1707" -attach $attach -M $mailbody -mime-type $mimetype -v


# rename computer using $LockerShortName
if (!($fdata.LockerShortName -eq $env:computername)) {
    Rename-Computer -NewName $($Fdata.LockerShortName) -Force -ErrorAction SilentlyContinue
}

# END
