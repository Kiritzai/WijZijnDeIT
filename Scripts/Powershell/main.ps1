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


<#
    .SYNOPSIS
        Displays a selection menu and returns the selected item
    
    .DESCRIPTION
        Takes a list of menu items, displays the items and returns the user's selection.
        Items can be selected using the up and down arrow and the enter key.
    
    .PARAMETER MenuItems
        List of menu items to display
    
    .PARAMETER MenuPrompt
        Menu prompt to display to the user.
    
    .EXAMPLE
        PS C:\> Get-MenuSelection -MenuItems $value1 -MenuPrompt 'Value2'
    
    .NOTES
        Additional information about the function.
#>
function Get-MenuSelection
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$MenuItems,
        [Parameter(Mandatory = $true)]
        [String]$MenuPrompt
    )
    # store initial cursor position
    $cursorPosition = $host.UI.RawUI.CursorPosition
    $pos = 0 # current item selection
    
    #==============
    # 1. Draw menu
    #==============
    function Write-Menu
    {
        param (
            [int]$selectedItemIndex
        )
        # reset the cursor position
        $Host.UI.RawUI.CursorPosition = $cursorPosition
        # Padding the menu prompt to center it
        $prompt = $MenuPrompt
        $maxLineLength = ($MenuItems | Measure-Object -Property Length -Maximum).Maximum + 4
        #while ($prompt.Length -lt $maxLineLength+4)
        #{
            $count = "== $prompt - v$($ncVer) ==========================="
            $total = ""
            for ($i = 0; $i -lt ($count | Measure-Object -Character).Characters; $i++) {
                $total += "="
            }
            $prompt = "`n $total`n $count`n $total`n"
        #}
        Write-Host $prompt -ForegroundColor Green
        # Write the menu lines
        for ($i = 0; $i -lt $MenuItems.Count; $i++)
        {
            $line = "    $($MenuItems[$i])" + (" " * ($maxLineLength - $MenuItems[$i].Length))
            if ($selectedItemIndex -eq $i)
            {
                Write-Host $line -ForegroundColor Blue -BackgroundColor Gray
            }
            else
            {
                Write-Host $line
            }
        }
    }
    
    Write-Menu -selectedItemIndex $pos
    $key = $null
    while ($key -ne 13)
    {
        #============================
        # 2. Read the keyboard input
        #============================
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $key = $press.virtualkeycode
        if ($key -eq 38)
        {
            $pos--
        }
        if ($key -eq 40)
        {
            $pos++
        }
        #handle out of bound selection cases
        if ($pos -lt 0) { $pos = 0 }
        if ($pos -eq $MenuItems.count) { $pos = $MenuItems.count - 1 }
        
        #==============
        # 1. Draw menu
        #==============
        Write-Menu -selectedItemIndex $pos
    }

    Clear-Host
    return $MenuItems[$pos]
    #return $pos
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
Press 'T1' for Getting TPM Version
Press 'T2' for Reset and Upgrade TPM
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

    # Wiping everything clean :)
    Clear-Host

    # Just making sure script variable is empty
    Clear-Variable script -ErrorAction SilentlyContinue

    $mainMenu = Get-MenuSelection -MenuItems "General", "Active Directory", "Software", "!! Danger !!", "Exit" -MenuPrompt "Main Menu"
    
    # Main Menu
    switch ($mainMenu) {
        "General" { # General Menu
            $generalMenu = Get-MenuSelection -MenuItems "Return to Main Menu", `
                                                        "Cleaning Windows Firewall Rules for RDS Servers", `
                                                        "Search and Close selected files" `
                                                    -MenuPrompt "General"

            switch ($generalMenu) {
                "Cleaning Windows Firewall Rules for RDS Servers"   { $script = "Scripts/Powershell/FirewallClean.ps1" }
                "Search and Close selected files"                   { $script = "Scripts/Powershell/SearchCloseFile.ps1" }
            }
        }
        "Active Directory" { # Active Directory Menu
            $adMenu = Get-MenuSelection -MenuItems "Return to Main Menu", `
                                                    "Testing Credentials", `
                                                    "Generating User List", `
                                                    "Generating Computer List", `
                                                    "Users in Groups List" `
                                                    -MenuPrompt "Active Directory"

            switch ($adMenu) {
                "Testing Credentials"                               { $script = "Scripts/Powershell/ActiveDirectoryTestCredentials.ps1" }
                "Generating User List"                              { $script = "Scripts/Powershell/ActiveDirectoryUserList.ps1" }
                "Generating Computer List"                          { $script = "Scripts/Powershell/ActiveDirectoryComputerList.ps1" }
                "Users in Groups List"                              { $script = "Scripts/Powershell/ActiveDirectoryUsersinGroups.ps1" }
            }
        }
        "Software" { # Software Menu
            $softwareMenu = Get-MenuSelection -MenuItems "Return to Main Menu", `
                                                    "Installing Microsoft Edge", `
                                                    "Installing Microsoft OneDrive" `
                                                    -MenuPrompt "Software"

            switch ($softwareMenu) {
                "Installing Microsoft Edge"                               { $script = "Scripts/Powershell/SoftwareMicrosoftEdge.ps1" }
                "Installing Microsoft OneDrive"                           { $script = "Scripts/Powershell/SoftwareOneDrive.ps1" }
            }
        }
        "!! Danger !!" { # Danger Menu
            $dangerMenu = Get-MenuSelection -MenuItems "Return to Main Menu", `
                                                    "Reset and Wipe Computer" `
                                                    -MenuPrompt "!! Danger !!"

            switch ($dangerMenu) {
                "Reset and Wipe Computer"                           { $script = "Scripts/Powershell/DangerWipe.ps1" }
            }
        }
        "Exit" { $mainMenu = 'q' }
    }

    #switch ($selection)
    #{
    #    'G1' { $script = "Scripts/Powershell/FirewallClean.ps1" }
    #    'G2' { $script = "Scripts/Powershell/SearchCloseFile.ps1" }
    #    'A1' { $script = "Scripts/Powershell/ActiveDirectoryTestCredentials.ps1" }
    #    'A2' { $script = "Scripts/Powershell/ActiveDirectoryUserList.ps1" }
    #    'A3' { $script = "Scripts/Powershell/ActiveDirectoryComputerList.ps1" }
    #    'A4' { $script = "Scripts/Powershell/ActiveDirectoryUsersinGroups.ps1" }
    #    'S1' { $script = "Scripts/Powershell/SoftwareMicrosoftEdge.ps1" }
    #    'S2' { $script = "Scripts/Powershell/SoftwareOneDrive.ps1" }
    #    'T1' { $script = "Scripts/Powershell/TpmGetVersion.ps1" }
    #    'T2' { $script = "Scripts/Powershell/TpmReset.ps1" }
    #    'M1' { $script = "Scripts/Powershell/IntuneGenerateHWID.ps1" }
    #    'c' { $script = "Scripts/Powershell/CreateShortcut.ps1" }
    #}

    if (($mainMenu -ne 'q') -and ($script -ne $null)) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -Headers @{"Cache-Control"="no-cache"} -DisableKeepAlive -useb "https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/$script")))
    }

} until ($mainMenu -eq 'q')