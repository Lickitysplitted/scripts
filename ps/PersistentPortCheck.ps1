<# This script will take a list of IPs and hostnames and perform test port connections #>

param(
    [Parameter(Mandatory=$true)]
    [string] $list,
    [Parameter(Mandatory=$true)]
    [string] $port,
    [Parameter(Mandatory=$false)]
    [string] $report
)

function Test-Port{
    foreach ($line in Get-Content $list){
        $Global:ProgressPreference = 'SilentlyContinue'
        $port_result = Test-NetConnection -Port "$port" -ComputerName "$line" -WarningAction SilentlyContinue | Select-Object ComputerName,RemoteAddress,TcpTestSucceeded,PingSucceeded
        $port_result
    }
}

function Test-HostList{
    while ($true) {
        Test-Port | Format-Table
        }
    }

Test-HostList