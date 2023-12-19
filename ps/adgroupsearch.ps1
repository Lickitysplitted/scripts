<# This script will take in a list of names/terms and wildcard search AD of groups and output multiple properties, including members, into a csv. #>
param(
    [Parameter(Mandatory=$true)]
    [string] $file,
    [Parameter(Mandatory=$true)]
    [string] $csv
)
function Search-ADGroups{
    foreach($line in Get-Content $file){
        Get-ADGroup -Properties Members -Filter "Name -like '*$line*'" | Select-Object -Property Name,SamAccountName,DistinguishedName,GroupCategory,GroupScope,ObjectClass,@{name="Members";expression={$_.Members -join "";""}}
    }
}

Search-ADGroups | Export-Csv -Path "$csv" -NoTypeInformation