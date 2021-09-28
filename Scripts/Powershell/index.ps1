###
# Variables
###
[string]$ncVer = "0.0.1.1"
[string]$Title = "WijZijnDe.IT"

<#
    .SYNOPSIS
        Displays a selection menu and returns the selected item
    
    .DESCRIPTION
        Takes a list of menu items, displays the items and returns the user's selection.
        Items can be selected using the up and down arrow and the enter key.
    
    .PARAMETER MenuItems
        List of menu items to display
    
    .PARAMETER MenuPrompt
        Menu prompt to display to the user.
    
    .EXAMPLE
        PS C:\> Get-MenuSelection -MenuItems $value1 -MenuPrompt 'Value2'
    
    .NOTES
        Additional information about the function.
#>
function Get-MenuSelection
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$MenuItems,
        [Parameter(Mandatory = $true)]
        [String]$MenuPrompt
    )
    # store initial cursor position
    $cursorPosition = $host.UI.RawUI.CursorPosition
    $pos = 0 # current item selection
    
    #==============
    # 1. Draw menu
    #==============
    function Write-Menu
    {
        param (
            [int]$selectedItemIndex
        )
        # reset the cursor position
        $Host.UI.RawUI.CursorPosition = $cursorPosition
        # Padding the menu prompt to center it
        $prompt = $MenuPrompt
        $maxLineLength = ($MenuItems | Measure-Object -Property Length -Maximum).Maximum + 4
        #while ($prompt.Length -lt $maxLineLength+4)
        #{
            $count = "== $prompt - v$($ncVer) ==========================="
            $total = ""
            for ($i = 0; $i -lt ($count | Measure-Object -Character).Characters; $i++) {
                $total += "="
            }
            $prompt = "`n $total`n $count`n $total`n"
        #}
        Write-Host $prompt -ForegroundColor Green
        # Write the menu lines
        for ($i = 0; $i -lt $MenuItems.Count; $i++)
        {
            $line = "    $($MenuItems[$i])" + (" " * ($maxLineLength - $MenuItems[$i].Length))
            if ($selectedItemIndex -eq $i)
            {
                Write-Host $line -ForegroundColor Blue -BackgroundColor Gray
            }
            else
            {
                Write-Host $line
            }
        }
    }
    
    Write-Menu -selectedItemIndex $pos
    $key = $null
    while ($key -ne 13)
    {
        #============================
        # 2. Read the keyboard input
        #============================
        $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
        $key = $press.virtualkeycode
        if ($key -eq 38)
        {
            $pos--
        }
        if ($key -eq 40)
        {
            $pos++
        }
        #handle out of bound selection cases
        if ($pos -lt 0) { $pos = 0 }
        if ($pos -eq $MenuItems.count) { $pos = $MenuItems.count - 1 }
        
        #==============
        # 1. Draw menu
        #==============
        Write-Menu -selectedItemIndex $pos
    }
    
    #return $MenuItems[$pos]
    Clear-Host

    return $pos
}

do
{

    $mainMenu = Get-MenuSelection -MenuItems "Active Directory", "Option 2", "Option 3", "antoher" -MenuPrompt "Main Menu"
    
    # Main Menu
    switch ($mainMenu) {
        "0" {
            $adMenu = Get-MenuSelection -MenuItems "Return to Main Menu", `
                                                    "Testing Credentials", `
                                                    "Generating User List", `
                                                    "Generating Computer List", `
                                                    "Users in Groups List" `
                                                    -MenuPrompt "Active Directory"

            # Active Directory Menu
            switch ($adMenu) {
                "0" { Write-Host "Testing Credentials" }
                "1" { write-host "Generating User List" }
                "2" { write-host "Generating Computer List" }
            }
        }
        "1" { write-host "Choosen 1" }
        "2" { write-host "Choosen 2" }
    }

} until ($selection -eq 'q')
