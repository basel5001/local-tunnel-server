#!/bin/bash
# Setup FRP (Fast Reverse Proxy) server on your VPS
# Run this on the machine with a public IP

set -euo pipefail

FRP_VERSION="${FRP_VERSION:-0.61.1}"
ARCH=$(uname -m)
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported: $ARCH"; exit 1 ;;
esac

echo "Installing FRP server v${FRP_VERSION}..."

cd /tmp
curl -fsSL "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${ARCH}.tar.gz" -o frp.tar.gz
tar xzf frp.tar.gz
sudo cp "frp_${FRP_VERSION}_linux_${ARCH}/frps" /usr/local/bin/
sudo chmod +x /usr/local/bin/frps
rm -rf frp.tar.gz "frp_${FRP_VERSION}_linux_${ARCH}"

# Create config
sudo mkdir -p /etc/frp
sudo tee /etc/frp/frps.toml > /dev/null << 'EOF'
bindPort = 7000
auth.method = "token"
auth.token = "CHANGE_ME_TO_A_SECURE_TOKEN"

webServer.addr = "0.0.0.0"
webServer.port = 7500
webServer.user = "admin"
webServer.password = "CHANGE_ME_ADMIN_PASSWORD"

# HTTPS
vhostHTTPSPort = 443
vhostHTTPPort = 80
EOF

# Create systemd service
sudo tee /etc/systemd/system/frps.service > /dev/null << 'EOF'
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/frps -c /etc/frp/frps.toml
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable frps
sudo systemctl start frps

echo ""
echo "FRP server installed and running!"
echo ""
echo "IMPORTANT: Edit /etc/frp/frps.toml and change:"
echo "  - auth.token (use a strong random string)"
echo "  - webServer.password"
echo ""
echo "Dashboard: http://$(curl -s ifconfig.me):7500"
echo "Bind port: 7000"
echo ""
echo "Restart after config changes: sudo systemctl restart frps"
