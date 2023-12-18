<# This script will take a list of IPs and hostnames and perform test port connections #>

param(
    [Parameter(Mandatory=$true)]
    [string] $list,
    [Parameter(Mandatory=$true)]
    [string] $port
)

# function Test-Ping{
#     foreach ($line in Get-Content $list){
#         $ping_result = Test-NetConnection -ComputerName "$line" | Select-Object ComputerName,RemoteAddress
#         $ping_result
#     }
# }

function Test-Port{
    foreach ($line in Get-Content $list){
        $port_result = Test-NetConnection -Port "$port" -ComputerName "$line" -WarningAction SilentlyContinue | Select-Object ComputerName,RemoteAddress,TcpTestSucceeded,PingSucceeded
        $port_result
    }
}

function Test-HostList{
    while ($true) {
        # Test-Ping | Format-Table
        Test-Port | Format-Table
        Write-Host "=====+++++=====+++++"
        Start-Sleep -Seconds 30
        }
    }

Test-HostList