#!/bin/bash

# CI/CD Pipeline Health Dashboard - Frontend Startup Script

echo "🚀 Starting CI/CD Pipeline Health Dashboard Frontend..."

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Start the Vite development server
echo "🌟 Starting Vite development server on port 5173..."
echo "📊 Dashboard will be available at: http://localhost:5173"
echo "🔌 Make sure backend is running at: http://localhost:8001"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

npm run dev
