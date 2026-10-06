#!/usr/bin/env bash
# Drill 3 — CPU spike.
# Burns CPU in a throwaway container for 6 minutes so the HighCpuLoad alert
# (80% for 5m) fires, then stops and the alert resolves on its own.
# Safe: the container is removed afterwards; nothing is installed on the host.
set -euo pipefail

echo "=== Drill 3: CPU spike ==="
echo
echo "[1/2] Starting CPU burn (6 min) in a throwaway container..."
docker run -d --rm --name cpu-burn --cpus="2" python:3.12-slim \
  python -c "import time; end=time.time()+360
while time.time()<end:
    sum(i*i for i in range(20000))" >/dev/null
echo "Burning. Watch the Grafana CPU panel (http://localhost:3000) climb and"
echo "expect HighCpuLoad (warning) after ~5-6 minutes: http://localhost:9090/alerts"
echo
docker wait cpu-burn >/dev/null
echo
echo "[2/2] Burn finished and container removed. CPU back to normal;"
echo "the alert will resolve by itself. Confirm in Alertmanager: http://localhost:9093"
