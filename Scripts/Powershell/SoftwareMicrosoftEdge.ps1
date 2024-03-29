# Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;


Clear-Host

# Generate Random String
$random_name = -join ((48..57) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Disable first Run Explorer
[microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\Main", "DisableFirstRunCustomize", 2)

#OPTIONAL CONFIGURATION:
$jsonUrl = "https://edgeupdates.microsoft.com/api/products"
$temporaryInstallerPath = Join-Path $Env:TEMP -ChildPath "$random_name.msi"

$result = Invoke-WebRequest -Uri $jsonUrl | ConvertFrom-Json
$result = $result | Where-Object { $_.Product -like "Stable" }
$result = $result.Releases | Where-Object { $_.Platform -like "Windows" -and $_.Architecture -like "x64" }
$result = $result.Artifacts | Where-Object { $_.ArtifactName -like "msi" }
$downloadUrl = $result.Location


function runProcess ($exectable, $params, $windowStyle=1) {
    $p = new-object System.Diagnostics.Process
    $p.StartInfo = new-object System.Diagnostics.ProcessStartInfo
    $exitcode = $false
    $p.StartInfo.FileName = $exectable
    $p.StartInfo.Arguments = $params
    $p.StartInfo.UseShellExecute = $False
    $p.StartInfo.RedirectStandardError = $True
    $p.StartInfo.RedirectStandardOutput = $True
    $p.StartInfo.WindowStyle = $windowStyle; #1 = hidden, 2 =maximized, 3=minimized, 4=normal
    $null = $p.Start()
    $output = $p.StandardOutput.ReadToEnd()
    $exitcode = $p.ExitCode
    $p.Dispose()
    $exitcode
    $output
}


#DOWNLOAD ONEDRIVE INSTALLER AND RUN IT
try {
#    if (!$isOnedriveInstalled -and $downloadURL) {
        Write-Host "Downloading Microsoft Edge"
        Invoke-WebRequest -Uri $downloadUrl -Method GET -UseBasicParsing -OutFile $temporaryInstallerPath | Out-Null
        Write-Host "Microsoft Edge has been downloaded"
        if([System.IO.File]::Exists($temporaryInstallerPath)){
            Write-Host "Installing Microsoft Edge..."
            Start-Sleep -s 5
            runProcess "C:\Windows\System32\msiexec.exe" "/i $temporaryInstallerPath /qn"
            Start-Sleep -s 5
            Remove-Item -Path $temporaryInstallerPath | Out-Null
            Write-Host "File removed from: $temporaryInstallerPath"
            [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge", "HideFirstRunExperience", 1)
            Write-Host "Installation finished"
        }
    #}
} catch {
    Write-Error "Failed to download or install from $downloadURL" -ErrorAction Continue
    Write-Error $_ -ErrorAction Continue
}

Write-Host `n"Press any key to continue..."

$UserInput = $Host.UI.ReadLine()