<#
.SYNOPSIS
    Enumerates remote Active Directory Group Policies that contain Schannel and Cryptography settings and outputs the results in CSV, JSON, and HTML formats.
.DESCRIPTION
    This script retrieves all Group Policy Objects (GPOs) in the domain from each discovered Domain Controller and checks for Schannel and Cryptography-related settings by parsing their corresponding policy files on SYSVOL.
    The results include the GPO name, description (if any), and the Schannel/Cryptography-related settings/controls.
.OUTPUT
    The script outputs the result in CSV, JSON, and HTML formats.
.NOTES
    Author: Senior Security Engineer
    Date: 2024-10-16
#>

# Import Active Directory module
Import-Module ActiveDirectory

# Define function to retrieve all domain controllers
function Get-AllDomainControllers {
    return Get-ADDomainController -Filter * | Select-Object -ExpandProperty Hostname
}

# Define a function to search for Schannel and Cryptography settings in a GPO on a specific domain controller
function Get-GPOWithSchannelSettings {
    param (
        [string]$gpoGuid,
        [string]$domainController,
        [string]$gpoName
    )

    # Define the path to the GPO's policy file in the SYSVOL share of the specific DC
    $sysvolPath = "\\$domainController\SYSVOL\$domain\Policies"
    $gpoPath = Join-Path $sysvolPath $gpoGuid
    $gptIniPath = Join-Path $gpoPath "gpt.ini"
    $gpoXmlPath = Join-Path $gpoPath "\Machine\Microsoft\Windows NT\SecEdit\GptTmpl.inf"

    # Create an object to hold GPO details
    $gpoDetails = @{
        GPOGuid         = $gpoGuid
        GPOName         = $gpoName
        Description     = $null
        Settings        = @()
        DomainController = $domainController
    }

    try {
        # Check if the GPO XML path exists (i.e., if the GPO has any machine settings)
        if (Test-Path $gpoXmlPath) {
            # Read the GptTmpl.inf file, which contains security settings
            $gptContent = Get-Content -Path $gpoXmlPath

            # Search for Schannel or Cryptography settings in the file
            $schannelSettings = $gptContent | Where-Object { $_ -match "Schannel|Cryptography" }

            # If any Schannel or Cryptography settings are found, store them in the GPO details
            if ($schannelSettings) {
                $gpoDetails.Settings += $schannelSettings
            }
        }

        # Check if the GPO has a description in the GPT.ini file
        if (Test-Path $gptIniPath) {
            $gptIniContent = Get-Content $gptIniPath
            $description = ($gptIniContent | Where-Object { $_ -match "gPCFunctionalityVersion" }) -split "="
            if ($description.Count -gt 1) {
                $gpoDetails.Description = $description[1].Trim()
            }
        }

        # Return the GPO details only if Schannel or Cryptography settings were found
        if ($gpoDetails.Settings.Count -gt 0) {
            return $gpoDetails
        }
    }
    catch {
        Write-Error "Error processing GPO '$gpoGuid' on DC '$domainController': $_"
    }
}

# Get all domain controllers in the domain
$domainControllers = Get-AllDomainControllers

# Store jobs to handle parallel processing
$jobs = @()

# Get all GPOs in the domain from Active Directory
$gpoObjects = Get-ADObject -Filter { objectClass -eq "groupPolicyContainer" } -Property displayName, cn

# Create jobs for each domain controller and process GPOs in parallel
foreach ($domainController in $domainControllers) {
    Write-Host "Starting job for Domain Controller: $domainController"
    
    # Start a job for each domain controller
    $job = Start-Job -ScriptBlock {
        param ($gpoObjects, $domainController)

        # Redefine the function inside the job
        function Get-GPOWithSchannelSettings {
            param (
                [string]$gpoGuid,
                [string]$domainController,
                [string]$gpoName
            )

            # Define the path to the GPO's policy file in the SYSVOL share of the specific DC
            $sysvolPath = "\\$domainController\SYSVOL\$domain\Policies"
            $gpoPath = Join-Path $sysvolPath $gpoGuid
            $gptIniPath = Join-Path $gpoPath "gpt.ini"
            $gpoXmlPath = Join-Path $gpoPath "\Machine\Microsoft\Windows NT\SecEdit\GptTmpl.inf"

            # Create an object to hold GPO details
            $gpoDetails = @{
                GPOGuid         = $gpoGuid
                GPOName         = $gpoName
                Description     = $null
                Settings        = @()
                DomainController = $domainController
            }

            try {
                # Check if the GPO XML path exists (i.e., if the GPO has any machine settings)
                if (Test-Path $gpoXmlPath) {
                    # Read the GptTmpl.inf file, which contains security settings
                    $gptContent = Get-Content -Path $gpoXmlPath

                    # Search for Schannel or Cryptography settings in the file
                    $schannelSettings = $gptContent | Where-Object { $_ -match "*Schannel*|*Cryptography*|*SSL*" }

                    # If any Schannel or Cryptography settings are found, store them in the GPO details
                    if ($schannelSettings) {
                        $gpoDetails.Settings += $schannelSettings
                    }
                }

                # Check if the GPO has a description in the GPT.ini file
                if (Test-Path $gptIniPath) {
                    $gptIniContent = Get-Content $gptIniPath
                    $description = ($gptIniContent | Where-Object { $_ -match "gPCFunctionalityVersion" }) -split "="
                    if ($description.Count -gt 1) {
                        $gpoDetails.Description = $description[1].Trim()
                    }
                }

                # Return the GPO details only if Schannel or Cryptography settings were found
                if ($gpoDetails.Settings.Count -gt 0) {
                    Write-Host "GPO Details available"
                    return $gpoDetails
                }

            }
            catch {
                Write-Error "Error processing GPO '$gpoGuid' on DC '$domainController': $_"
            }
        }

        $gpoWithSchannel = @()
        foreach ($gpo in $gpoObjects) {
            $result = Get-GPOWithSchannelSettings -gpoGuid $gpo.cn -domainController $domainController -gpoName $gpo.displayName
            if ($result) {
                $gpoWithSchannel += $result
            }
        }
        return $gpoWithSchannel

    } -ArgumentList ($gpoObjects, $domainController)

    $jobs += $job
}

# Wait for all jobs to complete
$jobs | ForEach-Object { 
    Write-Host "Waiting for job $_..."
    Wait-Job $_ 
}

# Collect results from each job
$gpoWithSchannel = @()
$jobs | ForEach-Object {
    $gpoWithSchannel += Receive-Job -Job $_
    Remove-Job -Job $_
}

Write-Host "$gpoWithSchannel"
# Output to CSV
$csvPath = "GPO_SchannelSettings.csv"
$gpoWithSchannel | ForEach-Object {
    [PSCustomObject]@{
        GPOName         = $_.GPOName
        Description     = $_.Description
        Settings        = ($_."Settings" -join "; ")  # Join settings into a single string
        DomainController = $_.DomainController
    }
} | Export-Csv -Path $csvPath -NoTypeInformation

# Output to JSON
$jsonPath = "GPO_SchannelSettings.json"
$gpoWithSchannel | ConvertTo-Json | Out-File -FilePath $jsonPath

# Output to HTML
$htmlPath = "GPO_SchannelSettings.html"
$gpoWithSchannel | ForEach-Object {
    [PSCustomObject]@{
        GPOName         = $_.GPOName
        Description     = $_.Description
        Settings        = ($_."Settings" -join "<br>")  # Join settings for better HTML readability
        DomainController = $_.DomainController
    }
} | ConvertTo-Html -Property GPOName, Description, Settings, DomainController | Out-File -FilePath $htmlPath

# Output final paths to the user
Write-Output "Results saved as CSV: $csvPath"
Write-Output "Results saved as JSON: $jsonPath"
Write-Output "Results saved as HTML: $htmlPath"
