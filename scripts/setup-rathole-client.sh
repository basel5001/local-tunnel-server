#!/bin/bash
# Setup Rathole client on your local machine
# Usage: ./setup-rathole-client.sh <vps-ip> [local-port]

set -euo pipefail

VPS_IP="${1:-}"
LOCAL_PORT="${2:-8080}"

if [ -z "$VPS_IP" ]; then
  echo "Usage: $0 <vps-ip> [local-port]"
  exit 1
fi

RATHOLE_VERSION="${RATHOLE_VERSION:-0.5.0}"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS-$ARCH" in
  linux-x86_64) BIN="rathole-x86_64-unknown-linux-gnu" ;;
  linux-aarch64) BIN="rathole-aarch64-unknown-linux-gnu" ;;
  darwin-x86_64) BIN="rathole-x86_64-apple-darwin" ;;
  darwin-arm64) BIN="rathole-aarch64-apple-darwin" ;;
  *) echo "Unsupported: $OS/$ARCH"; exit 1 ;;
esac

echo "Installing Rathole client v${RATHOLE_VERSION}..."

cd /tmp
curl -fsSL "https://github.com/rapiz1/rathole/releases/download/v${RATHOLE_VERSION}/${BIN}.zip" -o rathole.zip
unzip -o rathole.zip
sudo cp rathole /usr/local/bin/
sudo chmod +x /usr/local/bin/rathole
rm -f rathole.zip rathole

# Create config
mkdir -p "$HOME/.rathole"
cat > "$HOME/.rathole/client.toml" << EOF
[client]
remote_addr = "${VPS_IP}:2333"

[client.transport]
type = "tcp"

[client.services.web]
token = "CHANGE_ME_MATCH_SERVER_TOKEN"
local_addr = "127.0.0.1:${LOCAL_PORT}"
EOF

echo ""
echo "Rathole client installed!"
echo "Config: $HOME/.rathole/client.toml"
echo ""
echo "Set the token to match your server config."
echo "Run: rathole --client $HOME/.rathole/client.toml"
echo ""
echo "Exposes localhost:${LOCAL_PORT} via ${VPS_IP}:80"
