# Configuration

> API key, config file and environment, logs, autostart, the system tray and network safety of onlinesim mcp.

## API key

The key comes from your [OnlineSim profile](https://onlinesim.io/v2/profile/api). The server and the CLI read it from,
in this order:

1. `ONLINESIM_APIKEY` (environment);
2. the config file written by `onlinesim login`.

It is sent to the API as `Authorization: Bearer <key>`, never in a URL, and never appears in tool arguments, answers
or logs. A running server re-reads the config on each tool call, so `onlinesim login` / `logout` take effect without a
restart.

## Config file

`onlinesim config path` prints it: `~/.config/onlinesim/config.json` on Linux,
`~/Library/Application Support/io.onlinesim.onlinesim/config.json` on macOS,
`%APPDATA%\onlinesim\onlinesim\config\config.json` on Windows.

```json
{
  "apikey": "…",
  "base_url": "https://onlinesim.host/api/",
  "lang": "en"
}
```

<table>
<thead>
  <tr>
    <th>
      Field
    </th>
    
    <th>
      Default
    </th>
    
    <th>
      Set with
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      <code>
        apikey
      </code>
    </td>
    
    <td>
      —
    </td>
    
    <td>
      <code>
        onlinesim login
      </code>
      
       / <code>
        onlinesim logout
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        base_url
      </code>
    </td>
    
    <td>
      <code>
        https://onlinesim.host/api/
      </code>
    </td>
    
    <td>
      <code>
        onlinesim config set --base-url …
      </code>
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        lang
      </code>
    </td>
    
    <td>
      <code>
        en
      </code>
    </td>
    
    <td>
      <code>
        onlinesim config set --lang ru
      </code>
      
       (language of API texts)
    </td>
  </tr>
</tbody>
</table>

## Environment

<table>
<thead>
  <tr>
    <th>
      Variable
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
        ONLINESIM_APIKEY
      </code>
    </td>
    
    <td>
      API key; overrides the config file.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        ONLINESIM_NO_UPDATE
      </code>
    </td>
    
    <td>
      <code>
        1
      </code>
      
       turns off the daily release check.
    </td>
  </tr>
  
  <tr>
    <td>
      <code>
        RUST_LOG
      </code>
    </td>
    
    <td>
      Log filter, e.g. <code>
        onlinesim_mcp=debug
      </code>
      
       (wins over <code>
        -v
      </code>
      
      ).
    </td>
  </tr>
</tbody>
</table>

## Logs

`onlinesim mcp` logs to stderr at `info`: start-up (bind address, where the key comes from — never the key), each tool
call with its duration and result, and wait start / finish (the outcome only, never the SMS text or code).

```bash
onlinesim mcp                                  # onlinesim_mcp=info
onlinesim -v mcp                               # onlinesim_mcp=debug (catalog cache, …)
RUST_LOG=onlinesim_mcp=debug onlinesim mcp     # explicit filter
```

## Autostart

Start the server at login / reboot, the same way on every OS:

<table>
<thead>
  <tr>
    <th>
      OS
    </th>
    
    <th>
      User (default)
    </th>
    
    <th>
      <code>
        --system
      </code>
    </th>
  </tr>
</thead>

<tbody>
  <tr>
    <td>
      Windows
    </td>
    
    <td>
      HKCU Run
    </td>
    
    <td>
      HKLM Run (admin)
    </td>
  </tr>
  
  <tr>
    <td>
      macOS
    </td>
    
    <td>
      LaunchAgent in <code>
        ~/Library/LaunchAgents
      </code>
    </td>
    
    <td>
      LaunchDaemon (sudo)
    </td>
  </tr>
  
  <tr>
    <td>
      Linux
    </td>
    
    <td>
      systemd <code>
        --user
      </code>
    </td>
    
    <td>
      systemd system unit (sudo)
    </td>
  </tr>
</tbody>
</table>

```bash
onlinesim mcp autostart install               # enable + start in the background
onlinesim mcp autostart install --bind 127.0.0.1:8787
onlinesim mcp autostart status
onlinesim mcp autostart start                 # start now, autostart unchanged
onlinesim mcp autostart uninstall
sudo onlinesim mcp autostart install --system
```

The user level runs as you, so `onlinesim login` and the config keep working.

## System tray

While `onlinesim mcp` runs, a tray icon shows the available balance and the active Quick SMS and rental numbers, and
lets you:

- copy a number, an SMS code or the full message;
- get a desktop notification on a new SMS (the code is copied automatically) — toggle **Notify on SMS**;
- cancel a Quick SMS order;
- install the Cursor / VS Code client config;
- toggle **Start at login**;
- **Quit MCP**.

`--no-tray` runs headless (SSH, CI). On Linux the tray needs a desktop session (`DISPLAY` / `WAYLAND_DISPLAY`) and the
GTK / AppIndicator libraries (`libgtk-3`, `libayatana-appindicator3`); the Linux release binaries are headless.

## Network safety

The MCP endpoint has **no authentication**: anyone who can reach it can spend your balance. It binds to
`127.0.0.1:8787` and refuses other addresses unless you pass `--allow-remote`:

```bash
onlinesim mcp --bind 0.0.0.0:8787 --allow-remote
```

Do that only behind your own HTTPS and access control (a reverse proxy with auth, a VPN). Requests with a `Host` header
other than the bind address and loopback are rejected.
