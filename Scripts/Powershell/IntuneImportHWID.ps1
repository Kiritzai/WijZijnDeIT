$TenantId = "1929ce73-2bce-48e9-8454-cd562d7d5d64"
$AppId = "69821643-1aea-4d0f-aae9-8202e71fabf2"
$AppSecret = "pB37Q~HSAOTKlI9wrreUnV~n06E79Ht1Y_.uj"


Clear-Host

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host `n"!!Caution!!" -ForegroundColor Red
    Write-Host "This part will need administrator rights to continue!"`n
}

$confirmation = Read-Host "Do you want to continue (y/n)"
Write-Host ""
if ($confirmation -eq 'y') {

    Clear-Host

    Write-Host `n"Creating directory: c:\programdata\customscripts"
    New-Item -Path c:\programdata\customscripts -ItemType Directory -Force -Confirm:$false | out-null

    Write-Host "Installing NuGet latest version"
    Install-PackageProvider -name nuget -minimumversion 2.8.5.208 -Force -Scope CurrentUser | out-null

    Write-Host "Downloading AutoPilot script"
    #Install-Script -name Get-WindowsAutopilotInfo -Force
    #Install-Module -Name WindowsAutoPilotIntune -Force
    #Import-Module -Name WindowsAutoPilotIntune -ErrorAction Stop
    Save-Script -Name Get-WindowsAutoPilotInfo -Path c:\ProgramData\CustomScripts -force | out-null

    Write-Host "Grabbing serialnumber and computername"
    $sn = (Get-WmiObject win32_bios).SerialNumber
    $pcname = $env:COMPUTERNAME
    $file = $pcname + "_" + $sn

    Write-Host "Serialnumber: $sn"

    Write-Host "Importing HWID to Autopilot.."
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "powershell"
    $pinfo.Arguments = "-NoProfile -ExecutionPolicy Unrestricted -WindowStyle Hidden -File ""C:\ProgramData\CustomScripts\Get-WindowsAutoPilotInfo.ps1"" -Online -TenantId $TenantId -AppId $AppId -AppSecret $AppSecret"
    $pinfo.Verb = "RunAs"
    $pinfo.RedirectStandardError = $false
    $pinfo.RedirectStandardOutput = $false
    $pinfo.UseShellExecute = $true
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    if ($p.ExitCode -eq '0') {
        Write-Host "Import $sn succesfully"
    }

    Write-Host `n"Press any key te restart the machine!"
    $UserInput = $Host.UI.ReadLine()
    Restart-Computer -Force

}