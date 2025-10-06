#!/usr/bin/env python3
"""
Database migration script to create missing tables and columns
This will run automatically when the server starts
"""

import os
import sys
import django
from django.core.management import execute_from_command_line

def run_migrations():
    """Run Django migrations to create missing tables"""
    print("🔄 Running database migrations...")
    
    # Set up Django environment
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
    django.setup()
    
    try:
        # Run migrations
        execute_from_command_line(['manage.py', 'migrate'])
        print("✅ Database migrations completed successfully!")
        
        # Create superuser if it doesn't exist
        from django.contrib.auth.models import User
        if not User.objects.filter(username='admin').exists():
            User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
            print("✅ Created admin superuser")
        
        return True
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        return False

if __name__ == "__main__":
    success = run_migrations()
    sys.exit(0 if success else 1)