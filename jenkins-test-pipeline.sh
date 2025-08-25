#!/bin/bash

# Jenkins Pipeline Test Script
# This script simulates a CI/CD pipeline and sends data to the dashboard

echo "=== Starting CI/CD Pipeline Test ==="

# Pipeline configuration
PIPELINE_NAME="test-app-pipeline"
BUILD_NUMBER=${BUILD_NUMBER:-$RANDOM}
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
DASHBOARD_URL=${DASHBOARD_URL:-"http://localhost:8001"}

echo "Pipeline: $PIPELINE_NAME"
echo "Build: #$BUILD_NUMBER"
echo "Start Time: $START_TIME"

# Simulate build stages
echo ""
echo "=== Stage 1: Checkout ==="
sleep 2
echo "✅ Code checked out successfully"

echo ""
echo "=== Stage 2: Install Dependencies ==="
sleep 3
echo "✅ Dependencies installed"

echo ""
echo "=== Stage 3: Lint ==="
sleep 1
echo "✅ Code linting passed"

echo ""
echo "=== Stage 4: Build ==="
sleep 4
echo "✅ Application built successfully"

echo ""
echo "=== Stage 5: Test ==="
sleep 2

# Simulate test results (10% failure rate)
if [ $((RANDOM % 10)) -eq 0 ]; then
    echo "❌ Tests failed!"
    STATUS="failure"
    EXIT_CODE=1
else
    echo "✅ All tests passed!"
    STATUS="success"
    EXIT_CODE=0
fi

# Calculate duration
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_TIMESTAMP=$(python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$START_TIME'.replace('Z', '+00:00')).timestamp()))")
END_TIMESTAMP=$(python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$END_TIME'.replace('Z', '+00:00')).timestamp()))")
DURATION=$((END_TIMESTAMP - START_TIMESTAMP))

echo ""
echo "=== Pipeline Complete ==="
echo "Status: $STATUS"
echo "Duration: ${DURATION}s"

# Send data to dashboard
echo ""
echo "=== Sending data to CI/CD Dashboard ==="

WEBHOOK_DATA=$(cat <<EOF
{
  "repository": {
    "full_name": "Vtiwari-talentica/ci-cd-pipeline-health-dashboard"
  },
  "workflow": {
    "name": "$PIPELINE_NAME"
  },
  "workflow_run": {
    "id": $BUILD_NUMBER,
    "name": "$PIPELINE_NAME",
    "status": "completed",
    "conclusion": "$STATUS",
    "run_number": $BUILD_NUMBER,
    "created_at": "$START_TIME",
    "updated_at": "$END_TIME",
    "html_url": "http://localhost:8080/job/$PIPELINE_NAME/$BUILD_NUMBER/"
  },
  "action": "completed"
}
EOF
)

echo "Sending webhook to: $DASHBOARD_URL/webhook/jenkins"
echo "Data: $WEBHOOK_DATA"

# Send to Jenkins webhook endpoint
curl -X POST "$DASHBOARD_URL/webhook/jenkins" \
  -H "Content-Type: application/json" \
  -d "$WEBHOOK_DATA" \
  --connect-timeout 5 \
  --max-time 10 || echo "Failed to send webhook (dashboard might not be running)"

echo ""
echo "=== Pipeline Test Complete ==="
exit $EXIT_CODE
