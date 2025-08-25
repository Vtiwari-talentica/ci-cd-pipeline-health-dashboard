#!/bin/bash

# Jenkins Job Setup Script
# Creates a Jenkins pipeline job that sends data to your CI/CD dashboard

JENKINS_URL="http://localhost:8080"
JOB_NAME="ci-dashboard-test"

echo "🔧 Setting up Jenkins job for CI/CD Dashboard testing"
echo "=============================================="
echo ""

# Check if Jenkins is accessible
echo "📡 Checking Jenkins connectivity..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL")

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 403 ]; then
    echo "✅ Jenkins is accessible at $JENKINS_URL"
else
    echo "❌ Jenkins is not accessible. Please ensure Jenkins is running on port 8080"
    echo "   Start Jenkins with: brew services start jenkins"
    echo "   Or check if it's running on a different port"
    exit 1
fi

echo ""
echo "🎯 Next Steps to Complete Setup:"
echo ""

echo "1. 📂 Create a New Pipeline Job:"
echo "   • Open Jenkins: $JENKINS_URL"
echo "   • Click 'New Item'"
echo "   • Enter name: '$JOB_NAME'"
echo "   • Select 'Pipeline' and click OK"
echo ""

echo "2. ⚙️  Configure the Pipeline:"
echo "   • In the job configuration page:"
echo "   • Scroll to 'Pipeline' section"
echo "   • Select 'Pipeline script from SCM'"
echo "   • SCM: Git"
echo "   • Repository URL: https://github.com/Vtiwari-talentica/ci-cd-pipeline-health-dashboard.git"
echo "   • Script Path: Jenkinsfile"
echo "   • Click 'Save'"
echo ""

echo "3. 🚀 Alternative - Direct Pipeline Script:"
echo "   • Instead of SCM, select 'Pipeline script'"
echo "   • Copy the contents of ./Jenkinsfile into the script box"
echo "   • Click 'Save'"
echo ""

echo "4. ▶️  Run the Job:"
echo "   • Click 'Build Now'"
echo "   • Watch the console output"
echo "   • Check your dashboard at: http://localhost:5173"
echo ""

echo "5. 🔄 For Continuous Testing:"
echo "   • Go to job configuration"
echo "   • Check 'Build periodically'"
echo "   • Schedule: '*/2 * * * *' (every 2 minutes)"
echo "   • Save"
echo ""

echo "📊 Expected Results:"
echo "   • Jenkins job will execute the pipeline"
echo "   • Webhook will be sent to your dashboard"
echo "   • Real-time updates will appear in the dashboard"
echo "   • Build metrics will be calculated and displayed"
echo ""

echo "🔗 Useful URLs:"
echo "   • Jenkins: $JENKINS_URL"
echo "   • Dashboard: http://localhost:5173"
echo "   • Dashboard API: http://localhost:8001/docs"
echo "   • Webhook endpoint: http://localhost:8001/webhook/jenkins"
echo ""

echo "⚠️  Troubleshooting:"
echo "   • If webhook fails, check that your dashboard containers are running:"
echo "     docker-compose ps"
echo "   • Verify the webhook URL in Jenkinsfile matches your setup"
echo "   • Check Jenkins logs for detailed error messages"
echo ""

echo "🎉 Ready to test! Create the job in Jenkins and run it to see live data in your dashboard!"
