# Ensure onlinesim binary + local MCP HTTP + auth (Windows).
# Prints key=value lines. Exit: 0 ready | 2 auth missing | 1 hard failure
$ErrorActionPreference = "Stop"

$Endpoint = if ($env:ONLINESIM_MCP_ENDPOINT) { $env:ONLINESIM_MCP_ENDPOINT } else { "http://127.0.0.1:8787/mcp" }
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallScript = Join-Path $ScriptDir "install-binary.ps1"

$DefaultBinDir = Join-Path $env:LOCALAPPDATA "onlinesim\bin"
if ($env:Path -notlike "*$DefaultBinDir*") {
    $env:Path = "$DefaultBinDir;$env:Path"
}

function Emit([string]$Line) { Write-Output $Line }

function Find-Bin {
    $cmd = Get-Command onlinesim -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidate = Join-Path $DefaultBinDir "onlinesim.exe"
    if (Test-Path $candidate) { return $candidate }
    return $null
}

function Test-McpUp {
    try {
        $resp = Invoke-WebRequest -Uri $Endpoint -Method GET -TimeoutSec 2 -ErrorAction SilentlyContinue
        return $true
    } catch {
        # Any HTTP response (including 4xx/5xx) means something is listening.
        if ($_.Exception.Response) { return $true }
        return $false
    }
}

$binaryStatus = "missing"
$mcpStatus = "down"
$authStatus = "unknown"

$bin = Find-Bin
if (-not $bin) {
    Write-Host "# installing onlinesim binary…"
    try {
        & $InstallScript
    } catch {
        Emit "binary=fail"
        Emit "mcp=down"
        Emit "auth=unknown"
        Emit "endpoint=$Endpoint"
        Emit "error=binary_install_failed"
        exit 1
    }
    if ($env:Path -notlike "*$DefaultBinDir*") {
        $env:Path = "$DefaultBinDir;$env:Path"
    }
    $bin = Find-Bin
    if (-not $bin) {
        Emit "binary=fail"
        Emit "mcp=down"
        Emit "auth=unknown"
        Emit "endpoint=$Endpoint"
        Emit "error=binary_not_on_path_after_install"
        exit 1
    }
    $binaryStatus = "installed"
} else {
    $binaryStatus = "ok"
}

if (Test-McpUp) {
    $mcpStatus = "up"
} else {
    Write-Host "# starting onlinesim mcp --no-tray…"
    $log = Join-Path $env:TEMP "onlinesim-mcp-ensure.log"
    try {
        & $bin mcp autostart start 2>$null | Out-Null
    } catch { }
    if (-not (Test-McpUp)) {
        Start-Process -FilePath $bin -ArgumentList @("mcp", "--no-tray") -WindowStyle Hidden `
            -RedirectStandardOutput $log -RedirectStandardError $log
        for ($i = 0; $i -lt 20; $i++) {
            Start-Sleep -Milliseconds 250
            if (Test-McpUp) {
                $mcpStatus = "started"
                break
            }
        }
    } else {
        $mcpStatus = "started"
    }
    if (-not (Test-McpUp)) {
        Emit "binary=$binaryStatus"
        Emit "mcp=fail"
        Emit "auth=unknown"
        Emit "endpoint=$Endpoint"
        Emit "error=mcp_start_failed"
        Emit "log=$log"
        exit 1
    }
    if ($mcpStatus -eq "down") { $mcpStatus = "started" }
}

$doctorOk = $false
try {
    & $bin doctor 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $doctorOk = $true }
} catch { }
if (-not $doctorOk) {
    try {
        & $bin --format json balance 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $doctorOk = $true }
    } catch { }
}
$authStatus = if ($doctorOk) { "ok" } else { "missing" }

Emit "binary=$binaryStatus"
Emit "mcp=$mcpStatus"
Emit "auth=$authStatus"
Emit "endpoint=$Endpoint"
Emit "bin=$bin"

if ($authStatus -eq "missing") {
    Emit "action=ask_api_key"
    Emit "site=https://onlinesim.io/"
    Emit "topup=https://onlinesim.io/v2/payment"
    Emit "login=onlinesim login --apikey <KEY>"
    exit 2
}

Emit "action=ready"
exit 0
