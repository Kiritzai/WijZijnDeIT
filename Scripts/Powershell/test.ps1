# [System.Net.Cache.RequestCacheLevel]::NoCacheNoStore; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/test.ps1' -DisableKeepAlive))) -Silent:$true


if ( -Not (Get-PackageProvider -Name 'NuGet')) {
    Write-Host "Installing NuGet module..."
    Install-Module -Name $module -Force
}