<# 
.SYNOPSIS
    This script monitors an Active Directory group for changes in its membership.

.DESCRIPTION
    It checks the group members at regular intervals, compares the current state with the initial state,
    and outputs the names of members who are added or removed.

.PARAMETER identity
    The name or Distinguished Name (DN) of the AD group to monitor.

.PARAMETER interval
    The time interval (in seconds) to wait between each check. Defaults to 30 seconds.

.NOTES
    Author: [Your Name]
    Date: [Date]
#>

param(
    [Parameter(Mandatory=$true)]
    [string] $identity,

    [Parameter()]
    [int] $interval = 30
)

# Function to watch AD group members with logging and error handling
function Watch-ADGroupMembers {
    try {
        $starttime = Get-Date
        $members = Get-ADGroupMember -Identity $identity -ErrorAction Stop
        $membernames = $members | Select-Object Name
        $startstate = $members | Measure-Object
        $monitorstate = $startstate
        Write-Host "Initial members of the group: $($membernames.Name)"
        
        while ($monitorstate.Count -eq $startstate.Count) {
            $currenttime = Get-Date
            $elapsedtime = New-TimeSpan -Start $starttime -End $currenttime
            Write-Host "Member Count:", $startstate.Count, "Elapsed Time:", $elapsedtime, "Sleep:", $interval, "seconds"
            Start-Sleep -Seconds $interval

            # Check the group members again
            $monitorstate = Get-ADGroupMember -Identity $identity | Measure-Object
        }
        
        # If a change in member count is detected, display the differences
        $newstate = Get-ADGroupMember -Identity $identity | Select-Object Name
        $addedMembers = Compare-Object $membernames.Name $newstate.Name -PassThru | Where-Object { $_.SideIndicator -eq '=>' }
        $removedMembers = Compare-Object $membernames.Name $newstate.Name -PassThru | Where-Object { $_.SideIndicator -eq '<=' }

        if ($addedMembers) {
            Write-Host "New members added:"
            $addedMembers
        }
        if ($removedMembers) {
            Write-Host "Members removed:"
            $removedMembers
        }

    } catch {
        Write-Error "An error occurred: $_"
        exit 1
    }
}

# Validate if AD group exists
if (-Not (Get-ADGroup -Identity $identity -ErrorAction SilentlyContinue)) {
    Write-Error "The AD group $identity does not exist."
    exit 1
}

# Start monitoring the AD group
Watch-ADGroupMembers
