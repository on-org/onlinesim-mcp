---
title: Install
description: Install the onlinesim binary on macOS, Linux or Windows, or let your agent do it with the agent skill.
navigation:
  order: 1
---

Prebuilt binaries for every release are on [GitHub Releases](https://github.com/on-org/onlinesim-mcp/releases).
The install scripts pick the right one, put `onlinesim` on disk and print how to connect a client.

| OS | Targets |
|---|---|
| macOS | `aarch64-apple-darwin`, `x86_64-apple-darwin` (with tray) |
| Linux | `x86_64` / `aarch64`, `gnu` or `musl` (headless, no tray) |
| Windows | `x86_64-pc-windows-msvc`, `aarch64-pc-windows-msvc` (with tray) |

## macOS and Linux

```bash
curl -fsSL https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.sh | sh
```

The script downloads the latest release for your OS and CPU into `~/.local/bin/onlinesim`. On macOS it ad-hoc signs
the binary so Gatekeeper lets it run. If `~/.local/bin` is not on `PATH`, it prints the line to add.

| Variable | Default | Meaning |
|---|---|---|
| `ONLINESIM_INSTALL_DIR` | `~/.local/bin` | Where to put the binary. |
| `ONLINESIM_LIBC` | `gnu` | Linux only: `musl` for a fully static binary (Alpine, old glibc). |
| `ONLINESIM_MCP_REPO` | `on-org/onlinesim-mcp` | Repository to download from. |

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
