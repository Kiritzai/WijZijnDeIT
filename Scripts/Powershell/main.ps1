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
[string]$ncVer = "0.0.0.8"
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
$packageProviders = Get-PackageProvider | select name
if(!($packageProviders.name -contains "nuget")) {
    Write-Host "Installing nuGet package..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Scope CurrentUser | Out-Null
}

if ((Get-PackageProvider -Name NuGet).Version -lt '2.8.5.208' ) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Scope CurrentUser | Out-Null
}

if ((Get-CimInstance -ClassName CIM_OperatingSystem).Caption -like '*Windows 10*') {
    Write-Host "Installing AD Tools"
    Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat.ActiveDirectory.DS-LDS.Tools*" -and $_.State -eq "NotPresent"} | Add-WindowsCapability -Online | Out-Null
}

if ((Get-CimInstance -ClassName CIM_OperatingSystem).Caption -like '*Windows Server*') {
    Write-Host "Installing AD Tools"
    Import-Module ServerManager
    $rsatAD = Get-WindowsFeature | Where-Object {$_.Name -eq "RSAT-AD-PowerShell"}
    if(!$rsatAD.Installed) { Install-WindowsFeature -Name RSAT-AD-PowerShell }
}



function Show-Menu
{
    [cmdletbinding()]
    param (
        [string]$foregroundcolor = "Green"
    )
    Clear-Host
    Write-Host `n"# $Title v" $ncVer "#"`n -ForeGroundColor $foregroundcolor
    $textMenu = @"
=========================== General ============================
Press 'G1' for Cleaning Windows Firewall Rules for RDS Servers
Press 'G2' for Search and Close selected files
================================================================

======================= Active Directory =======================
Press 'A1' for ActiveDirectory Testing Credentials
Press 'A2' for ActiveDirectory Generating User List
Press 'A3' for ActiveDirectory Generating Computer List
Press 'A4' for ActiveDirectory Users in Groups List
================================================================

=========================== Software ===========================
Press 'S1' for Installing Microsoft Edge
Press 'S2' for Installing Microsoft OneDrive
================================================================

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
        'G1' { $script = "Scripts/Powershell/FirewallClean.ps1" }
        'G2' { $script = "Scripts/Powershell/SearchCloseFile.ps1" }
        'A1' { $script = "Scripts/Powershell/ActiveDirectoryTestCredentials.ps1" }
        'A2' { $script = "Scripts/Powershell/ActiveDirectoryUserList.ps1" }
        'A3' { $script = "Scripts/Powershell/ActiveDirectoryComputerList.ps1" }
        'A4' { $script = "Scripts/Powershell/ActiveDirectoryUsersinGroups.ps1" }
        'S1' { $script = "Scripts/Powershell/SoftwareMicrosoftEdge.ps1" }
        'S2' { $script = "Scripts/Powershell/SoftwareOneDrive.ps1" }
        'c' { $script = "Scripts/Powershell/CreateShortcut.ps1" }
    }

    if ($selection -ne 'q') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -DisableKeepAlive -useb "https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/$script")))
    }

} until ($selection -eq 'q')