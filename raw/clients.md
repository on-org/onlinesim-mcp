# Connect a client

> Point Cursor, Claude Code, VS Code Copilot, Codex, Claude Desktop or any Streamable HTTP MCP client at onlinesim mcp.

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

<table>
<thead>
  <tr>
    <th>
      Flag
    </th>
    
    <th>
      Meaning
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        --client
      </code>
    </td>
    
    <td>
      <code>
        cursor
      </code>
      
       (default), <code>
        vscode
      </code>
      
      , <code>
        claude
      </code>
      
      , <code>
        codex
      </code>
      
      , <code>
        all
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        --project
      </code>
      
       / <code>
        --global
      </code>
    </td>
    
    <td>
      Project file (default) or user-wide file
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        --dir <path>
      </code>
    </td>
    
    <td>
      Project root (default: current directory)
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        --url <url>
      </code>
    </td>
    
    <td>
      Endpoint (default <code>
        http://127.0.0.1:8787/mcp
      </code>
      
      )
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        --force
      </code>
    </td>
    
    <td>
      Overwrite an existing <code>
        onlinesim
      </code>
      
       entry
    </td>
  </tr>
</tbody>
</table>

The tray menu has the same install items.

## Cursor

<table>
<thead>
  <tr>
    <th>
      Scope
    </th>
    
    <th>
      File
    </th>
    
    <th>
      CLI
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      Project
    </td>
    
    <td>
      <code>
        .cursor/mcp.json
      </code>
    </td>
    
    <td>
      <code>
        onlinesim mcp install
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Global
    </td>
    
    <td>
      <code>
        ~/.cursor/mcp.json
      </code>
    </td>
    
    <td>
      <code>
        onlinesim mcp install --client cursor --global
      </code>
    </td>
  </tr>
</tbody>
</table>

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

<table>
<thead>
  <tr>
    <th>
      Scope
    </th>
    
    <th>
      How
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      Project (shared via git)
    </td>
    
    <td>
      <code>
        onlinesim mcp install --client claude --project
      </code>
      
       → <code>
        .mcp.json
      </code>
      
       (same JSON as Cursor)
    </td>
  </tr>
  
  <tr>
    <td>
      Global (all projects)
    </td>
    
    <td>
      <code>
        onlinesim mcp install --client claude --global
      </code>
      
      , or <code>
        claude mcp add --scope user --transport http onlinesim http://127.0.0.1:8787/mcp
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      Local (you, this project)
    </td>
    
    <td>
      <code>
        claude mcp add --transport http onlinesim http://127.0.0.1:8787/mcp
      </code>
    </td>
  </tr>
</tbody>
</table>

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
servers). Use a stdio bridge instead:```json
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
