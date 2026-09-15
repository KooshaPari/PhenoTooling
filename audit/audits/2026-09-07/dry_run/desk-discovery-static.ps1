Write-Output 'DESK_ROOT_DIRECTORIES'
Get-ChildItem -LiteralPath 'C:\dev','D:\codeprojects','D:\Dev','D:\koosh','C:\Users\kooshapari\CodeProjects','C:\Users\koosh\CodeProjects' -Directory -ErrorAction SilentlyContinue | Select-Object -First 85 -ExpandProperty FullName
Write-Output 'WSL_DISTRIBUTIONS'
wsl.exe --list --verbose | Select-Object -First 8
Write-Output 'DISCOVERY_COMPLETE'
