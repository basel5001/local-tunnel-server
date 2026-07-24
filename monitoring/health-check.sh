#!/usr/bin/env bash
# health-check.sh — Tunnel health monitoring with auto-restart and notifications
set -euo pipefail

# Configuration (override via environment)
TUNNEL_ENDPOINT="${TUNNEL_ENDPOINT:-http://localhost:8080}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"
LOG_FILE="${LOG_FILE:-/var/log/tunnel-health.log}"
WEBHOOK_URL="${WEBHOOK_URL:-}"
NOTIFY_EMAIL="${NOTIFY_EMAIL:-}"
TUNNEL_SERVICE="${TUNNEL_SERVICE:-tunnel.service}"
MAX_RETRIES="${MAX_RETRIES:-3}"

log() {
  local level="$1" msg="$2"
  echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') [$level] $msg" | tee -a "$LOG_FILE"
}

send_notification() {
  local subject="$1" body="$2"

  if [[ -n "$WEBHOOK_URL" ]]; then
    curl -sf -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{\"text\":\"$subject: $body\"}" &>/dev/null || true
  fi

  if [[ -n "$NOTIFY_EMAIL" ]] && command -v mail &>/dev/null; then
    echo "$body" | mail -s "$subject" "$NOTIFY_EMAIL" || true
  fi
}

check_tunnel() {
  local status_code
  status_code=$(curl -sf -o /dev/null -w "%{http_code}" --max-time 10 "$TUNNEL_ENDPOINT" 2>/dev/null) || status_code="000"

  if [[ "$status_code" =~ ^[23] ]]; then
    return 0
  else
    return 1
  fi
}

restart_tunnel() {
  log "WARN" "Attempting tunnel restart..."
  if sudo systemctl restart "$TUNNEL_SERVICE" 2>/dev/null; then
    log "INFO" "Tunnel service restarted successfully"
    sleep 5
    if check_tunnel; then
      log "INFO" "Tunnel recovered after restart"
      send_notification "Tunnel Recovered" "Tunnel at $TUNNEL_ENDPOINT recovered after restart"
      return 0
    fi
  fi
  log "ERROR" "Tunnel restart failed"
  return 1
}

run_once() {
  if check_tunnel; then
    log "INFO" "Tunnel UP — endpoint: $TUNNEL_ENDPOINT"
    return 0
  else
    log "ERROR" "Tunnel DOWN — endpoint: $TUNNEL_ENDPOINT"
    send_notification "Tunnel Down" "Tunnel at $TUNNEL_ENDPOINT is unreachable"

    local attempt
    for attempt in $(seq 1 "$MAX_RETRIES"); do
      log "WARN" "Restart attempt $attempt/$MAX_RETRIES"
      if restart_tunnel; then
        return 0
      fi
      sleep 10
    done

    log "ERROR" "All restart attempts failed"
    send_notification "Tunnel Critical" "Tunnel at $TUNNEL_ENDPOINT failed after $MAX_RETRIES restart attempts"
    return 1
  fi
}

run_daemon() {
  log "INFO" "Starting health check daemon (interval: ${CHECK_INTERVAL}s)"
  log "INFO" "Monitoring endpoint: $TUNNEL_ENDPOINT"

  while true; do
    run_once || true
    sleep "$CHECK_INTERVAL"
  done
}

case "${1:-daemon}" in
  once)   run_once ;;
  daemon) run_daemon ;;
  *)      echo "Usage: $0 [once|daemon]"; exit 1 ;;
esac
