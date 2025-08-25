# 🎯 Webhook Configuration - Ready to Go!

## ✅ Your ngrok URL is Active
**Dashboard URL**: `https://bad56dcf41e1.ngrok-free.app`
**Webhook URL**: `https://bad56dcf41e1.ngrok-free.app/webhook/github`

## 🔗 Configure GitHub Webhook (2 minutes)

### Step 1: Go to Webhook Settings
Click here: [Add Webhook to Your Repository](https://github.com/Vtiwari-talentica/ci-cd-pipeline-health-dashboard/settings/hooks/new)

### Step 2: Configure Webhook
Fill in these details:

- **Payload URL**: `https://bad56dcf41e1.ngrok-free.app/webhook/github`
- **Content type**: `application/json`
- **Secret**: (leave empty)
- **Which events**: Select "Let me select individual events"
  - ✅ Check "Workflow runs"
  - ✅ Check "Workflow jobs" (optional, for more detailed data)
- **Active**: ✅ Checked

### Step 3: Save
Click "Add webhook"

## 🧪 Test the Integration

### Option 1: Manual GitHub Actions Trigger
1. Go to [GitHub Actions](https://github.com/Vtiwari-talentica/ci-cd-pipeline-health-dashboard/actions)
2. Click on "CI Dashboard Test" workflow
3. Click "Run workflow" → "Run workflow"

### Option 2: Push a Test Commit
```bash
echo "Testing webhook integration - $(date)" >> test-webhook.txt
git add test-webhook.txt
git commit -m "Test: webhook integration with ngrok"
git push
```

## 📊 View Results

### Your Dashboard (Real-time)
- **Local**: http://localhost:5173
- **Public**: https://bad56dcf41e1.ngrok-free.app

### Monitor Webhook Activity
- **ngrok Inspector**: http://localhost:4040
- **GitHub Webhook**: https://github.com/Vtiwari-talentica/ci-cd-pipeline-health-dashboard/settings/hooks

## 🎉 What You'll See

1. **GitHub Actions** runs your test-app pipeline
2. **Webhook delivers** build data to your dashboard
3. **Real-time updates** appear in the dashboard
4. **Build metrics** update with actual CI/CD data

## ⚡ Quick Test Command
Run this to trigger a test build right now:
```bash
curl -X POST https://github.com/Vtiwari-talentica/ci-cd-pipeline-health-dashboard/dispatches \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -d '{"event_type":"webhook-test"}'
```

Your webhook is **LIVE** and ready to receive real CI/CD pipeline data! 🚀
