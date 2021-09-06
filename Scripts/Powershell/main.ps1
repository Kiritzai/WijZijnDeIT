#
# Set-ExecutionPolicy Bypass -Scope Process -Force;
#
#
# Run powershell script by running one of the following 2 commands below
#
# Set-ExecutionPolicy Bypass -Scope Process -Force; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -Headers @{"Cache-Control"="no-cache"} -DisableKeepAlive -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/main.ps1')))
#



# Check for administrator rights
#If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
#    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
#    $UserInput = $Host.UI.ReadLine()
#    Exit
#}

###
# Globals
###
$global:progressPreference = 'silentlyContinue'

###
# Variables
###
[string]$ncVer = "0.0.1.1"
[string]$Title = "WijZijnDe.IT"


# Disable first Run Explorer
[microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\Main", "DisableFirstRunCustomize", 2)


####
## Clean Console
####
Clear-Host
Write-Host ""
Write-Host "Loading please wait..."

####
## Install required packages
####
if((Get-PackageProvider | Select-Object name).name -notcontains "nuget" -or (Get-PackageProvider | Select-Object name,version | Where-Object {$_.Name -contains "nuget"}).Version -lt '2.8.5.208' ) {
    Write-Host "Installing NuGet latest version"
    Install-PackageProvider -name nuget -minimumversion 2.8.5.208 -Force -Scope CurrentUser | out-null
}

if ((Get-CimInstance -ClassName CIM_OperatingSystem).Caption -match 'Windows 10') {
    Write-Host "Installing AD Tools"
    Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat.ActiveDirectory.DS-LDS.Tools*" -and $_.State -eq "NotPresent"} | Add-WindowsCapability -Online | Out-Null
}

if ((Get-CimInstance -ClassName CIM_OperatingSystem).Caption -match 'Windows Server') {
    Write-Host "Installing AD Tools"
    Import-Module ServerManager
    Get-WindowsFeature | Where-Object {$_.Name -eq "RSAT-AD-PowerShell" -and $_.InstallState -ne "Installed"} | Install-WindowsFeature | Out-Null
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

============================= TPM ==============================
Press 'S1' for Getting TPM Version
Press 'S2' for Reset and Upgrade TPM
================================================================

======================= Microsoft Intune =======================
Press 'M1' for Generating HWID File
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
        'T1' { $script = "Scripts/Powershell/TpmGetVersion.ps1" }
        'T2' { $script = "Scripts/Powershell/TpmReset.ps1" }
        'M1' { $script = "Scripts/Powershell/IntuneGenerateHWID.ps1" }
        'c' { $script = "Scripts/Powershell/CreateShortcut.ps1" }
    }

    if ($selection -ne 'q') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -Headers @{"Cache-Control"="no-cache"} -DisableKeepAlive -useb "https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/$script")))
    }

} until ($selection -eq 'q')