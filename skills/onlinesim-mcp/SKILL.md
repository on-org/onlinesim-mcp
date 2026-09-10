---
name: onlinesim-mcp
description: >
  Install and keep Onlinesim local MCP ready (CLI binary, HTTP server, API
  login) for SMS verification numbers. Use at session start when this skill is
  installed, and whenever the user mentions Onlinesim, SMS codes, receive-only
  numbers, temporary phones, Quick SMS, rentals, or MCP SMS tools. Runs
  scripts/ensure-ready, asks for API key in chat if missing, wires clients,
  and follows the Quick SMS / Rent playbook. Never put the API key in MCP tool
  arguments.
---

# Onlinesim MCP

Local Streamable HTTP MCP + CLI for [Onlinesim](https://onlinesim.io/) (receive-only SMS numbers).

**Site:** https://onlinesim.io/  
**Top up:** https://onlinesim.io/v2/payment  
**Public install (no agent):** `curl -fsSL https://raw.githubusercontent.com/on-org/onlinesim-mcp/master/install.sh | sh` (Windows: `irm …/install.ps1 | iex`)

## Persistence — run ensure first

At the **start of the session** (when this skill is available) and **before any** Onlinesim / SMS / MCP-number work:

1. Resolve this skill directory (folder that contains this `SKILL.md`).
2. Run the ensure script with the shell tool:
   - macOS / Linux: `bash "<skill>/scripts/ensure-ready.sh"`
   - Windows: `pwsh -File "<skill>/scripts/ensure-ready.ps1"`
3. Read stdout `key=value` lines (`binary=`, `mcp=`, `auth=`, `endpoint=`, `action=`).

Do **not** skip this because the user did not say “install”.

### Act on status

| Status | Action |
|--------|--------|
| `action=ready` | Continue with the user task / playbook |
| `auth=missing` / `action=ask_api_key` | Ask the user to **paste their Onlinesim API key** in chat. Link site + top-up. Then run `onlinesim login --apikey '<key>'` (do not echo the key back, do not pass it to MCP tools). Re-run ensure. |
| `binary=fail` / `mcp=fail` | Show `error=` / `log=` once; fix PATH or retry install once |

Optional always-on (every Cursor chat): copy [`rules/onlinesim-mcp.mdc`](rules/onlinesim-mcp.mdc) into the project `.cursor/rules/` or paste into **Cursor → Settings → Rules → User Rules**.

## After ready

1. Confirm client wiring if tools are missing: `onlinesim mcp install` (Cursor project default) or `--client cursor --global` / `vscode` / `claude` / `codex` / `all`.
2. Prefer the **MCP tools** when connected; CLI (`onlinesim sms|rent|…`) is fine as fallback.
3. Keep the server up (`ensure-ready` starts `onlinesim mcp --no-tray` in the background). For a tray UI on a desktop: user can run `onlinesim mcp` themselves or `onlinesim mcp autostart install`.

## Security

- API key: local config (`onlinesim login`) or `ONLINESIM_APIKEY` only.
- **Never** put the key in MCP tool arguments, commits, or repeated chat echoes.
- Non-loopback binds need `--allow-remote` (no auth on the MCP port — warn the user).

## Quick SMS playbook (do not invent ids)

1. `get_account_balance` (or `onlinesim balance`) — if low, send top-up link.
2. `search_sms_services` → `find_cheapest_sms_countries` / `get_sms_service_countries`.
   Full country directory (no service): `list_sms_countries`.
3. `order_sms_verification` with catalog `serviceId` + `countryId` only (spends balance).
4. User enters the phone on the target site/app and requests SMS.
5. Prefer `wait_sms_verification(orderId)`; else poll `check_sms_verification` every 15–30s.
6. `cancel_sms_verification` when done (early cancel ~2 min may return `NO_COMPLETE_TZID`).

Ids in `[brackets]`: `serviceId` (slug), `countryId`/`rentalId` (numeric), Order/Receipt ID (`tzid`).  
Statuses: `TZ_NUM_WAIT` = waiting; `TZ_NUM_ANSWER` = code received.

## Rent playbook (separate tools — do not mix with Quick SMS)

`list_sms_rentals` → `rent_sms_number` → `get_sms_rental_messages` / `extend_sms_rental` / `cancel_sms_rental`.

## Scripts in this skill

| Script | Role |
|--------|------|
| `scripts/ensure-ready.sh` / `.ps1` | Binary + MCP up + auth check |
| `scripts/install-binary.sh` / `.ps1` | Calls public `install.sh` / `install.ps1` (GitHub Releases) |
