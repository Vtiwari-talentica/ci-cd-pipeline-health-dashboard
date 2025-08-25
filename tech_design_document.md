# Technical Design Document

## High-Level Architecture

```
┌─────────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   CI/CD Providers   │    │     Backend API      │    │    Frontend UI      │
│                     │    │                      │    │                     │
│  GitHub Actions ────┼────┤ FastAPI + SQLAlchemy ├────┤ React + Vite        │
│  Jenkins        ────┼────┤                      │    │                     │
│                     │    │ ┌──────────────────┐ │    │ ┌─────────────────┐ │
└─────────────────────┘    │ │   SQLite DB      │ │    │ │ Dashboard       │ │
                           │ │                  │ │    │ │ Components      │ │
┌─────────────────────┐    │ └──────────────────┘ │    │ └─────────────────┘ │
│   Alert Channels    │    │                      │    │                     │
│                     │    │ ┌──────────────────┐ │    │ ┌─────────────────┐ │
│  Slack Webhook  ────┼────┤ │ WebSocket        │ ├────┤ │ Real-time       │ │
│  Email SMTP     ────┼────┤ │ Manager          │ │    │ │ Updates         │ │
│                     │    │ └──────────────────┘ │    │ └─────────────────┘ │
└─────────────────────┘    └──────────────────────┘    └─────────────────────┘
```

### Data Flow
1. **Ingestion**: CI/CD providers send webhook payloads or polling scripts fetch data
2. **Processing**: Backend validates, stores, and computes metrics
3. **Alerting**: Failures trigger Slack/email notifications
4. **Real-time**: WebSocket broadcasts updates to connected clients
5. **Visualization**: Frontend displays metrics, charts, and build tables

### Component Overview
- **Backend**: FastAPI application with REST endpoints and WebSocket support
- **Database**: SQLite for persistence with SQLAlchemy ORM
- **Frontend**: React SPA with real-time dashboard
- **Collectors**: Optional polling scripts for data ingestion
- **Alerting**: Slack webhook and SMTP email integration

## API Structure

### Core Endpoints

#### Data Ingestion
```http
POST /ingest/github
POST /ingest/jenkins
```

**Sample Request Body:**
```json
{
  "pipeline": "build-and-test",
  "repo": "org/repository",
  "branch": "main",
  "status": "success",
  "started_at": "2025-08-24T10:30:00Z",
  "completed_at": "2025-08-24T10:35:30Z",
  "duration_seconds": 330,
  "url": "https://github.com/org/repo/actions/runs/12345",
  "logs": "Build completed successfully..."
}
```

**Sample Response:**
```json
{
  "id": 42,
  "provider": "github",
  "pipeline": "build-and-test",
  "repo": "org/repository",
  "branch": "main",
  "status": "success",
  "started_at": "2025-08-24T10:30:00Z",
  "completed_at": "2025-08-24T10:35:30Z",
  "duration_seconds": 330,
  "url": "https://github.com/org/repo/actions/runs/12345"
}
```

#### Metrics & Analytics
```http
GET /metrics/summary?window=7d
```

**Sample Response:**
```json
{
  "window": "7d",
  "success_rate": 87.5,
  "failure_rate": 12.5,
  "avg_build_time": 245.8,
  "last_status_by_pipeline": {
    "build-and-test": "success",
    "deploy-staging": "failure",
    "security-scan": "success"
  }
}
```

#### Build Data
```http
GET /builds?limit=50
GET /builds/latest?pipeline=build-and-test
```

**Sample Response (builds list):**
```json
[
  {
    "id": 42,
    "provider": "github",
    "pipeline": "build-and-test",
    "repo": "org/repository",
    "branch": "main",
    "status": "success",
    "started_at": "2025-08-24T10:30:00Z",
    "completed_at": "2025-08-24T10:35:30Z",
    "duration_seconds": 330,
    "url": "https://github.com/org/repo/actions/runs/12345"
  }
]
```

#### Real-time Updates
```websocket
WS /ws
```

**Sample WebSocket Message:**
```json
{
  "event": "build_ingested",
  "data": {
    "pipeline": "build-and-test",
    "status": "failure"
  }
}
```

## Database Schema

### `builds` Table
```sql
CREATE TABLE builds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider VARCHAR(20) NOT NULL,           -- 'github', 'jenkins'
    pipeline VARCHAR(100) NOT NULL,          -- Pipeline/workflow name
    repo VARCHAR(200) NOT NULL,              -- Repository identifier
    branch VARCHAR(100) NOT NULL,            -- Git branch
    status VARCHAR(20) NOT NULL,             -- 'success', 'failure', 'cancelled', 'in_progress'
    started_at DATETIME NOT NULL,            -- Build start timestamp (UTC)
    completed_at DATETIME,                   -- Build completion timestamp (UTC)
    duration_seconds REAL,                   -- Build duration in seconds
    url VARCHAR(500),                        -- Link to build/run page
    logs TEXT,                               -- Build logs snippet
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP -- Record creation timestamp
);

-- Indexes for performance
CREATE INDEX idx_builds_provider ON builds(provider);
CREATE INDEX idx_builds_pipeline ON builds(pipeline);
CREATE INDEX idx_builds_status ON builds(status);
CREATE INDEX idx_builds_started_at ON builds(started_at);
```

### Schema Design Considerations
- **Flexible provider field**: Supports multiple CI/CD systems
- **Timezone-aware timestamps**: All times stored in UTC
- **Optional fields**: `completed_at`, `duration_seconds`, `url`, `logs` can be null
- **Indexing strategy**: Optimized for common query patterns (filtering by provider, pipeline, status, time)

## UI Layout

### Dashboard Structure
```
┌─────────────────────────────────────────────────────────────────┐
│                     CI/CD Pipeline Health Dashboard             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌───────────┐  │
│  │ Success     │ │ Failure     │ │ Avg Build   │ │ Live:     │  │
│  │ Rate: 87.5% │ │ Rate: 12.5% │ │ Time: 4m 5s │ │ Connected │  │
│  └─────────────┘ └─────────────┘ └─────────────┘ └───────────┘  │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────┐ ┌─────────────────────────────┐ │
│ │     Build Duration Trend    │ │   Last Status by Pipeline   │ │
│ │                             │ │                             │ │
│ │  ^                          │ │ build-and-test    ● Success │ │
│ │  │ Duration                 │ │ deploy-staging    ● Failure │ │
│ │  │ (seconds)                │ │ security-scan     ● Success │ │
│ │  │     ╭─╮                  │ │ performance-test  ● Success │ │
│ │  │   ╭─╯ ╰╮ ╭─╮             │ │                             │ │
│ │  │ ╭─╯     ╰─╯ ╰─╮           │ │                             │ │
│ │  └─────────────────────────> │ │                             │ │
│ │           Time               │ │                             │ │
│ └─────────────────────────────┘ └─────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                          Latest Builds                          │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Time       │Pipeline     │Provider│Repo/Branch│Duration│Status│ │
│ │──────────────────────────────────────────────────────────────│ │
│ │10:35:30   │build-test   │github  │org/repo   │330s   │●Success│ │
│ │10:32:15   │deploy-stage │jenkins │org/api    │125s   │●Failure│ │
│ │10:28:45   │security-scan│github  │org/web    │89s    │●Success│ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Component Breakdown

#### 1. Header Section
- **Title**: "CI/CD Pipeline Health Dashboard"
- **Live Status Indicator**: Shows WebSocket connection status (Connected/Disconnected)

#### 2. Metrics Cards Row
- **Success Rate Card**: Percentage of successful builds in time window
- **Failure Rate Card**: Percentage of failed builds in time window  
- **Average Build Time Card**: Mean duration of completed builds
- **Live Status Card**: Real-time connection indicator with color coding

#### 3. Visualization Panel (2-column layout)
- **Left Panel - Build Duration Trend**: Line chart showing build times over time
  - X-axis: Time (chronological)
  - Y-axis: Duration in seconds
  - Interactive tooltips with exact values
- **Right Panel - Pipeline Status Summary**: Table showing last status per pipeline
  - Pipeline name and current status
  - Color-coded status indicators (green=success, red=failure, gray=other)

#### 4. Latest Builds Table
- **Columns**: Timestamp, Pipeline, Provider, Repo/Branch, Duration, Status, Action Link
- **Features**: 
  - Sortable by timestamp (newest first)
  - Status pills with color coding
  - Clickable links to original build/run pages
  - Responsive design for mobile devices

### Responsive Design Considerations
- **Mobile**: Stack metric cards vertically, simplify table columns
- **Tablet**: 2x2 grid for metric cards, maintain dual-panel layout
- **Desktop**: Full horizontal layout as shown above

### Color Scheme & Visual Design
- **Success**: Green (#22c55e)
- **Failure**: Red (#ef4444)  
- **In Progress**: Blue (#3b82f6)
- **Cancelled/Other**: Gray (#6b7280)
- **Background**: Light gray (#f9fafb)
- **Cards**: White with subtle shadow
- **Borders**: Light gray (#e5e7eb)
