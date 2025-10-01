#!/usr/bin/env python3
"""
DigitalOcean App Platform Deployment Script for PinIt App
This script prepares your Django app for deployment to DigitalOcean App Platform
"""

import os
import sys
import json
import subprocess
from pathlib import Path

def create_app_yaml():
    """Create .do/app.yaml for DigitalOcean App Platform"""
    app_config = {
        "name": "pinit-backend",
        "services": [
            {
                "name": "web",
                "source_dir": ".",
                "github": {
                    "repo": "your-username/pinit-app",  # Update this
                    "branch": "main"
                },
                "run_command": "gunicorn StudyCon.wsgi --log-file - --bind 0.0.0.0:$PORT",
                "environment_slug": "python",
                "instance_count": 1,
                "instance_size_slug": "basic-xxs",
                "http_port": 8080,
                "envs": [
                    {
                        "key": "DEBUG",
                        "value": "False"
                    },
                    {
                        "key": "DJANGO_SETTINGS_MODULE",
                        "value": "StudyCon.settings_production"
                    },
                    {
                        "key": "SECRET_KEY",
                        "value": "your-production-secret-key-change-this"
                    },
                    {
                        "key": "ALLOWED_HOSTS",
                        "value": "pinit-backend.ondigitalocean.app,pin-it.net,www.pin-it.net"
                    }
                ]
            }
        ],
        "databases": [
            {
                "name": "pinit-db",
                "engine": "PG",
                "version": "13"
            }
        ]
    }
    
    # Create .do directory
    do_dir = Path(".do")
    do_dir.mkdir(exist_ok=True)
    
    # Write app.yaml
    with open(do_dir / "app.yaml", "w") as f:
        json.dump(app_config, f, indent=2)
    
    print("✅ Created .do/app.yaml for DigitalOcean App Platform")

def create_dockerfile():
    """Create Dockerfile for containerized deployment"""
    dockerfile_content = """FROM python:3.13-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    postgresql-client \\
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements_production.txt .
RUN pip install --no-cache-dir -r requirements_production.txt

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

# Expose port
EXPOSE 8080

# Run migrations and start server
CMD ["sh", "-c", "python manage.py migrate && gunicorn StudyCon.wsgi --log-file - --bind 0.0.0.0:8080"]
"""
    
    with open("Dockerfile", "w") as f:
        f.write(dockerfile_content)
    
    print("✅ Created Dockerfile")

def create_docker_compose():
    """Create docker-compose.yml for local testing"""
    compose_content = """version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: pinit_production
      POSTGRES_USER: pinit_user
      POSTGRES_PASSWORD: pinit_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8080
    volumes:
      - .:/app
    ports:
      - "8080:8080"
    depends_on:
      - db
      - redis
    environment:
      - DEBUG=False
      - DB_HOST=db
      - REDIS_URL=redis://redis:6379/0
      - SECRET_KEY=your-secret-key-change-this
      - DJANGO_SETTINGS_MODULE=StudyCon.settings_production

volumes:
  postgres_data:
"""
    
    with open("docker-compose.yml", "w") as f:
        f.write(compose_content)
    
    print("✅ Created docker-compose.yml")

def create_github_actions():
    """Create GitHub Actions workflow for automated deployment"""
    workflow_dir = Path(".github/workflows")
    workflow_dir.mkdir(parents=True, exist_ok=True)
    
    workflow_content = """name: Deploy to DigitalOcean App Platform

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to DigitalOcean App Platform
      uses: digitalocean/app_action@v1
      with:
        app_id: ${{ secrets.DIGITALOCEAN_APP_ID }}
        api_token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}
"""
    
    with open(workflow_dir / "deploy.yml", "w") as f:
        f.write(workflow_content)
    
    print("✅ Created GitHub Actions workflow")

def setup_git_repo():
    """Initialize git repository and create initial commit"""
    try:
        # Check if git is initialized
        if not Path(".git").exists():
            subprocess.run(["git", "init"], check=True)
            print("✅ Initialized git repository")
        
        # Create .gitignore
        gitignore_content = """# Django
*.pyc
__pycache__/
db.sqlite3
*.log
.env
local_settings.py

# Virtual environment
venv/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Production files
local_data_export.json
database_schema.json

# Docker
.dockerignore
"""
        
        with open(".gitignore", "w") as f:
            f.write(gitignore_content)
        
        print("✅ Created .gitignore")
        
        # Add all files
        subprocess.run(["git", "add", "."], check=True)
        
        # Create initial commit
        subprocess.run(["git", "commit", "-m", "Initial commit for PinIt backend deployment"], check=True)
        
        print("✅ Created initial git commit")
        
    except subprocess.CalledProcessError as e:
        print(f"❌ Git setup failed: {e}")
        return False
    
    return True

def create_deployment_instructions():
    """Create deployment instructions"""
    instructions = """# 🚀 PinIt Backend Deployment Instructions

## Option 1: DigitalOcean App Platform (Recommended)

### Step 1: Create DigitalOcean Account
1. Go to https://digitalocean.com
2. Sign up for an account
3. Add a payment method

### Step 2: Create App
1. Go to Apps in DigitalOcean dashboard
2. Click "Create App"
3. Connect your GitHub repository
4. Select the repository: your-username/pinit-app
5. Choose the branch: main

### Step 3: Configure App
1. App Name: pinit-backend
2. Source Directory: Back_End/StudyCon
3. Build Command: pip install -r requirements_production.txt
4. Run Command: gunicorn StudyCon.wsgi --log-file - --bind 0.0.0.0:$PORT

### Step 4: Add Database
1. Click "Add Database"
2. Choose PostgreSQL
3. Name: pinit-db
4. Version: 13

### Step 5: Set Environment Variables
- DEBUG: False
- DJANGO_SETTINGS_MODULE: StudyCon.settings_production
- SECRET_KEY: [Generate a secure secret key]
- ALLOWED_HOSTS: pinit-backend.ondigitalocean.app,pin-it.net,www.pin-it.net

### Step 6: Deploy
1. Click "Create Resources"
2. Wait for deployment to complete
3. Your app will be available at: https://pinit-backend.ondigitalocean.app

## Option 2: Docker Deployment

### Local Testing
```bash
# Build and run with Docker Compose
docker-compose up --build

# Your app will be available at: http://localhost:8080
```

### Deploy to Any Cloud Provider
1. Build Docker image: `docker build -t pinit-backend .`
2. Push to registry (Docker Hub, AWS ECR, etc.)
3. Deploy to your preferred cloud provider

## Option 3: Manual VPS Deployment

### Step 1: Set up VPS
1. Create a VPS (DigitalOcean Droplet, Linode, etc.)
2. Install Python 3.13, PostgreSQL, Redis
3. Clone your repository

### Step 2: Deploy Application
```bash
# Install dependencies
pip install -r requirements_production.txt

# Set up database
python manage.py migrate

# Collect static files
python manage.py collectstatic

# Run with Gunicorn
gunicorn StudyCon.wsgi --bind 0.0.0.0:8000
```

## 🌐 Domain Setup

### For DigitalOcean App Platform
1. Go to your app settings
2. Click "Domains"
3. Add custom domain: pin-it.net
4. Update DNS records as instructed

### For Other Providers
1. Point your domain to your server IP
2. Configure SSL certificate (Let's Encrypt)
3. Update ALLOWED_HOSTS in environment variables

## 📱 Next Steps

1. Test your API endpoints
2. Update iOS app to use production URL
3. Set up monitoring and logging
4. Configure push notifications
5. Submit iOS app to App Store

## 🔧 Useful Commands

```bash
# Check app logs
doctl apps logs <app-id> --follow

# Scale app
doctl apps update <app-id> --spec .do/app.yaml

# Database access
doctl databases connection <database-id>
```

## 💰 Estimated Costs

- DigitalOcean App Platform: $5-12/month
- Domain: Already owned ✅
- SSL Certificate: Free
- Total: ~$5-12/month

---

**Your PinIt backend is ready for production deployment!**
"""
    
    with open("DEPLOYMENT_INSTRUCTIONS.md", "w") as f:
        f.write(instructions)
    
    print("✅ Created deployment instructions")

def main():
    """Main deployment setup function"""
    print("🚀 PinIt Backend - Production Deployment Setup")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not Path("manage.py").exists():
        print("❌ Error: Please run this script from the StudyCon directory")
        print("   Current directory:", os.getcwd())
        sys.exit(1)
    
    try:
        # Create deployment files
        create_app_yaml()
        create_dockerfile()
        create_docker_compose()
        create_github_actions()
        create_deployment_instructions()
        
        # Setup git repository
        if setup_git_repo():
            print("\n🎉 Deployment setup completed successfully!")
            print("\n📋 Next steps:")
            print("1. Push your code to GitHub")
            print("2. Follow DEPLOYMENT_INSTRUCTIONS.md")
            print("3. Deploy to DigitalOcean App Platform")
            print("4. Test your API endpoints")
            print("5. Update iOS app with production URL")
            print("\n🌐 Your PinIt backend is ready for production!")
        else:
            print("\n⚠️  Deployment files created, but git setup failed")
            print("   You can manually initialize git and push to GitHub")
    
    except Exception as e:
        print(f"❌ Error during setup: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
