#Requires -RunAsAdministrator

####
## Title
####
(Get-Host).UI.RawUI.WindowTitle = ":: WijZijnDe.IT :: Power Menu :: V0.0.0.3 :: AD Computer List ::"

Clear-Host

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$modules = @("ImportExcel")

foreach ($module in $modules) {
    if ( -Not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module module..."
        Install-Module -Name $module -Force
    } else {
        Import-Module $module
    }
}

$foldername = Get-Random
$folder = "$env:TEMP\$foldername\"
New-Item -Path "$folder" -ItemType "directory" | Out-Null

$xlfile = "$folder\ComputersGeneratedList.xlsx"
Remove-Item $xlfile -ErrorAction SilentlyContinue

# Get Computers
Get-ADComputer -Filter  {OperatingSystem -notLike '*SERVER*' } -Properties lastlogondate,operatingsystem,OperatingSystemVersion,Description,Enabled,IPv4Address,Created,serialNumber |
Select-Object name,lastlogondate,operatingsystem,OperatingSystemVersion,Description,Enabled,IPv4Address,Created,@{N="serialNumber";E={$_.serialNumber -join ","}} |
Sort-Object lastlogondate | Export-Excel $xlfile -AutoSize -FreezeTopRow -StartRow 1 -TableName ReportProcess

$result = @"
File has been generated and saved on the following location:
$xlfile

Press any key to continue
"@

# Opens the folder
explorer "$folder"

$result
$UserInput = $Host.UI.ReadLine()

#Remove-Item $xlfile -ErrorAction SilentlyContinue