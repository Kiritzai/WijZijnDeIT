#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; &([scriptblock]::Create((Invoke-WebRequest -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/test.ps1'))) -Silent:$true

param (
    [switch]$Silent = $false
)

if ($Silent) {
    Write-Host "Silent run"
} else {
    Write-Host "Not Silent Run"
}