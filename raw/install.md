# Install

> Install the onlinesim binary on macOS, Linux or Windows, or let your agent do it with the agent skill.

Prebuilt binaries for every release are on [GitHub Releases](https://github.com/on-org/onlinesim-mcp/releases).
The install scripts pick the right one, put `onlinesim` on disk and print how to connect a client.

<table>
<thead>
  <tr>
    <th>
      OS
    </th>
    
    <th>
      Targets
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      macOS
    </td>
    
    <td>
      <code>
        aarch64-apple-darwin
      </code>
      
      , <code>
        x86_64-apple-darwin
      </code>
      
       (with tray)
    </td>
  </tr>
  
  <tr>
    <td>
      Linux
    </td>
    
    <td>
      <code>
        x86_64
      </code>
      
       / <code>
        aarch64
      </code>
      
      , <code>
        gnu
      </code>
      
       or <code>
        musl
      </code>
      
       (headless, no tray)
    </td>
  </tr>
  
  <tr>
    <td>
      Windows
    </td>
    
    <td>
      <code>
        x86_64-pc-windows-msvc
      </code>
      
      , <code>
        aarch64-pc-windows-msvc
      </code>
      
       (with tray)
    </td>
  </tr>
</tbody>
</table>

## macOS and Linux

```bash
curl -fsSL https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.sh | sh
```

The script downloads the latest release for your OS and CPU into `~/.local/bin/onlinesim`. On macOS it ad-hoc signs
the binary so Gatekeeper lets it run. If `~/.local/bin` is not on `PATH`, it prints the line to add.

<table>
<thead>
  <tr>
    <th>
      Variable
    </th>
    
    <th>
      Default
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
        ONLINESIM_INSTALL_DIR
      </code>
    </td>
    
    <td>
      <code>
        ~/.local/bin
      </code>
    </td>
    
    <td>
      Where to put the binary.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        ONLINESIM_LIBC
      </code>
    </td>
    
    <td>
      <code>
        gnu
      </code>
    </td>
    
    <td>
      Linux only: <code>
        musl
      </code>
      
       for a fully static binary (Alpine, old glibc).
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        ONLINESIM_MCP_REPO
      </code>
    </td>
    
    <td>
      <code>
        on-org/onlinesim-mcp
      </code>
    </td>
    
    <td>
      Repository to download from.
    </td>
  </tr>
</tbody>
</table>

```bash
curl -fsSL https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.sh | ONLINESIM_LIBC=musl sh
```

## Windows

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.ps1 | iex
```

It installs `onlinesim.exe` into `%LOCALAPPDATA%\onlinesim\bin` (override with `$env:ONLINESIM_INSTALL_DIR`) and adds
that folder to your user `PATH`. Open a new terminal afterwards.

## Manual download

Download `onlinesim-<target>.tar.gz` (or `.zip` on Windows) from
[the latest release](https://github.com/on-org/onlinesim-mcp/releases/latest), unpack it and put `onlinesim` somewhere on
`PATH`. Check:

```bash
onlinesim --version
```

## Agent skill

The skill lets the agent install the binary, start the server and ask you for the API key when needed:

```bash
npx skills add on-org/onlinesim-mcp                  # this workspace
npx skills add on-org/onlinesim-mcp -g               # all projects
npx skills add on-org/onlinesim-mcp -a cursor -y     # Cursor only
```

Open a new agent chat. The skill runs `scripts/ensure-ready` first (binary → MCP up → auth). If there is no API key,
the agent asks you to paste it and runs `onlinesim login --apikey …`.

To have the rules in every Cursor chat, copy
[`skills/onlinesim-mcp/rules/onlinesim-mcp.mdc`](https://github.com/on-org/onlinesim-mcp/blob/master/skills/onlinesim-mcp/rules/onlinesim-mcp.mdc)
to `.cursor/rules/` of your project, or paste it into **Cursor → Settings → Rules → User Rules**.

## After installing

```bash
onlinesim login      # paste the API key
onlinesim doctor     # config, key and API reachability
onlinesim mcp        # start the server
```

Then [connect your client](/clients).

## Updates

The CLI checks GitHub for a newer release at most once a day and prints the update command. Run the install script
again to update. Turn the check off with `--no-update-check` or `ONLINESIM_NO_UPDATE=1`.

## Uninstall

```bash
onlinesim mcp autostart uninstall    # if you enabled autostart
onlinesim logout                     # remove the stored key
rm ~/.local/bin/onlinesim
```

On Windows delete `%LOCALAPPDATA%\onlinesim\bin\onlinesim.exe`. The config file location is printed by
`onlinesim config path`.
