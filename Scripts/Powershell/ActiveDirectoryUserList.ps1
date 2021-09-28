#Requires -RunAsAdministrator

####
## Title
####
(Get-Host).UI.RawUI.WindowTitle = ":: WijZijnDe.IT :: Power Menu :: V0.0.0.3 :: AD User List ::"

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

# Get domain
$sDistDomain = (Get-ADDomain).DistinguishedName
$sDistDomain = "*CN=Users,$sDistDomain"

$foldername = Get-Random
$folder = "$env:TEMP\$foldername\"
New-Item -Path "$folder" -ItemType "directory" | Out-Null

$xlfile = "$folder\UsersGeneratedList.xlsx"
Remove-Item $xlfile -ErrorAction SilentlyContinue

# Get Computers
Get-ADUser -Filter * -Properties sAMAccountName,name,mail,title,userPrincipalName,lastlogondate,Enabled,Created,DistinguishedName,Description |
Where-Object { $_.DistinguishedName -notlike "$sDistDomain" } |
Select-Object sAMAccountName,name,mail,title,userPrincipalName,lastlogondate,Enabled,Created,DistinguishedName,Description |
Sort-Object lastlogondate | Export-Excel $xlfile -AutoSize -BoldTopRow -FreezeTopRow -StartRow 1 -TableName ReportProcess

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