Function Get-MSHotfix
{
    try {
        $outputs = Invoke-Expression 'wmic qfe get caption`,HotFixID`,InstalledOn'

        $outputs = $outputs[1..($outputs.length)]
    
        foreach ($output in $Outputs) {

            if ($output) {

                $output = $output -replace 'y U','y-U'

                $output = $output -replace 'NT A','NT-A'

                $output = $output -replace '\s+',' '

                $parts = $output -split ' '

                if ($parts[2] -like "*/*/*") {

                    $Dateis = [datetime]::ParseExact($parts[2], '%M/%d/yyyy',[Globalization.cultureinfo]::GetCultureInfo("en-US").DateTimeFormat)

                } elseif (($parts[2] -eq $null) -or ($parts[2] -eq ''))

                {

                    $Dateis = [datetime]1700

                }
            
                else {

                    $Dateis = get-date([DateTime][Convert]::ToInt64("$parts[2]", 16))-Format '%M/%d/yyyy'
                }

                New-Object -Type PSObject -Property @{

                    KBArticle = [string]$parts[0] 

                    HotFixID = [string]$parts[1]

                    InstalledOn = Get-Date($Dateis)-format "dddd d MMMM yyyy"

                }

            }

        }

    } catch {}

}

