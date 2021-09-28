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
	} else {
		Write-Host "Phewwww.... Cancelled just in time :)" -ForegroundColor Red
	}
} else {
	Write-Host "Cancelled" -ForegroundColor Red
}

$UserInput = $Host.UI.ReadLine()