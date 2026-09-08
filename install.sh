#!/usr/bin/env sh
# Install onlinesim MCP CLI from GitHub Releases.
# Usage: curl -fsSL .../install.sh | sh
set -eu

REPO="${ONLINESIM_MCP_REPO:-on-org/onlinesim-mcp}"
BIN_NAME="onlinesim"
INSTALL_DIR="${ONLINESIM_INSTALL_DIR:-${HOME}/.local/bin}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: '$1' is required" >&2
    exit 1
  }
}

need curl
need uname
need mktemp

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"

case "$os" in
  linux)
    libc="${ONLINESIM_LIBC:-gnu}"
    case "$libc" in
      gnu|musl) os="unknown-linux-${libc}" ;;
      *)
        echo "error: ONLINESIM_LIBC must be gnu or musl (got: $libc)" >&2
        exit 1
        ;;
    esac
    ;;
  darwin) os="apple-darwin" ;;
  mingw*|msys*|cygwin*)
    echo "error: use install.ps1 on Windows" >&2
    exit 1
    ;;
  *)
    echo "error: unsupported OS: $os" >&2
    exit 1
    ;;
esac

case "$arch" in
  x86_64|amd64) arch="x86_64" ;;
  aarch64|arm64) arch="aarch64" ;;
  *)
    echo "error: unsupported arch: $arch" >&2
    exit 1
    ;;
esac

target="${arch}-${os}"
asset="${BIN_NAME}-${target}.tar.gz"

echo "Detecting latest release for ${REPO} (${target})..."
api="https://api.github.com/repos/${REPO}/releases/latest"
tag="$(curl -fsSL "$api" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1)"
if [ -z "$tag" ]; then
  echo "error: could not resolve latest release tag" >&2
  exit 1
fi

url="https://github.com/${REPO}/releases/download/${tag}/${asset}"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "Downloading ${url}"
if ! curl -fsSL "$url" -o "${tmpdir}/${asset}"; then
  echo "error: download failed — is release asset '${asset}' published?" >&2
  exit 1
fi

tar -xzf "${tmpdir}/${asset}" -C "$tmpdir"
mkdir -p "$INSTALL_DIR"
dest="${INSTALL_DIR}/${BIN_NAME}"
install -m 755 "${tmpdir}/${BIN_NAME}" "$dest"
chmod +x "$dest"

# macOS: downloads from the internet get com.apple.quarantine; clear it and
# ad-hoc sign locally (same idea as `codesign --sign -` on .app bundles).
case "$(uname -s)" in
  Darwin)
    echo "macOS: clearing quarantine + ad-hoc codesign..."
    xattr -cr "$dest" 2>/dev/null || true
    if command -v codesign >/dev/null 2>&1; then
      codesign --force --sign - "$dest" || {
        echo "warning: codesign failed — if Gatekeeper blocks the binary, run:" >&2
        echo "  xattr -cr \"$dest\" && codesign --force --sign - \"$dest\"" >&2
      }
    fi
    ;;
esac

echo "Installed ${dest} (${tag})"
case ":$PATH:" in
  *":${INSTALL_DIR}:"*) ;;
  *)
    echo "Note: add ${INSTALL_DIR} to PATH, e.g.:"
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
    ;;
esac

echo
echo "Next:"
echo "  onlinesim login"
echo "  onlinesim doctor"
echo "  onlinesim mcp"
echo "  onlinesim mcp autostart install   # optional: login/reboot background"
echo
echo "MCP endpoint (keep mcp running, or use autostart):"
echo "  http://127.0.0.1:8787/mcp"
echo
echo "Connect (keep onlinesim mcp running):"
echo "  Claude Code global:  claude mcp add --scope user --transport http onlinesim http://127.0.0.1:8787/mcp"
echo "  Claude Code project: claude mcp add --scope project --transport http onlinesim http://127.0.0.1:8787/mcp"
echo "  Codex:               codex mcp add onlinesim --url http://127.0.0.1:8787/mcp"
echo "  Cursor global:       ~/.cursor/mcp.json"
echo "  Cursor project:      .cursor/mcp.json"
echo "  Cursor / Claude JSON: {\"mcpServers\":{\"onlinesim\":{\"type\":\"http\",\"url\":\"http://127.0.0.1:8787/mcp\"}}}"
echo "  VS Code project:     .vscode/mcp.json"
echo "  VS Code JSON:        {\"servers\":{\"onlinesim\":{\"type\":\"http\",\"url\":\"http://127.0.0.1:8787/mcp\"}}}"
echo "  Desktop:             npx -y mcp-remote http://127.0.0.1:8787/mcp --transport http-only"
echo
echo "Docs: https://github.com/on-org/onlinesim-mcp#connect-an-mcp-client"
