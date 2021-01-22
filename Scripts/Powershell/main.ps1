# Cleaning firewall rules for RDS Servers
# Set-ExecutionPolicy Bypass -Scope Process -Force;
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/main.ps1'))

function Show-Menu
{
    param (
        [string]$Title = 'My Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "Press '1' for Testing AD Credentials."
    Write-Host "Press '2' for this option."
    Write-Host "Press '3' for this option."
    Write-Host "Press 'Q' to quit."
}

do
 {
     Show-Menu –Title 'WijZijnDe.iT'
     $selection = Read-Host "Please make a selection"
     switch ($selection)
    {
        '1' { Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/ActiveDirectoryTestCredentials.ps1')) }
        '2' { 'You chose option #2' }
        '3' { 'You chose option #3' }
    }
    pause
 }
 until ($selection -eq 'q')


