![Security](https://github.com/basel5001/local-tunnel-server/actions/workflows/security.yml/badge.svg)

# Local Tunnel Server

Expose your local server to the internet using **free** software. No static IP or port forwarding needed.

## Solutions Included

| Method | Provider | Cost | Custom Domain | HTTPS | Speed |
|--------|----------|------|---------------|-------|-------|
| Cloudflare Tunnel | Cloudflare | Free | Yes | Yes | Fast |
| DuckDNS + WireGuard | DuckDNS.org | Free | Subdomain | Manual | Fast |
| FRP (Fast Reverse Proxy) | Self-hosted | Free | Yes | Yes | Fast |
| Rathole | Self-hosted | Free | Yes | Yes | Very Fast |
| SSH Reverse Tunnel | Any VPS | Free* | Yes | Manual | OK |

*Requires a VPS with public IP ($0 with Oracle Cloud free tier or similar)

## Quick Start

### Option 1: Cloudflare Tunnel (Recommended - Easiest)

```bash
# Install cloudflared
./scripts/install-cloudflared.sh

# Login and create tunnel
cloudflared tunnel login
cloudflared tunnel create my-server

# Configure
cp configs/cloudflared/config.example.yml configs/cloudflared/config.yml
# Edit config.yml with your tunnel ID and domain

# Run
cloudflared tunnel run my-server
```

### Option 2: DuckDNS + WireGuard VPN

```bash
# Setup DuckDNS dynamic DNS
./scripts/setup-duckdns.sh your-subdomain your-token

# Install WireGuard and configure
./scripts/setup-wireguard.sh
```

### Option 3: FRP (Fast Reverse Proxy)

```bash
# On your VPS (public server)
./scripts/setup-frp-server.sh

# On your local machine
./scripts/setup-frp-client.sh your-vps-ip
```

### Option 4: Rathole (Lightweight alternative to FRP)

```bash
# On your VPS
./scripts/setup-rathole-server.sh

# On your local machine
./scripts/setup-rathole-client.sh your-vps-ip
```

### Option 5: SSH Reverse Tunnel (No extra software)

```bash
# Simple one-liner (expose local port 8080)
./scripts/ssh-tunnel.sh user@your-vps-ip 8080
```

## Docker Compose (All-in-One)

```bash
# Cloudflare Tunnel via Docker
docker compose -f docker-compose.cloudflared.yml up -d

# FRP via Docker
docker compose -f docker-compose.frp.yml up -d
```

## Auto-TLS Certificate Management

Automatically obtain and renew Let's Encrypt TLS certificates:

```bash
# Standard certificate
./scripts/auto-tls.sh tunnel.example.com admin@example.com

# Wildcard certificate (requires DNS plugin credentials)
./scripts/auto-tls.sh example.com admin@example.com true
```

### DNS-01 Challenge (Wildcard)

For wildcard certs, create `/etc/letsencrypt/dns-credentials.ini`:

```ini
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN
```

Then run with `true` as the third argument. Auto-renewal is configured via systemd timer.

## Health Monitoring

### Health Check Script

```bash
# Run once
./monitoring/health-check.sh once

# Run as daemon (checks every 60s)
TUNNEL_ENDPOINT=http://localhost:8080 \
WEBHOOK_URL=https://hooks.slack.com/... \
./monitoring/health-check.sh daemon
```

Environment variables:
- `TUNNEL_ENDPOINT` — URL to check (default: `http://localhost:8080`)
- `CHECK_INTERVAL` — Seconds between checks (default: `60`)
- `WEBHOOK_URL` — Slack/Discord webhook for notifications
- `NOTIFY_EMAIL` — Email for failure alerts
- `MAX_RETRIES` — Restart attempts before alerting (default: `3`)

### Status Dashboard

Open `monitoring/tunnel-status.html` in a browser for a real-time status page showing uptime, connection logs, and tunnel state.

### Systemd Services

Install the systemd units for production use:

```bash
sudo cp systemd/*.service systemd/*.timer /etc/systemd/system/
sudo systemctl daemon-reload

# Start tunnel
sudo systemctl enable --now tunnel.service

# Start health monitoring
sudo systemctl enable --now tunnel-health.service
```

## Architecture

```
                    Internet
                       |
    +------------------+------------------+
    |                  |                  |
    v                  v                  v
Cloudflare         DuckDNS            Your VPS
(Zero Trust)     (Dynamic DNS)     (FRP/Rathole/SSH)
    |                  |                  |
    v                  v                  v
cloudflared        WireGuard         frps/rathole
(tunnel agent)    (VPN tunnel)     (reverse proxy)
    |                  |                  |
    +------------------+------------------+
                       |
                       v
              Your Local Server
              (private IP, no port forwarding)
```

## Security Notes

- Never expose admin panels (SSH, databases) directly
- Always use HTTPS for web traffic
- Use authentication on all exposed services
- Rotate tunnel credentials regularly
- Consider IP allowlisting where possible

## License

MIT
