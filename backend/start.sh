#!/bin/bash

# CI/CD Pipeline Health Dashboard - Backend Startup Script

echo "🚀 Starting CI/CD Pipeline Health Dashboard Backend..."

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "📦 Creating Python virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source .venv/bin/activate

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Create data directory if it doesn't exist
mkdir -p /tmp/dashboard-data

# Set database path for local development
export SQLALCHEMY_DATABASE_URL="sqlite:////tmp/dashboard-data/dashboard.db"

# Start the FastAPI server
echo "🌟 Starting FastAPI server on port 8001..."
echo "📊 Dashboard API will be available at: http://localhost:8001"
echo "📖 API Documentation available at: http://localhost:8001/docs"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

uvicorn main:app --reload --host 0.0.0.0 --port 8001
