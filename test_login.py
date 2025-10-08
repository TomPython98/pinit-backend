#!/usr/bin/env python3
"""
Test login functionality
"""

import requests
import json

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app/api"

def test_login(username, password):
    """Test login for a user"""
    url = f"{BASE_URL}/login/"
    data = {
        "username": username,
        "password": password
    }
    
    print(f"Testing login for {username}...")
    print(f"URL: {url}")
    print(f"Data: {data}")
    
    try:
        response = requests.post(url, json=data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Success! Full response: {result}")
            # Try different possible token fields
            token = result.get('access') or result.get('token') or result.get('access_token')
            if token:
                print(f"Token found: {token[:50]}...")
                return token
            else:
                print("No token found in response")
                return None
        else:
            print(f"Login failed: {response.text}")
            return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def main():
    print("🔍 Testing login functionality...")
    
    # Test with one of the users
    test_login("alex_student", "testpass123")
    
    print("\n" + "="*50)
    
    # Test with a user we know exists (from the logs)
    test_login("tomas", "testpass123")

if __name__ == "__main__":
    main()
