Write-Output 'WINDOWS_PHENO_CONTROL_PLANE'
git -C 'D:\koosh\pheno-control-plane' rev-parse HEAD
git -C 'D:\koosh\pheno-control-plane' config --get remote.origin.url
Get-Content -LiteralPath 'D:\koosh\pheno-control-plane\README.md' -TotalCount 10 -ErrorAction SilentlyContinue
if (((wsl.exe --list --running --quiet | Out-String) -replace '\x00','') -match '(?m)^\s*FedoraLinux-44\s*$') {
  Write-Output 'FEDORA_ALREADY_RUNNING_MATCHES'
  wsl.exe -d FedoraLinux-44 --exec sh -c "find /home -maxdepth 5 -type d \( -name .git -o -name node_modules -o -name target -o -name .cache -o -name cache \) -prune -o -type d \( -iname '*substrate*' -o -iname '*genesis*' \) -print -exec git -C '{}' rev-parse HEAD \; -exec git -C '{}' config --get remote.origin.url \; -exec head -n 8 '{}/README.md' \; 2>/dev/null" | Select-Object -First 55
} else {
  Write-Output 'FEDORA_NOT_RUNNING_SKIPPED'
}
Write-Output 'IDENTITY_CHECK_COMPLETE'
