#!/usr/bin/env bash
# Reset the lab to a clean state after drills.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "Cleaning up drill artifacts..."
rm -f node-exporter/textfile/drill.prom
docker rm -f cpu-burn 2>/dev/null || true
docker compose start demo-app 2>/dev/null || true
echo
docker compose ps
echo
echo "Clean. All alerts should resolve within a few minutes."
