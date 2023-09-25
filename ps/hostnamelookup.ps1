<# This script will lookup hostnames from a list #>

param(
    [Parameter()]
    [string] $list,
    [Parameter()]
    [string] $csv
)

function Search-HostNameList{
    foreach ($line in Get-Content $list){
        $answer = Resolve-DnsName "$line" | Select-Object Name,IPAddress
        $answer
    }
}

Search-HostNameList | Export-Csv -Path "$csv" -NoTypeInformation