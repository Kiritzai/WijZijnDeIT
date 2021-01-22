
Clear-Host

$userName = Read-Host "Username"
$passWord = Read-Host "Password" | ConvertTo-SecureString -asPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential($userName, $passWord)
$cred = Get-Credential -Credential $credential

#Exit
#$cred = Get-Credential | Out-Null
#$username = $cred.username
#$password = $cred.GetNetworkCredential().password

# Get current domain using logged-on user's credentials
$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
$domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$cred.username,$cred.GetNetworkCredential().password)

if ([string]::IsNullOrWhitespace($domain.name))
{
    write-host "Authentication failed - please verify your username and password."
    Read-Host "Press ENTER to continue..."
}
else
{
    write-host "Successfully authenticated with domain $domain.name"
    Read-Host "Press ENTER to continue..."
}