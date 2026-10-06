#!/usr/bin/env python3
"""Tiny Alertmanager webhook receiver.

Listens on :5001/webhook, appends every firing/resolved notification to
/data/alerts.log (mounted to ./alert-receiver/data on the host) and prints it.
Stands in for a real paging channel (email/Slack) so the lab works with zero
external credentials. stdlib only.
"""
import json
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

LOG = "/data/alerts.log"


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/webhook":
            self.send_response(404)
            self.end_headers()
            return
        length = int(self.headers.get("Content-Length", 0))
        payload = json.loads(self.rfile.read(length) or b"{}")
        ts = datetime.now(timezone.utc).isoformat()
        lines = [f"=== {ts} status={payload.get('status')} ==="]
        for a in payload.get("alerts", []):
            labels = a.get("labels", {})
            ann = a.get("annotations", {})
            lines.append(
                f"- [{labels.get('severity', '?')}] {labels.get('alertname', '?')}: "
                f"{ann.get('summary', '')} (startsAt={a.get('startsAt', '?')})"
            )
        text = "\n".join(lines) + "\n"
        with open(LOG, "a") as f:
            f.write(text)
        print(text, flush=True)
        self.send_response(200)
        self.end_headers()

    def log_message(self, *args):  # keep logs clean; alerts go to alerts.log
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 5001), Handler).serve_forever()
