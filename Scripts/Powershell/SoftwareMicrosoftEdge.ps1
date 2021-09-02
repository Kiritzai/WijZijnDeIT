# Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;


Clear-Host

#OPTIONAL CONFIGURATION:
$jsonUrl = "https://edgeupdates.microsoft.com/api/products"
$temporaryInstallerPath = Join-Path $Env:TEMP -ChildPath "InstallMicrosoftEdge.msi"


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
        Write-Output "downloading from download URL: $downloadUrl"
        Invoke-WebRequest -UseBasicParsing -Uri $downloadUrl -Method GET -OutFile $temporaryInstallerPath
        Write-Output "downloaded finished from download URL: $downloadUrl"
        if([System.IO.File]::Exists($temporaryInstallerPath)){
            Write-Output "Starting client installer"
            Start-Sleep -s 5 #let A/V scan the file so it isn't locked
            #first kill existing instances
            #Get-Process | Where-Object {$_.ProcessName -like "onedrive*"} | Stop-Process -Force -Confirm:$False
            Start-Sleep -s 5
            runProcess "C:\Windows\System32\msiexec.exe" "/i $temporaryInstallerPath /passive"
            Start-Sleep -s 5
            Write-Output "Install finished"
            Remove-Item -Path $temporaryInstallerPath | out-null
            Write-Output "File removed from: $temporaryInstallerPath"
        }
    #}
} catch {
    Write-Error "Failed to download or install from $downloadURL" -ErrorAction Continue
    Write-Error $_ -ErrorAction Continue
}


$UserInput = $Host.UI.ReadLine()