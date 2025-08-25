# Local Webhook Testing Setup

## Option 1: ngrok Setup (Recommended)

### Step 1: Sign up for ngrok (Free)
1. Go to https://dashboard.ngrok.com/signup
2. Sign up for a free account
3. Go to https://dashboard.ngrok.com/get-started/your-authtoken
4. Copy your authtoken

### Step 2: Authenticate ngrok
```bash
ngrok config add-authtoken YOUR_AUTHTOKEN_HERE
```

### Step 3: Start ngrok tunnel
```bash
ngrok http 5173
```

This will give you a public URL like: `https://abc123-def456.ngrok-free.app`

### Step 4: Configure GitHub Webhook
1. Go to your repository: https://github.com/Vtiwari-talentica/ci-cd-pipeline-health-dashboard
2. Go to Settings → Webhooks → Add webhook
3. Payload URL: `https://YOUR_NGROK_URL.ngrok-free.app/webhook/github`
4. Content type: `application/json`
5. Events: Select "Workflow runs"
6. Active: ✓
7. Click "Add webhook"

## Option 2: Test Locally (No ngrok)

If you prefer not to use ngrok, you can test the webhook mechanism locally:

### Run the test script directly:
```bash
cd /Users/vikast/Downloads/ci-cd-pipeline-health-dashboard
python test_cicd_scenarios.py
```

This will simulate GitHub Actions data being sent to your dashboard.

## Option 3: Deploy to Cloud (Production Testing)

Deploy your dashboard to a cloud service for real webhook testing:

### Quick Deploy Options:
- **Railway**: Connect your GitHub repo, auto-deploy
- **Render**: Deploy from GitHub, free tier available  
- **Fly.io**: Simple Docker deployment

## Verification Steps

### 1. Check Dashboard is Running
Visit: http://localhost:5173
You should see the CI/CD Pipeline Health Dashboard

### 2. Check Backend API
Visit: http://localhost:8001/docs
You should see the FastAPI documentation

### 3. Test Webhook Endpoint
```bash
curl -X POST http://localhost:8001/webhook/github \
  -H "Content-Type: application/json" \
  -d '{"test": "webhook"}'
```

### 4. Check WebSocket Connection
Open browser dev tools → Network tab → Look for WebSocket connection to `ws://localhost:8001/ws`

## Triggering GitHub Actions

Once webhook is configured:

1. **Manual trigger**: Go to GitHub Actions tab → Select workflow → "Run workflow"
2. **Push trigger**: Make any commit and push:
   ```bash
   echo "# Test commit" >> README.md
   git add README.md
   git commit -m "Test webhook integration"
   git push
   ```

## Expected Results

- GitHub Actions will run the test-app pipeline
- Webhook will send build data to your dashboard
- Dashboard will update in real-time with new build information
- You'll see success rates, build trends, and recent build history

## Troubleshooting

- **Webhook not working**: Check ngrok URL is correct and dashboard is running
- **No data appearing**: Verify webhook is configured with correct endpoint
- **Dashboard not loading**: Check Docker containers are healthy: `docker-compose ps`
- **Connection issues**: Verify ports 5173 (frontend) and 8001 (backend) are accessible

## Current Repository
Your repository: https://github.com/Vtiwari-talentica/ci-cd-pipeline-health-dashboard

GitHub Actions workflow is already configured and ready to test!
