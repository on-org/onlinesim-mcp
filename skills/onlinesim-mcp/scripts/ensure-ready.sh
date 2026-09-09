#!/usr/bin/env sh
# Ensure onlinesim binary + local MCP HTTP + auth.
# Prints machine-readable key=value lines on stdout.
# Exit: 0 ready | 2 auth missing (ask user for API key) | 1 hard failure
set -eu

ENDPOINT="${ONLINESIM_MCP_ENDPOINT:-http://127.0.0.1:8787/mcp}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INSTALL_SCRIPT="${SCRIPT_DIR}/install-binary.sh"

# Common install path from install.sh
export PATH="${HOME}/.local/bin:${PATH}"

emit() {
  printf '%s\n' "$1"
}

find_bin() {
  if command -v onlinesim >/dev/null 2>&1; then
    command -v onlinesim
    return 0
  fi
  if [ -x "${HOME}/.local/bin/onlinesim" ]; then
    printf '%s\n' "${HOME}/.local/bin/onlinesim"
    return 0
  fi
  return 1
}

mcp_up() {
  code=$(curl -sS -o /dev/null -w '%{http_code}' -m 2 "$ENDPOINT" 2>/dev/null || printf '000')
  case "$code" in
    000) return 1 ;;
    *) return 0 ;;
  esac
}

binary_status=missing
mcp_status=down
auth_status=unknown

BIN=""
if BIN=$(find_bin); then
  binary_status=ok
else
  emit "# installing onlinesim binary…" >&2
  if ! sh "$INSTALL_SCRIPT"; then
    emit "binary=fail"
    emit "mcp=down"
    emit "auth=unknown"
    emit "endpoint=${ENDPOINT}"
    emit "error=binary_install_failed"
    exit 1
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
  if BIN=$(find_bin); then
    binary_status=installed
  else
    emit "binary=fail"
    emit "mcp=down"
    emit "auth=unknown"
    emit "endpoint=${ENDPOINT}"
    emit "error=binary_not_on_path_after_install"
    emit "hint=export PATH=\"\$HOME/.local/bin:\$PATH\""
    exit 1
  fi
fi

if mcp_up; then
  mcp_status=up
else
  emit "# starting onlinesim mcp --no-tray…" >&2
  log="${TMPDIR:-/tmp}/onlinesim-mcp-ensure.log"
  "$BIN" mcp autostart start >/dev/null 2>&1 || true
  if ! mcp_up; then
    nohup "$BIN" mcp --no-tray >>"$log" 2>&1 &
    i=0
    while [ "$i" -lt 20 ]; do
      if mcp_up; then
        mcp_status=started
        break
      fi
      i=$((i + 1))
      sleep 0.25
    done
  else
    mcp_status=started
  fi
  if ! mcp_up; then
    mcp_status=fail
    emit "binary=${binary_status}"
    emit "mcp=fail"
    emit "auth=unknown"
    emit "endpoint=${ENDPOINT}"
    emit "error=mcp_start_failed"
    emit "log=${log}"
    exit 1
  fi
  if [ "$mcp_status" = "down" ]; then
    mcp_status=started
  fi
fi

# Auth: doctor succeeds only with a working key (or mock/dev).
if "$BIN" doctor >/dev/null 2>&1; then
  auth_status=ok
elif "$BIN" --format json balance >/dev/null 2>&1; then
  auth_status=ok
else
  auth_status=missing
fi

emit "binary=${binary_status}"
emit "mcp=${mcp_status}"
emit "auth=${auth_status}"
emit "endpoint=${ENDPOINT}"
emit "bin=${BIN}"

if [ "$auth_status" = "missing" ]; then
  emit "action=ask_api_key"
  emit "site=https://onlinesim.io/"
  emit "topup=https://onlinesim.io/v2/payment"
  emit "login=onlinesim login --apikey <KEY>"
  exit 2
fi

emit "action=ready"
exit 0
