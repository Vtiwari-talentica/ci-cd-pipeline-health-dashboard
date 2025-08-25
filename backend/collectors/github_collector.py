import os, requests, time
from datetime import datetime, timezone

BACKEND = os.getenv("BACKEND_URL", "http://localhost:8001")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")  # personal access token or fine-grained token
REPO = os.getenv("REPO", "owner/name")
INTERVAL = int(os.getenv("INTERVAL", "60"))

def run():
    headers = {"Authorization": f"Bearer {GITHUB_TOKEN}"} if GITHUB_TOKEN else {}
    url = f"https://api.github.com/repos/{REPO}/actions/runs?per_page=10"
    resp = requests.get(url, headers=headers, timeout=10)
    resp.raise_for_status()
    for item in resp.json().get("workflow_runs", []):
        status = item.get("conclusion") or ("in_progress" if item.get("status") != "completed" else "cancelled")
        payload = {
            "pipeline": item.get("name") or "github-workflow",
            "repo": REPO,
            "branch": (item.get("head_branch") or "unknown"),
            "status": "success" if status == "success" else ("failure" if status == "failure" else status),
            "started_at": item.get("run_started_at"),
            "completed_at": item.get("updated_at"),
            "duration_seconds": None,
            "url": item.get("html_url"),
            "logs": None
        }
        try:
            requests.post(f"{BACKEND}/ingest/github", json=payload, timeout=5)
        except Exception as e:
            print("Ingest error:", e)

if __name__ == "__main__":
    while True:
        try:
            run()
        except Exception as e:
            print("Collector error:", e)
        time.sleep(INTERVAL)
