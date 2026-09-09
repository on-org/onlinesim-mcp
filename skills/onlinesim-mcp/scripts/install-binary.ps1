# Install/update the onlinesim CLI via the canonical public install.ps1.
# Usage: pwsh -File scripts/install-binary.ps1
$ErrorActionPreference = "Stop"

$Repo = if ($env:ONLINESIM_MCP_REPO) { $env:ONLINESIM_MCP_REPO } else { "on-org/onlinesim-mcp" }
$Url = "https://raw.githubusercontent.com/$Repo/master/install.ps1"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootCandidate = Resolve-Path (Join-Path $ScriptDir "..\..\..") -ErrorAction SilentlyContinue
$LocalInstall = if ($RootCandidate) { Join-Path $RootCandidate.Path "install.ps1" } else { $null }

if ($LocalInstall -and (Test-Path $LocalInstall)) {
    & $LocalInstall
} else {
    Invoke-Expression (Invoke-RestMethod -Uri $Url)
}
