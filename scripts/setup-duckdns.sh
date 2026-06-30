#!/bin/bash
# Setup DuckDNS dynamic DNS updater
# Usage: ./setup-duckdns.sh <subdomain> <token>

set -euo pipefail

SUBDOMAIN="${1:-}"
TOKEN="${2:-}"

if [ -z "$SUBDOMAIN" ] || [ -z "$TOKEN" ]; then
  echo "Usage: $0 <subdomain> <token>"
  echo ""
  echo "Get your token at: https://www.duckdns.org"
  echo "Example: $0 myserver abc123-your-token-here"
  exit 1
fi

echo "Setting up DuckDNS for ${SUBDOMAIN}.duckdns.org..."

# Create update script
DUCK_DIR="$HOME/.duckdns"
mkdir -p "$DUCK_DIR"

cat > "$DUCK_DIR/update.sh" << EOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=${SUBDOMAIN}&token=${TOKEN}&ip=" | curl -k -o "$DUCK_DIR/duck.log" -K -
EOF
chmod +x "$DUCK_DIR/update.sh"

# Test the update
echo "Testing DNS update..."
bash "$DUCK_DIR/update.sh"
RESULT=$(cat "$DUCK_DIR/duck.log")
if [ "$RESULT" = "OK" ]; then
  echo "DuckDNS update successful!"
else
  echo "ERROR: DuckDNS update failed. Check your token."
  exit 1
fi

# Setup cron job (every 5 minutes)
CRON_LINE="*/5 * * * * $DUCK_DIR/update.sh >/dev/null 2>&1"
(crontab -l 2>/dev/null | grep -v duckdns; echo "$CRON_LINE") | crontab -

echo ""
echo "Setup complete!"
echo "  Domain: ${SUBDOMAIN}.duckdns.org"
echo "  Update script: $DUCK_DIR/update.sh"
echo "  Cron: every 5 minutes"
echo "  Log: $DUCK_DIR/duck.log"
