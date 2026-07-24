#!/usr/bin/env bash
# auto-tls.sh — Automatic TLS certificate management with Let's Encrypt
set -euo pipefail

DOMAIN="${1:-}"
EMAIL="${2:-}"
WILDCARD="${3:-false}"
CERT_DIR="/etc/letsencrypt/live"

usage() {
  echo "Usage: $0 <domain> <email> [wildcard:true|false]"
  echo ""
  echo "Examples:"
  echo "  $0 tunnel.example.com admin@example.com"
  echo "  $0 example.com admin@example.com true   # Wildcard *.example.com"
  exit 1
}

[[ -z "$DOMAIN" || -z "$EMAIL" ]] && usage

install_certbot() {
  if command -v certbot &>/dev/null; then
    echo "[INFO] certbot already installed: $(certbot --version 2>&1)"
    return
  fi

  echo "[INFO] Installing certbot..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y certbot python3-certbot-dns-cloudflare
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y certbot python3-certbot-dns-cloudflare
  elif command -v yum &>/dev/null; then
    sudo yum install -y certbot python3-certbot-dns-cloudflare
  else
    echo "[ERROR] Unsupported package manager. Install certbot manually."
    exit 1
  fi
}

request_certificate() {
  local args=(
    --non-interactive
    --agree-tos
    --email "$EMAIL"
  )

  if [[ "$WILDCARD" == "true" ]]; then
    echo "[INFO] Requesting wildcard certificate for *.$DOMAIN via DNS-01 challenge"
    echo "[NOTE] Ensure DNS plugin credentials are configured at /etc/letsencrypt/dns-credentials.ini"
    args+=(
      certonly
      --dns-cloudflare
      --dns-cloudflare-credentials /etc/letsencrypt/dns-credentials.ini
      -d "$DOMAIN"
      -d "*.$DOMAIN"
    )
  else
    echo "[INFO] Requesting certificate for $DOMAIN via HTTP-01 challenge"
    args+=(
      certonly
      --standalone
      -d "$DOMAIN"
    )
  fi

  sudo certbot "${args[@]}"
}

setup_auto_renewal() {
  echo "[INFO] Setting up auto-renewal via systemd timer..."

  sudo tee /etc/systemd/system/certbot-renewal.service >/dev/null <<EOF
[Unit]
Description=Certbot Renewal
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/certbot renew --quiet --deploy-hook "systemctl reload tunnel.service"
EOF

  sudo tee /etc/systemd/system/certbot-renewal.timer >/dev/null <<EOF
[Unit]
Description=Certbot Renewal Timer

[Timer]
OnCalendar=*-*-* 02:30:00
RandomizedDelaySec=3600
Persistent=true

[Install]
WantedBy=timers.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now certbot-renewal.timer
  echo "[INFO] Auto-renewal timer active. Certificates renew daily at ~02:30."
}

verify_certificate() {
  if [[ -d "$CERT_DIR/$DOMAIN" ]]; then
    echo "[INFO] Certificate installed at $CERT_DIR/$DOMAIN/"
    echo "  Fullchain: $CERT_DIR/$DOMAIN/fullchain.pem"
    echo "  Key:       $CERT_DIR/$DOMAIN/privkey.pem"
    sudo openssl x509 -in "$CERT_DIR/$DOMAIN/fullchain.pem" -noout -dates
  else
    echo "[WARN] Certificate directory not found. Check certbot logs."
  fi
}

main() {
  echo "=== Auto-TLS Certificate Management ==="
  install_certbot
  request_certificate
  setup_auto_renewal
  verify_certificate
  echo "[DONE] TLS setup complete for $DOMAIN"
}

main
