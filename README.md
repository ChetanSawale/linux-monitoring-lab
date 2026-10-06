# Linux Monitoring Lab

A working Prometheus + Grafana + Alertmanager stack on your own machine, built the
way a real L1/NOC team runs it: **metrics in → alerts out → runbook → incident report.**

This lab was built from 11 fresher Linux admin job descriptions — every piece maps
to a skill employers actually list (see [JD skill mapping](#jd-skill-mapping) below).

## Architecture

```
 ┌──────────────┐   scrape :9100   ┌────────────┐
 │ node_exporter│◄─────────────────│            │
 └──────────────┘                  │            │  alert rules      ┌──────────────┐
 ┌──────────────┐   scrape :8080   │ Prometheus │  ──────────────►  │ Alertmanager │
 │   demo-app   │◄─────────────────│   :9090    │                   │    :9093     │
 └──────────────┘                  │            │                   └──────┬───────┘
        ▲ drill scripts write       └─────┬──────┘                          │ webhook
        │ textfile metrics                │ datasource                      ▼
        │                           ┌─────▼──────┐                  ┌──────────────┐
        └───────────────────────────│  Grafana   │                  │ alert-receiver│
            node-exporter/textfile  │   :3000    │                  │ writes alerts │
            drill.prom              └────────────┘                  │ to alerts.log │
                                                                    └──────────────┘
```

## Prerequisites

- Docker + Docker Compose (Docker Desktop on Windows/Mac, or `docker.io` + compose plugin on Linux)
- ~2 GB free RAM, ports 3000, 8080, 9090, 9093, 9100, 5001 free

## Quickstart

```bash
cd linux-monitoring-lab
./run.sh up        # builds + starts everything, prints URLs
./run.sh status    # containers + Prometheus target health (expect all UP)
./run.sh urls      # list of UIs
./run.sh down      # stop everything
```

Open Grafana at http://localhost:3000 (login `admin` / `admin`) → dashboard
**"Linux Host Overview"** is provisioned automatically.

## The drills (the actual lab)

Each drill fires a real alert end-to-end. Do all three, in order:

| Drill | Script | Alert fired | What you practice |
|---|---|---|---|
| 1. Service outage | `drills/drill-1-service-outage.sh` | `DemoAppDown` (critical) | detect → diagnose (`ps`, logs, `curl`) → fix → verify → write incident report |
| 2. Disk pressure | `drills/drill-2-disk-pressure.sh` | `SyntheticDiskPressure` (warning) | textfile-collector pattern for custom metrics; safe synthetic signal |
| 3. CPU spike | `drills/drill-3-cpu-spike.sh` | `HighCpuLoad` (warning) | sustained-load triage; watching an alert resolve by itself |

`drills/cleanup.sh` resets everything. After each drill, file an incident report —
copy `incident-reports/TEMPLATE.md`; a worked example is already there.

While a drill runs, watch it in three places (this is the L1 workflow):
1. **Prometheus** http://localhost:9090/alerts — alert goes pending → firing
2. **Alertmanager** http://localhost:9093 — routing, grouping, silence
3. **Webhook log** `tail -f alert-receiver/data/alerts.log` — the notification a pager would get

`RUNBOOK.md` tells you exactly what to check for each alert.

## Verification checklist

- [ ] `./run.sh status` shows all Prometheus targets UP
- [ ] Grafana dashboard renders CPU/memory/disk/network graphs
- [ ] Drill 1: `DemoAppDown` fired *and* resolved; incident report filed
- [ ] Drill 2: `SyntheticDiskPressure` fired via textfile; resolved after cleanup
- [ ] Drill 3: `HighCpuLoad` fired after ~5 min burn; resolved on its own
- [ ] `alert-receiver/data/alerts.log` contains firing + resolved entries

## Screenshots worth taking (resume / LinkedIn)

1. Grafana "Linux Host Overview" dashboard with live graphs
2. Prometheus `/alerts` page showing a firing alert
3. Alertmanager UI with the alert timeline
4. Your filled incident report (shows documentation habit — rare in freshers)

## Going further

- Point Alertmanager at a real channel: add an `email_configs` or `slack_configs` receiver in `alertmanager/alertmanager.yml`.
- Add a second host: run node_exporter on another machine/VM and add it to `prometheus.yml` — now you're monitoring a fleet.
- Write your own alert: disk *inode* exhaustion (`node_filesystem_files_free`) is a classic real-world gotcha.
- Export the Grafana dashboard JSON and keep it in version control (already done here).

## JD skill mapping

Built from 11 fresher Linux admin JDs (research in `../goals/linux-devops-aws-internship-applications/files/linux-admin-skills.md`):

| JD skill (frequency) | Covered in this lab |
|---|---|
| Monitoring tools (6/11) | Prometheus + Grafana + Alertmanager, full stack |
| Troubleshooting OS/service (8/11) | 3 guided drills + RUNBOOK.md per-alert procedures |
| Ticketing / incident handling (6/11) | Incident report template + worked example (ITSM-style) |
| Documentation / SOPs (5/11) | RUNBOOK.md, incident reports, this README |
| Shell scripting (4/11) | Drill scripts, `run.sh` helper |
| Linux fundamentals (9/11) | node_exporter host metrics: CPU, memory, disk, network |
| Networking (8/11) | Network I/O panel, scrape-target networking between containers |

## Resume bullets (copy-ready)

- Built a Linux monitoring lab with Prometheus, Grafana, and Alertmanager; configured 7 alert rules across host and application metrics with webhook notification routing.
- Ran 3 guided incident drills (service outage, disk pressure, CPU spike); triaged via runbooks and documented each as ITSM-style incident reports.
- Instrumented a Python service with Prometheus client metrics and built a Grafana dashboard covering CPU, memory, disk, network, and error-rate panels.
