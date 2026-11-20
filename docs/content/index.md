---
title: onlinesim-mcp
description: Local MCP server (Streamable HTTP) and CLI for OnlineSim — let an AI agent order receive-only numbers and read SMS.
---

`onlinesim` is a single binary. `onlinesim mcp` runs a local [MCP](https://modelcontextprotocol.io) server that
Cursor, Claude Code, VS Code Copilot, Codex and any other Streamable HTTP client can use. The same binary is a CLI
for the terminal and scripts.

```text
MCP client  ── Streamable HTTP ──►  onlinesim mcp  ──►  OnlineSim API
                                  http://127.0.0.1:8787/mcp
CLI: onlinesim sms|rent|…  ────────────────────────────┘
                       local config or ONLINESIM_APIKEY
```

The API key stays on your machine (local config or `ONLINESIM_APIKEY`). Agents never see it and never pass it in
tool arguments.

## Quick start

1. Install the binary (macOS / Linux; Windows and other options in [Install](/install)):

   ```bash
   curl -fsSL https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.sh | sh
   ```

2. Save your API key (from the [OnlineSim profile](https://onlinesim.io/v2/profile/api)) and check it:

   ```bash
   onlinesim login
   onlinesim doctor
   ```

3. Start the server and keep it running (or enable [autostart](/configuration#autostart)):

   ```bash
   onlinesim mcp
   # http://127.0.0.1:8787/mcp
   ```

4. Wire your client, e.g. Cursor for this project (others in [Connect a client](/clients)):

   ```bash
   onlinesim mcp install
   ```

5. Ask the agent: *"Get me a number for Telegram and wait for the code."*

## Two product lines

| | Quick SMS | Rent |
|---|---|---|
| What | A short-lived number for one service (`telegram`, `google`, …) | A number of your own for days; every SMS to it |
| Flow | balance → catalog → order → user enters the number → wait / check → cancel | rentals → rent → messages → extend / cancel |
| Money | The price is reserved at order and refunded when the order closes without SMS | The price is reserved and charged by the first SMS |
| Tools | `order_sms_verification`, `wait_sms_verification`, `check_sms_verification`, `cancel_sms_verification` | `rent_sms_number`, `get_sms_rental_messages`, `extend_sms_rental`, `cancel_sms_rental` |

Do not mix them: a Quick SMS order id is not a rental receipt id. All tools are described in [MCP tools](/tools).

## Pages

- [Install](/install) — install script per OS, agent skill, updates, uninstall.
- [Connect a client](/clients) — Cursor, Claude Code, VS Code, Codex, Claude Desktop, any HTTP client.
- [MCP tools](/tools) — every tool: inputs, answer, errors, and the agent flows.
- [CLI](/cli) — the same operations from the terminal, JSON output for scripts.
- [Configuration](/configuration) — API key, config file, environment, logs, autostart, tray, network safety.
- [Changelog](/changelog).
