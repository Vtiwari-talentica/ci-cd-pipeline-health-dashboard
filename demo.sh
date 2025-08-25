#!/bin/bash

# CI/CD Dashboard Demo Script
# This script demonstrates the full functionality of the dashboard

echo "🎬 CI/CD Pipeline Health Dashboard Demo"
echo "======================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "📋 Step 1: Starting the dashboard..."
docker-compose up -d

echo "⏳ Waiting for containers to be healthy..."
sleep 10

echo ""
echo "📋 Step 2: Verifying health checks..."
echo "Backend health:"
curl -s http://localhost:8001/health | jq . || echo "Backend not ready"

echo ""
echo "Frontend status:"
curl -s -o /dev/null -w "%{http_code}" http://localhost:5173
echo ""

echo ""
echo "📋 Step 3: Injecting sample data..."

# Sample GitHub Actions build
echo "Adding GitHub Actions build..."
curl -X POST http://localhost:8001/ingest/github \
  -H "Content-Type: application/json" \
  -d '{
    "pipeline": "ci-pipeline",
    "repo": "demo/frontend-app",
    "branch": "main",
    "status": "success",
    "started_at": "2025-08-25T09:00:00Z",
    "completed_at": "2025-08-25T09:03:30Z",
    "duration_seconds": 210,
    "url": "https://github.com/demo/frontend-app/actions/runs/123"
  }' | jq .

sleep 1

# Sample Jenkins build
echo ""
echo "Adding Jenkins build..."
curl -X POST http://localhost:8001/ingest/jenkins \
  -H "Content-Type: application/json" \
  -d '{
    "pipeline": "backend-deploy",
    "repo": "demo/backend-api",
    "branch": "develop",
    "status": "failure",
    "started_at": "2025-08-25T09:05:00Z",
    "completed_at": "2025-08-25T09:08:45Z",
    "duration_seconds": 225,
    "url": "http://jenkins.local/job/backend-deploy/456"
  }' | jq .

sleep 1

# Another successful build
echo ""
echo "Adding another successful build..."
curl -X POST http://localhost:8001/ingest/github \
  -H "Content-Type: application/json" \
  -d '{
    "pipeline": "test-suite",
    "repo": "demo/mobile-app",
    "branch": "feature/new-ui",
    "status": "success",
    "started_at": "2025-08-25T09:10:00Z",
    "completed_at": "2025-08-25T09:11:15Z",
    "duration_seconds": 75,
    "url": "https://github.com/demo/mobile-app/actions/runs/789"
  }' | jq .

echo ""
echo "📋 Step 4: Checking metrics..."
echo "Current metrics summary:"
curl -s http://localhost:8001/metrics/summary | jq .

echo ""
echo "Recent builds:"
curl -s http://localhost:8001/builds?limit=5 | jq '.[0:3]'

echo ""
echo "🎉 Demo Complete!"
echo ""
echo "🔗 Access the dashboard:"
echo "   Dashboard UI: http://localhost:5173"
echo "   API Docs: http://localhost:8001/docs"
echo "   Health Check: http://localhost:8001/health"
echo ""
echo "💡 The dashboard shows:"
echo "   ✅ Real-time build data from GitHub Actions and Jenkins"
echo "   ✅ Success rate: ~67% (2 success, 1 failure)"
echo "   ✅ Average build time: ~170 seconds"
echo "   ✅ Recent builds table with provider labels"
echo "   ✅ Interactive charts and visualizations"
echo ""
echo "🧪 To test real-time updates:"
echo "   1. Keep the dashboard open in your browser"
echo "   2. Run this script again to see instant updates"
echo "   3. Or manually POST to /ingest/github or /ingest/jenkins"
echo ""
echo "🛑 To stop the demo:"
echo "   docker-compose down"
