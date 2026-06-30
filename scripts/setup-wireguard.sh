#!/bin/bash
# Setup WireGuard VPN tunnel between local machine and VPS
# Run this on your LOCAL machine
# Prerequisites: WireGuard installed, a VPS with public IP

set -euo pipefail

VPS_IP="${1:-}"
if [ -z "$VPS_IP" ]; then
  echo "Usage: $0 <vps-public-ip>"
  echo ""
  echo "This sets up WireGuard to tunnel traffic through your VPS."
  echo "You'll need to also run the server setup on your VPS."
  exit 1
fi

# Check if WireGuard is installed
if ! command -v wg &>/dev/null; then
  echo "Installing WireGuard..."
  if [ -f /etc/debian_version ]; then
    sudo apt-get update && sudo apt-get install -y wireguard
  elif [ -f /etc/redhat-release ]; then
    sudo dnf install -y wireguard-tools
  elif command -v brew &>/dev/null; then
    brew install wireguard-tools
  else
    echo "Please install WireGuard manually: https://www.wireguard.com/install/"
    exit 1
  fi
fi

# Generate keys
WG_DIR="$HOME/.wireguard"
mkdir -p "$WG_DIR"
chmod 700 "$WG_DIR"

if [ ! -f "$WG_DIR/privatekey" ]; then
  wg genkey | tee "$WG_DIR/privatekey" | wg pubkey > "$WG_DIR/publickey"
  chmod 600 "$WG_DIR/privatekey"
fi

CLIENT_PRIVATE=$(cat "$WG_DIR/privatekey")
CLIENT_PUBLIC=$(cat "$WG_DIR/publickey")

echo "=== WireGuard Client Setup ==="
echo ""
echo "Your public key (give this to the VPS): $CLIENT_PUBLIC"
echo ""

# Generate client config
cat > "$WG_DIR/wg0.conf" << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE}
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
# VPS public key (replace with actual key from VPS setup)
PublicKey = REPLACE_WITH_VPS_PUBLIC_KEY
Endpoint = ${VPS_IP}:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

echo "Client config written to: $WG_DIR/wg0.conf"
echo ""
echo "Next steps:"
echo "  1. Run the server setup on your VPS"
echo "  2. Replace REPLACE_WITH_VPS_PUBLIC_KEY in $WG_DIR/wg0.conf"
echo "  3. Start: sudo wg-quick up $WG_DIR/wg0.conf"
echo "  4. Stop:  sudo wg-quick down $WG_DIR/wg0.conf"
echo ""
echo "=== VPS Server Config (run on VPS) ==="
echo ""
cat << EOF
# Generate server keys on VPS:
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey

# Create /etc/wireguard/wg0.conf:
[Interface]
PrivateKey = <VPS_PRIVATE_KEY>
Address = 10.0.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = ${CLIENT_PUBLIC}
AllowedIPs = 10.0.0.2/32

# Then: sudo systemctl enable --now wg-quick@wg0
EOF
