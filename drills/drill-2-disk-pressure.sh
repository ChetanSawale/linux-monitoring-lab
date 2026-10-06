#!/usr/bin/env bash
# Drill 2 — Synthetic disk pressure.
# Writes a gauge into node_exporter's textfile collector directory, which the
# SyntheticDiskPressure alert picks up. 100% safe: no real disk is touched.
# Teaches the textfile-collector pattern used for custom app/business metrics.
set -euo pipefail
cd "$(dirname "$0")/.."

METRIC_DIR="node-exporter/textfile"
mkdir -p "$METRIC_DIR"

echo "=== Drill 2: synthetic disk pressure ==="
echo
echo "[1/3] Publishing drill_disk_pressure_percent=93 via textfile collector..."
cat > "$METRIC_DIR/drill.prom" <<'EOF'
# HELP drill_disk_pressure_percent Synthetic disk-pressure signal for the alerting drill (0-100).
# TYPE drill_disk_pressure_percent gauge
drill_disk_pressure_percent 93
EOF
echo "Verify the exporter sees it:"
curl -s http://localhost:9100/metrics | grep '^drill_disk_pressure_percent' || echo "(exporter not reachable yet)"
echo
echo "[2/3] Watch for SyntheticDiskPressure (warning, ~1-2 min):"
echo "      http://localhost:9090/alerts   and   tail -f alert-receiver/data/alerts.log"
echo
read -rp "Press Enter once the alert is FIRING..."
echo
echo "[3/3] Remediate (the 'cleanup' an admin would do): removing the signal file..."
rm -f "$METRIC_DIR/drill.prom"
echo "Removed. The alert should resolve within a couple of minutes."
echo
echo "Takeaway for interviews: the textfile collector lets any cron/script expose"
echo "metrics without writing an exporter — e.g. backup-job status, cert expiry."
