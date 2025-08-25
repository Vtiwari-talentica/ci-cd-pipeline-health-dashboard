# Tech Design – CI/CD Pipeline Health Dashboard

## Architecture
```
     GitHub Actions / Jenkins  ──webhook/poll──▶  FastAPI (ingest)
                                              └──▶ SQLite (SQLAlchemy)
                                                       ▲
                          WebSocket push ◀─────────────┘
                                │
                         React Frontend  ◀── REST (summary/builds)
```

- **Backend** (FastAPI)
  - Endpoints:
    - `POST /ingest/github`, `POST /ingest/jenkins`
    - `GET /metrics/summary?window=7d`
    - `GET /builds`, `GET /builds/latest`
    - `WS /ws` – server pushes `{"event":"build_ingested"}`
  - Modules:
    - `models.py` (SQLAlchemy), `database.py`
    - `alerting.py` (Slack/email)
    - `collectors/*` (optional polling)
- **Frontend** (React + Vite)
  - Components:
    - Metric cards (success/failure rate, avg build time)
    - Line chart: build durations
    - Table: latest builds with status pills & run links
  - Data flow:
    - Initial fetch on mount
    - Refresh on WS events

## API Contracts (Samples)

### `POST /ingest/github`
```json
{
  "pipeline": "build-and-test",
  "repo": "org/repo",
  "branch": "main",
  "status": "success | failure | cancelled | in_progress",
  "started_at": "2025-08-24T11:16:00Z",
  "completed_at": "2025-08-24T11:20:40Z",
  "duration_seconds": 280,
  "url": "https://github.com/org/repo/actions/runs/123",
  "logs": "optional snippet"
}
```

### `GET /metrics/summary?window=7d`
```json
{
  "window": "7d",
  "success_rate": 92.3,
  "failure_rate": 7.7,
  "avg_build_time": 245.7,
  "last_status_by_pipeline": {
    "build-and-test": "success",
    "release": "failure"
  }
}
```

## DB Schema
**builds**
- id (PK)
- provider (github|jenkins)
- pipeline
- repo
- branch
- status
- started_at (datetime, tz-aware)
- completed_at (datetime, nullable)
- duration_seconds (float, nullable)
- url (string, nullable)
- logs (text, nullable)
- created_at (now)

## Alerts
- On ingest if `status == "failure"`, call both Slack & Email handlers.

## UI Layout
- Header with title + live status pill
- Row of metric cards
- 2-panels: durations line chart | last status by pipeline table
- Latest builds table (sortable in future)

## Deployment
- Dockerfiles for backend & frontend
- `docker-compose.yml` orchestrates both + persistent volume for SQLite

## Future Enhancements
- Authn/Authz, multi-tenant
- Prometheus metrics & Grafana dashboard
- Replace SQLite → Postgres
- Add provider-specific webhook signature verification
