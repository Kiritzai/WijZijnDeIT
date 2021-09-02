Clear-Host

Write-Host ""

#$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
$DesktopPath = Join-Path "$DesktopPath" "WijZijnDeIT.lnk"

if (Test-Path -Path $DesktopPath -PathType Leaf) {
    Write-Host "File [$($DesktopPath)] already exists"
} else {
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($DesktopPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/main.ps1'))"
    $Shortcut.Save()
    
    # Set RunAsAdministrator checkbox
    $bytes = [System.IO.File]::ReadAllBytes($DesktopPath)
    $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
    [System.IO.File]::WriteAllBytes($DesktopPath, $bytes)

    Write-Host "Created file [$($DesktopPath)]"
}

$UserInput = $Host.UI.ReadLine()