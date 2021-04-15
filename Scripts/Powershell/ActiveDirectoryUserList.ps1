#Requires -RunAsAdministrator

Clear-Host

# Company Name
#Read-Host $sCompanyName = 'Enter Company Name'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

#
# Installing Modules
#
if ((Get-CimInstance -ClassName CIM_OperatingSystem).Caption -match 'Windows 10') {
    Add-WindowsCapability –online –Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
} else {
    Import-Module ServerManager
    $rsatAD = Get-WindowsFeature | Where-Object {$_.Name -eq "RSAT-AD-PowerShell"}
    if($rsatAD.Installed -eq "False") { Install-WindowsFeature -Name RSAT-AD-PowerShell }
}

$modules = @("ImportExcel")

foreach ($module in $modules) {
    if ( -Not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module module..."
        Install-Module -Name $module -Force
    }
}

# Get domain
#$sDomain = (Get-ADDomain).Forest

$xlfile = "$env:TEMP\UsersGeneratedList.xlsx"
Remove-Item $xlfile -ErrorAction SilentlyContinue

# Get Computers
Get-ADUser -Filter * -Properties name,lastlogondate,Description,Enabled,Created,DistinguishedName |
Select-Object name,lastlogondate,Description,Enabled,Created,DistinguishedName |
Sort-Object lastlogondate | Export-Excel $xlfile -AutoSize -FreezeTopRow -StartRow 1 -TableName ReportProcess

$result = @"
File has been generated and saved on the following location:
$xlfile

Press any key to continue
"@

# Opens the folder
explorer "$env:TEMP"

$result
$UserInput = $Host.UI.ReadLine()

#Remove-Item $xlfile -ErrorAction SilentlyContinue