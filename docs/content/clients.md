---
title: Connect a client
description: Point Cursor, Claude Code, VS Code Copilot, Codex, Claude Desktop or any Streamable HTTP MCP client at onlinesim mcp.
navigation:
  order: 2
---

Endpoint: `http://127.0.0.1:8787/mcp` (or the address you pass to `--bind`). The transport is
[Streamable HTTP](https://modelcontextprotocol.io/specification/2025-03-26/basic/transports#streamable-http): one `/mcp`
endpoint, JSON-RPC over POST, SSE when needed. Clients discover the tools with `tools/list`, so the config only needs
the URL.

`onlinesim mcp` must be running while the client works — start it by hand or enable
[autostart](/configuration#autostart).

## Auto-wire

`onlinesim mcp install` writes the client config for you (it does not start the server):

```bash
onlinesim mcp install                                  # Cursor, this project (default)
onlinesim mcp install --client cursor --global         # Cursor, all projects
onlinesim mcp install --client vscode --project        # VS Code Copilot, this project
onlinesim mcp install --client claude --project        # Claude Code, .mcp.json
onlinesim mcp install --client all --project           # Cursor + VS Code + Claude project files
onlinesim mcp install --client codex --global          # Codex, ~/.codex/config.toml
```

| Flag | Meaning |
|---|---|
| `--client` | `cursor` (default), `vscode`, `claude`, `codex`, `all` |
| `--project` / `--global` | Project file (default) or user-wide file |
| `--dir <path>` | Project root (default: current directory) |
| `--url <url>` | Endpoint (default `http://127.0.0.1:8787/mcp`) |
| `--force` | Overwrite an existing `onlinesim` entry |

The tray menu has the same install items.

## Cursor

| Scope | File | CLI |
|---|---|---|
| Project | `.cursor/mcp.json` | `onlinesim mcp install` |
| Global | `~/.cursor/mcp.json` | `onlinesim mcp install --client cursor --global` |

Or Command Palette → **Open MCP settings** → **Add custom MCP**. The file:

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

## Claude Code

| Scope | How |
|---|---|
| Project (shared via git) | `onlinesim mcp install --client claude --project` → `.mcp.json` (same JSON as Cursor) |
| Global (all projects) | `onlinesim mcp install --client claude --global`, or `claude mcp add --scope user --transport http onlinesim http://127.0.0.1:8787/mcp` |
| Local (you, this project) | `claude mcp add --transport http onlinesim http://127.0.0.1:8787/mcp` |

## VS Code (GitHub Copilot)

```bash
onlinesim mcp install --client vscode --project
```

`.vscode/mcp.json` — the root key is `servers`, not `mcpServers`:

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

## Codex

```bash
onlinesim mcp install --client codex --global
# or
codex mcp add onlinesim --url http://127.0.0.1:8787/mcp
```

`~/.codex/config.toml`:

```toml
[mcp_servers.onlinesim]
url = "http://127.0.0.1:8787/mcp"
```

## Claude Desktop / Claude.ai

- A public HTTPS URL: **Settings → Connectors → Add custom connector** and paste the endpoint.
- A local `http://127.0.0.1/…` URL in `claude_desktop_config.json` is usually not supported (that file is for stdio
  servers). Use a stdio bridge instead:

  ```json
  {
    "mcpServers": {
      "onlinesim": {
        "command": "npx",
        "args": ["-y", "mcp-remote", "http://127.0.0.1:8787/mcp", "--transport", "http-only"]
      }
    }
  }
  ```

## Other clients

Any Streamable HTTP MCP client works with the same URL. The server info is `Onlinesim Numbers`; it offers tools only
(no resources or prompts) and sends a short playbook in its `instructions`.

## Another machine

The server binds to loopback only. To reach it from another host see
[network safety](/configuration#network-safety): it has no authentication of its own.
