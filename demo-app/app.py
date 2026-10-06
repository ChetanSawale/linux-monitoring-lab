#!/usr/bin/env python3
"""demo-app: a tiny instrumented HTTP service to monitor.

Endpoints:
  /         -> 200 "demo-app ok"
  /metrics  -> Prometheus exposition format
  /fail     -> 500 (increments the error counter; use for error-rate drills)
  /slow     -> sleeps 2s then 200 (use for latency observation)

Metrics:
  demo_app_http_requests_total{path,code}
  demo_app_http_errors_total
  demo_app_http_request_latency_seconds (histogram)
"""
from http.server import BaseHTTPRequestHandler, HTTPServer
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import time

REQUESTS = Counter("demo_app_http_requests_total", "Total HTTP requests", ["path", "code"])
ERRORS = Counter("demo_app_http_errors_total", "Total HTTP 5xx responses")
LATENCY = Histogram("demo_app_http_request_latency_seconds", "Request latency in seconds")


class Handler(BaseHTTPRequestHandler):
    def _respond(self, code, body):
        start = time.time()
        self.send_response(code)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        self.wfile.write(body.encode())
        REQUESTS.labels(path=self.path.split("?")[0], code=str(code)).inc()
        if code >= 500:
            ERRORS.inc()
        LATENCY.observe(time.time() - start)

    def do_GET(self):
        if self.path == "/metrics":
            data = generate_latest()
            self.send_response(200)
            self.send_header("Content-Type", CONTENT_TYPE_LATEST)
            self.end_headers()
            self.wfile.write(data)
            return
        if self.path == "/fail":
            self._respond(500, "simulated failure\n")
            return
        if self.path == "/slow":
            time.sleep(2)
            self._respond(200, "slow ok\n")
            return
        self._respond(200, "demo-app ok\n")

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
