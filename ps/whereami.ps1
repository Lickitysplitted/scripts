<# this script will use various methods to determine external ip addresses#>
$dnsipsvc = @(("OpenDNS", "myip.opendns.com", "resolver1.opendns.com"),("Google", "o-o.myaddr.l.google.com", "ns1.google.com"))
$httpipsvc = "checkip.amazonaws.com", "ifconfig.me", "icanhazip.com", "ipecho.net/plain"
Write-Host "DNS Methods`nForced"
foreach ($svc in $dnsipsvc){
    if ($svc[0] -eq "Google"){
        $answer = Resolve-DnsName -Name $svc[1] -Type TXT -Server $svc[2]
        Write-host $svc[0], ": ", $answer.Strings
    }
    else {
        $answer = Resolve-DnsName -Name $svc[1] -Server $svc[2]
        Write-host $svc[0], ": ", $answer.IPAddress
    }
}
Write-Host "`nNative"
foreach ($svc in $dnsipsvc){
    if ($svc[0] -eq "Google"){
        $answer = Resolve-DnsName -Name $svc[1] -Type TXT
        Write-host "Google: ", $answer.Strings
    }
    elseif ($svc[0] -eq "OpenDNS"){
        $answer = Resolve-DnsName -Name $svc[1]
        Write-host "OpenDNS: ", $answer.IPAddress
    }
}
Write-Host "`nHTTP Methods"
foreach ($site in $httpipsvc){
    if ($site -eq "checkip.amazonaws.com"){
        $resp = [System.Text.Encoding]::ASCII.GetString((Invoke-WebRequest -Uri $site).Content)
        Write-Host $site, ": ", $resp
    }
    else {
        $resp = Invoke-WebRequest -Uri $site -Headers @{"Cache-Control"="no-cache"}
        Write-Host $site, ": ", $resp.Content
    }
}