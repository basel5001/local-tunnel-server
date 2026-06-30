#!/bin/bash
# Setup FRP client on your local machine
# Usage: ./setup-frp-client.sh <vps-ip> [local-port] [remote-port]

set -euo pipefail

VPS_IP="${1:-}"
LOCAL_PORT="${2:-8080}"
REMOTE_PORT="${3:-80}"

if [ -z "$VPS_IP" ]; then
  echo "Usage: $0 <vps-ip> [local-port] [remote-port]"
  echo "Example: $0 203.0.113.1 8080 80"
  exit 1
fi

FRP_VERSION="${FRP_VERSION:-0.61.1}"
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported: $ARCH"; exit 1 ;;
esac

echo "Installing FRP client v${FRP_VERSION}..."

cd /tmp
if [ "$OS" = "darwin" ]; then
  curl -fsSL "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_darwin_${ARCH}.tar.gz" -o frp.tar.gz
else
  curl -fsSL "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${ARCH}.tar.gz" -o frp.tar.gz
fi
tar xzf frp.tar.gz
sudo cp frp_${FRP_VERSION}_*/frpc /usr/local/bin/
sudo chmod +x /usr/local/bin/frpc
rm -rf frp.tar.gz frp_${FRP_VERSION}_*

# Create config
mkdir -p "$HOME/.frp"
cat > "$HOME/.frp/frpc.toml" << EOF
serverAddr = "${VPS_IP}"
serverPort = 7000
auth.method = "token"
auth.token = "CHANGE_ME_TO_MATCH_SERVER_TOKEN"

[[proxies]]
name = "web"
type = "tcp"
localIP = "127.0.0.1"
localPort = ${LOCAL_PORT}
remotePort = ${REMOTE_PORT}

# Uncomment for HTTP with custom domain:
# [[proxies]]
# name = "web-http"
# type = "http"
# localPort = ${LOCAL_PORT}
# customDomains = ["myapp.example.com"]
EOF

echo ""
echo "FRP client installed!"
echo "Config: $HOME/.frp/frpc.toml"
echo ""
echo "IMPORTANT: Edit the config and set auth.token to match your server."
echo ""
echo "Run: frpc -c $HOME/.frp/frpc.toml"
echo ""
echo "This will expose localhost:${LOCAL_PORT} at ${VPS_IP}:${REMOTE_PORT}"
