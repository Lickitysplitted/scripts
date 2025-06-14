<# 
.SYNOPSIS
    This script continuously checks port connectivity for a list of IPs/hostnames.

.DESCRIPTION
    The script reads from a list of IPs or hostnames, tests connectivity to a specified port,
    and outputs the results in a table. It runs continuously, testing at regular intervals.

.PARAMETER list
    The file path containing the list of IPs or hostnames to test.

.PARAMETER port
    The port number to check connectivity on.

.PARAMETER report
    Optional parameter to save results to a CSV file for reporting.

.NOTES
    Author: [Your Name]
    Date: [Date]
#>

param(
    [Parameter(Mandatory=$true)]
    [string] $list,

    [Parameter(Mandatory=$true)]
    [int] $port,  # Port should be an integer

    [Parameter(Mandatory=$false)]
    [string] $report
)

# Function to validate port number
function Validate-Port {
    if ($port -lt 1 -or $port -gt 65535) {
        Write-Error "Port number must be between 1 and 65535."
        exit 1
    }
}

# Function to test port connectivity with error handling and logging
function Test-Port {
    foreach ($line in Get-Content $list) {
        $Global:ProgressPreference = 'SilentlyContinue'
        try {
            $port_result = Test-NetConnection -Port "$port" -ComputerName "$line" -WarningAction SilentlyContinue | 
                Select-Object ComputerName, RemoteAddress, TcpTestSucceeded, PingSucceeded
            if ($port_result.TcpTestSucceeded) {
                Write-Host "Connection successful: $($port_result.ComputerName)"
            } else {
                Write-Warning "Failed connection: $($port_result.ComputerName)"
            }
            # Optionally log results
            if ($report) {
                $port_result | Export-Csv -Path $report -Append -NoTypeInformation
            }
        } catch {
            Write-Error "Error testing connection to $line: $_"
        }
    }
}

# Function to test the list of hosts continuously
function Test-HostList {
    while ($true) {
        Test-Port | Format-Table
        Start-Sleep -Seconds 30  # Optionally add a sleep period to avoid constant checks
    }
}

# Validate the input port before starting
Validate-Port

# Check if the list file exists
if (-Not (Test-Path $list)) {
    Write-Error "The file $list does not exist."
    exit 1
}

# Start monitoring the host list
Test-HostList
