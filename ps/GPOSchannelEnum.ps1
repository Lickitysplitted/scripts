<#
.SYNOPSIS
    Enumerates remote Active Directory Group Policies that contain Schannel settings and outputs the results in CSV, JSON, and HTML formats.
.DESCRIPTION
    This script retrieves all Group Policy Objects (GPOs) in the domain and checks for Schannel-related settings by generating and parsing their reports.
    The results include the GPO name, description (if any), and the Schannel-related settings/controls.
.OUTPUT
    The script outputs the result in CSV, JSON, and HTML formats.
.NOTES
    Author: Senior Security Engineer
    Date: 2024-10-16
#>

# Import necessary module for Active Directory and Group Policy operations
Import-Module GroupPolicy

# Define a function to search GPO reports for Schannel settings
function Get-GPOWithSchannelSettings {
    param (
        [string]$GPOName
    )

    # Generate a temporary XML report for each GPO
    $reportPath = [System.IO.Path]::GetTempFileName() + ".xml"
    
    try {
        # Generate an XML report for the specified GPO
        Get-GPOReport -Name $GPOName -ReportType XML -Path $reportPath

        # Load the XML report
        [xml]$gpoXml = Get-Content -Path $reportPath

        # Extract GPO details
        $gpoDetails = @{
            GPOName     = $GPOName
            Description = $gpoXml.GPO.Description  # Get the GPO description
            Settings    = @()  # Placeholder for Schannel settings
        }

        # Search for Schannel-related settings within the XML
        $schannelSettings = $gpoXml.GPO.Section | Where-Object { $_.name -like "*Schannel*" }

        # If Schannel settings are found, add them to the GPO details
        if ($schannelSettings) {
            foreach ($setting in $schannelSettings) {
                $gpoDetails.Settings += $setting.InnerText
            }
        }

        # Return GPO details only if Schannel settings were found
        if ($gpoDetails.Settings.Count -gt 0) {
            return $gpoDetails
        }
    }
    catch {
        Write-Error "Error processing GPO '$GPOName': $_"
    }
    finally {
        # Clean up the temporary report
        if (Test-Path $reportPath) {
            Remove-Item $reportPath -Force
        }
    }
}

# Get a list of all GPOs in the domain
$gpos = Get-GPO -All

# Store GPOs with Schannel settings
$gpoWithSchannel = @()

foreach ($gpo in $gpos) {
    $result = Get-GPOWithSchannelSettings -GPOName $gpo.DisplayName
    if ($result) {
        $gpoWithSchannel += $result
    }
}

# Output to CSV
$csvPath = "GPO_SchannelSettings.csv"
$gpoWithSchannel | ForEach-Object {
    [PSCustomObject]@{
        GPOName     = $_.GPOName
        Description = $_.Description
        Settings    = ($_."Settings" -join "; ")  # Join settings into a single string
    }
} | Export-Csv -Path $csvPath -NoTypeInformation

# Output to JSON
$jsonPath = "GPO_SchannelSettings.json"
$gpoWithSchannel | ConvertTo-Json | Out-File -FilePath $jsonPath

# Output to HTML
$htmlPath = "GPO_SchannelSettings.html"
$gpoWithSchannel | ForEach-Object {
    [PSCustomObject]@{
        GPOName     = $_.GPOName
        Description = $_.Description
        Settings    = ($_."Settings" -join "<br>")  # Join settings for better HTML readability
    }
} | ConvertTo-Html -Property GPOName, Description, Settings | Out-File -FilePath $htmlPath

# Output final paths to the user
Write-Output "Results saved as CSV: $csvPath"
Write-Output "Results saved as JSON: $jsonPath"
Write-Output "Results saved as HTML: $htmlPath"
