#!/usr/bin/env bash
# Start/stop the self-hosted demo: server, then collectors, then generators.
set -euo pipefail
cd "$(dirname "$0")"

server() { docker compose -f selfhosted/docker-compose.yaml "$@"; }
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
