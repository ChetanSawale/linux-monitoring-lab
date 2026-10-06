# Incident: demo-app outage (drill)

| Field | Value |
|---|---|
| Incident ID | INC-2026-10-06-001 |
| Date / time (IST) | 2026-10-06, ~22:50–23:05 IST |
| Severity | critical |
| Service / host | demo-app (sample service, lab host) |
| Alert that fired | DemoAppDown |
| Detected by | monitoring (Prometheus → Alertmanager → webhook log) |
| Documented by | Chetan Sawale |

## Summary
The demo-app container was stopped as part of a planned drill. Prometheus detected the missing scrape target within a minute and Alertmanager raised DemoAppDown (critical). Service was restarted and verified healthy; total simulated downtime ~12 minutes.

## Timeline (IST)
| Time | Event |
|---|---|
| 22:50 | `docker compose stop demo-app` (drill start) |
| 22:51 | DemoAppDown firing in Prometheus /alerts; webhook log shows critical notification |
| 22:53 | Investigation started: `docker compose ps` shows container exited; port 8080 refusing connections |
| 22:55 | Root cause confirmed: container intentionally stopped (drill); no crash, no OOM in logs |
| 22:57 | `docker compose start demo-app`; `curl localhost:8080/` returns 200 |
| 23:02 | Target UP in Prometheus; DemoAppDown resolved in Alertmanager; resolved notification in webhook log |

## Impact
None — controlled lab drill. In production this would have been a full outage of the demo service.

## Root cause
Container stopped (drill scenario simulating an accidental `docker stop` / failed deploy).

## Resolution
1. `docker compose ps demo-app` — confirmed exited state.
2. `docker compose logs --tail 15 demo-app` — clean shutdown, no errors (rules out crash).
3. `curl -m 3 http://localhost:8080/` — connection refused (rules out "up but wedged").
4. `docker compose start demo-app` — service back.
5. Smoke test: `curl -s http://localhost:8080/` → `demo-app ok`; `/metrics` exposing counters again.

## Verification
- Prometheus Status → Targets: demo-app UP.
- Alertmanager: DemoAppDown moved to resolved; `alert-receiver/data/alerts.log` shows the resolved notification.
- Grafana "demo-app UP" stat back to 1.

## Action items
| # | Action | Owner | Done |
|---|---|---|---|
| 1 | Add a `restart: unless-stopped` policy review to deploy checklist (already set in compose; drill proved it only helps on daemon restart, not manual stop) | me | ✅ |
| 2 | Consider a dead-man's-switch alert (e.g. "no successful deploy in 24h") for real services | me | ⬜ |

## Lessons learned
The diagnose-before-fix order mattered: checking `ps`, logs, and the port took two minutes and ruled out a crash vs. a stop — the fix differs. Also, the `for: 1m` on the alert meant detection lag was ~1 minute of scrape interval + 1 minute pending; for a real SLA-bound service I'd tighten the scrape interval on that job.
