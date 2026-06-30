#!/bin/bash
# Setup Rathole - lightweight reverse proxy (Rust-based, faster than FRP)
# Run this on your VPS

set -euo pipefail

RATHOLE_VERSION="${RATHOLE_VERSION:-0.5.0}"
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="x86_64-unknown-linux-gnu" ;;
  aarch64|arm64) ARCH="aarch64-unknown-linux-gnu" ;;
  *) echo "Unsupported: $ARCH"; exit 1 ;;
esac

echo "Installing Rathole server v${RATHOLE_VERSION}..."

cd /tmp
curl -fsSL "https://github.com/rapiz1/rathole/releases/download/v${RATHOLE_VERSION}/rathole-${ARCH}.zip" -o rathole.zip
unzip -o rathole.zip
sudo cp rathole /usr/local/bin/
sudo chmod +x /usr/local/bin/rathole
rm -f rathole.zip rathole

# Create config
sudo mkdir -p /etc/rathole
sudo tee /etc/rathole/server.toml > /dev/null << 'EOF'
[server]
bind_addr = "0.0.0.0:2333"

[server.transport]
type = "tcp"

[server.services.web]
token = "CHANGE_ME_SECURE_TOKEN"
bind_addr = "0.0.0.0:80"
EOF

# Create systemd service
sudo tee /etc/systemd/system/rathole.service > /dev/null << 'EOF'
[Unit]
Description=Rathole Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/rathole --server /etc/rathole/server.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable rathole
sudo systemctl start rathole

echo ""
echo "Rathole server running!"
echo "  Control port: 2333"
echo "  Service port: 80"
echo ""
echo "Edit /etc/rathole/server.toml to change the token."
echo "Restart: sudo systemctl restart rathole"
