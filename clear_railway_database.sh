#!/bin/bash

# Simple script to clear Railway PostgreSQL database data
# This will run the Django management command directly on Railway

echo "🚀 Clearing Railway PostgreSQL Database Data"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will delete ALL data from your PostgreSQL database!"
echo "   - All users and profiles will be deleted"
echo "   - All events and comments will be deleted" 
echo "   - All social data will be deleted"
echo "   - Database structure will be preserved"
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Please install it first:"
    echo "   npm install -g @railway/cli"
    echo "   or visit: https://docs.railway.app/develop/cli"
    exit 1
fi

# Check if user is logged in
if ! railway whoami &> /dev/null; then
    echo "❌ Not logged in to Railway. Please login first:"
    echo "   railway login"
    exit 1
fi

echo "🔍 Current Railway status:"
railway whoami
echo ""

# List available projects
echo "📋 Available Railway projects:"
railway projects
echo ""

# Ask user to confirm
read -p "Are you sure you want to clear ALL data? Type 'CLEAR ALL DATA' to confirm: " confirmation

if [ "$confirmation" != "CLEAR ALL DATA" ]; then
    echo "❌ Operation cancelled. Confirmation text did not match."
    exit 1
fi

echo ""
echo "🗑️  Starting database cleanup..."
echo "This may take a few minutes..."

# Run the Django management command
railway run python manage.py clear_database_data --confirm

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Database cleanup completed successfully!"
    echo "🎉 All data has been cleared while preserving database structure"
    echo ""
    echo "📊 What was cleared:"
    echo "   - Users and user profiles"
    echo "   - User images and galleries"
    echo "   - Study events and invitations"
    echo "   - Event comments, likes, and shares"
    echo "   - Friend requests and chat messages"
    echo "   - User ratings and reputation data"
    echo "   - Device tokens for push notifications"
    echo ""
    echo "🔧 What was preserved:"
    echo "   - Database structure and tables"
    echo "   - Django migrations"
    echo "   - User trust levels (recommended)"
    echo "   - Auto-increment sequences reset to 1"
else
    echo ""
    echo "❌ Database cleanup failed!"
    echo "Please check the Railway logs for more details:"
    echo "   railway logs"
    exit 1
fi