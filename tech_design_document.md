# Technical Design Document
## CI/CD Pipeline Health Dashboard

**Version**: 1.0  
**Date**: August 25, 2025  
**Author**: Development Team  
**Project**: CI/CD Pipeline Health Dashboard

---

## Executive Summary

The CI/CD Pipeline Health Dashboard is a production-ready monitoring solution designed to provide real-time visibility into CI/CD pipeline performance across multiple providers (GitHub Actions, Jenkins). The system features a modern microservices architecture with containerized deployment, real-time data ingestion via webhooks, and a responsive web interface for metrics visualization.

---

## High-Level Architecture

### System Overview

The dashboard follows a three-tier architecture pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION TIER                         │
├─────────────────────────────────────────────────────────────────────┤
│  React Frontend (Port 5173)                                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │
│  │   Dashboard     │  │   Metrics       │  │   Real-time     │    │
│  │   Components    │  │   Visualization │  │   WebSocket     │    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ HTTPS/WebSocket
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                           APPLICATION TIER                          │
├─────────────────────────────────────────────────────────────────────┤
│  FastAPI Backend (Port 8001)                                       │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │
│  │   Webhook       │  │   Metrics       │  │   WebSocket     │    │
│  │   Ingestion     │  │   Calculation   │  │   Broadcasting  │    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │
│  │   Alerting      │  │   API Routes    │  │   Authentication│    │
│  │   System        │  │   Management    │  │   (Future)      │    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
                                   │
                                   │ SQLAlchemy ORM
                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                             DATA TIER                               │
├─────────────────────────────────────────────────────────────────────┤
│  SQLite Database (Persistent Volume)                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │
│  │     Builds      │  │   Metrics       │  │   Configuration │    │
│  │     Table       │  │   Cache         │  │   Settings      │    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Architecture

#### 1. External Integration Layer
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ GitHub Actions  │────▶│   Webhook       │◀────│   Jenkins       │
│                 │     │   Gateway       │     │                 │
│ - Workflow runs │     │                 │     │ - Build events  │
│ - Status updates│     │ - Authentication│     │ - Job status    │
│ - Metadata      │     │ - Validation    │     │ - Artifacts     │
└─────────────────┘     │ - Routing       │     └─────────────────┘
                        └─────────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │   Data          │
                        │   Normalization │
                        │   Layer         │
                        └─────────────────┘
```

#### 2. Core Application Services
```
┌─────────────────────────────────────────────────────────────────────┐
│                      APPLICATION SERVICES                           │
├─────────────────┬─────────────────┬─────────────────┬──────────────┤
│   Ingestion     │   Metrics       │   Alerting      │  WebSocket   │
│   Service       │   Service       │   Service       │  Service     │
│                 │                 │                 │              │
│ - Webhook       │ - Success rate  │ - Slack         │ - Connection │
│   processing    │   calculation   │   notifications │   management │
│ - Data          │ - Build time    │ - Email alerts  │ - Real-time  │
│   validation    │   aggregation   │ - Failure       │   broadcasting│
│ - Provider      │ - Trend         │   detection     │ - Client     │
│   abstraction   │   analysis      │ - Alert rules   │   lifecycle  │
└─────────────────┴─────────────────┴─────────────────┴──────────────┘
```

#### 3. Data Flow Architecture
```
1. Webhook Ingestion Flow:
   CI/CD Provider → Webhook → Validation → Normalization → Database → WebSocket Broadcast

2. Metrics Calculation Flow:
   Database → Query Engine → Aggregation → Cache → API Response

3. Real-time Update Flow:
   Data Change → Event Trigger → WebSocket Manager → Connected Clients

4. Alerting Flow:
   Build Failure → Alert Rules → Notification Service → Slack/Email
```

---

## API Structure

### Base Configuration
- **Base URL**: `http://localhost:8001`
- **API Version**: v1 (implicit)
- **Content-Type**: `application/json`
- **Authentication**: None (internal deployment)

### Core API Routes

#### 1. Health and Status Endpoints

##### GET /health
**Purpose**: System health check for monitoring and load balancers

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-08-25T10:00:00Z",
  "version": "1.0.0",
  "services": {
    "database": "connected",
    "websocket": "active",
    "alerting": "configured"
  },
  "uptime_seconds": 3600
}
```

##### GET /metrics/health
**Purpose**: Detailed service health with performance metrics

**Response**:
```json
{
  "database": {
    "status": "healthy",
    "connection_pool": {
      "active": 2,
      "idle": 8,
      "max": 10
    },
    "query_performance": {
      "avg_response_ms": 15,
      "slow_queries": 0
    }
  },
  "websocket": {
    "status": "active",
    "connected_clients": 3,
    "messages_sent_last_hour": 147
  }
}
```

#### 2. Data Ingestion Endpoints

##### POST /ingest/github
**Purpose**: Ingest GitHub Actions webhook data

**Request Body**:
```json
{
  "pipeline": "ci-pipeline",
  "repo": "my-org/my-repo",
  "branch": "main",
  "status": "success",
  "started_at": "2025-08-25T10:00:00Z",
  "completed_at": "2025-08-25T10:05:00Z",
  "duration_seconds": 300,
  "url": "https://github.com/my-org/my-repo/actions/runs/123456",
  "logs": "Build completed successfully with 0 errors",
  "metadata": {
    "actor": "developer@company.com",
    "commit_sha": "abc123def456",
    "workflow_name": "CI Pipeline"
  }
}
```

**Response** (201 Created):
```json
{
  "id": 1001,
  "status": "ingested",
  "provider": "github",
  "pipeline": "ci-pipeline",
  "created_at": "2025-08-25T10:05:30Z",
  "alerts_sent": [],
  "websocket_broadcast": true
}
```

##### POST /ingest/jenkins
**Purpose**: Ingest Jenkins build webhook data

**Request Body**:
```json
{
  "pipeline": "jenkins-build",
  "repo": "internal/api-service",
  "branch": "develop",
  "status": "failure",
  "started_at": "2025-08-25T10:10:00Z",
  "completed_at": "2025-08-25T10:15:00Z",
  "duration_seconds": 300,
  "url": "https://jenkins.company.com/job/api-service/123/",
  "logs": "Build failed: compilation error in src/main.py line 45",
  "metadata": {
    "build_number": 123,
    "triggered_by": "SCM change",
    "node": "jenkins-agent-01"
  }
}
```

**Response** (201 Created):
```json
{
  "id": 1002,
  "status": "ingested",
  "provider": "jenkins",
  "pipeline": "jenkins-build",
  "created_at": "2025-08-25T10:15:30Z",
  "alerts_sent": [
    {
      "type": "slack",
      "sent_at": "2025-08-25T10:15:31Z",
      "status": "delivered"
    }
  ],
  "websocket_broadcast": true
}
```

#### 3. Metrics and Analytics Endpoints

##### GET /metrics/summary
**Purpose**: Get aggregated metrics for dashboard overview

**Query Parameters**:
- `window`: Time window (1d, 7d, 30d) - default: 7d
- `provider`: Filter by provider (github, jenkins) - optional

**Response**:
```json
{
  "time_window": "7d",
  "period_start": "2025-08-18T10:00:00Z",
  "period_end": "2025-08-25T10:00:00Z",
  "total_builds": 156,
  "success_rate": 0.8462,
  "failure_rate": 0.1538,
  "average_duration_seconds": 245.7,
  "providers": {
    "github": {
      "builds": 89,
      "success_rate": 0.8876,
      "avg_duration": 198.3
    },
    "jenkins": {
      "builds": 67,
      "success_rate": 0.7910,
      "avg_duration": 312.1
    }
  },
  "trends": {
    "success_rate_trend": "+2.3%",
    "duration_trend": "-15.2%",
    "volume_trend": "+8.7%"
  }
}
```

##### GET /metrics/builds-over-time
**Purpose**: Get build volume and success trends for charting

**Query Parameters**:
- `window`: Time window (1d, 7d, 30d)
- `granularity`: Data points (hourly, daily)

**Response**:
```json
{
  "granularity": "daily",
  "data_points": [
    {
      "date": "2025-08-18",
      "total_builds": 23,
      "successful_builds": 19,
      "failed_builds": 4,
      "avg_duration": 267.4
    },
    {
      "date": "2025-08-19",
      "total_builds": 31,
      "successful_builds": 28,
      "failed_builds": 3,
      "avg_duration": 241.8
    }
  ]
}
```

#### 4. Build Data Endpoints

##### GET /builds
**Purpose**: Get paginated list of recent builds

**Query Parameters**:
- `limit`: Number of builds (default: 50, max: 200)
- `offset`: Pagination offset (default: 0)
- `status`: Filter by status (success, failure, cancelled)
- `provider`: Filter by provider (github, jenkins)
- `pipeline`: Filter by pipeline name

**Response**:
```json
{
  "total_count": 1247,
  "limit": 50,
  "offset": 0,
  "builds": [
    {
      "id": 1002,
      "provider": "jenkins",
      "pipeline": "jenkins-build",
      "repo": "internal/api-service",
      "branch": "develop",
      "status": "failure",
      "started_at": "2025-08-25T10:10:00Z",
      "completed_at": "2025-08-25T10:15:00Z",
      "duration_seconds": 300,
      "url": "https://jenkins.company.com/job/api-service/123/",
      "created_at": "2025-08-25T10:15:30Z"
    }
  ]
}
```

##### GET /builds/{build_id}
**Purpose**: Get detailed information for specific build

**Response**:
```json
{
  "id": 1002,
  "provider": "jenkins",
  "pipeline": "jenkins-build",
  "repo": "internal/api-service",
  "branch": "develop",
  "status": "failure",
  "started_at": "2025-08-25T10:10:00Z",
  "completed_at": "2025-08-25T10:15:00Z",
  "duration_seconds": 300,
  "url": "https://jenkins.company.com/job/api-service/123/",
  "logs": "Build failed: compilation error in src/main.py line 45",
  "metadata": {
    "build_number": 123,
    "triggered_by": "SCM change",
    "node": "jenkins-agent-01"
  },
  "alerts_triggered": [
    {
      "type": "slack",
      "sent_at": "2025-08-25T10:15:31Z",
      "recipient": "#dev-alerts",
      "status": "delivered"
    }
  ],
  "created_at": "2025-08-25T10:15:30Z"
}
```

#### 5. WebSocket API

##### WebSocket /ws
**Purpose**: Real-time updates for dashboard clients

**Connection**: `ws://localhost:8001/ws`

**Message Types**:

**Build Ingested Event**:
```json
{
  "event": "build_ingested",
  "timestamp": "2025-08-25T10:15:30Z",
  "data": {
    "build_id": 1002,
    "provider": "jenkins",
    "status": "failure",
    "pipeline": "jenkins-build"
  }
}
```

**Metrics Updated Event**:
```json
{
  "event": "metrics_updated",
  "timestamp": "2025-08-25T10:15:31Z",
  "data": {
    "success_rate": 0.8461,
    "total_builds": 157,
    "avg_duration": 246.2
  }
}
```

**System Status Event**:
```json
{
  "event": "system_status",
  "timestamp": "2025-08-25T10:16:00Z",
  "data": {
    "status": "healthy",
    "connected_clients": 4,
    "last_build_time": "2025-08-25T10:15:30Z"
  }
}
```

---

## Database Schema

### Database Configuration
- **Engine**: SQLite 3.x (development/single-node)
- **ORM**: SQLAlchemy 2.x
- **Migration**: Alembic (future enhancement)
- **Connection Pool**: 10 connections max
- **Persistence**: Docker volume mount

### Core Tables

#### 1. builds Table

**Purpose**: Primary table storing all CI/CD build information

```sql
CREATE TABLE builds (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider VARCHAR(50) NOT NULL,
    pipeline VARCHAR(255) NOT NULL,
    repo VARCHAR(255) NOT NULL,
    branch VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    started_at TIMESTAMP NOT NULL,
    completed_at TIMESTAMP NULL,
    duration_seconds FLOAT NULL,
    url VARCHAR(512) NULL,
    logs TEXT NULL,
    metadata JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes**:
```sql
CREATE INDEX idx_builds_provider ON builds(provider);
CREATE INDEX idx_builds_status ON builds(status);
CREATE INDEX idx_builds_created_at ON builds(created_at);
CREATE INDEX idx_builds_pipeline ON builds(pipeline);
CREATE INDEX idx_builds_repo_branch ON builds(repo, branch);
CREATE INDEX idx_builds_provider_status ON builds(provider, status);
```

**Field Descriptions**:
- `id`: Auto-increment primary key
- `provider`: CI/CD provider (github, jenkins, etc.)
- `pipeline`: Pipeline/workflow name
- `repo`: Repository identifier
- `branch`: Git branch name
- `status`: Build status (success, failure, cancelled, in_progress)
- `started_at`: Build start timestamp (UTC)
- `completed_at`: Build completion timestamp (UTC, nullable for in-progress)
- `duration_seconds`: Calculated build duration
- `url`: Link to build details in CI/CD provider
- `logs`: Build logs or summary (text)
- `metadata`: Provider-specific additional data (JSON)
- `created_at`: Record creation timestamp
- `updated_at`: Record last update timestamp

**Sample Data**:
```sql
INSERT INTO builds VALUES (
    1001,
    'github',
    'ci-pipeline',
    'my-org/my-repo',
    'main',
    'success',
    '2025-08-25 10:00:00',
    '2025-08-25 10:05:00',
    300.0,
    'https://github.com/my-org/my-repo/actions/runs/123456',
    'Build completed successfully with 0 errors',
    '{"actor": "developer@company.com", "commit_sha": "abc123def456"}',
    '2025-08-25 10:05:30',
    '2025-08-25 10:05:30'
);
```

#### 2. alerts Table (Future Enhancement)

**Purpose**: Track alerting history and configuration

```sql
CREATE TABLE alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    build_id INTEGER NOT NULL,
    alert_type VARCHAR(50) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    sent_at TIMESTAMP NOT NULL,
    status VARCHAR(50) NOT NULL,
    error_message TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (build_id) REFERENCES builds(id)
);
```

#### 3. metrics_cache Table (Future Enhancement)

**Purpose**: Cache computed metrics for performance

```sql
CREATE TABLE metrics_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cache_key VARCHAR(255) UNIQUE NOT NULL,
    cache_value JSON NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Database Relationships

```
┌─────────────────┐         ┌─────────────────┐
│     builds      │1      *│     alerts      │
│                 │◀────────│                 │
│ id (PK)         │         │ build_id (FK)   │
│ provider        │         │ alert_type      │
│ pipeline        │         │ recipient       │
│ status          │         │ sent_at         │
│ started_at      │         │ status          │
│ completed_at    │         └─────────────────┘
│ duration        │
└─────────────────┘
```

### Query Patterns

**Most Common Queries**:

1. **Recent Builds**:
```sql
SELECT * FROM builds 
ORDER BY created_at DESC 
LIMIT 50;
```

2. **Success Rate Calculation**:
```sql
SELECT 
    COUNT(CASE WHEN status = 'success' THEN 1 END) * 1.0 / COUNT(*) as success_rate
FROM builds 
WHERE created_at >= datetime('now', '-7 days');
```

3. **Average Duration by Provider**:
```sql
SELECT 
    provider,
    AVG(duration_seconds) as avg_duration
FROM builds 
WHERE status = 'success' 
    AND completed_at >= datetime('now', '-7 days')
GROUP BY provider;
```

4. **Build Trend Analysis**:
```sql
SELECT 
    date(created_at) as build_date,
    COUNT(*) as total_builds,
    COUNT(CASE WHEN status = 'success' THEN 1 END) as successful_builds
FROM builds 
WHERE created_at >= datetime('now', '-30 days')
GROUP BY date(created_at)
ORDER BY build_date;
```

---

## UI Layout

### Design Principles
- **Mobile-First Responsive Design**: Optimized for mobile, tablet, and desktop
- **Real-time Updates**: Live data refresh without page reload
- **Intuitive Navigation**: Single-page application with logical flow
- **Accessibility**: WCAG 2.1 AA compliance
- **Performance**: Lightweight components with lazy loading

### Overall Layout Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│                           TOP NAVIGATION                            │
├─────────────────────────────────────────────────────────────────────┤
│  Logo    CI/CD Dashboard    [Real-time Status: ●]    [Health: ✓]   │
└─────────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────────┐
│                         METRICS OVERVIEW                            │
├───────────────┬───────────────┬───────────────┬─────────────────────┤
│   SUCCESS     │  AVG BUILD    │ TOTAL BUILDS  │   FAILURE RATE     │
│     RATE      │     TIME      │   (7 DAYS)    │    (24 HOURS)      │
│               │               │               │                     │
│    84.6%      │   4m 12s      │     156       │      15.4%         │
│   ▲ +2.3%     │   ▼ -15s      │   ▲ +23       │     ▼ -1.2%        │
└───────────────┴───────────────┴───────────────┴─────────────────────┘
┌─────────────────────────────────────────────────────────────────────┐
│                      CHARTS AND TRENDS                              │
├─────────────────────┬───────────────────────────────────────────────┤
│   BUILD SUCCESS     │         BUILD DURATION TRENDS                 │
│   OVER TIME         │                                               │
│                     │  Duration (minutes)                           │
│   [Chart showing    │   8 ┤                                         │
│    success/failure  │   6 ┤     ●                                   │
│    rates over last  │   4 ┤   ●   ●     ●                           │
│    7 days]          │   2 ┤ ●       ● ●   ●                         │
│                     │   0 └───────────────────                      │
│                     │     Mon Tue Wed Thu Fri Sat Sun               │
└─────────────────────┴───────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────────┐
│                        RECENT BUILDS                                │
├─────┬──────────┬─────────────┬──────────┬──────────┬────────────────┤
│ ●   │ PIPELINE │ REPO/BRANCH │ PROVIDER │ DURATION │ TIME           │
├─────┼──────────┼─────────────┼──────────┼──────────┼────────────────┤
│ 🔴  │ api-ci   │ main/api    │ GitHub   │ 5m 23s   │ 2 min ago      │
│ 🟢  │ frontend │ dev/web     │ Jenkins  │ 3m 41s   │ 5 min ago      │
│ 🟢  │ tests    │ main/core   │ GitHub   │ 2m 15s   │ 8 min ago      │
│ 🟡  │ deploy   │ release/v2  │ Jenkins  │ 7m 02s   │ 12 min ago     │
└─────┴──────────┴─────────────┴──────────┴──────────┴────────────────┘
```

### Component Breakdown

#### 1. Navigation Header
**Location**: Top of application  
**Components**:
- **Logo/Brand**: CI/CD Dashboard title
- **Real-time Status Indicator**: WebSocket connection status
- **System Health Badge**: Overall system health
- **Responsive Menu**: Collapsible on mobile

**React Implementation**:
```jsx
const NavigationHeader = () => (
  <header className="bg-blue-600 text-white p-4 shadow-lg">
    <div className="flex justify-between items-center">
      <h1 className="text-xl font-bold">CI/CD Dashboard</h1>
      <div className="flex space-x-4">
        <StatusIndicator />
        <HealthBadge />
      </div>
    </div>
  </header>
);
```

#### 2. Metrics Overview Cards
**Layout**: 4-column grid (responsive: 2x2 on tablet, 1x4 on mobile)  
**Purpose**: Display key performance indicators

**Card Structure**:
```jsx
const MetricCard = ({ title, value, trend, icon }) => (
  <div className="bg-white rounded-lg shadow p-6">
    <div className="flex items-center justify-between">
      <div>
        <p className="text-gray-500 text-sm">{title}</p>
        <p className="text-2xl font-bold">{value}</p>
        <TrendIndicator trend={trend} />
      </div>
      <div className="text-blue-500">{icon}</div>
    </div>
  </div>
);
```

**Cards Included**:
1. **Success Rate**: Percentage with trend arrow
2. **Average Build Time**: Duration with comparison
3. **Total Builds**: Count with period indicator
4. **Failure Rate**: Recent failure percentage

#### 3. Charts and Visualization
**Layout**: 2-column grid (1-column on mobile)

**Chart 1: Build Success Over Time**
- **Type**: Line chart with area fill
- **Library**: Recharts
- **Data**: Daily success/failure counts
- **Interactive**: Hover tooltips, zoom capability

```jsx
const BuildSuccessChart = ({ data }) => (
  <ResponsiveContainer width="100%" height={300}>
    <LineChart data={data}>
      <CartesianGrid strokeDasharray="3 3" />
      <XAxis dataKey="date" />
      <YAxis />
      <Tooltip />
      <Line type="monotone" dataKey="successRate" stroke="#10B981" />
      <Line type="monotone" dataKey="failureRate" stroke="#EF4444" />
    </LineChart>
  </ResponsiveContainer>
);
```

**Chart 2: Build Duration Trends**
- **Type**: Bar chart with trend line
- **Purpose**: Show build performance over time
- **Features**: Provider filtering, time range selection

#### 4. Recent Builds Table
**Layout**: Full-width responsive table

**Columns**:
1. **Status Indicator**: Color-coded dot (🟢 🔴 🟡)
2. **Pipeline Name**: Build/job identifier
3. **Repository/Branch**: Source information
4. **Provider**: GitHub/Jenkins badge
5. **Duration**: Build time with formatting
6. **Timestamp**: Relative time (e.g., "5 min ago")

**Features**:
- **Real-time Updates**: New builds appear automatically
- **Status Filtering**: Filter by success/failure/in-progress
- **Provider Filtering**: Show only GitHub or Jenkins builds
- **Pagination**: Load more builds on scroll
- **Click Navigation**: Link to build details in CI/CD provider

```jsx
const BuildsTable = ({ builds, onFilterChange }) => (
  <div className="bg-white rounded-lg shadow overflow-hidden">
    <div className="px-6 py-4 border-b">
      <h2 className="text-lg font-semibold">Recent Builds</h2>
      <BuildFilters onChange={onFilterChange} />
    </div>
    <div className="overflow-x-auto">
      <table className="min-w-full">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left">Status</th>
            <th className="px-6 py-3 text-left">Pipeline</th>
            <th className="px-6 py-3 text-left">Repo/Branch</th>
            <th className="px-6 py-3 text-left">Provider</th>
            <th className="px-6 py-3 text-left">Duration</th>
            <th className="px-6 py-3 text-left">Time</th>
          </tr>
        </thead>
        <tbody>
          {builds.map(build => (
            <BuildRow key={build.id} build={build} />
          ))}
        </tbody>
      </table>
    </div>
  </div>
);
```

### Responsive Design Breakpoints

**Mobile (320px - 768px)**:
- Single column layout
- Stacked metric cards
- Horizontal scroll for table
- Simplified charts

**Tablet (768px - 1024px)**:
- 2-column metric cards
- Side-by-side charts
- Responsive table with hidden columns

**Desktop (1024px+)**:
- Full 4-column metric grid
- Side-by-side charts and tables
- All columns visible
- Optimal chart sizing

### Real-time UI Updates

**WebSocket Integration**:
```jsx
const Dashboard = () => {
  const [builds, setBuilds] = useState([]);
  const [metrics, setMetrics] = useState({});
  
  useEffect(() => {
    const ws = new WebSocket('ws://localhost:8001/ws');
    
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      
      switch (message.event) {
        case 'build_ingested':
          setBuilds(prev => [message.data, ...prev.slice(0, 49)]);
          break;
        case 'metrics_updated':
          setMetrics(message.data);
          break;
      }
    };
    
    return () => ws.close();
  }, []);
  
  return (
    <div className="min-h-screen bg-gray-100">
      <NavigationHeader />
      <MetricsOverview metrics={metrics} />
      <ChartsSection builds={builds} />
      <BuildsTable builds={builds} />
    </div>
  );
};
```

### Loading and Error States

**Loading States**:
- Skeleton components for initial load
- Shimmer effects for data refresh
- Progressive loading for large datasets

**Error States**:
- Connection lost indicator
- Retry mechanisms for failed requests
- Graceful degradation for partial failures

**Empty States**:
- Helpful messaging for no data
- Setup instructions for first-time users
- Sample data injection guidance

This technical design provides a comprehensive foundation for implementing a production-ready CI/CD Pipeline Health Dashboard with modern architecture, robust API design, efficient database schema, and intuitive user interface.
