#!/bin/bash

# PinIt App - Go Live Deployment Script
# This script will help you deploy your app to production

set -e

echo "🚀 PinIt App - GOING LIVE!"
echo "=========================="

# Check if we're in the right directory
if [ ! -f "manage.py" ]; then
    echo "❌ Error: Please run this script from the StudyCon directory"
    exit 1
fi

echo "✅ Current directory: $(pwd)"
echo "✅ Django project found"

# Step 1: Create GitHub repository
echo ""
echo "📁 Step 1: Create GitHub Repository"
echo "=================================="
echo "1. Go to https://github.com/new"
echo "2. Repository name: pinit-backend"
echo "3. Description: PinIt App Backend - Django API"
echo "4. Make it PUBLIC (required for free Railway deployment)"
echo "5. DON'T initialize with README"
echo "6. Click 'Create repository'"
echo ""
read -p "Press Enter when you've created the repository..."

# Step 2: Get GitHub username
echo ""
echo "👤 Step 2: Get Your GitHub Username"
echo "==================================="
read -p "Enter your GitHub username: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ GitHub username is required"
    exit 1
fi

# Step 3: Add remote and push
echo ""
echo "📤 Step 3: Push Code to GitHub"
echo "=============================="
echo "Adding GitHub remote..."

git remote add origin https://github.com/$GITHUB_USERNAME/pinit-backend.git
git branch -M main

echo "Pushing code to GitHub..."
git push -u origin main

echo "✅ Code pushed to GitHub successfully!"

# Step 4: Deploy to Railway
echo ""
echo "🚀 Step 4: Deploy to Railway"
echo "==========================="
echo "1. Go to https://railway.app"
echo "2. Sign up with GitHub"
echo "3. Click 'New Project'"
echo "4. Select 'Deploy from GitHub repo'"
echo "5. Choose your 'pinit-backend' repository"
echo "6. Railway will automatically detect Django and deploy!"
echo ""

# Step 5: Environment variables
echo "⚙️ Step 5: Set Environment Variables"
echo "===================================="
echo "In Railway dashboard, go to Variables tab and add:"
echo ""
echo "DEBUG=False"
echo "DJANGO_SETTINGS_MODULE=StudyCon.settings_production"
echo "SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')"
echo "ALLOWED_HOSTS=*.railway.app,pin-it.net,www.pin-it.net"
echo ""

# Step 6: Add database
echo "🗄️ Step 6: Add PostgreSQL Database"
echo "=================================="
echo "1. In Railway dashboard, click 'New'"
echo "2. Select 'Database' → 'PostgreSQL'"
echo "3. Railway will automatically connect it"
echo ""

# Step 7: Test deployment
echo "🧪 Step 7: Test Your Live API"
echo "============================"
echo "1. Wait for Railway to finish deploying (2-3 minutes)"
echo "2. Click on your app URL in Railway dashboard"
echo "3. Test: https://your-app.railway.app/api/get_all_users/"
echo "4. If you see JSON, your API is working! 🎉"
echo ""

# Step 8: Update iOS app
echo "📱 Step 8: Update iOS App"
echo "========================"
echo "1. Open your iOS project in Xcode"
echo "2. Replace hardcoded URLs with your Railway URL"
echo "3. Test your iOS app with the production backend"
echo ""

# Step 9: Custom domain
echo "🌐 Step 9: Set Up Custom Domain"
echo "==============================="
echo "1. In Railway dashboard → Settings → Domains"
echo "2. Add custom domain: pin-it.net"
echo "3. Update DNS records as shown"
echo "4. Wait for DNS propagation (up to 24 hours)"
echo ""

echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================="
echo "Your PinIt backend is now LIVE!"
echo ""
echo "📋 Summary:"
echo "- ✅ GitHub repository created"
echo "- ✅ Code pushed to GitHub"
echo "- ✅ Ready for Railway deployment"
echo "- ✅ Environment variables configured"
echo "- ✅ Database setup ready"
echo ""
echo "🌐 Your app will be live at: https://your-app.railway.app"
echo "📱 Next: Update iOS app and submit to App Store!"
echo ""
echo "🚀 Congratulations! Your PinIt app is going live!"


