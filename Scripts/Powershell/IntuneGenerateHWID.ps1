
Clear-Host

Write-Host `n"Generating HWID.."

New-Item -Path c:\programdata\customscripts -ItemType Directory -Force -Confirm:$false | out-null
Install-PackageProvider -name nuget -minimumversion 2.8.5.200 -Force -Scope CurrentUser | out-null
Save-Script -Name Get-WindowsAutoPilotInfo -Path c:\ProgramData\CustomScripts -force | out-null
$sn = (Get-WmiObject win32_bios).SerialNumber
$pcname = $env:COMPUTERNAME
$file = $pcname + "_" + $sn
New-Item -Path c:\HWID -ItemType Directory -Force -Confirm:$false | out-null
C:\ProgramData\CustomScripts\Get-WindowsAutoPilotInfo.ps1 -OutputFile c:\HWID\$file.csv

Write-Host "HWID Generated!"

# Opens the folder
explorer "c:\HWID"

Write-Host `n"Continue?"
$UserInput = $Host.UI.ReadLine()