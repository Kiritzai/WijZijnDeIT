# Cleaning firewall rules for RDS Servers
# Set-ExecutionPolicy Bypass -Scope Process -Force;
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/FirewallClean.ps1'))

$FWInboundRules       = Get-NetFirewallRule -Direction Inbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner
$FWInboundRulesUnique = Get-NetFirewallRule -Direction Inbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner -Unique
Write-Host "# inbound rules         : " $FWInboundRules.Count
Write-Host "# inbound rules (Unique): " $FWInboundRulesUnique.Count
if ($FWInboundRules.Count -ne $FWInboundRulesUnique.Count) {
Write-Host "# rules to remove       : " (Compare-Object -referenceObject $FWInboundRules  -differenceObject $FWInboundRulesUnique).Count
Compare-Object -referenceObject $FWInboundRules  -differenceObject $FWInboundRulesUnique   | Select-Object -ExpandProperty inputobject |Remove-NetFirewallRule }

$FWOutboundRules       = Get-NetFirewallRule -Direction Outbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner
$FWOutboundRulesUnique = Get-NetFirewallRule -Direction Outbound | Where-Object {$_.Owner -ne $Null} | Sort-Object Displayname, Owner -Unique
Write-Host "# outbound rules         : : " $FWOutboundRules.Count
Write-Host "# outbound rules (Unique): " $FWOutboundRulesUnique.Count
if ($FWOutboundRules.Count -ne $FWOutboundRulesUnique.Count)  {
Write-Host "# rules to remove       : " (Compare-Object -referenceObject $FWOutboundRules  -differenceObject $FWOutboundRulesUnique).Count
Compare-Object -referenceObject $FWOutboundRules  -differenceObject $FWOutboundRulesUnique   | Select-Object -ExpandProperty inputobject |Remove-NetFirewallRule}