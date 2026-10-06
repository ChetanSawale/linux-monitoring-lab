# Incident report template

Copy this file to `INCIDENT-YYYY-MM-DD-<short-name>.md` and fill it in after
every drill (and every real incident). Hiring managers for L1/admin roles
read these to judge how you think under pressure.

---

# Incident: <short title>

| Field | Value |
|---|---|
| Incident ID | INC-YYYY-MM-DD-001 |
| Date / time (IST) | |
| Severity | critical / warning / info |
| Service / host | |
| Alert that fired | |
| Detected by | monitoring / user report / drill |
| Documented by | |

## Summary
One or two sentences: what happened and what the user-visible impact was.

## Timeline (IST)
| Time | Event |
|---|---|
| | Alert fired |
| | Investigation started |
| | Root cause identified |
| | Fix applied |
| | Service verified healthy |
| | Alert resolved |

## Impact
Who/what was affected, for how long. ("None — lab drill" is a valid answer.)

## Root cause
The underlying reason, not the symptom. (Symptom: "service down". Root cause: "container stopped during drill" / "log partition filled because rotation was disabled".)

## Resolution
Exact steps taken, in order. Include commands where useful.

## Verification
How you confirmed the fix: target UP in Prometheus, alert resolved in Alertmanager, smoke test (`curl`), log check.

## Action items
| # | Action | Owner | Done |
|---|---|---|---|
| 1 | | | |

## Lessons learned
What you'd do differently next time, or what monitoring gap this exposed.
