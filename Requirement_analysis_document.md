# Requirement Analysis Document

## 1. Problem Statement

Modern engineering teams need visibility into the health of their CI/CD pipelines. Failures in builds or long build times can directly affect developer productivity and release cycles. The goal is to create a CI/CD Pipeline Health Dashboard that aggregates execution data, computes key health metrics, and provides real-time monitoring and alerting.

## 2. Key Features

### Data Collection
* Ingest pipeline execution events from GitHub Actions or Jenkins
* Store attributes: success/failure, build time, status, logs, URL

### Metrics
* Success/Failure rate over a time window
* Average build time
* Last build status for each pipeline

### Real-time Monitoring
* Live updates on dashboard when new builds complete

### Alerts
* Send alerts via Slack webhook or Email on pipeline failures

### UI
* Dashboard showing metrics in cards/charts
* Table of latest builds with logs/status

## 3. Technology Choices

### Backend:
* FastAPI (Python) or Node.js (Express) for quick API development
* REST APIs for metrics + WebSocket for live updates

### Database:
* SQLite (simple, lightweight, works well in container)
* Can be extended to PostgreSQL for production use

### Frontend:
* React (with Vite) for responsive UI
* Charting with Recharts or Chart.js

### Alerting:
* Slack Incoming Webhook integration
* SMTP for email notifications

### Deployment:
* Docker for containerization
* Docker Compose for local orchestration

## 4. APIs/Tools Required

### GitHub Actions
* Workflow run webhook payload or API polling (`/repos/{owner}/{repo}/actions/runs`)

### Jenkins
* Post-build webhook plugin
* Jenkins REST API (`/job/{job}/lastBuild/api/json`)

### Slack
* Incoming Webhook URL for posting alerts

### SMTP
* Mail server credentials for sending email alerts

## 5. Constraints & Assumptions

* Initial scope: focus only on GitHub Actions or Jenkins (at least one fully implemented).
* SQLite database is sufficient for assignment demonstration.
* Dashboard requires no authentication (demo purpose only).
* Real-time update can be simulated with WebSocket push on new ingestions.

## 6. Expected Outcome

A running dashboard app that:
* Collects CI/CD build execution data
* Shows metrics (success/failure rate, avg build time, last status)
* Alerts team on pipeline failures
* Provides a frontend for visualization and build logs/status
* All code + documentation hosted in a public GitHub repo.
