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
Write-Host "This part will need administrator rights to continue!"`n

$confirmation = Read-Host "Do you want to continue (y/n)"
Write-Host ""

if ($confirmation -eq 'y') {

    Clear-Host

    try {
        #Start-ElevatedCode { Disable-TpmAutoProvisioning | Out-Null }
        #Start-ElevatedCode { Initialize-Tpm -AllowClear $true }
        
        Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/dell_tpm_upgrade.exe" -Method GET -OutFile "$env:TEMP\dell_tpm_upgrade.exe" | Out-Null

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

        Start-Sleep -Seconds 5
        Start-ElevatedCode { Start-Process powershell -WindowStyle Hidden -ArgumentList "$env:TEMP\Upgrade-TPM-Chip.ps1" }

        Remove-Item "$env:TEMP\Upgrade-TPM-Chip.ps1"

        #Copy-Item "$env:TEMP\dell_tpm_upgrade.exe"
    }
    catch {
        Write-Host `n"Seems there is no TPM active or available."
    }
    
    Write-Host `n"Continue?"
    $UserInput = $Host.UI.ReadLine()

}