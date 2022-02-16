Clear-Host

$infoText = @"
!!Caution!!
All data and information on THIS computer will be GONE!
There is no way to restore any files beyond this point!

Everything will be wiped and removed!
"@

$infoText

Write-Host ""
$confirmation = Read-Host "Would you like to reset and wipe this computer? (y/n)"
Write-Host ""
if ($confirmation -eq 'y') {

	$confirmation2 = Read-Host "Are you absolutely sure!? (y/n)"
	Write-Host ""
	if ($confirmation2 -eq 'y') {

		Write-Host "Reset and Wiping computer..." -ForegroundColor Yellow

		Set-ExecutionPolicy -Scope Currentuser Unrestricted -Force
		$ErrorActionPreference= 'silentlycontinue'
		$global:ProgressPreference = 'SilentlyContinue'
		New-Item -Path c:\programdata\customscripts -ItemType Directory -Force -Confirm:$false | out-null
		
$reset =
@’
$namespaceName = "root\cimv2\mdm\dmmap"
$className = "MDM_RemoteWipe"
$methodName = "doWipeMethod"
$session = New-CimSession 
$params = New-Object Microsoft.Management.Infrastructure.CimMethodParametersCollection
$param = [Microsoft.Management.Infrastructure.CimMethodParameter]::Create("param", "", "String", "In")
$params.Add($param) 
		try
			{
					$instance = Get-CimInstance -Namespace $namespaceName -ClassName $className -Filter "ParentID='./Vendor/MSFT' and InstanceID='RemoteWipe'"
					$session.InvokeMethod($namespaceName, $instance, $methodName, $params)
			}
				catch [Exception]
			{
					write-host $_ | out-string
			} 
‘@
		
		
$start =
@’
reg.exe ADD HKCU\Software\Sysinternals /v EulaAccepted /t REG_DWORD /d 1 /f | out-null
Start-Process -FilePath "c:\ProgramData\CustomScripts\pstools\psexec.exe" -windowstyle hidden -ArgumentList '-i -s cmd /c "powershell.exe -ExecutionPolicy Bypass -file c:\programdata\customscripts\reset.ps1"'
‘@
		
		#To made sure we have the autopilot hash before remote wipe
		
		Out-File -FilePath $(Join-Path $env:ProgramData CustomScripts\start.ps1) -Encoding unicode -Force -InputObject $start -Confirm:$false
		Out-File -FilePath $(Join-Path $env:ProgramData CustomScripts\reset.ps1) -Encoding unicode -Force -InputObject $reset -Confirm:$false
		
		#Sysinternals download part
		invoke-webrequest -uri: "https://download.sysinternals.com/files/SysinternalsSuite.zip" -outfile "c:\programdata\customscripts\pstools.zip" | out-null
		Expand-Archive c:\programdata\customscripts\pstools.zip -DestinationPath c:\programdata\customscripts\pstools -force | out-null
		
		Start-Process powershell -ArgumentList '-noprofile -file c:\programdata\customscripts\start.ps1'

	} else {
		Write-Host "Phewwww.... Cancelled just in time :)" -ForegroundColor Red
	}
} else {
	Write-Host "Cancelled" -ForegroundColor Red
}

$UserInput = $Host.UI.ReadLine()