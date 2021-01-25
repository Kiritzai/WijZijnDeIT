# Cleaning firewall rules for RDS Servers
# Set-ExecutionPolicy Bypass -Scope Process -Force;
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/FirewallClean.ps1'))
#
# Add this registry key to make sure rules are removed
# [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy", "DeleteUserAppContainersOnLogoff", 1)
#

Clear-Host

Write-Host ""
Write-Host "Getting all Firewall Rules... ( This can take a while )"
Write-Host ""

$FWInboundRules       = Get-NetFirewallRule -Direction Inbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner
$FWInboundRulesUnique = Get-NetFirewallRule -Direction Inbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner -Unique

$FWOutboundRules       = Get-NetFirewallRule -Direction Outbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner
$FWOutboundRulesUnique = Get-NetFirewallRule -Direction Outbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner -Unique

$FWInbountCount         = $FWInboundRules.Count
$FWInbountUniqueCount   = $FWInboundRulesUnique.Count
$FWOutbountCount        = $FWOutboundRules.Count
$FWOutbountUniqueCount  = $FWOutboundRulesUnique.Count

$FWInboundRulesRemoval = (Compare-Object -referenceObject $FWInboundRules -differenceObject $FWInboundRulesUnique).Count
$FWOutboundRulesRemoval = (Compare-Object -referenceObject $FWOutboundRules -differenceObject $FWOutboundRulesUnique).Count

$output = @"
Inbound rules               $FWInbountCount
Inbound rules (Unique)      $FWInbountUniqueCount
Outbound rules              $FWOutbountCount
Outbound rules (Unique)     $FWOutbountUniqueCount

Inbound rules to remove     $FWInboundRulesRemoval
Outbound rules to remove    $FWOutboundRulesRemoval
"@

$output

Write-Host ""
$confirmation = Read-Host "Would you like to remove firewall rules? (y/n)"
if ($confirmation -eq 'y') {
    
    if ($FWInboundRules.Count -ne $FWInboundRulesUnique.Count) {
        Compare-Object -referenceObject $FWInboundRules -differenceObject $FWInboundRulesUnique | Select-Object -ExpandProperty inputobject | Remove-NetFirewallRule
    }

    if ($FWOutboundRules.Count -ne $FWOutboundRulesUnique.Count) {
        Compare-Object -referenceObject $FWOutboundRules -differenceObject $FWOutboundRulesUnique | Select-Object -ExpandProperty inputobject | Remove-NetFirewallRule
    }

} else {
    Write-Host "No"
}

Write-Host ""
Write-Host "Firewall rules removed!" -ForegroundColor Green
$UserInput = $Host.UI.ReadLine()