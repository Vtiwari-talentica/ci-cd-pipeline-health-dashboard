#!/bin/bash

echo "🚀 CI/CD Dashboard GitHub Setup Helper"
echo "======================================"

# Check if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not in a git repository. Run 'git init' first."
    exit 1
fi

# Check if there are uncommitted changes
if [[ -n $(git status -s) ]]; then
    echo "📝 Adding all files to git..."
    git add .
    
    echo "💬 Committing changes..."
    git commit -m "Setup CI/CD Pipeline Health Dashboard with GitHub Actions"
else
    echo "✅ No uncommitted changes found"
fi

# Check if remote origin exists
if git remote get-url origin > /dev/null 2>&1; then
    echo "✅ Git remote 'origin' already configured"
    ORIGIN_URL=$(git remote get-url origin)
    echo "   Remote URL: $ORIGIN_URL"
else
    echo ""
    echo "🔗 You need to set up the GitHub remote:"
    echo "   1. Create a new repository on GitHub"
    echo "   2. Copy the repository URL"
    echo "   3. Run: git remote add origin YOUR_REPO_URL"
    echo "   4. Run: git push -u origin main"
    echo ""
    read -p "📋 Enter your GitHub repository URL (or press Enter to skip): " REPO_URL
    
    if [[ -n "$REPO_URL" ]]; then
        git remote add origin "$REPO_URL"
        echo "✅ Remote added successfully"
        
        echo "🚀 Pushing to GitHub..."
        git branch -M main
        git push -u origin main
        echo "✅ Code pushed to GitHub!"
    else
        echo "⏭️  Skipping remote setup"
    fi
fi

echo ""
echo "🎯 Next Steps:"
echo "1. 📊 Make sure your dashboard is running: docker-compose up -d"
echo "2. 🌐 Set up ngrok: ngrok http 3000"
echo "3. 🔗 Configure webhook in GitHub repo settings"
echo "4. 🧪 Trigger a workflow to test!"
echo ""
echo "📖 See GITHUB_TESTING.md for detailed instructions"
echo "🎉 Happy testing!"
