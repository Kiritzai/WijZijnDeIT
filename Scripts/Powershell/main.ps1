#
# Set-ExecutionPolicy Bypass -Scope Process -Force;
#
#
# Run powershell script by running one of the following 2 commands below
#
# Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/main.ps1'))
#
# Set-ExecutionPolicy Bypass -Scope Process -Force; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -DisableKeepAlive -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/main.ps1')))
#

###
# Variables
###
[string]$ncVer = "0.0.0.7"
[string]$Title = "WijZijnDe.IT"

####
## Clean Console
####
Clear-Host
Write-Host ""
Write-Host "Loading please wait..."

####
## Install required packages
####
if ((Get-PackageProvider -Name NuGet).Version -lt '2.8.5.201' ) {
    Write-Host "Installing nuGet package..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
}

if ((Get-CimInstance -ClassName CIM_OperatingSystem).Caption -match 'Windows 10') {
    Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat.ActiveDirectory.DS-LDS.Tools*" -and $_.State -eq "NotPresent"} | Add-WindowsCapability -Online | Out-Null
} else {
    Import-Module ServerManager
    $rsatAD = Get-WindowsFeature | Where-Object {$_.Name -eq "RSAT-AD-PowerShell"}
    if($rsatAD.Installed -eq "False") { Install-WindowsFeature -Name RSAT-AD-PowerShell }
}



function Show-Menu
{
    [cmdletbinding()]
    param (
        [string]$foregroundcolor = "Green"
    )
    Clear-Host
    Write-Host `n"$Title v" $ncVer "#"`n -ForeGroundColor $foregroundcolor
    $textMenu = @"
================ $Title ================
Press '1' for ActiveDirectory Testing Credentials
Press '2' for ActiveDirectory Generating User List
Press '3' for ActiveDirectory Generating Computer List
Press '4' for ActiveDirectory Users in Groups List
Press '5' for Cleaning Windows Firewall Rules for RDS Servers
Press '6' for Search and Close selected files
============================================================

Press 'c' for Creating a shortcut of this menu on desktop
Press 'q' to quit.

"@
$textMenu

}

do
{
    (Get-Host).UI.RawUI.WindowTitle = ":: WijZijnDe.IT :: Power Menu :: $ncVer ::"

    Clear-Variable script -ErrorAction SilentlyContinue

    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
        '1' { $script = "Scripts/Powershell/ActiveDirectoryTestCredentials.ps1" }
        '2' { $script = "Scripts/Powershell/ActiveDirectoryUserList.ps1" }
        '3' { $script = "Scripts/Powershell/ActiveDirectoryComputerList.ps1" }
        '4' { $script = "Scripts/Powershell/ActiveDirectoryUsersinGroups.ps1" }
        '5' { $script = "Scripts/Powershell/FirewallClean.ps1" }
        '6' { $script = "Scripts/Powershell/SearchCloseFile.ps1" }
        'c' { $script = "Scripts/Powershell/CreateShortcut.ps1" }
    }

    if ($selection -ne 'q') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -DisableKeepAlive -useb "https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/$script")))
    }

} until ($selection -eq 'q')