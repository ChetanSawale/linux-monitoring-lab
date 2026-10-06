#!/usr/bin/env bash
# Helper: ./run.sh up | down | status | logs | urls
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
  up)
    docker compose up -d --build
    echo
    echo "Waiting for services to become healthy..."
    sleep 8
    ./run.sh status
    ./run.sh urls
    ;;
  down)
    docker compose down
    ;;
  status)
    docker compose ps
    echo
    echo "Prometheus targets (expect all UP):"
    curl -s http://localhost:9090/api/v1/targets | python3 -c "
import json,sys
d=json.load(sys.stdin)
for t in d['data']['activeTargets']:
    print(f\"  {t['labels'].get('job')}/{t['labels'].get('instance')}: {t['health']}\")" 2>/dev/null || echo "  (Prometheus not reachable yet)"
    ;;
  logs)
    docker compose logs -f --tail=50 "${2:-}"
    ;;
  urls)
    cat <<'EOF'

  Grafana       http://localhost:3000   (admin / admin)  -> dashboard "Linux Host Overview"
  Prometheus    http://localhost:9090   -> Status > Targets,  Alerts
  Alertmanager  http://localhost:9093   -> alert timeline
  Webhook log   tail -f alert-receiver/data/alerts.log
  demo-app      http://localhost:8080/  (/metrics, /fail, /slow)
EOF
    ;;
  *)
    echo "Usage: ./run.sh up | down | status | logs [service] | urls"
    exit 1
    ;;
esac
