#!/usr/bin/env python3
"""
Startup script that runs migrations before starting the Django server
"""

import os
import sys
import subprocess
import django
from django.core.management import execute_from_command_line

def setup_database():
    """Set up the database with all required tables"""
    print("🚀 Setting up database...")
    
    # Set up Django environment
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
    django.setup()
    
    try:
        # Run migrations
        print("📊 Running database migrations...")
        execute_from_command_line(['manage.py', 'migrate'])
        print("✅ Migrations completed!")
        
        # Create UserImage table if it doesn't exist
        from myapp.models import UserImage
        print("✅ UserImage model loaded successfully!")
        
        # Create admin user if it doesn't exist
        from django.contrib.auth.models import User
        if not User.objects.filter(username='admin').exists():
            User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
            print("✅ Created admin superuser")
        
        return True
        
    except Exception as e:
        print(f"❌ Database setup failed: {e}")
        return False

def start_server():
    """Start the Django development server"""
    print("🌐 Starting Django server...")
    try:
        execute_from_command_line(['manage.py', 'runserver', '0.0.0.0:8000'])
    except Exception as e:
        print(f"❌ Server start failed: {e}")

if __name__ == "__main__":
    print("🎯 PinIt Backend Startup Script")
    print("=" * 40)
    
    # Setup database first
    if setup_database():
        print("✅ Database setup complete!")
        print("🌐 Starting server...")
        start_server()
    else:
        print("❌ Failed to setup database. Exiting.")
        sys.exit(1)