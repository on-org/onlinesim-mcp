[![GitHub release](https://img.shields.io/github/v/release/on-org/onlinesim-mcp?style=for-the-badge&label=release)](https://github.com/on-org/onlinesim-mcp/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/on-org/onlinesim-mcp/total?style=for-the-badge)](https://github.com/on-org/onlinesim-mcp/releases)
[![Rust](https://img.shields.io/badge/rust-1.88%2B-orange?style=for-the-badge&logo=rust)](https://www.rust-lang.org/)
[![MCP](https://img.shields.io/badge/MCP-Streamable%20HTTP-0d9488?style=for-the-badge)](https://modelcontextprotocol.io)
[![GitHub issues](https://img.shields.io/github/issues/on-org/onlinesim-mcp?style=for-the-badge)](https://github.com/on-org/onlinesim-mcp/issues)
[![GitHub stars](https://img.shields.io/github/stars/on-org/onlinesim-mcp?style=for-the-badge)](https://github.com/on-org/onlinesim-mcp/stargazers)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue?style=for-the-badge)](LICENSE)

![Onlinesim MCP](assets/hero.png)

# Onlinesim MCP

Local [MCP](https://modelcontextprotocol.io) server (Streamable HTTP) and CLI for [Onlinesim](https://onlinesim.io): order receive-only numbers and read SMS.

The API key lives in local config (`onlinesim login`) or `ONLINESIM_APIKEY`. Never pass the key in tool arguments.

## Install

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.sh | sh

# Windows PowerShell
irm https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.ps1 | iex
```

Binaries are published on [GitHub Releases](https://github.com/on-org/onlinesim-mcp/releases). Build-from-source is for maintainers with private source access.

## How it works

```
MCP client  ── Streamable HTTP ──►  onlinesim mcp  ──►  Onlinesim API
                                  http://HOST:PORT/mcp
CLI: onlinesim sms|rent|…  ────────────────────────────┘
                       local config + ONLINESIM_APIKEY
```

Transport: [Streamable HTTP](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports#streamable-http) — a single `/mcp` endpoint (JSON-RPC POST, SSE when needed). Clients discover tools via `tools/list`; you do not need to list them in the client config.

Two product lines (do not mix tools):

1. **Quick SMS** — short-lived number for a service (`telegram`, `whatsapp`, …): balance → catalog → order → user enters the number on the target site → wait/check → cancel.
2. **Rent** — long-term rental: list rentals → rent → messages / extend / cancel.

Tariff catalogs are cached locally (~5 min). Balance and order operations always hit the API.

Statuses: `TZ_NUM_WAIT` — waiting for SMS; `TZ_NUM_ANSWER` — code received. Ids appear in `[brackets]`: `serviceId` (slug), `countryId` / `rentalId` (numeric), Order / Receipt ID (`tzid`).

## Quick start

```bash
onlinesim login
onlinesim doctor
onlinesim balance
onlinesim mcp
# default: http://127.0.0.1:8787/mcp
# other bind: onlinesim mcp --bind 127.0.0.1:9000
# non-loopback requires: onlinesim mcp --bind 0.0.0.0:8787 --allow-remote
```

The MCP client cannot connect until `onlinesim mcp` is running. Non-loopback binds are refused unless `--allow-remote` (the MCP endpoint has no auth). For access from another host or the cloud, put HTTPS and access control in front yourself — the default bind is loopback only.

### Logs (stderr)

By default the MCP process logs at **info** on stderr: startup (bind, auth source without the key), each tool call start/ok/err with duration, and wait start/finish (outcome only — never the SMS code).

```bash
onlinesim mcp                 # onlinesim_mcp=info
onlinesim -v mcp              # onlinesim_mcp=debug (catalog cache, …)
RUST_LOG=onlinesim_mcp=debug onlinesim mcp   # explicit filter wins over -v
```

### Autostart

Enable login/reboot autostart with [`auto-launcher`](https://crates.io/crates/auto-launcher) — same model on every OS (no Windows SCM):

| OS | User (default) | `--system` |
|---|---|---|
| Windows | HKCU Run | HKLM Run (admin) |
| macOS | LaunchAgent `~/Library/LaunchAgents` | LaunchDaemon (sudo) |
| Linux | systemd --user | systemd system (sudo) |

```bash
onlinesim mcp autostart install              # enable + start in background
onlinesim mcp autostart status
onlinesim mcp autostart start                # start now without changing autostart
onlinesim mcp autostart uninstall            # disable autostart

sudo onlinesim mcp autostart install --system
```

Runs as your user by default, so `onlinesim login` / config keep working. Autostart survives reboot after you log in (Windows/macOS) or with a user systemd session (Linux).

## Connect an MCP client

Endpoint: `http://127.0.0.1:8787/mcp` (or your `--bind`). Keep `onlinesim mcp` running.

### Auto-wire (recommended)

```bash
# Cursor, this project (default)
onlinesim mcp install

# Cursor, all projects
onlinesim mcp install --client cursor --global

# VS Code Copilot (project only)
onlinesim mcp install --client vscode --project

# Claude Code project file (.mcp.json)
onlinesim mcp install --client claude --project

# Cursor + VS Code + Claude project files
onlinesim mcp install --client all --project

# Codex (global ~/.codex/config.toml)
onlinesim mcp install --client codex --global
```

Flags: `--dir <project-root>`, `--url <endpoint>`, `--force` (overwrite existing `onlinesim` entry).

Or edit configs manually — same JSON body for Cursor and Claude Code project files (`type` is required):

```json
{
  "mcpServers": {
    "onlinesim": {
      "type": "http",
      "url": "http://127.0.0.1:8787/mcp"
    }
  }
}
```

### Cursor

| Scope | File | CLI |
|-------|------|-----|
| **Global** (all projects) | `~/.cursor/mcp.json` | `onlinesim mcp install --client cursor --global` |
| **Project** (this repo / team) | `.cursor/mcp.json` | `onlinesim mcp install` |

Or: Command Palette → **Open MCP settings** → **Add custom MCP**.

### Claude Code

| Scope | How |
|-------|-----|
| **Global** (all projects) | `onlinesim mcp install --client claude --global` or `claude mcp add --scope user --transport http onlinesim …` |
| **Project** (shared via git) | `onlinesim mcp install --client claude --project` → `.mcp.json` |
| **Local** (you, this project only) | `claude mcp add --transport http onlinesim …` (default) |

Manual project file: `.mcp.json` at the repo root (same JSON as above). User scope: `~/.claude.json`.

### VS Code (GitHub Copilot)

```bash
onlinesim mcp install --client vscode --project
```

Project file: `.vscode/mcp.json` — root key is **`servers`**, not `mcpServers`:

```json
{
  "servers": {
    "onlinesim": {
      "type": "http",
      "url": "http://127.0.0.1:8787/mcp"
    }
  }
}
```

### Codex

```bash
onlinesim mcp install --client codex --global
# or:
codex mcp add onlinesim --url http://127.0.0.1:8787/mcp
```

Or in `~/.codex/config.toml`:

```toml
[mcp_servers.onlinesim]
url = "http://127.0.0.1:8787/mcp"
```

### Claude Desktop / Claude.ai

- **Public HTTPS URL** — Settings → Connectors → Add custom connector → paste the endpoint URL.
- **Local `http://127.0.0.1/…`** via `url` in `claude_desktop_config.json` is usually unsupported (that file is stdio-oriented). Options: a Custom Connector on proxied HTTPS, or a stdio bridge to Streamable HTTP (e.g. `npx -y mcp-remote http://127.0.0.1:8787/mcp --transport http-only`).

Any other Streamable HTTP client: same URL.

## MCP tools

| Tool | Purpose |
|------|---------|
| `get_account_balance` | Balance before spending |
| `search_sms_services` | Search Quick SMS services |
| `get_sms_service_countries` | Countries for a `serviceId` |
| `find_cheapest_sms_countries` | Cheapest `countryId`s by price |
| `order_sms_verification` | Order a number (**spends** balance) |
| `wait_sms_verification` | Wait for a code (default 45s, max 60; shared poller) |
| `check_sms_verification` | Status / code by `orderIds` |
| `cancel_sms_verification` | Close order(s) |
| `list_sms_orders` | Active Quick SMS orders |
| `list_sms_rentals` | Rental tariffs |
| `rent_sms_number` | Rent a number (**spends** balance) |
| `get_sms_rental_messages` | SMS for a rental |
| `extend_sms_rental` | Extend |
| `cancel_sms_rental` | Cancel a rental |

### Typical agent flow (Quick SMS)

```
get_account_balance
→ search_sms_services → find_cheapest_sms_countries
→ order_sms_verification          # serviceId/countryId from catalog only
→ user enters the number on the target site and requests SMS
→ wait_sms_verification(orderId)  # or poll check every 15–30s
→ cancel_sms_verification
```

Bulk: `orderIds` / `receiptIds` (1–20), or omit / `[]` for all active. Cancel-all only when the user explicitly asks to close everything. Prefer one bulk call — never one RPC per number.

## CLI

Human-readable by default. For scripts and integrations, use `--format json` (stable envelope on stdout):

```bash
onlinesim --format json balance
onlinesim --format json sms search telegram
# { "ok": true, "command": "sms.search", "data": { ... } }
```

```bash
onlinesim sms search telegram
onlinesim sms countries telegram
onlinesim sms order telegram 7
onlinesim sms check
onlinesim sms cancel 1001
onlinesim sms list

onlinesim rent list
onlinesim rent order 7 7
onlinesim rent messages
onlinesim rent extend 1001 7
onlinesim rent cancel 1001

onlinesim config show | path | set
onlinesim logout
```

## Dev / mock

Build with `--features dev` to use `MockOnlineSim` (no API key, no real HTTPS). State file: `…/onlinesim/mock-state.json` or `ONLINESIM_MOCK_STATE`. Reset: `onlinesim config reset-mock`.

There is no `--dev` / `--live` CLI flag — mock vs live is compile-time only.

## License

Apache License 2.0
