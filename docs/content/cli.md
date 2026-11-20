---
title: CLI
description: The MCP tools from the terminal — onlinesim sms, rent, balance — with a stable JSON envelope for scripts.
navigation:
  order: 4
---

The CLI runs the same operations as the [MCP tools](/tools) and prints the same text. Every command has `--help`.

## Account

```bash
onlinesim login                 # save the API key (prompted, hidden)
onlinesim login --apikey KEY    # non-interactive
onlinesim logout                # remove the stored key
onlinesim doctor                # config, key, API reachability, endpoint
onlinesim balance
```

`login` checks the key with the balance request. A key the API rejects (`ERROR_WRONG_KEY`) is not saved; on a network
error the key is saved with a warning.

## Quick SMS

```bash
onlinesim sms search                    # top services
onlinesim sms search telegram
onlinesim sms countries telegram        # countries, prices, stock
onlinesim sms list-countries            # every country, no service filter
onlinesim sms order telegram 7          # serviceId countryId — reserves the price
onlinesim sms check                     # all active orders
onlinesim sms check 1001 1002
onlinesim sms cancel 1001               # without ids: closes ALL active orders
onlinesim sms list                      # active orders and rentals
```

## Rent

```bash
onlinesim rent list                     # countries and day tiers
onlinesim rent order 7 3                # rentalId days — reserves, first SMS charges
onlinesim rent messages                 # all rentals; or: rent messages 1001
onlinesim rent extend 1001 1            # days: an extension period shown by `rent messages`
onlinesim rent cancel 1001              # without ids: closes ALL active rentals
```

## Server and clients

```bash
onlinesim mcp                           # start the MCP server (tray where available)
onlinesim mcp --bind 127.0.0.1:9000
onlinesim mcp --no-tray
onlinesim mcp install [--client cursor|vscode|claude|codex|all] [--project|--global]
onlinesim mcp autostart install|status|start|uninstall
```

See [Connect a client](/clients) and [Configuration](/configuration).

## Settings

```bash
onlinesim config show                   # path, base URL, language, key status (never the key)
onlinesim config path
onlinesim config set --lang ru
onlinesim config set --base-url https://onlinesim.host/api/
```

## JSON output

`--format json` prints one envelope on stdout, for scripts and integrations:

```bash
onlinesim --format json sms search tele
```

```json
{
  "ok": true,
  "command": "sms.search",
  "data": {
    "query": "tele",
    "total": 1,
    "services": [
      { "service_id": "telegram", "name": "telegram", "countries": 1, "min_price": 1.2 }
    ]
  }
}
```

On failure `ok` is `false` and the exit code is non-zero:

```json
{
  "ok": false,
  "command": "sms.countries",
  "error": {
    "code": "ERROR_NO_SERVICE",
    "message": "No matching SMS service in stock (or service missing). …"
  }
}
```

`command` is `balance`, `sms.search`, `sms.countries`, `sms.list-countries`, `sms.order`, `sms.check`, `sms.cancel`,
`sms.list`, `rent.list`, `rent.order`, `rent.messages`, `rent.extend`, `rent.cancel`, `login`, `doctor`,
`config.show`, ….

## Global flags

| Flag | Meaning |
|---|---|
| `--format text\|json` | Human text (default) or the JSON envelope. |
| `--color auto\|always\|never` | Colors in text output. |
| `-v`, `--verbose` | Debug logs on stderr (ignored when `RUST_LOG` is set). |
| `--no-update-check` | Skip the daily GitHub release check. |
