# Install onlinesim MCP CLI from GitHub Releases (Windows).
# Usage: irm https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Repo = if ($env:ONLINESIM_MCP_REPO) { $env:ONLINESIM_MCP_REPO } else { "on-org/onlinesim-mcp" }
$BinName = "onlinesim"
$InstallDir = if ($env:ONLINESIM_INSTALL_DIR) { $env:ONLINESIM_INSTALL_DIR } else {
    Join-Path $env:LOCALAPPDATA "onlinesim\bin"
}

$Arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
$Target = switch ($Arch) {
    "Arm64" { "aarch64-pc-windows-msvc" }
    "X64" { "x86_64-pc-windows-msvc" }
    default {
        throw "Unsupported Windows architecture: $Arch (need X64 or Arm64)"
    }
}
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
    $Dest = Join-Path $InstallDir "$BinName.exe"
    Copy-Item -Force $Src $Dest
    # Clear Mark-of-the-Web so SmartScreen does not treat the unzipped exe as blocked.
    Unblock-File -Path $Dest -ErrorAction SilentlyContinue
} finally {
    Remove-Item -Recurse -Force $Tmp.FullName
}

Write-Host "Installed $Dest ($Tag)"
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
Write-Host "  onlinesim mcp"
Write-Host "  onlinesim mcp autostart install   # optional: login/reboot background"
Write-Host ""
Write-Host "MCP endpoint (keep mcp running, or use autostart):"
Write-Host "  http://127.0.0.1:8787/mcp"
Write-Host ""
Write-Host "Connect (keep onlinesim mcp running):"
Write-Host "  Claude Code global:  claude mcp add --scope user --transport http onlinesim http://127.0.0.1:8787/mcp"
Write-Host "  Claude Code project: claude mcp add --scope project --transport http onlinesim http://127.0.0.1:8787/mcp"
Write-Host "  Codex:               codex mcp add onlinesim --url http://127.0.0.1:8787/mcp"
Write-Host "  Cursor global:       ~/.cursor/mcp.json"
Write-Host "  Cursor project:      .cursor/mcp.json"
Write-Host '  Cursor / Claude JSON: {"mcpServers":{"onlinesim":{"type":"http","url":"http://127.0.0.1:8787/mcp"}}}'
Write-Host "  VS Code project:     .vscode/mcp.json"
Write-Host '  VS Code JSON:        {"servers":{"onlinesim":{"type":"http","url":"http://127.0.0.1:8787/mcp"}}}'
Write-Host "  Desktop:             npx -y mcp-remote http://127.0.0.1:8787/mcp --transport http-only"
Write-Host ""
Write-Host "Docs: https://github.com/on-org/onlinesim-mcp#connect-an-mcp-client"
