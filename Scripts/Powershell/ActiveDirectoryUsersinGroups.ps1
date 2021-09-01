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

# Generate random foldername
$foldername = Get-Random
$folder = "$env:TEMP\$foldername\"
New-Item -Path "$folder" -ItemType "directory" | Out-Null

# Get Groups
$groups = Get-ADGroup -Filter "GroupScope -ne 'DomainLocal'" -Properties Members
foreach ($group in $groups) {
    $name = $group.name
    $xlfile = "$folder\$name.xlsx"
    Remove-Item $xlfile -ErrorAction SilentlyContinue

    try {
        Get-ADGroupMember -Identity "$name" |
        Select-Object name,SamAccountName,distinguishedName,SID |
        Sort-Object name |
        Export-Excel $xlfile -AutoSize -AutoFilter -FreezeTopRow -TableName ReportProcess | Out-Null    
    }
    catch {}
    
}


$result = @"
File(s) have been generated and saved on the following location:
$folder

Press any key to continue
"@

# Opens the folder
explorer "$folder"

$result
$UserInput = $Host.UI.ReadLine()

#Remove-Item $xlfile -ErrorAction SilentlyContinue