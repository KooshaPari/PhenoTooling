# elicitate installer — irm https://raw.githubusercontent.com/Kooshapari/PhenoTooling/main/scripts/install.ps1 | iex
#
# Installs elicitate + elicitate-mcp binaries to ~/.elicitate/bin/

$ErrorActionPreference = "Stop"

$REPO = "Kooshapari/PhenoTooling"
$INSTALL_DIR = if ($env:ELICITATE_INSTALL_DIR) { $env:ELICITATE_INSTALL_DIR } else { Join-Path $HOME ".elicitate\bin" }
$VERSION = if ($env:ELICITATE_VERSION) { $env:ELICITATE_VERSION } else { "latest" }
$GITHUB_API = "https://api.github.com/repos/$REPO"

Write-Host "elicitate installer" -ForegroundColor Cyan
Write-Host ""

$arch = if ([System.Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64" } else { "x86_64" }
} else {
    Write-Host "error: 32-bit Windows is not supported" -ForegroundColor Red; exit 1
}

$target = "$arch-pc-windows-msvc"
Write-Host "info: detected platform: $target" -ForegroundColor Green

if ($VERSION -eq "latest") {
    $release = Invoke-RestMethod -Uri "$GITHUB_API/releases/latest" -UseBasicParsing
    $VERSION = $release.tag_name
}
Write-Host "info: version: $VERSION" -ForegroundColor Green

$archive = "elicitate-$VERSION-$target.zip"
$url = "https://github.com/$REPO/releases/download/$VERSION/$archive"
Write-Host "info: downloading $archive ..." -ForegroundColor Green

New-Item -ItemType Directory -Force -Path $INSTALL_DIR | Out-Null
$tmpDir = Join-Path $env:TEMP "elicitate-install-$(Get-Random)"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

try {
    Invoke-WebRequest -Uri $url -OutFile "$tmpDir\$archive" -UseBasicParsing

    try {
        $checksumContent = (Invoke-WebRequest -Uri "$url.sha256" -UseBasicParsing).Content
        $expectedHash = ($checksumContent -split "\s+")[0]
        $actualHash = (Get-FileHash "$tmpDir\$archive" -Algorithm SHA256).Hash.ToLower()
        if ($expectedHash -eq $actualHash) { Write-Host "info: checksum verified" -ForegroundColor Green }
        else { Write-Host "warn: checksum mismatch — proceeding anyway" -ForegroundColor Yellow }
    } catch { Write-Host "warn: no checksum — skipping verification" -ForegroundColor Yellow }

    Write-Host "info: extracting to $INSTALL_DIR ..." -ForegroundColor Green
    Expand-Archive -Path "$tmpDir\$archive" -DestinationPath $INSTALL_DIR -Force

    Write-Host ""
    Write-Host "installed successfully!" -ForegroundColor Green
    Write-Host "  binaries: $INSTALL_DIR"
    Write-Host "    - $INSTALL_DIR\elicitate.exe"
    Write-Host "    - $INSTALL_DIR\elicitate-mcp.exe"

    $pathDirs = $env:PATH -split ";"
    if ($pathDirs -notcontains $INSTALL_DIR) {
        Write-Host ""
        Write-Host "add to your PATH:" -ForegroundColor Yellow
        Write-Host "  [Environment]::SetEnvironmentVariable('PATH', `$env:PATH + ';$INSTALL_DIR', 'User')"
    }

    Write-Host ""
    Write-Host "run 'elicitate --help' to get started"
} finally {
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
}
