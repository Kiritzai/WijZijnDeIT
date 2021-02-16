$input = Read-Host -Prompt 'Filename to search'

Clear-Host

if ($input) {
    $files = Get-SMBOpenFile | Where-Object -Property Path -Match "$input" | Select-Object -Property ClientUserName,ClientComputerName,ShareRelativePath,FileId,SessionId,Path

    #Write-Host $input

    If ($files.Count -eq 0) {
        Write-Host "No results found..."
        $UserInput = $Host.UI.ReadLine()
    } else {
        Write-Host "Found Total: $($files.Count)"
        Write-Host ""

        Write-Host "Please choose ID:"
        Write-Host ""

        For ($i=0; $i -lt $files.Count; $i++)  {
          Write-Host "ID: $($i+1)"
          Write-Host "User: $($files[$i].ClientUserName)"
          Write-Host "File: $($files[$i].ShareRelativePath)"
          Write-Host ""
        }

        [int]$number = Read-Host "Enter ID to close"
    
        $fileId = $($files[$number-1].FileId)

        Close-SmbOpenFile -FileId $fileId -Force

        Write-Host "Closed" -ForegroundColor Green
        Write-Host "FileID: $($files[$number-1].FileId)"
        Write-Host "ClientUserName: $($files[$number-1].ClientUserName)"
        Write-Host "ShareRelativePath: $($files[$number-1].ShareRelativePath)"
    }
}