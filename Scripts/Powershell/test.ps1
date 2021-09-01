# [System.Net.Cache.RequestCacheLevel]::NoCacheNoStore; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -useb 'https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/Scripts/Powershell/test.ps1' -DisableKeepAlive))) -Silent:$true

Function Create-Menu (){
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True)][array]$MenuOptions,
        [string]$Title = "WijZijnDe.IT",
        [string]$ncVer = "0.0.0.7",
        [string]$foregroundcolor = "Green"
    )

    $MaxValue = $MenuOptions.count-1
    $Selection = 0
    $EnterPressed = $False
    
    (Get-Host).UI.RawUI.WindowTitle = ":: WijZijnDe.IT :: Power Menu :: $ncVer ::"

    Clear-Host

    While($EnterPressed -eq $False){
        
        Write-Host `n"# $Title v" $ncVer "#`n" -ForeGroundColor $foregroundcolor

        For ($i=0; $i -le $MaxValue; $i++){
            
            If ($i -eq $Selection){
                Write-Host -BackgroundColor Cyan -ForegroundColor Black "[ $($MenuOptions[$i]) ]"
            } Else {
                Write-Host "  $($MenuOptions[$i])  "
            }

        }

        $KeyInput = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown").virtualkeycode

        Switch($KeyInput){
            13{
                $EnterPressed = $True
                switch ($Selection)
                {
                    '1' { $script = "Scripts/Powershell/ActiveDirectoryTestCredentials.ps1" }
                    '2' { $script = "Scripts/Powershell/ActiveDirectoryUserList.ps1" }
                    '3' { $script = "Scripts/Powershell/ActiveDirectoryComputerList.ps1" }
                    '4' { $script = "Scripts/Powershell/FirewallClean.ps1" }
                    '5' { $script = "Scripts/Powershell/SearchCloseFile.ps1" }
                    'c' { $script = "Scripts/Powershell/CreateShortcut.ps1" }
                }
                #Return $Selection
                Clear-Host
                break
            }

            38{
                If ($Selection -eq 0){
                    $Selection = $MaxValue
                } Else {
                    $Selection -= 1
                }
                Clear-Host
                break
            }

            40{
                If ($Selection -eq $MaxValue){
                    $Selection = 0
                } Else {
                    $Selection +=1
                }
                Clear-Host
                break
            }
            Default{
                Clear-Host
            }
        }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::SecurityProtocol -bor 3072; &([scriptblock]::Create((Invoke-WebRequest -DisableKeepAlive -useb "https://raw.githubusercontent.com/Kiritzai/WijZijnDeIT/master/$script")))
    }
}

$menuItems = @(
                "ActiveDirectory Testing Credentials",
                "ActiveDirectory Generating User List",
                "ActiveDirectory Generating Computer List",
                "Cleaning Windows Firewall Rules for RDS Servers",
                "Search and Close selected files")

Create-Menu $menuItems