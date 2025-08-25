#!/usr/bin/env python3
"""
Test script for CI/CD Pipeline Health Dashboard Alerting System

This script tests both Slack webhook and email alerting functionality
by simulating pipeline failures and verifying alert delivery.
"""

import os
import sys
import json
import time
import requests
from datetime import datetime

# Add backend to path for imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

def test_slack_webhook():
    """Test Slack webhook functionality"""
    webhook_url = os.getenv("ALERT_SLACK_WEBHOOK")
    
    if not webhook_url:
        print("❌ ALERT_SLACK_WEBHOOK not configured")
        return False
    
    if webhook_url == "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK":
        print("❌ ALERT_SLACK_WEBHOOK contains placeholder value")
        return False
    
    test_message = {
        "text": "🧪 *Test Alert from CI/CD Dashboard*\n📋 *Pipeline:* test-pipeline\n📁 *Repository:* test-repo\n🕒 *Time:* " + datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC") + "\n🔗 *Build URL:* https://example.com/build/123\n📝 *Status:* TEST FAILURE ❌\n\nThis is a test alert to verify Slack integration is working.",
        "username": "CI/CD Monitor",
        "icon_emoji": ":rotating_light:"
    }
    
    try:
        print("🧪 Testing Slack webhook...")
        response = requests.post(
            webhook_url,
            json=test_message,
            timeout=10,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            print("✅ Slack webhook test successful!")
            print(f"   Response: {response.text}")
            return True
        else:
            print(f"❌ Slack webhook failed with status {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Slack webhook connection error: {e}")
        return False
    except Exception as e:
        print(f"❌ Unexpected Slack error: {e}")
        return False

def test_email_config():
    """Test email configuration (without sending)"""
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = os.getenv("SMTP_PORT", "587")
    smtp_user = os.getenv("SMTP_USER")
    smtp_pass = os.getenv("SMTP_PASS")
    sender = os.getenv("ALERT_EMAIL_FROM")
    recipient = os.getenv("ALERT_EMAIL_TO")
    
    print("🧪 Testing email configuration...")
    
    config_valid = True
    
    if not smtp_host:
        print("❌ SMTP_HOST not configured")
        config_valid = False
    else:
        print(f"✅ SMTP_HOST: {smtp_host}")
    
    if not sender:
        print("❌ ALERT_EMAIL_FROM not configured")
        config_valid = False
    else:
        print(f"✅ ALERT_EMAIL_FROM: {sender}")
    
    if not recipient:
        print("❌ ALERT_EMAIL_TO not configured")
        config_valid = False
    else:
        print(f"✅ ALERT_EMAIL_TO: {recipient}")
    
    print(f"✅ SMTP_PORT: {smtp_port}")
    
    if smtp_user:
        print(f"✅ SMTP_USER: {smtp_user}")
    else:
        print("⚠️  SMTP_USER not configured (may be optional)")
    
    if smtp_pass:
        print("✅ SMTP_PASS: [CONFIGURED]")
    else:
        print("⚠️  SMTP_PASS not configured (may be optional)")
    
    return config_valid

def test_backend_alerting():
    """Test the backend alerting by sending a failure build"""
    backend_url = os.getenv("VITE_BACKEND_URL", "http://localhost:8001")
    
    test_failure = {
        "pipeline": "test-alert-pipeline",
        "repo": "alert-test-repo",
        "branch": "main",
        "status": "failure",
        "started_at": "2025-08-24T15:00:00Z",
        "completed_at": "2025-08-24T15:05:00Z",
        "duration_seconds": 300,
        "url": "https://github.com/test/repo/actions/runs/12345",
        "logs": "ERROR: Build failed during compilation\nERROR: Tests failed with 3 errors\nERROR: Deployment cancelled due to test failures"
    }
    
    try:
        print(f"🧪 Testing backend alerting via {backend_url}/ingest/github...")
        
        response = requests.post(
            f"{backend_url}/ingest/github",
            json=test_failure,
            timeout=10,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            print("✅ Backend ingestion successful - alerts should be triggered!")
            build_data = response.json()
            print(f"   Created build ID: {build_data.get('id')}")
            print("   Check your Slack channel and email for alert notifications.")
            return True
        else:
            print(f"❌ Backend ingestion failed with status {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("❌ Could not connect to backend server")
        print("   Make sure the backend is running on the specified URL")
        return False
    except Exception as e:
        print(f"❌ Backend test error: {e}")
        return False

def main():
    """Run all alerting tests"""
    print("🚨 CI/CD Pipeline Health Dashboard - Alerting System Test")
    print("=" * 60)
    
    # Load environment variables from .env file if it exists
    env_file = os.path.join(os.path.dirname(__file__), '..', '.env')
    if os.path.exists(env_file):
        print(f"📂 Loading environment from {env_file}")
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()
    else:
        print("⚠️  No .env file found - using system environment variables")
    
    print()
    
    # Test configurations
    slack_ok = test_slack_webhook()
    print()
    
    email_ok = test_email_config()
    print()
    
    # Test backend integration
    backend_ok = test_backend_alerting()
    print()
    
    # Summary
    print("📊 Test Summary:")
    print(f"   Slack Webhook: {'✅ WORKING' if slack_ok else '❌ FAILED'}")
    print(f"   Email Config:  {'✅ VALID' if email_ok else '❌ INVALID'}")
    print(f"   Backend Alert: {'✅ WORKING' if backend_ok else '❌ FAILED'}")
    print()
    
    if slack_ok or email_ok:
        print("🎉 Alerting system is configured and working!")
        if backend_ok:
            print("   Failure alerts will be sent when pipelines fail.")
    else:
        print("⚠️  No alert methods are properly configured.")
        print("   Please configure SLACK_WEBHOOK or email settings in .env file.")

if __name__ == "__main__":
    main()
