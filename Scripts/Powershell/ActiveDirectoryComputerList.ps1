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
}

$modules = @("ImportExcel")

foreach ($module in $modules) {
    if ( -Not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module module..."
        Install-Module -Name $module -Force
    }
}

#Get-ADComputer -Filter  {OperatingSystem -notLike '*SERVER*' } -Properties lastlogondate,operatingsystem,OperatingSystemVersion | select name,lastlogondate,operatingsystem,OperatingSystemVersion | Export-Csv C:\Temp\users.csv

# Get domain
#$sDomain = (Get-ADDomain).Forest

$xlfile = "$env:TEMP\ComputersGeneratedList.xlsx"
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

$result
$UserInput = $Host.UI.ReadLine()

#Remove-Item $xlfile -ErrorAction SilentlyContinue