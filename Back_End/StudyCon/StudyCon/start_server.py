#!/usr/bin/env python
"""
Startup script that handles database migrations gracefully
"""
import os
import sys
import django
from django.core.management import execute_from_command_line
from django.db import connection
from django.core.exceptions import ImproperlyConfigured

def test_database_connection():
    """Test if database connection works"""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        return True
    except Exception as e:
        print(f"Database connection test failed: {e}")
        return False

def run_migrations():
    """Run migrations if database is available"""
    print("🔄 Testing database connection...")
    
    if test_database_connection():
        print("✅ Database connection successful!")
        print("🔄 Running migrations...")
        try:
            execute_from_command_line(['manage.py', 'migrate', '--noinput'])
            print("✅ Migrations completed successfully!")
        except Exception as e:
            print(f"❌ Migration failed: {e}")
            print("⚠️  Continuing without migrations...")
    else:
        print("⚠️  Database not available, skipping migrations...")
        print("ℹ️  App will start with existing database state...")

if __name__ == "__main__":
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
    
    try:
        django.setup()
        run_migrations()
        
        print("🚀 Starting Gunicorn server...")
        # Start the server
        os.execvp('gunicorn', [
            'gunicorn', 
            'StudyCon.wsgi', 
            '--log-file', '-', 
            '--bind', f'0.0.0.0:{os.environ.get("PORT", "8000")}'
        ])
    except Exception as e:
        print(f"❌ Startup failed: {e}")
        sys.exit(1)

