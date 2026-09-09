#!/usr/bin/env sh
# Install/update the onlinesim CLI via the canonical public install.sh.
# Usage: bash scripts/install-binary.sh
set -eu

REPO="${ONLINESIM_MCP_REPO:-on-org/onlinesim-mcp}"
URL="https://raw.githubusercontent.com/${REPO}/master/install.sh"

# Prefer a sibling install.sh when developing from the monorepo / synced tree.
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_CANDIDATE=$(CDPATH= cd -- "${SCRIPT_DIR}/../../.." && pwd)
if [ -f "${ROOT_CANDIDATE}/install.sh" ]; then
  # shellcheck disable=SC1091
  exec sh "${ROOT_CANDIDATE}/install.sh"
fi

# skill lives at …/skills/onlinesim-mcp/scripts → repo root is three levels up from scripts,
# but when installed via npx skills the tree is only the skill folder — fall back to curl.
curl -fsSL "${URL}" | sh
