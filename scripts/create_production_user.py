#!/usr/bin/env python3
"""
Create a test user on the production server via API
"""

import requests
import json

def create_production_user():
    """Create a test user on the production server"""
    
    # First, try to register a new user
    url = "https://pinit-backend-production.up.railway.app/api/register/"
    
    user_data = {
        "username": "testuser",
        "password": "testpass123"
    }
    
    try:
        response = requests.post(url, json=user_data)
        print(f"Registration response: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 201:
            print("✅ User created successfully!")
        elif response.status_code == 400:
            print("⚠️ User might already exist, trying to login...")
        else:
            print(f"❌ Registration failed: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
    
    # Now try to login
    login_url = "https://pinit-backend-production.up.railway.app/api/login/"
    login_data = {
        "username": "testuser",
        "password": "testpass123"
    }
    
    try:
        response = requests.post(login_url, json=login_data)
        print(f"\nLogin response: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            print("✅ Login successful!")
        else:
            print(f"❌ Login failed: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    create_production_user()
