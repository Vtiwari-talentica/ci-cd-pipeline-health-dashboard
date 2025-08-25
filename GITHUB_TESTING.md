# GitHub Actions Testing Guide

## Setting Up Real CI/CD Pipeline Testing

### Prerequisites
- GitHub account
- Dashboard running locally (via Docker or directly)
- ngrok installed (for local webhook testing) or deployed dashboard

### Step 1: Push to GitHub

1. Add all files to git:
```bash
cd /Users/vikast/Downloads/ci-cd-pipeline-health-dashboard
git add .
git commit -m "Initial commit: CI/CD Pipeline Health Dashboard"
```

2. Create a new repository on GitHub (keep it public for webhooks):
   - Go to https://github.com/new
   - Repository name: `ci-cd-pipeline-health-dashboard`
   - Make it public
   - Don't initialize with README (we already have one)

3. Push to GitHub:
```bash
git remote add origin https://github.com/YOUR_USERNAME/ci-cd-pipeline-health-dashboard.git
git branch -M main
git push -u origin main
```

### Step 2: Set Up Webhook (Local Testing)

If testing with local dashboard:

1. Install and start ngrok:
```bash
# Install ngrok if not already installed
brew install ngrok

# Start ngrok to expose local dashboard
ngrok http 3000
```

2. Copy the ngrok URL (e.g., `https://abc123.ngrok.io`)

3. Configure GitHub webhook:
   - Go to your repo → Settings → Webhooks
   - Click "Add webhook"
   - Payload URL: `https://YOUR_NGROK_URL.ngrok.io/webhook/github`
   - Content type: `application/json`
   - Events: Select "Workflow runs"
   - Active: ✓

### Step 3: Test the Pipeline

1. Make sure your dashboard is running:
```bash
docker-compose up -d
```

2. Trigger the GitHub Actions workflow by:
   - Pushing a new commit
   - Or manually trigger from GitHub Actions tab

3. Watch the dashboard at http://localhost:3000 to see builds appear in real-time!

### Step 4: Alternative - Deploy Dashboard Publicly

If you want to avoid ngrok, deploy the dashboard to a cloud service:

1. **Railway/Render/Vercel**: Deploy the Docker containers
2. **Use the public URL** for the webhook instead of ngrok
3. Update the webhook URL in GitHub to point to your deployed dashboard

### Troubleshooting

- **Webhook not receiving data**: Check ngrok URL is correct and dashboard is running
- **GitHub Actions failing**: Check the logs in the Actions tab
- **Dashboard not updating**: Verify WebSocket connection in browser dev tools
- **Import errors**: Make sure you're using the containerized version

### What to Expect

- GitHub Actions will run the test-app pipeline
- Each workflow run will send data to your dashboard
- You'll see real-time updates with build status, duration, success rates
- The test has a 10% chance of random failure to simulate real-world scenarios

### Monitoring

- Dashboard shows: Build trends, success rates, recent builds, failure analysis
- Real-time WebSocket updates when new builds complete
- Build details with timestamps, durations, and status

## Testing Different Scenarios

1. **Successful builds**: Most commits should pass
2. **Failed builds**: Some tests have random failures
3. **Multiple commits**: Push several commits to see trend analysis
4. **Different workflows**: You can add more .yml files for different pipelines
