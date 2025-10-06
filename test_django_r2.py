#!/usr/bin/env python3
"""
Test Django R2 configuration
"""
import os
import sys
import django

# Add the project directory to Python path
sys.path.append('/Users/tombesinger/Desktop/PinItApp')

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.conf import settings

def test_django_r2():
    print("Testing Django R2 configuration...")
    print(f"DEBUG: {settings.DEBUG}")
    print(f"DEFAULT_FILE_STORAGE: {settings.DEFAULT_FILE_STORAGE}")
    print(f"MEDIA_URL: {settings.MEDIA_URL}")
    
    # Test file upload
    test_content = b'This is a Django R2 test file'
    test_file = ContentFile(test_content, name='django-r2-test.txt')
    
    try:
        # Save file using Django storage
        saved_path = default_storage.save('test/django-r2-test.txt', test_file)
        print(f"✅ File saved to: {saved_path}")
        
        # Get the URL
        file_url = default_storage.url(saved_path)
        print(f"✅ File URL: {file_url}")
        
        # Check if file exists
        exists = default_storage.exists(saved_path)
        print(f"✅ File exists: {exists}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    test_django_r2()
