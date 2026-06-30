#!/bin/bash
# SSH Reverse Tunnel - expose local port via any VPS
# Usage: ./ssh-tunnel.sh user@vps-ip [local-port] [remote-port]
# No extra software needed - just SSH!

set -euo pipefail

VPS="${1:-}"
LOCAL_PORT="${2:-8080}"
REMOTE_PORT="${3:-80}"

if [ -z "$VPS" ]; then
  echo "Usage: $0 user@vps-ip [local-port] [remote-port]"
  echo ""
  echo "Example: $0 root@203.0.113.1 8080 80"
  echo "This exposes localhost:8080 at vps-ip:80"
  exit 1
fi

echo "Creating SSH reverse tunnel..."
echo "  Local:  localhost:${LOCAL_PORT}"
echo "  Remote: ${VPS}:${REMOTE_PORT}"
echo ""
echo "Press Ctrl+C to stop."
echo ""

# -R: remote port forwarding
# -N: no remote command
# -o ServerAliveInterval: keep connection alive
# -o ExitOnForwardFailure: fail if port is busy
ssh -R "${REMOTE_PORT}:localhost:${LOCAL_PORT}" \
    -N \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    "$VPS"
