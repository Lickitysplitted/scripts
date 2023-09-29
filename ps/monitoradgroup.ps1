<# This script will monitor a given ad group for changes in members #>

param(
    [Parameter()]
    [string] $identity,
    [Parameter()]
    [string] $interval = 30
)

function Watch-ADGroupMembers{
    $starttime = Get-Date
    $members = Get-ADGroupMember -Identity $identity
    $membernames = $members | Select-Object Name
    $startstate = $members | Measure-Object
    $monitorstate = $startstate
    Write-Host $membernames.Name
    while($monitorstate.Count -eq $startstate.Count){
        $currenttime = Get-Date
        $elapsedtime = New-TimeSpan -Start $starttime -End $currenttime
        Write-Host "Member Count:",$startstate.Count,"Elapsed Time:",$elapsedtime,"Sleep:",$interval,"seconds"
        Start-Sleep $interval
        $monitorstate = Get-ADGroupMember -Identity $identity | Measure-Object
    }
    $newstate = Get-ADGroupMember -Identity $identity | Select-Object Name
    $newstate | Where-Object -Property Name -NE -Value $membernames
}

Watch-ADGroupMembers