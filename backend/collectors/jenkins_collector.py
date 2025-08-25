import os, requests, time
from requests.auth import HTTPBasicAuth

BACKEND = os.getenv("BACKEND_URL", "http://localhost:8001")
JENKINS_URL = os.getenv("JENKINS_URL", "http://localhost:8080")
JENKINS_USER = os.getenv("JENKINS_USER", "")
JENKINS_TOKEN = os.getenv("JENKINS_TOKEN", "")
JOB = os.getenv("JOB", "")

def run():
    url = f"{JENKINS_URL}/job/{JOB}/lastBuild/api/json"
    resp = requests.get(url, auth=HTTPBasicAuth(JENKINS_USER, JENKINS_TOKEN), timeout=10)
    if resp.status_code != 200:
        print("Jenkins fetch failed", resp.status_code)
        return
    data = resp.json()
    result = data.get("result")  # SUCCESS/FAILURE/ABORTED/None (building)
    status = "success" if result == "SUCCESS" else ("failure" if result == "FAILURE" else "in_progress")
    duration = (data.get("duration") or 0) / 1000.0
    started_ts = (data.get("timestamp") or 0) / 1000.0

    payload = {
        "pipeline": JOB or "jenkins-job",
        "repo": "jenkins",
        "branch": "main",
        "status": status,
        "started_at": None if not started_ts else __import__("datetime").datetime.fromtimestamp(started_ts, tz=__import__("datetime").timezone.utc).isoformat(),
        "completed_at": None,
        "duration_seconds": duration,
        "url": f"{JENKINS_URL}/job/{JOB}/{data.get('number')}",
        "logs": None
    }
    try:
        requests.post(f"{BACKEND}/ingest/jenkins", json=payload, timeout=5)
    except Exception as e:
        print("Ingest error:", e)

if __name__ == "__main__":
    while True:
        try:
            run()
        except Exception as e:
            print("Collector error:", e)
        time.sleep(60)
