#!/bin/bash
# Install Cloudflare Tunnel (cloudflared)
# Works on Linux (amd64/arm64) and macOS

set -euo pipefail

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  armv7l) ARCH="arm" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "Installing cloudflared for $OS/$ARCH..."

if [ "$OS" = "darwin" ]; then
  if command -v brew &>/dev/null; then
    brew install cloudflared
  else
    echo "Install Homebrew first: https://brew.sh"
    exit 1
  fi
elif [ "$OS" = "linux" ]; then
  RELEASE_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"
  sudo curl -fsSL "$RELEASE_URL" -o /usr/local/bin/cloudflared
  sudo chmod +x /usr/local/bin/cloudflared
fi

echo "Installed: $(cloudflared --version)"

echo ""
echo "Next steps:"
echo "  1. cloudflared tunnel login"
echo "  2. cloudflared tunnel create my-server"
echo "  3. Configure configs/cloudflared/config.yml"
echo "  4. cloudflared tunnel run my-server"
