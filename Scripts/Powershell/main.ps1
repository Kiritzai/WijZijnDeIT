# Cleaning firewall rules for RDS Servers
# Set-ExecutionPolicy Bypass -Scope Process -Force;
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/main.ps1'))
#
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/main.ps1' -DisableKeepAlive)))

function Show-Menu
{
    param (
        [string]$Title = 'WijZijnDe.IT'
    )
    Clear-Host
    Write-Host ""
    Write-Host ""
    Write-Host "================ $Title ================"
    Write-Host "Press '1' for Testing AD Credentials."
    Write-Host "Press '2' for Cleaning Windows Firewall Rules for RDS Servers"
    Write-Host "Press '3' for this option."
    Write-Host "Press 'q' to quit."
}

Clear-Variable -Name $script
Clear-Variable -Name $runScript
$runScript = [string]::Format('[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -DisableKeepAlive -useb "{0}")))',$script)

do
{
    Show-Menu -Title "WijZijnDe.IT"
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
        '1' { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -DisableKeepAlive -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/ActiveDirectoryTestCredentials.ps1'))) }
        '2' { Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/FirewallClean.ps1')) }
        '3' { $script = 'test.ps11111111111133323423'; write-host $runScript; read-host "test" }
        #'q' { return }
    }
} until ($selection -eq 'q')