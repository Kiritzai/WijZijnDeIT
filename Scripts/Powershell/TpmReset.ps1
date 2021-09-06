function Start-ElevatedCode
{
    param([ScriptBlock]$code)

    $random = Get-Random
    $file = "$env:TEMP\$random.txt"
    #$passThruArgs = '-NoExit', '-noprofile', '-command', $code, '*>', "`"$file`""
    #Start-Process powershell -Wait -PassThru -Verb RunAs -ArgumentList $passThruArgs
    $passThruArgs = '-noprofile', '-command', $code, '*>', "`"$file`""
    Start-Process powershell -WindowStyle Hidden -Wait -PassThru -Verb RunAs -ArgumentList $passThruArgs | Out-Null

    $output = Get-Content $file
    Remove-Item $file

    return $output
}

Clear-Host

Write-Host `n"!!Caution!!" -ForegroundColor Red
Write-Host "This part will need administrator rights to continue!`nAlso the computer will RESTART after these commands!"`n

$confirmation = Read-Host "Do you want to continue (y/n)"
Write-Host ""

if ($confirmation -eq 'y') {

    Clear-Host

    try {

        Write-Host `n"Disable Auto Provisioning"
        Start-ElevatedCode { Disable-TpmAutoProvisioning | Out-Null }

        Write-Host "Initialize and Clear TPM"
        Start-ElevatedCode { Initialize-Tpm -AllowClear $true | Out-Null }
        
        Write-Host "Downloading dell TPM upgrade tool"
        Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/Kiritzai/WijZijnDeIT/raw/master/Scripts/Powershell/dell_tpm_upgrade.exe" -Method GET -OutFile "$env:TEMP\dell_tpm_upgrade.exe" | Out-Null

        $script = @'
        Register-ScheduledTask -Action $(New-ScheduledTaskAction -Execute "$env:TEMP\dell_tpm_upgrade.exe" -Argument "/s /f"),
                                        (New-ScheduledTaskAction -Execute "shutdown" -Argument "-r -t 30 -f"),
                                        (New-ScheduledTaskAction -Execute "powershell" -Argument "-ExecutionPolicy ByPass -Command `"& { Get-ScheduledTask -TaskName \`"Upgrade-TPM-Chip\`" | Unregister-ScheduledTask -Confirm:`$false } `"") `
                                -Trigger $(New-ScheduledTaskTrigger -AtStartup) `
                                -TaskName "Upgrade-TPM-Chip" `
                                -Description "Upgrade TPM Firmare" `
                                -Settings $(New-ScheduledTaskSettingsSet `
                                            -Compatibility Win8 `
                                            -Hidden `
                                            -DontStopIfGoingOnBatteries `
                                            -AllowStartIfOnBatteries) `
                                -User "System" `
                                -RunLevel Highest
'@ | Out-File "$env:TEMP\Upgrade-TPM-Chip.ps1"

        Write-Host "Creating scheduled task"
        Start-Sleep -Seconds 5
        Start-ElevatedCode { Start-Process powershell -WindowStyle Hidden -ArgumentList "$env:TEMP\Upgrade-TPM-Chip.ps1" }

        Remove-Item "$env:TEMP\Upgrade-TPM-Chip.ps1"
        
        Write-Host "Restarting computer...."
        Start-Sleep -Seconds 5
        Restart-Computer -Force
    }
    catch {
        Write-Host `n"Seems there is no TPM active or available."
    }
    
    Write-Host `n"Continue?"
    $UserInput = $Host.UI.ReadLine()

}