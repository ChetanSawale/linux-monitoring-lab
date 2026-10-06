#!/usr/bin/env bash
# Drill 1 — Service outage.
# Stops demo-app, watches the DemoAppDown (critical) alert fire end-to-end,
# then recovers. This is the full L1 loop: detect -> diagnose -> fix -> document.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== Drill 1: service outage (demo-app) ==="
echo
echo "[1/4] Stopping demo-app..."
docker compose stop demo-app
echo
echo "[2/4] Detect. Open these and watch for DemoAppDown (critical, ~1-2 min):"
echo "      Prometheus alerts : http://localhost:9090/alerts"
echo "      Alertmanager      : http://localhost:9093"
echo "      Webhook log       : tail -f alert-receiver/data/alerts.log"
echo
read -rp "Press Enter once DemoAppDown is FIRING (or after ~3 minutes)..."
echo
echo "[3/4] Diagnose — what an L1 checks first:"
docker compose ps demo-app || true
echo "--- last log lines ---"
docker compose logs --tail=15 demo-app || true
echo "--- is the port still answering? ---"
(curl -s -m 3 http://localhost:8080/ || echo "connection refused -> service is down") 
echo
echo "[4/4] Recover:"
docker compose start demo-app
sleep 5
curl -s http://localhost:8080/ || echo "(still starting, retry in a few seconds)"
echo
echo "Done. The alert should move to resolved; check alerts.log for the resolved notification."
echo "Now document it: copy incident-reports/TEMPLATE.md to"
echo "  incident-reports/INCIDENT-$(date +%F)-demo-app-outage.md"
echo "The worked example INCIDENT-2026-10-06-demo-app-outage.md shows the expected depth."
