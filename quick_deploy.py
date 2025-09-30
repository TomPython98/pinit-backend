#!/usr/bin/env python3
"""
Quick Deployment Script for PinIt Backend
This script helps you deploy your Django backend quickly using Railway
"""

import os
import sys
import subprocess
import webbrowser
from pathlib import Path

def check_requirements():
    """Check if all required files exist"""
    required_files = [
        "manage.py",
        "requirements_production.txt",
        "StudyCon/settings_production.py",
        "railway.json"
    ]
    
    missing_files = []
    for file in required_files:
        if not Path(file).exists():
            missing_files.append(file)
    
    if missing_files:
        print("❌ Missing required files:")
        for file in missing_files:
            print(f"   - {file}")
        return False
    
    print("✅ All required files present")
    return True

def create_github_repo():
    """Guide user to create GitHub repository"""
    print("\n📁 GitHub Repository Setup")
    print("=" * 30)
    print("1. Go to https://github.com/new")
    print("2. Repository name: pinit-backend")
    print("3. Description: PinIt App Backend - Django API")
    print("4. Make it Public (for free Railway deployment)")
    print("5. Don't initialize with README (we already have files)")
    print("6. Click 'Create repository'")
    
    input("\nPress Enter when you've created the repository...")
    
    print("\n📤 Push your code to GitHub:")
    print("Run these commands in your terminal:")
    print("git remote add origin https://github.com/YOUR_USERNAME/pinit-backend.git")
    print("git branch -M main")
    print("git push -u origin main")
    
    return True

def deploy_to_railway():
    """Guide user through Railway deployment"""
    print("\n🚀 Railway Deployment")
    print("=" * 25)
    print("1. Go to https://railway.app")
    print("2. Sign up with GitHub")
    print("3. Click 'New Project'")
    print("4. Select 'Deploy from GitHub repo'")
    print("5. Choose your 'pinit-backend' repository")
    print("6. Railway will automatically detect Django and deploy!")
    
    print("\n⚙️ Environment Variables to set:")
    print("DEBUG=False")
    print("DJANGO_SETTINGS_MODULE=StudyCon.settings_production")
    print("SECRET_KEY=your-super-secret-key-here-make-it-long-and-random")
    print("ALLOWED_HOSTS=*.railway.app,pin-it.net,www.pin-it.net")
    
    print("\n🗄️ Add PostgreSQL Database:")
    print("1. In Railway dashboard, click 'New'")
    print("2. Select 'Database' → 'PostgreSQL'")
    print("3. Railway will automatically connect it")
    
    return True

def test_deployment():
    """Guide user to test the deployment"""
    print("\n🧪 Testing Your Deployment")
    print("=" * 30)
    print("1. Wait for Railway to finish deploying (2-3 minutes)")
    print("2. Click on your app URL in Railway dashboard")
    print("3. Test these endpoints:")
    print("   - https://your-app.railway.app/api/get_all_users/")
    print("   - https://your-app.railway.app/admin/")
    print("4. If you see JSON responses, your API is working!")
    
    return True

def update_ios_app():
    """Guide user to update iOS app"""
    print("\n📱 Update iOS App")
    print("=" * 20)
    print("1. Open your iOS project in Xcode")
    print("2. Find all files with hardcoded URLs like:")
    print("   - http://127.0.0.1:8000")
    print("   - http://localhost:8000")
    print("3. Replace them with your Railway URL:")
    print("   - https://your-app.railway.app")
    print("4. Use the APIConfig.swift file I created")
    print("5. Test the app with the production backend")
    
    return True

def setup_domain():
    """Guide user to set up custom domain"""
    print("\n🌐 Custom Domain Setup")
    print("=" * 25)
    print("1. In Railway dashboard, go to Settings")
    print("2. Click 'Domains'")
    print("3. Add custom domain: pin-it.net")
    print("4. Update DNS records as shown:")
    print("   Type: CNAME")
    print("   Name: @")
    print("   Value: your-app.railway.app")
    print("5. Wait for DNS propagation (up to 24 hours)")
    print("6. Update ALLOWED_HOSTS to include pin-it.net")
    
    return True

def main():
    """Main deployment function"""
    print("🚀 PinIt Backend - Quick Deployment Guide")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not Path("manage.py").exists():
        print("❌ Error: Please run this script from the StudyCon directory")
        print("   Current directory:", os.getcwd())
        sys.exit(1)
    
    # Check requirements
    if not check_requirements():
        print("\n❌ Please fix the missing files first")
        sys.exit(1)
    
    print("\n🎯 Deployment Steps:")
    print("1. Create GitHub repository")
    print("2. Push your code")
    print("3. Deploy to Railway")
    print("4. Test deployment")
    print("5. Update iOS app")
    print("6. Set up custom domain")
    
    # Step 1: GitHub
    create_github_repo()
    
    # Step 2: Railway
    deploy_to_railway()
    
    # Step 3: Testing
    test_deployment()
    
    # Step 4: iOS App
    update_ios_app()
    
    # Step 5: Domain
    setup_domain()
    
    print("\n🎉 Deployment Complete!")
    print("=" * 25)
    print("Your PinIt backend is now live!")
    print("Next: Submit your iOS app to the App Store")
    print("\n📞 Need help? Check the deployment guides:")
    print("- railway_deploy.md")
    print("- DEPLOYMENT_INSTRUCTIONS.md")

if __name__ == "__main__":
    main()
