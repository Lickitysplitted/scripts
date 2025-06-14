<# 
.SYNOPSIS
    This script determines the system's external IP address using DNS and HTTP methods.
.DESCRIPTION
    The script queries various DNS and HTTP services to obtain the external IP address of the system.
.NOTES
    Author: [Your Name]
    Date: [Date]
.EXAMPLE
    .\whereami.ps1
#>

$dnsipsvc = @(("OpenDNS", "myip.opendns.com", "resolver1.opendns.com"), ("Google", "o-o.myaddr.l.google.com", "ns1.google.com"))
$httpipsvc = "checkip.amazonaws.com", "ifconfig.me", "icanhazip.com", "ipecho.net/plain"

# Function to query DNS for external IP
function Get-DNSExternalIP {
    param ($svcName, $queryName, $server)
    try {
        $answer = Resolve-DnsName -Name $queryName -Server $server
        Write-Host "'$svcName': $($answer.IPAddress)"
    }
    catch {
        Write-Warning "Error resolving '$svcName': $_"
    }
}

# Function to query HTTP services for external IP
function Get-HTTPExternalIP {
    param ($url)
    try {
        $resp = Invoke-WebRequest -Uri $url -TimeoutSec 5
        Write-Host "$url : $($resp.Content)"
    }
    catch {
        Write-Warning "Error fetching from $url : $_"
    }
}

# Query DNS methods
Write-Host "DNS Methods"
foreach ($svc in $dnsipsvc) {
    Get-DNSExternalIP $svc[0] $svc[1] $svc[2]
}

# Query HTTP methods
Write-Host "`nHTTP Methods"
foreach ($site in $httpipsvc) {
    Get-HTTPExternalIP $site
}
