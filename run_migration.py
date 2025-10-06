#!/usr/bin/env python3
"""
Run Django Migration for R2 Object Storage
"""
import os
import sys
import django
from django.core.management import execute_from_command_line

# Add the project directory to Python path
sys.path.append('/Users/tombesinger/Desktop/PinItApp')

# Set Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')

# Setup Django
django.setup()

def run_migration():
    """Run the migration to add object storage fields"""
    print("🔄 Running Django migration for R2 object storage...")
    
    try:
        # Run the migration
        execute_from_command_line(['manage.py', 'migrate', 'myapp', '0034'])
        print("✅ Migration completed successfully!")
        
        # Check if the fields were added
        from myapp.models import UserImage
        print("✅ UserImage model loaded")
        
        # List the fields
        fields = [field.name for field in UserImage._meta.fields]
        print(f"UserImage fields: {fields}")
        
        if 'storage_key' in fields and 'public_url' in fields:
            print("✅ Object storage fields are present!")
        else:
            print("❌ Object storage fields are missing!")
            
    except Exception as e:
        print(f"❌ Migration failed: {e}")

if __name__ == "__main__":
    run_migration()
