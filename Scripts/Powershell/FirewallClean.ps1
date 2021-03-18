# Cleaning firewall rules for RDS Servers
# Set-ExecutionPolicy Bypass -Scope Process -Force;
# NEW VERSION
#
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/FirewallClean.ps1'))) -Silent:$true
# [System.Net.Cache.RequestCacheLevel]::NoCacheNoStore; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/FirewallClean.ps1'))) -Silent:$true
#
# 
# Add this registry key to make sure rules are removed
# [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy", "DeleteUserAppContainersOnLogoff", 1)
#

param (
    [switch]$Silent = $false
)

Clear-Host

$infoText = @"
!!Caution!!
Make sure that no users are logged on this server besides an administrator.
It can cause problems with login/logout proccess of a session.

This script can also be run silent by using the following command:
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/FirewallClean.ps1'))) -Silent:$true

Getting all Firewall Rules... ( This can take a while )
"@

$infoText

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

if ($Silent) {

    Write-Host "Removing Inbound rules..." -ForegroundColor Yellow

    if ($FWInboundRules.Count -ne $FWInboundRulesUnique.Count) {
        Compare-Object -referenceObject $FWInboundRules -differenceObject $FWInboundRulesUnique | Select-Object -ExpandProperty inputobject | Remove-NetFirewallRule
    }

    Write-Host "Removing Outbound rules..." -ForegroundColor Yellow

    if ($FWOutboundRules.Count -ne $FWOutboundRulesUnique.Count) {
        Compare-Object -referenceObject $FWOutboundRules -differenceObject $FWOutboundRulesUnique | Select-Object -ExpandProperty inputobject | Remove-NetFirewallRule
    }

} else {

    Write-Host ""
    $confirmation = Read-Host "Would you like to remove firewall rules? (y/n)"
    Write-Host ""
    if ($confirmation -eq 'y') {
    
        Write-Host "Removing Inbound rules..." -ForegroundColor Yellow
    
        if ($FWInboundRules.Count -ne $FWInboundRulesUnique.Count) {
            Compare-Object -referenceObject $FWInboundRules -differenceObject $FWInboundRulesUnique | Select-Object -ExpandProperty inputobject | Remove-NetFirewallRule
        }
    
        Write-Host "Removing Outbound rules..." -ForegroundColor Yellow
    
        if ($FWOutboundRules.Count -ne $FWOutboundRulesUnique.Count) {
            Compare-Object -referenceObject $FWOutboundRules -differenceObject $FWOutboundRulesUnique | Select-Object -ExpandProperty inputobject | Remove-NetFirewallRule
        }
    
        
        Write-Host "Firewall rules removed!" -ForegroundColor Green
    
    } else {
        Write-Host "Cancelled" -ForegroundColor Red
    }
}

$UserInput = $Host.UI.ReadLine()