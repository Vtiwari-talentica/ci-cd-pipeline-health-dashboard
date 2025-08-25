#!/usr/bin/env python3
"""
CI/CD Pipeline Dashboard Testing Script

This script simulates real CI/CD pipeline scenarios by sending webhook data
to the dashboard, allowing you to test the system with realistic data.
"""

import requests
import json
import time
import random
from datetime import datetime, timedelta
from typing import List, Dict

class CICDTester:
    def __init__(self, dashboard_url: str = "http://localhost:8001"):
        self.dashboard_url = dashboard_url
        self.session = requests.Session()
        
    def test_connection(self) -> bool:
        """Test if the dashboard backend is accessible."""
        try:
            response = self.session.get(f"{self.dashboard_url}/health")
            if response.status_code == 200:
                print("✅ Dashboard backend is accessible")
                return True
            else:
                print(f"❌ Dashboard backend returned status {response.status_code}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"❌ Cannot connect to dashboard: {e}")
            return False
    
    def send_build_event(self, provider: str, build_data: Dict) -> bool:
        """Send a build event to the dashboard."""
        url = f"{self.dashboard_url}/ingest/{provider}"
        try:
            response = self.session.post(url, json=build_data)
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Sent {provider} build: {build_data['pipeline']} - {build_data['status']}")
                print(f"   Build ID: {result.get('id', 'N/A')}")
                return True
            else:
                print(f"❌ Failed to send build event: {response.status_code} - {response.text}")
                return False
        except requests.exceptions.RequestException as e:
            print(f"❌ Error sending build event: {e}")
            return False
    
    def generate_realistic_build(self, provider: str, pipeline: str, repo: str) -> Dict:
        """Generate realistic build data."""
        # Random status with weighted probability
        status_choices = ["success"] * 7 + ["failure"] * 2 + ["cancelled"] * 1
        status = random.choice(status_choices)
        
        # Realistic build durations based on pipeline type
        duration_ranges = {
            "unit-tests": (30, 180),
            "integration-tests": (120, 600),
            "build": (60, 300),
            "deploy": (180, 900),
            "e2e-tests": (300, 1200),
            "security-scan": (120, 480)
        }
        
        base_duration = duration_ranges.get(pipeline, (60, 300))
        duration = random.randint(*base_duration)
        
        # If failed, might be shorter (early failure) or longer (timeout)
        if status == "failure":
            if random.random() < 0.3:  # 30% chance of early failure
                duration = random.randint(10, 60)
            elif random.random() < 0.2:  # 20% chance of timeout
                duration = random.randint(900, 1800)
        
        # Generate timestamps
        completed_at = datetime.utcnow()
        started_at = completed_at - timedelta(seconds=duration)
        
        return {
            "pipeline": pipeline,
            "repo": repo,
            "branch": random.choice(["main", "develop", "feature/auth", "hotfix/bug-123"]),
            "status": status,
            "started_at": started_at.isoformat() + "Z",
            "completed_at": completed_at.isoformat() + "Z",
            "duration_seconds": duration,
            "url": f"https://{provider}.example.com/{repo}/builds/{random.randint(1000, 9999)}",
            "logs": self.generate_logs(status, pipeline)
        }
    
    def generate_logs(self, status: str, pipeline: str) -> str:
        """Generate realistic log snippets."""
        if status == "success":
            return f"{pipeline} completed successfully. All checks passed."
        elif status == "failure":
            failure_reasons = [
                f"Test failure in {pipeline}: AssertionError in test_user_authentication",
                f"Build error: Package '{random.choice(['numpy', 'requests', 'flask'])}' not found",
                f"Deployment failed: Connection timeout to production server",
                f"Security scan failed: 2 high-severity vulnerabilities found",
                f"E2E test failed: Element not found - button#submit-form"
            ]
            return random.choice(failure_reasons)
        else:
            return f"{pipeline} was cancelled by user or system timeout."
    
    def run_test_scenario(self, scenario: str):
        """Run a specific test scenario."""
        print(f"\n🧪 Running test scenario: {scenario}")
        print("=" * 50)
        
        if not self.test_connection():
            return
        
        if scenario == "github_actions":
            self.simulate_github_actions()
        elif scenario == "jenkins":
            self.simulate_jenkins()
        elif scenario == "mixed_providers":
            self.simulate_mixed_providers()
        elif scenario == "failure_scenarios":
            self.simulate_failure_scenarios()
        elif scenario == "high_volume":
            self.simulate_high_volume()
        elif scenario == "real_time":
            self.simulate_real_time()
        else:
            print(f"❌ Unknown scenario: {scenario}")
    
    def simulate_github_actions(self):
        """Simulate GitHub Actions workflows."""
        repos = ["web-app", "api-service", "mobile-app"]
        pipelines = ["unit-tests", "integration-tests", "build", "deploy"]
        
        for repo in repos:
            for pipeline in pipelines:
                build_data = self.generate_realistic_build("github", pipeline, f"company/{repo}")
                self.send_build_event("github", build_data)
                time.sleep(0.5)  # Small delay to see real-time updates
    
    def simulate_jenkins(self):
        """Simulate Jenkins builds."""
        repos = ["legacy-system", "data-pipeline", "microservice-a"]
        pipelines = ["build", "test", "deploy", "security-scan"]
        
        for repo in repos:
            for pipeline in pipelines:
                build_data = self.generate_realistic_build("jenkins", pipeline, repo)
                self.send_build_event("jenkins", build_data)
                time.sleep(0.5)
    
    def simulate_mixed_providers(self):
        """Simulate builds from multiple providers."""
        scenarios = [
            ("github", "unit-tests", "company/frontend"),
            ("jenkins", "build", "backend-service"),
            ("github", "e2e-tests", "company/e2e-suite"),
            ("jenkins", "deploy", "production-app"),
            ("github", "security-scan", "company/api"),
        ]
        
        for provider, pipeline, repo in scenarios:
            build_data = self.generate_realistic_build(provider, pipeline, repo)
            self.send_build_event(provider, build_data)
            time.sleep(1)
    
    def simulate_failure_scenarios(self):
        """Simulate various failure scenarios."""
        failure_builds = [
            {"provider": "github", "pipeline": "unit-tests", "repo": "company/buggy-code"},
            {"provider": "jenkins", "pipeline": "security-scan", "repo": "vulnerable-app"},
            {"provider": "github", "pipeline": "deploy", "repo": "company/broken-deploy"},
        ]
        
        for build_info in failure_builds:
            build_data = self.generate_realistic_build(
                build_info["provider"], 
                build_info["pipeline"], 
                build_info["repo"]
            )
            # Force failure status
            build_data["status"] = "failure"
            build_data["logs"] = f"CRITICAL FAILURE in {build_info['pipeline']}: {random.choice(['Syntax error', 'Test timeout', 'Deploy failed'])}"
            
            self.send_build_event(build_info["provider"], build_data)
            time.sleep(1)
    
    def simulate_high_volume(self):
        """Simulate high volume of builds."""
        print("📊 Simulating high volume scenario (20 builds)...")
        
        for i in range(20):
            provider = random.choice(["github", "jenkins"])
            pipeline = random.choice(["unit-tests", "build", "deploy", "integration-tests"])
            repo = f"project-{random.randint(1, 5)}"
            
            build_data = self.generate_realistic_build(provider, pipeline, repo)
            success = self.send_build_event(provider, build_data)
            
            if not success:
                print(f"❌ Failed to send build {i+1}/20")
            
            time.sleep(0.2)  # Rapid fire
    
    def simulate_real_time(self):
        """Simulate real-time builds over a period."""
        print("⏰ Simulating real-time builds (will run for 60 seconds)...")
        print("   Watch your dashboard for live updates!")
        
        end_time = time.time() + 60  # Run for 1 minute
        build_count = 0
        
        while time.time() < end_time:
            provider = random.choice(["github", "jenkins"])
            pipeline = random.choice(["unit-tests", "build", "integration-tests"])
            repo = f"realtime-{random.choice(['app', 'service', 'api'])}"
            
            build_data = self.generate_realistic_build(provider, pipeline, repo)
            if self.send_build_event(provider, build_data):
                build_count += 1
            
            # Random interval between builds (5-15 seconds)
            time.sleep(random.randint(5, 15))
        
        print(f"✅ Completed real-time simulation: {build_count} builds sent")
    
    def get_dashboard_metrics(self):
        """Fetch and display current dashboard metrics."""
        try:
            response = self.session.get(f"{self.dashboard_url}/metrics/summary?window=7d")
            if response.status_code == 200:
                metrics = response.json()
                print("\n📊 Current Dashboard Metrics:")
                print("=" * 30)
                print(f"Success Rate: {metrics.get('success_rate', 0):.1f}%")
                print(f"Failure Rate: {metrics.get('failure_rate', 0):.1f}%")
                print(f"Average Build Time: {metrics.get('avg_build_time', 0):.1f}s")
                print(f"Total Builds: {metrics.get('total_builds', 0)}")
                
                last_status = metrics.get('last_status_by_pipeline', {})
                if last_status:
                    print("\nLast Status by Pipeline:")
                    for pipeline, status in last_status.items():
                        print(f"  {pipeline}: {status}")
            else:
                print(f"❌ Failed to fetch metrics: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"❌ Error fetching metrics: {e}")

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Test CI/CD Pipeline Dashboard with realistic data")
    parser.add_argument("--url", default="http://localhost:8001", help="Dashboard URL")
    parser.add_argument("--scenario", choices=[
        "github_actions", "jenkins", "mixed_providers", 
        "failure_scenarios", "high_volume", "real_time"
    ], default="mixed_providers", help="Test scenario to run")
    parser.add_argument("--metrics", action="store_true", help="Show current metrics")
    
    args = parser.parse_args()
    
    tester = CICDTester(args.url)
    
    if args.metrics:
        tester.get_dashboard_metrics()
    else:
        tester.run_test_scenario(args.scenario)
        print("\n" + "="*50)
        print("🎉 Test scenario completed!")
        print("📊 Check your dashboard at http://localhost:5173")
        print("💡 Tip: Use --metrics to see current dashboard statistics")

if __name__ == "__main__":
    main()
