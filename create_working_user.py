#!/usr/bin/env python3
"""
Quick user creation script - run when backend is working
"""

import requests
import json
from datetime import datetime, timedelta

BASE_URL = "https://pinit-backend-production.up.railway.app"

def create_working_user():
    """Create a single working user"""
    print("🚀 Creating working test user...")
    
    # Register user
    user_data = {
        "username": "working_test_user",
        "email": "working@test.com",
        "password": "password123",
        "first_name": "Working",
        "last_name": "User"
    }
    
    url = f"{BASE_URL}/api/register/"
    response = requests.post(url, json=user_data)
    
    if response.status_code == 201:
        result = response.json()
        if result.get("success"):
            print("✅ User created successfully!")
            print(f"Username: {user_data['username']}")
            print(f"Password: {user_data['password']}")
            return True
    
    print(f"❌ Failed to create user: {response.text}")
    return False

if __name__ == "__main__":
    create_working_user()
