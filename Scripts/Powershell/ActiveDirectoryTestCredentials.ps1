
Clear-Host

Write-Host ""
Write-Host `t"Active Directory Test Credentials"
Write-Host ""

$userName = Read-Host "Username"
$passWord = Read-Host "Password" | ConvertTo-SecureString -asPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential($userName, $passWord)
$cred = Get-Credential -Credential $credential

# Get current domain using logged-on user's credentials
$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
$domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$cred.username,$cred.GetNetworkCredential().password)

if ([string]::IsNullOrWhitespace($domain.name))
{
    write-host "Authentication failed" -ForegroundColor Red
    Read-Host ""
}
else
{
    write-host "Successfully authenticated with domain $domain.name" -ForegroundColor Green
    Read-Host ""
}