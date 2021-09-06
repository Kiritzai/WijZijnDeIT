function Start-ElevatedCode
{
    param([ScriptBlock]$code)

    $random = Get-Random
    $file = "$env:TEMP\$random.txt"
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
        $tpmversion = Start-ElevatedCode { (Get-WmiObject -Namespace "root\cimv2\security\microsofttpm" -Class Win32_TPM).SpecVersion }
        $tpmversion = $tpmversion.SubString(0, 3)

        Write-Host `n"TPM Version: $tpmversion"
    }
    catch {
        Write-Host `n"Seems there is no TPM available.`nAdmin rights are also required for this this work."
    }
    
    Write-Host `n"Continue?"
    $UserInput = $Host.UI.ReadLine()

}