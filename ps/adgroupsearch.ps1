<# This script will take in a list of names/terms and wildcard search AD and output multiple properties, including members, into a csv. #>
param ($file)
param ($csv)

$file = Get-Content "$file"
function Search-ADGroups{
    foreach($line in $file){
        $result = Get-ADGroup -Properties Members -Filter "Name -like '*$line*'" | Select-Object -Property Name,SamAccountName,DistinguishedName,GroupCategory,GroupScope,ObjectClass,Members
        $result
    }
}