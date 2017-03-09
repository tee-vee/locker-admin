#Requires -version 3.0

# Derek Yuen <derekyuen@lockerlife.hk>
# March 2017

# reg-test.ps1 -- base tester script for locker-registration

$basename = "register-locker"
$ErrorActionPreference = "Continue"


# Import BitsTransfer ...
if (!(Get-Module BitsTransfer)) {
    Import-Module BitsTransfer
} else {
    # BitsTransfer module already loaded ... clear queue
    Get-BitsTransfer | Complete-BitsTransfer
}

# get and source DeploymentConfig - just throw it into $Env:USERPROFILE\temp
(New-Object System.Net.WebClient).DownloadFile("http://lockerlife.hk/deploy/99-DeploymentConfig.ps1","C:\99-DeploymentConfig.ps1")
. C:\99-DeploymentConfig.ps1
$basename = "00-init"


$lp = New-Object PSObject 
#$lp = [PSCustomObject]

$location = @"
{
    "lat": 22.3964,
    "lon": 114.1095
}
"@ | ConvertFrom-Json

$description = @"
{
  "en": "empty"
}
"@ | ConvertFrom-Json

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
        building = "NULL"
        city = "Hong Kong"
        country = "CHINA"
        district = "NULL"
        room = "NULL"
        street = "NULL"
        town = "NULL"
    }
    zh_CN = [pscustomobject]@{
        building = "NULL"
        city = "Hong Kong"
        country = "CHINA"
        district = "NULL"
        room = "NULL"
        street = "NULL"
        town = "NULL"
    }
    zh_HK = [pscustomobject]@{
        building = "NULL"
        city = "Hong Kong"
        country = "CHINA"
        district = "NULL"
        room = "NULL"
        street = "NULL"
        town = "NULL"
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
$type = 7

if ($type -eq 72) {
    $col = 8
    $row = 9
} elseif ($type -eq 54) {
    $col = 6
    $row = 9
} elseif ($type -eq 36) {
    $col = 4
    $row = 9
} elseif ($type -eq 18) {
    $col = 2
    $row = 9
} elseif ($type -eq 13) {
    $col = 2
    $row = 9
} else {
    # Locker Type: 7-11
    $col = 2
    # set $row within foreach
}

#$TestAddMember = {

ForEach ($i in (1..$col)) {
    # 7-11 exception (column 1 has only 4 rows; column 2 has 9)
    if ($type -eq 7) {
        if ($i -eq 1) {
            $row = 4
        } else {
            $row = 9
        }
    }
    ForEach ($j in (1..$row)) {
        if ($type -eq 7) {
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
$lp | Add-Member -Name "nickname" -Value "test-vm0" -MemberType NoteProperty -Force
$lp | Add-Member -Name "certificateId" -Value "561b31425b2fac5695c236b2b42244bb55777f25538b5a2cd0f920bb91b2d6d2" -MemberType NoteProperty
$lp | Add-Member -Name "csNumber" -Value "85236672668" -MemberType NoteProperty
$lp | Add-Member -Name "status" -Value 0 -MemberType NoteProperty
$lp | Add-Member -Name "openTime" -Value "NULL" -MemberType NoteProperty -Force
$lp | Add-Member -Name "location" -Value $location -MemberType NoteProperty
$lp | Add-Member -Name "description" -Value $description -MemberType NoteProperty
$lp | Add-Member -Name "lockerProfile" -Value $lockerProfile -MemberType NoteProperty
#$lp | Add-Member -Name "mac" -Value (Get-WimObject Win32_NetworkAdapter -Filter "MACAddress != NULL").MACAddress -MemberType NoteProperty
$lp | Add-Member -Name "mac" -Value ((Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "MACAddress != NULL").MACAddress).Replace(':', '-') -MemberType NoteProperty
$lp | Add-Member -Name "address" -value $address -MemberType NoteProperty
$lp | Add-Member -Name "boxes" -value $boxes -MemberType NoteProperty

$body = ($lp | ConvertTo-Json)

#$uri = "https://770txnczi6.execute-api.ap-northeast-1.amazonaws.com/dev/lockers"
$uri = "https://kv7slzj8yk.execute-api.ap-northeast-1.amazonaws.com/local/lockers"

try {
    #-SkipCertificateCheck
    Invoke-RestMethod -DisableKeepAlive -body $body -ContentType "application/json" -Method Post -Headers @{"X-API-KEY" = "123456789"} -Uri $uri -Verbose -Debug -TimeoutSec 30
} catch {
    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
}




# END