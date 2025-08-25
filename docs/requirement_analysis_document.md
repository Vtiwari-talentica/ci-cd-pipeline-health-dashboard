# Requirement Analysis – CI/CD Pipeline Health Dashboard

## Problem Summary
Modern engineering teams need to **monitor CI/CD health**. The dashboard should ingest build events from **GitHub Actions/Jenkins**, compute **KPIs** (success/failure rate, average build time, last status), **alert** on failures, and show a **simple UI** for visibility.

## Key Features
1. **Ingestion**
   - Webhooks for GitHub Actions & Jenkins
   - Optional polling scripts (GitHub/Jenkins APIs)
2. **Storage**
   - Build executions in a SQL database with minimal schema
3. **Metrics**
   - Success rate, failure rate (within a window: 24h/7d)
   - Average build duration
   - Last status per pipeline
4. **UI**
   - Metrics cards + time-series of durations
   - Latest builds table + run links + status pills
   - Logs snippet (optional field)
5. **Alerts**
   - Slack webhook
   - Email via SMTP
6. **Real-time**
   - WebSocket push to refresh frontend automatically

## Constraints & Assumptions
- **SQLite** is adequate for a single-node demo; can swap to Postgres later.
- Frontend polls summary + gets WS nudges to refresh.
- Alerts only for **failures** to reduce noise.
- Security: demo scope; in prod add auth, rate limiting, secrets manager.

## Non-Functional
- Simple to run with Docker Compose
- Observable: structured logs, `/docs` on API
- Extensible for more providers (CircleCI, GitLab CI) via new ingest endpoints

## Acceptance Criteria
- Ingest minimal JSON from providers
- Display metrics and latest builds
- Trigger Slack/email on failure
- Real-time updates present (ws connected indicator)
- Containerized and documented
