<# 
.SYNOPSIS
    This script performs wildcard searches for AD groups based on a list of terms and exports group details to a CSV file.

.DESCRIPTION
    The script reads a list of terms from a file, performs wildcard searches for matching AD groups,
    retrieves several group properties (including members), and exports the results to a CSV file.

.PARAMETER file
    The file path containing the list of search terms (group names or fragments).

.PARAMETER csv
    The file path for the output CSV file.

.NOTES
    Author: [Your Name]
    Date: [Date]
#>

param(
    [Parameter(Mandatory=$true)]
    [string] $file,

    [Parameter(Mandatory=$true)]
    [string] $csv
)

# Function to search AD groups with error handling and logging
function Search-ADGroups {
    $results = @()

    foreach ($line in Get-Content $file) {
        try {
            # Search for AD groups matching the wildcard search term
            $groups = Get-ADGroup -Properties Members -Filter "Name -like '*$line*'" -ErrorAction Stop

            if ($groups) {
                foreach ($group in $groups) {
                    $result = New-Object PSObject -Property @{
                        Name              = $group.Name
                        SamAccountName    = $group.SamAccountName
                        DistinguishedName = $group.DistinguishedName
                        GroupCategory     = $group.GroupCategory
                        GroupScope        = $group.GroupScope
                        ObjectClass       = $group.ObjectClass
                        Members           = ($group.Members -join "; ") # Separate members with semicolons
                    }
                    $results += $result
                }
                Write-Host "Processed search term: $line"
            } else {
                Write-Warning "No groups found for search term: $line"
            }
        } catch {
            Write-Error "Error searching for groups with term $line: $_"
        }
    }

    return $results
}

# Validate the input file before starting
if (-Not (Test-Path $file)) {
    Write-Error "The file $file does not exist."
    exit 1
}

# Validate that the file is not empty
if ((Get-Content $file).Length -eq 0) {
    Write-Error "The file $file is empty."
    exit 1
}

# Perform AD group searches and export the results to CSV
$results = Search-ADGroups
if ($results) {
    $results | Export-Csv -Path "$csv" -NoTypeInformation
    Write-Host "Search results exported to $csv"
} else {
    Write-Warning "No results to export."
}
