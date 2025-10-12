#!/usr/bin/env python3
"""
Quick backend connectivity test
"""

import requests
import json

BASE_URL = "https://pinit-backend-production.up.railway.app"

def test_backend():
    """Test basic backend connectivity"""
    print("🔍 Testing Backend Connectivity")
    print("=" * 40)
    
    # Test basic endpoint
    try:
        response = requests.get(f"{BASE_URL}/api/")
        print(f"✅ Backend is responding: {response.status_code}")
    except Exception as e:
        print(f"❌ Backend connection failed: {e}")
        return False
    
    # Test registration
    print("\n📝 Testing user registration...")
    test_user = {
        "username": "test_user_rsvp",
        "email": "test@example.com",
        "password": "test123456",
        "first_name": "Test",
        "last_name": "User"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/register/", json=test_user)
        if response.status_code in [200, 201]:
            result = response.json()
            if result.get("success"):
                print("✅ User registration works")
                return True
            else:
                print(f"❌ Registration failed: {result}")
        else:
            print(f"❌ Registration failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"❌ Registration error: {e}")
    
    return False

if __name__ == "__main__":
    test_backend()
