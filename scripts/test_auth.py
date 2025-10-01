#!/usr/bin/env python3
"""
Test authentication for the created users
"""

import os
import sys
import django

# Add the Django project directory to the Python path
sys.path.append('/Users/tombesinger/Desktop/PinItApp/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.contrib.auth import authenticate
from django.contrib.auth.models import User

def test_authentication():
    """Test authentication for different users"""
    
    # Test the new test user
    print("=== Testing New Test User ===")
    user = authenticate(username="testuser", password="testpass123")
    if user:
        print(f"✅ testuser authentication successful!")
        print(f"   User ID: {user.id}")
        print(f"   Email: {user.email}")
        print(f"   Is Active: {user.is_active}")
    else:
        print("❌ testuser authentication failed!")
    
    # Test one of the generated users
    print("\n=== Testing Generated User ===")
    user = authenticate(username="maria luiza_kruschwitz_343", password="buenosaires123")
    if user:
        print(f"✅ maria luiza_kruschwitz_343 authentication successful!")
        print(f"   User ID: {user.id}")
        print(f"   Email: {user.email}")
        print(f"   Is Active: {user.is_active}")
    else:
        print("❌ maria luiza_kruschwitz_343 authentication failed!")
    
    # Check if user exists
    try:
        user_obj = User.objects.get(username="maria luiza_kruschwitz_343")
        print(f"   User exists in database: {user_obj.username}")
        print(f"   User is active: {user_obj.is_active}")
        print(f"   User has password: {bool(user_obj.password)}")
    except User.DoesNotExist:
        print("   User does not exist in database!")

if __name__ == "__main__":
    test_authentication()
