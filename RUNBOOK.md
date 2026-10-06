# Alert Runbook

What to do when each lab alert fires — the same shape as an L1 runbook in a NOC:
**detect → triage → diagnose → fix → verify → document**.

## InstanceDown (critical)

**Meaning:** Prometheus got no metrics from the target for 1 minute.
**Triage (first 2 minutes):**
1. Prometheus → Status → Targets: which job/instance is down?
2. Is it one target or all? All down = Prometheus/network issue; one down = that service/host.
**Diagnose:**
- `docker compose ps <service>` — is the container running?
- `docker compose logs --tail 30 <service>` — crash loop? OOM?
- `curl -s http://<host>:<port>/metrics` — port answering?
**Fix:** `docker compose restart <service>` (or `up -d` if missing). If OOM-killed, check `dmesg | grep -i oom`.
**Verify:** target returns to UP in Prometheus; alert resolves in Alertmanager.
**Document:** file an incident report (see `incident-reports/`).

## DemoAppDown (critical)

Same as InstanceDown, scoped to the sample app. Extra checks:
- `curl -s http://localhost:8080/` and `/metrics` directly.
- If the container is up but `/metrics` hangs, the app may be wedged — `docker compose restart demo-app`.

## HighCpuLoad (warning)

**Meaning:** average CPU > 80% for 5 minutes.
**Diagnose:**
- Grafana CPU panel: sudden spike or gradual climb?
- Top consumers: `docker stats`, or on a real host `top` / `ps -eo pcpu,pid,comm --sort=-pcpu | head`.
- Is it expected (backup window, batch job) or a runaway process?
**Fix:** kill/restart the runaway process; if legitimate load, consider scaling or rescheduling.
**Verify:** CPU back under threshold for 5+ minutes; alert resolves.

## HighMemoryUsage (warning)

**Meaning:** < 10% memory available for 5 minutes.
**Diagnose:** `free -m`, `ps -eo pmem,pid,comm --sort=-pmem | head`, `dmesg | grep -i oom` (OOM killer active?).
**Fix:** restart the leaking service; add swap or memory only after confirming need.
**Verify:** available memory recovers; no new OOM kills.

## DiskSpaceLow (warning)

**Meaning:** root filesystem > 85% full for 5 minutes.
**Diagnose:** `df -h /`, then `du -sh /* 2>/dev/null | sort -h | tail` to find the hog. Usual suspects: logs (`/var/log`), docker (`docker system df`), old backups.
**Fix:** rotate/truncate logs, `docker system prune`, move or compress the data. Never `rm -rf` blindly.
**Verify:** `df -h` shows headroom; alert resolves.

## SyntheticDiskPressure (warning, drill)

Fired by `drills/drill-2-disk-pressure.sh` via the node_exporter textfile collector — no real disk is involved. "Fix" is `rm node-exporter/textfile/drill.prom` (the drill script does this). Real-world lesson: the textfile collector is how cron jobs and scripts expose custom metrics (backup status, cert expiry, queue depth).

## DemoAppHighErrorRate (warning)

**Meaning:** > 5% of demo-app responses are 5xx for 2 minutes.
**Diagnose:** hit `/fail` a few times yourself to reproduce, then check what changed — this alert exists to practice the "error budget" conversation: is the deploy bad, or is a dependency down?
**Fix:** depends on cause; in the lab, stop hitting `/fail`.
**Verify:** error rate back near zero; alert resolves.
