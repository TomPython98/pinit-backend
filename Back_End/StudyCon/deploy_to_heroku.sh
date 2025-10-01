#!/bin/bash

# PinIt App - Heroku Deployment Script
# This script automates the deployment of your Django backend to Heroku

set -e  # Exit on any error

echo "🚀 PinIt App - Heroku Deployment"
echo "================================="

# Check if we're in the right directory
if [ ! -f "manage.py" ]; then
    echo "❌ Error: Please run this script from the StudyCon directory"
    echo "   Current directory: $(pwd)"
    exit 1
fi

# Check if Heroku CLI is installed
if ! command -v heroku &> /dev/null; then
    echo "❌ Heroku CLI not found. Please install it first:"
    echo "   brew install heroku/brew/heroku"
    exit 1
fi

# Check if user is logged in to Heroku
if ! heroku auth:whoami &> /dev/null; then
    echo "🔐 Please log in to Heroku first:"
    heroku login
fi

# Step 1: Initialize git repository if needed
echo "📁 Step 1: Setting up Git repository..."
if [ ! -d ".git" ]; then
    git init
    echo "✅ Git repository initialized"
else
    echo "ℹ️  Git repository already exists"
fi

# Create .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << EOL
# Django
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
EOL
    echo "✅ .gitignore created"
fi

# Step 2: Create or update Heroku app
echo "🌐 Step 2: Setting up Heroku app..."
read -p "Enter your Heroku app name (e.g., pinit-backend): " APP_NAME

if [ -z "$APP_NAME" ]; then
    echo "❌ App name cannot be empty"
    exit 1
fi

# Check if app already exists
if heroku apps:info $APP_NAME &> /dev/null; then
    echo "ℹ️  Heroku app '$APP_NAME' already exists"
    heroku git:remote -a $APP_NAME
else
    echo "🆕 Creating new Heroku app '$APP_NAME'..."
    heroku create $APP_NAME
fi

# Step 3: Add required addons
echo "🔧 Step 3: Setting up Heroku addons..."

# Add PostgreSQL
if ! heroku addons --app $APP_NAME | grep -q "heroku-postgresql"; then
    echo "📊 Adding PostgreSQL database..."
    heroku addons:create heroku-postgresql:hobby-dev --app $APP_NAME
else
    echo "ℹ️  PostgreSQL addon already exists"
fi

# Add Redis
if ! heroku addons --app $APP_NAME | grep -q "heroku-redis"; then
    echo "🔴 Adding Redis for WebSockets..."
    heroku addons:create heroku-redis:hobby-dev --app $APP_NAME
else
    echo "ℹ️  Redis addon already exists"
fi

# Step 4: Set environment variables
echo "⚙️  Step 4: Setting environment variables..."

# Generate a new secret key
SECRET_KEY=$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')

heroku config:set \
    SECRET_KEY="$SECRET_KEY" \
    DEBUG=False \
    DJANGO_SETTINGS_MODULE=StudyCon.settings_production \
    ALLOWED_HOSTS="$APP_NAME.herokuapp.com,pin-it.net,www.pin-it.net,api.pin-it.net" \
    --app $APP_NAME

echo "✅ Environment variables set"

# Step 5: Prepare files for deployment
echo "📝 Step 5: Preparing deployment files..."

# Ensure requirements_production.txt exists
if [ ! -f "requirements_production.txt" ]; then
    echo "❌ requirements_production.txt not found"
    exit 1
fi

# Copy production requirements to requirements.txt for Heroku
cp requirements_production.txt requirements.txt
echo "✅ Requirements file prepared"

# Ensure Procfile exists
if [ ! -f "Procfile" ]; then
    echo "❌ Procfile not found"
    exit 1
fi

# Ensure runtime.txt exists
if [ ! -f "runtime.txt" ]; then
    echo "❌ runtime.txt not found"
    exit 1
fi

# Step 6: Commit and deploy
echo "🚀 Step 6: Deploying to Heroku..."

git add .
git commit -m "Deploy PinIt backend to Heroku - $(date)" || echo "ℹ️  No changes to commit"

echo "📤 Pushing to Heroku..."
git push heroku main

# Step 7: Run database migrations
echo "📊 Step 7: Setting up database..."
heroku run python manage.py migrate --app $APP_NAME

# Step 8: Create superuser (optional)
echo "👤 Step 8: Creating admin user..."
read -p "Do you want to create an admin user? (y/n): " CREATE_ADMIN

if [ "$CREATE_ADMIN" = "y" ] || [ "$CREATE_ADMIN" = "Y" ]; then
    heroku run python manage.py createsuperuser --app $APP_NAME
fi

# Step 9: Test the deployment
echo "🧪 Step 9: Testing deployment..."
APP_URL="https://$APP_NAME.herokuapp.com"

echo "📡 Testing API endpoint..."
if curl -s "$APP_URL/api/get_all_users/" | grep -q "success\|error"; then
    echo "✅ API is responding!"
else
    echo "⚠️  API might not be responding correctly"
fi

# Step 10: Display results
echo ""
echo "🎉 Deployment completed!"
echo "========================"
echo "🌐 Your app is live at: $APP_URL"
echo "🔧 Admin panel: $APP_URL/admin/"
echo "📡 API base URL: $APP_URL/api/"
echo ""
echo "📋 Next steps:"
echo "1. Update your iOS app to use: $APP_URL/api/"
echo "2. Set up custom domain (pin-it.net) in Heroku dashboard"
echo "3. Test all API endpoints"
echo "4. Update DNS settings for pin-it.net"
echo ""
echo "🔍 Useful commands:"
echo "   heroku logs --tail --app $APP_NAME    # View logs"
echo "   heroku run python manage.py shell --app $APP_NAME    # Django shell"
echo "   heroku restart --app $APP_NAME    # Restart app"
echo ""
echo "✅ Your PinIt backend is now live!"

