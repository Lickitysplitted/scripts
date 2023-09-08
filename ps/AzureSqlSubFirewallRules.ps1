param(
    [Parameter (Mandatory)][String]$Subscription
)
function Get-AzSqlSubFirewallRules{
    Set-AzContext -Subscription $Subscription > $null
    
    $SqlServers = Get-AzResourceGroup | Get-AzSqlServer
    
    foreach ($SqlServer in $SqlServers){
        Get-AzSqlServerFirewallRule -ResourceGroupName $SqlServer.ResourceGroupName -ServerName $SqlServer.ServerName
    }
}

Get-AzSqlSubFirewallRules -Subscription $Subscription