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

## Comparison Guide

### When to use each method:

| Scenario | Best Option |
|----------|-------------|
| Web app with custom domain | Cloudflare Tunnel |
| Game server / TCP traffic | FRP or Rathole |
| IoT / Home automation | DuckDNS + WireGuard |
| Quick one-off access | SSH Reverse Tunnel |
| Maximum performance | Rathole |
| No VPS available | Cloudflare Tunnel |

### Pros & Cons:

**Cloudflare Tunnel** - Zero config networking, automatic HTTPS, DDoS protection. Requires Cloudflare account (free). Only HTTP/HTTPS traffic on free plan.

**DuckDNS + WireGuard** - Full network access (any protocol), encrypted. Requires port forwarding for WireGuard OR a VPS as relay. Free subdomain from DuckDNS.

**FRP** - Any protocol (TCP/UDP/HTTP), multiplexing, dashboard. Requires a VPS. Very flexible.

**Rathole** - Like FRP but written in Rust, faster and lighter. Requires a VPS.

**SSH Tunnel** - No extra software, works anywhere SSH is available. Requires VPS. Can be unstable for long connections.

## Security Notes

- Never expose admin panels (SSH, databases) directly
- Always use HTTPS for web traffic
- Use authentication on all exposed services
- Rotate tunnel credentials regularly
- Consider IP allowlisting where possible

## License

MIT
