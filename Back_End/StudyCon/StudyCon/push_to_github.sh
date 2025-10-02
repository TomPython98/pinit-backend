#!/bin/bash

# Simple script to push code to GitHub
# Run this after you've created the GitHub repository

echo "📤 Pushing PinIt Backend to GitHub..."
echo "===================================="

# Check if we're in the right directory
if [ ! -f "manage.py" ]; then
    echo "❌ Error: Please run this script from the StudyCon directory"
    exit 1
fi

# Get GitHub username
read -p "Enter your GitHub username: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ GitHub username is required"
    exit 1
fi

echo "🚀 Pushing to https://github.com/$GITHUB_USERNAME/pinit-backend.git"

# Add remote and push
git remote add origin https://github.com/$GITHUB_USERNAME/pinit-backend.git
git branch -M main
git push -u origin main

echo ""
echo "✅ Code pushed to GitHub successfully!"
echo ""
echo "🌐 Next steps:"
echo "1. Go to https://railway.app"
echo "2. Sign up with GitHub"
echo "3. Deploy from your pinit-backend repository"
echo "4. Set environment variables"
echo "5. Add PostgreSQL database"
echo ""
echo "🎉 Your PinIt backend is ready to go live!"


