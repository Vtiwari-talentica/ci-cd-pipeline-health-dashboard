# 🔧 Local Jenkins Testing Guide

## ✅ Current Status

Your Jenkins testing environment is **LIVE and WORKING**! 

- ✅ **Jenkins webhook endpoint**: http://localhost:8001/webhook/jenkins
- ✅ **Dashboard**: http://localhost:5173 (with real-time updates)
- ✅ **Test script**: `./jenkins-test-pipeline.sh` (ready to use)
- ✅ **Multiple builds tested**: 5 builds including 1 failure (realistic simulation)

## 🧪 Testing Options

### Option 1: Manual Pipeline Testing (Recommended)

Run individual pipeline tests:
```bash
./jenkins-test-pipeline.sh
```

Run multiple tests in sequence:
```bash
for i in {1..10}; do 
  echo "=== Build $i ==="; 
  ./jenkins-test-pipeline.sh; 
  echo ""; 
  sleep 2; 
done
```

### Option 2: Full Jenkins Setup (Optional)

Start a complete Jenkins instance:
```bash
docker-compose -f docker-compose.jenkins.yml up -d jenkins
```

- **Jenkins UI**: http://localhost:8080
- **Initial setup**: Jenkins will provide setup instructions
- **Admin password**: `docker logs jenkins-local` (look for initial admin password)

### Option 3: Automated Testing Loop

Run continuous testing to simulate active CI/CD:
```bash
# Run builds every 30 seconds for 10 minutes
for i in {1..20}; do 
  ./jenkins-test-pipeline.sh; 
  sleep 30; 
done
```

## 📊 Dashboard Features Being Tested

With the Jenkins tests, you can see:

### Real-time Updates
- **WebSocket connections**: Live build notifications
- **Build status**: Success/failure indicators
- **Provider tracking**: Jenkins vs GitHub Actions builds

### Metrics & Analytics
- **Success rates**: Calculated from multiple builds
- **Build trends**: Visual patterns over time
- **Failure analysis**: Failed build identification
- **Average build times**: Performance metrics

### Build History
- **Recent builds**: Latest pipeline executions
- **Build details**: Duration, status, timestamps
- **Provider comparison**: Jenkins vs GitHub data

## 🎯 What You'll See in Dashboard

1. **Build Cards**: Each test creates a new build entry
2. **Success Rate**: Updates as you run more tests
3. **Real-time Notifications**: WebSocket updates as builds complete
4. **Provider Labels**: "Jenkins" tag on test builds
5. **Build Links**: Links to mock Jenkins URLs

## 🔗 Webhook Flow

```
Jenkins Test Script → HTTP POST → Dashboard Backend → WebSocket → Frontend
```

Each test simulates:
1. **Pipeline execution** (checkout, build, test stages)
2. **Webhook delivery** (Jenkins → Dashboard)
3. **Real-time update** (Backend → Frontend via WebSocket)
4. **Data persistence** (SQLite database storage)

## 🚀 Advanced Testing Scenarios

### Test Different Pipeline Names
```bash
# Custom pipeline name
PIPELINE_NAME="mobile-app-build" ./jenkins-test-pipeline.sh

# Different repository
REPO_NAME="my-org/mobile-app" ./jenkins-test-pipeline.sh
```

### Simulate Build Environment Variables
```bash
# Custom build number
BUILD_NUMBER=42 ./jenkins-test-pipeline.sh

# Different dashboard URL (if testing remote)
DASHBOARD_URL="https://your-dashboard.com" ./jenkins-test-pipeline.sh
```

### Test Failure Scenarios
The script has a 10% random failure rate, but you can force failures by modifying the test section in the script.

## 📈 Monitoring Results

### Dashboard Views
- **Main Dashboard**: http://localhost:5173
- **API Health**: http://localhost:8001/health
- **API Documentation**: http://localhost:8001/docs

### WebSocket Monitoring
Open browser dev tools → Network tab → Look for WebSocket connection to see real-time updates.

### Build Data API
```bash
# Get recent builds
curl http://localhost:8001/builds

# Get metrics summary
curl http://localhost:8001/metrics/summary

# Get latest build
curl http://localhost:8001/builds/latest
```

## 🎉 You're Ready!

Your local Jenkins testing environment is fully operational. You can:

1. **Test immediately**: Run `./jenkins-test-pipeline.sh`
2. **Watch real-time updates**: Open http://localhost:5173
3. **Compare with GitHub**: Use both Jenkins and GitHub webhooks
4. **Scale testing**: Run multiple builds to see trends

The dashboard now supports **both GitHub Actions and Jenkins** with real-time updates and comprehensive metrics! 🚀
