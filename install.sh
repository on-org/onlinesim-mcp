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
  linux) os="unknown-linux-gnu" ;;
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
install -m 755 "${tmpdir}/${BIN_NAME}" "${INSTALL_DIR}/${BIN_NAME}"

echo "Installed ${INSTALL_DIR}/${BIN_NAME} (${tag})"
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
echo
echo "MCP (Streamable HTTP):"
echo "  onlinesim mcp"
echo "  endpoint: http://127.0.0.1:8787/mcp"
echo "  Claude Code: claude mcp add --transport http onlinesim http://127.0.0.1:8787/mcp"
