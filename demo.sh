#!/usr/bin/env bash
# Start/stop the self-hosted demo: server, then collectors, then generators.
set -euo pipefail
cd "$(dirname "$0")"

# An exported empty BINDPLANE_LICENSE in the shell shadows selfhosted/.env in
# Compose, clear it so the .env value wins. No-op if it was never set.
unset BINDPLANE_LICENSE || true

server() {
  local f=(-f selfhosted/docker-compose.yaml)
  [ -f selfhosted/docker-compose.override.yaml ] && f+=(-f selfhosted/docker-compose.override.yaml)
  docker compose "${f[@]}" "$@"
}
collectors() { docker compose "$@"; }
blitz() { docker compose -f docker-compose.blitz.yaml "$@"; }

case "${1:-}" in
  up)
    server up -d
    until curl -sf -o /dev/null http://localhost:3001/; do sleep 2; done
    collectors up -d
    blitz up -d
    chmod 644 logs/*/*.log 2>/dev/null || true
    ;;
  down) blitz down; collectors down; server down ;;
  stop) blitz stop; collectors stop; server stop ;;
  start)
    server start
    until curl -sf -o /dev/null http://localhost:3001/; do sleep 2; done
    collectors start
    blitz start
    ;;
  status)
    for s in server collectors blitz; do echo "== $s"; $s ps --format '{{.Name}}\t{{.Status}}'; done
    ;;
  *) echo "usage: $0 up|down|start|stop|status" >&2; exit 1 ;;
esac
