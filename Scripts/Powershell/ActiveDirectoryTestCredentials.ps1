
Clear-Host

Write-Host ""
Write-Host `t"Active Directory Test Credentials"
Write-Host ""

$userName = Read-Host "Username"
$passWord = Read-Host "Password" -MaskInput | ConvertTo-SecureString -asPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential($userName, $passWord)
$cred = Get-Credential -Credential $credential

# Get current domain using logged-on user's credentials
$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
$domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$cred.username,$cred.GetNetworkCredential().password)

if ([string]::IsNullOrWhitespace($domain.name))
{
    Write-Host "Authentication failed" -ForegroundColor Red
}
else
{
    Write-Host "Authentication successful" -ForegroundColor Green
}
Write-Host `n"Continue"
$UserInput = $Host.UI.ReadLine()