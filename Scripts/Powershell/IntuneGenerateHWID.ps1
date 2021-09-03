
Clear-Host

If (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
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
    Save-Script -Name Get-WindowsAutoPilotInfo -Path c:\ProgramData\CustomScripts -force | out-null

    Write-Host "Grabbing serialnumber and computername"
    $sn = (Get-WmiObject win32_bios).SerialNumber
    $pcname = $env:COMPUTERNAME
    $file = $pcname + "_" + $sn

    Write-Host "Creating directory: c:\HWID"
    New-Item -Path c:\HWID -ItemType Directory -Force -Confirm:$false | out-null

    Write-Host "Generating HWID.."
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "powershell"
    $pinfo.Arguments = "-NoProfile -ExecutionPolicy Unrestricted -File ""C:\ProgramData\CustomScripts\Get-WindowsAutoPilotInfo.ps1"" -OutputFile c:\HWID\$file.csv"
    $pinfo.Verb = "RunAs"
    $pinfo.RedirectStandardError = $false
    $pinfo.RedirectStandardOutput = $false
    $pinfo.UseShellExecute = $true
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $p.ExitCode

    Write-Host "HWID Generated!"

    # Opens the folder
    explorer "c:\HWID"

    Write-Host `n"Continue?"
    $UserInput = $Host.UI.ReadLine()

}