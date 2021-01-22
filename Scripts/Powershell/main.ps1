# Cleaning firewall rules for RDS Servers
# Set-ExecutionPolicy Bypass -Scope Process -Force;
# [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
# iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/main.ps1'))

do
 {
     Show-Menu –Title 'WijZijnDe.iT Menu'
     $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
         '1' {
             'You chose option #1'
         } '2' {
             'You chose option #2'
         } '3' {
             'You chose option #3'
         }
     }
     pause
 }
 until ($selection -eq 'q')


 function Show-Menu
{
    param (
        [string]$Title = 'My Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' for this option."
    Write-Host "2: Press '2' for this option."
    Write-Host "3: Press '3' for this option."
    Write-Host "Q: Press 'Q' to quit."
}