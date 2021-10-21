
Clear-Host

# Disable IE FirstRun
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2

#OPTIONAL CONFIGURATION:
#$xmlDownloadURL = "https://g.live.com/1rewlive5skydrive/ODSUInsider"
$xmlDownloadURL = "https://g.live.com/1rewlive5skydrive/ODSUProduction64"
$temporaryInstallerPath = Join-Path $Env:TEMP -ChildPath "OnedriveInstaller.EXE"
$regPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive"


function runProcess ($cmd, $params, $windowStyle=1) {
    $p = new-object System.Diagnostics.Process
    $p.StartInfo = new-object System.Diagnostics.ProcessStartInfo
    $exitcode = $false
    $p.StartInfo.FileName = $cmd
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



$isOnedriveInstalled = $False
#GET ONLINE VERSION INFO
try {
    [xml]$xmlInfo = (New-Object System.Net.WebClient).DownloadString($xmlDownloadURL)
    $xmlInfo.root.update.currentversion
    $version = $xmlInfo.root.update.currentversion
    $downloadURL = $xmlInfo.root.update.amd64binary.url
    write-output "Microsoft's XML shows the latest Onedrive version is $version and can be downloaded from $downloadURL"
} catch {
    write-error "Failed to download / read version info for Onedrive from $xmlDownloadURL" -ErrorAction Continue
    write-error $_ -ErrorAction Continue
}



#GET LOCAL INSTALL STATUS AND VERSION
try {
    $installedVersion = (Get-ItemProperty -Path $regPath -Name "Version" -ErrorAction Stop).Version
    Write-Output "Detected $installedVersion in registry"
} catch {
    write-error "Failed to read Onedrive version information from the registry, assuming Onedrive is not installed" -ErrorAction Continue
    write-error $_ -ErrorAction Continue
}



#DOWNLOAD ONEDRIVE INSTALLER AND RUN IT
try {
    if (!$isOnedriveInstalled -and $downloadURL) {
        Write-Output "Downloading OneDrive"
        Invoke-WebRequest -UseBasicParsing -Uri $downloadURL -Method GET -OutFile $temporaryInstallerPath | Out-Null
        Write-Output "Finished downloading OneDrive"
        if([System.IO.File]::Exists($temporaryInstallerPath)){
            Write-Output "Installing OneDrive"
            Start-Sleep -s 5 #let A/V scan the file so it isn't locked
            #first kill existing instances
            Get-Process | Where-Object {$_.ProcessName -like "onedrive*"} | Stop-Process -Force -Confirm:$False
            Start-Sleep -s 5
            runProcess $temporaryInstallerPath "/allusers /silent"
            Start-Sleep -s 5
            Write-Output "Install finished"
        }
    }
} catch {
    Write-Error "Failed to download or install from $downloadURL" -ErrorAction Continue
    Write-Error $_ -ErrorAction Continue
}
