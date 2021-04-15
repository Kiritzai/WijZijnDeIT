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

function Show-Menu
{
    param (
        [string]$Title = 'WijZijnDe.IT'
    )
    Clear-Host
    $textMenu = @"
================ $Title ================
Press '1' for ActiveDirectory Testing Credentials
Press '2' for ActiveDirectory Generating Computer List 
Press '3' for Cleaning Windows Firewall Rules for RDS Servers"
============================================================

Press 'c' for Creating a shortcut of this menu on desktop"
Press 'q' to quit.

"@
$textMenu    

}

do
{
    Clear-Variable script -ErrorAction SilentlyContinue

    Show-Menu -Title "WijZijnDe.IT"
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
        '1' { $script = "Scripts/Powershell/ActiveDirectoryTestCredentials.ps1" }
        '2' { $script = "Scripts/Powershell/ActiveDirectoryComputerList.ps1" }
        '3' { $script = "Scripts/Powershell/FirewallClean.ps1" }
        'c' { $script = "Scripts/Powershell/CreateShortcut.ps1" }
    }

    if ($selection -ne 'q') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -DisableKeepAlive -useb "https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/$script")))
    }

} until ($selection -eq 'q')