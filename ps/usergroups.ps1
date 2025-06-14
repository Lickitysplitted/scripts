<#
.SYNOPSIS
Fetches and displays all AD groups a user is a member of in a table format.

.DESCRIPTION
This script uses Active Directory cmdlets to query and list all groups a user belongs to.
It outputs group details, including Group Name, Group Description, and Distinguished Name.

.PARAMETER Username
Specifies the username (SamAccountName) to search for.

.NOTES
- Requires Active Directory module.
- Ensure the user running the script has the necessary permissions.

#>

param (
    [Parameter(Mandatory = $true, HelpMessage = "Enter the username (SamAccountName) to search for.")]
    [string]$Username
)

# Import Active Directory module
try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Write-Error "The Active Directory module is not available. Please ensure it is installed and loaded."
    exit 1
}

# Fetch user groups
try {
    $User = Get-ADUser -Identity $Username -Properties MemberOf -ErrorAction Stop
    $GroupDNs = $User.MemberOf

    if ($GroupDNs.Count -eq 0) {
        Write-Host "The user '$Username' is not a member of any groups." -ForegroundColor Yellow
        exit 0
    }

    # Fetch detailed group information
    $Groups = $GroupDNs | ForEach-Object {
        Get-ADGroup -Identity $_ -Properties Description | Select-Object Name, Description, DistinguishedName
    }

    # Display groups in a table format
    $Groups | Format-Table -AutoSize
} catch {
    Write-Error "An error occurred: $_"
}
