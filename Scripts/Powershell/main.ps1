# Cleaning firewall rules for RDS Servers
# Set-ExecutionPolicy Bypass -Scope Process -Force;
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/main.ps1'))

function Show-Menu
{
    param (
        [string]$Title = 'WijZijnDe.IT'
    )
    Clear-Host
    Write-Host ""
    Write-Host ""
    Write-Host `t"================ $Title ================"
    Write-Host `t"Press '1' for Testing AD Credentials."
    Write-Host `t"Press '2' for Cleaning Windows Firewall Rules for RDS Servers"
    Write-Host `t"Press '3' for this option."
    Write-Host `t"Press 'q' to quit."
}

do
{
    Show-Menu -Title "WijZijnDe.IT"
    $selection = Read-Host `t"Please make a selection"
    switch ($selection)
    {
        '1' { Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/ActiveDirectoryTestCredentials.ps1')) }
        '2' { Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/FirewallClean.ps1')) }
        '3' { Write-Host 'You chose option #3' }
        #'q' { return }
    }
} until ($selection -eq 'q')

#do
#{
#    Show-Menu
#    $selection = Read-Host "Please make a selection"
#    switch ($selection)
#    {
#        '1' { Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/ActiveDirectoryTestCredentials.ps1')) }
#        '2' { 'You chose option #2' }
#        '3' { 'You chose option #3' }
#    }
#    pause
#}
#until ($selection -eq 'q')