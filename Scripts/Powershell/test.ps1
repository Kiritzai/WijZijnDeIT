# [System.Net.Cache.RequestCacheLevel]::NoCacheNoStore; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/test.ps1' -Headers @{"Cache-Control"="no-cache"}))) -Silent:$true

param (
    [switch]$Silent = $false
)

if ($Silent) {
    Write-Host "Test 3"
    Write-Host "Silent run"
} else {
    Write-Host "Not Silent Run"
}