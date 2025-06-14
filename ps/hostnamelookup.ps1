<# 
.SYNOPSIS
    This script performs DNS lookups for hostnames from a provided list and exports the results to a CSV file.

.DESCRIPTION
    The script accepts a file containing a list of hostnames, performs DNS lookups for each, 
    and outputs the results (hostname and IP address) to a specified CSV file.

.PARAMETER list
    The file path to the list of hostnames.

.PARAMETER csv
    The file path for the output CSV file.

.NOTES
    Author: Lickitysplitted
    Date: 2024-10-17
#>

param(
    [Parameter(Mandatory=$true)]
    [string] $list,

    [Parameter(Mandatory=$true)]
    [string] $csv
)

# Function to perform DNS lookups with error handling and logging
function Search-HostNameList {
    $results = @()

    foreach ($line in Get-Content $list) {
        try {
            $answer = Resolve-DnsName "$line" -ErrorAction Stop | Select-Object Name,IPAddress
            Write-Host "Lookup successful for: $line"
            $results += $answer
        } catch {
            Write-Warning "Failed to resolve $line. Error: $_"
        }
    }
    
    return $results
}

# Check if the list file exists
if (-Not (Test-Path $list)) {
    Write-Error "The file $list does not exist."
    exit 1
}

# Perform DNS lookups and export to CSV
$results = Search-HostNameList
if ($results) {
    $results | Export-Csv -Path "$csv" -NoTypeInformation
    Write-Host "Exported results to $csv"
} else {
    Write-Warning "No results to export."
}
