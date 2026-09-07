# Install onlinesim MCP CLI from GitHub Releases (Windows).
# Usage: irm https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = if ($env:ONLINESIM_MCP_REPO) { $env:ONLINESIM_MCP_REPO } else { "on-org/onlinesim-mcp" }
$BinName = "onlinesim"
$InstallDir = if ($env:ONLINESIM_INSTALL_DIR) { $env:ONLINESIM_INSTALL_DIR } else {
    Join-Path $env:LOCALAPPDATA "onlinesim\bin"
}

$Target = "x86_64-pc-windows-msvc"
$Asset = "$BinName-$Target.zip"

Write-Host "Detecting latest release for $Repo ($Target)..."
$Release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
$Tag = $Release.tag_name
$Url = "https://github.com/$Repo/releases/download/$Tag/$Asset"

$Tmp = New-Item -ItemType Directory -Path ([System.IO.Path]::GetTempPath() + [guid]::NewGuid().ToString())
try {
    $ZipPath = Join-Path $Tmp.FullName $Asset
    Write-Host "Downloading $Url"
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath
    Expand-Archive -Path $ZipPath -DestinationPath $Tmp.FullName -Force
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    $Src = Join-Path $Tmp.FullName "$BinName.exe"
    Copy-Item -Force $Src (Join-Path $InstallDir "$BinName.exe")
} finally {
    Remove-Item -Recurse -Force $Tmp.FullName
}

Write-Host "Installed $(Join-Path $InstallDir "$BinName.exe") ($Tag)"
$pathEntry = $InstallDir
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$pathEntry*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$pathEntry", "User")
    $env:Path = "$env:Path;$pathEntry"
    Write-Host "Added $pathEntry to user PATH (new shells will pick it up)."
}

Write-Host ""
Write-Host "Next:"
Write-Host "  onlinesim login"
Write-Host "  onlinesim doctor"
Write-Host ""
Write-Host "MCP (Streamable HTTP):"
Write-Host "  onlinesim mcp"
Write-Host "  endpoint: http://127.0.0.1:8787/mcp"
Write-Host "  Claude Code: claude mcp add --transport http onlinesim http://127.0.0.1:8787/mcp"
