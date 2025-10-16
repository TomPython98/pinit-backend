#!/usr/bin/env python3
"""
JWT Token Expiration Test
Tests token expiration and refresh functionality
"""

import requests
import json
import time
from datetime import datetime, timedelta

BASE_URL = "https://pinit-backend-production.up.railway.app"
API_BASE = f"{BASE_URL}/api"

def test_token_expiration():
    """Test JWT token expiration behavior"""
    print("🔐 Testing JWT Token Expiration...")
    
    # Register and login
    test_user = f"tokenuser_{int(time.time())}"
    reg_data = {"username": test_user, "password": "testpassword123"}
    
    print(f"  Registering user: {test_user}")
    reg_response = requests.post(f"{API_BASE}/register/", json=reg_data, timeout=10)
    print(f"  Registration: {reg_response.status_code}")
    
    print(f"  Logging in...")
    login_response = requests.post(f"{API_BASE}/login/", json=reg_data, timeout=10)
    print(f"  Login: {login_response.status_code}")
    
    if login_response.status_code == 200:
        token_data = login_response.json()
        access_token = token_data.get("access_token")
        refresh_token = token_data.get("refresh_token")
        
        print(f"  ✅ Got tokens:")
        print(f"    Access token: {access_token[:50]}...")
        print(f"    Refresh token: {refresh_token[:50]}...")
        
        # Test with access token
        headers = {"Authorization": f"Bearer {access_token}"}
        
        print(f"\n  Testing authenticated request...")
        response = requests.get(f"{API_BASE}/get_all_users/", headers=headers, timeout=10)
        print(f"  Authenticated request: {response.status_code}")
        
        if response.status_code == 200:
            print(f"  ✅ Token is valid")
            
            # Test token refresh
            print(f"\n  Testing token refresh...")
            refresh_data = {"refresh": refresh_token}
            refresh_response = requests.post(f"{API_BASE}/token/refresh/", json=refresh_data, timeout=10)
            print(f"  Token refresh: {refresh_response.status_code}")
            
            if refresh_response.status_code == 200:
                new_token_data = refresh_response.json()
                new_access_token = new_token_data.get("access")
                print(f"  ✅ Got new access token: {new_access_token[:50]}...")
                
                # Test with new token
                new_headers = {"Authorization": f"Bearer {new_access_token}"}
                test_response = requests.get(f"{API_BASE}/get_all_users/", headers=new_headers, timeout=10)
                print(f"  Test with new token: {test_response.status_code}")
                
                if test_response.status_code == 200:
                    print(f"  ✅ Token refresh working correctly")
                else:
                    print(f"  ❌ New token not working: {test_response.text}")
            else:
                print(f"  ❌ Token refresh failed: {refresh_response.text}")
        else:
            print(f"  ❌ Token not valid: {response.text}")
    else:
        print(f"  ❌ Login failed: {login_response.text}")

def test_event_creation_with_token():
    """Test event creation with proper token handling"""
    print("\n📅 Testing Event Creation with Token...")
    
    # Register and login
    test_user = f"eventuser_{int(time.time())}"
    reg_data = {"username": test_user, "password": "testpassword123"}
    
    requests.post(f"{API_BASE}/register/", json=reg_data, timeout=10)
    login_response = requests.post(f"{API_BASE}/login/", json=reg_data, timeout=10)
    
    if login_response.status_code == 200:
        token_data = login_response.json()
        access_token = token_data.get("access_token")
        headers = {"Authorization": f"Bearer {access_token}"}
        
        # Test event creation
        event_data = {
            "title": "Token Test Event",
            "description": "Testing event creation with token",
            "latitude": 40.7128,
            "longitude": -74.0060,
            "time": "2025-12-15T18:00:00Z",
            "end_time": "2025-12-15T20:00:00Z",
            "is_public": True,
            "event_type": "study"
        }
        
        print(f"  Creating event...")
        response = requests.post(f"{API_BASE}/create_study_event/", json=event_data, headers=headers, timeout=10)
        print(f"  Event creation: {response.status_code}")
        
        if response.status_code == 201:
            print(f"  ✅ Event created successfully")
            event_response = response.json()
            print(f"  Event ID: {event_response.get('event_id')}")
        else:
            print(f"  ❌ Event creation failed: {response.text}")
            
            # Check if it's a token issue
            if "token" in response.text.lower() or "authentication" in response.text.lower():
                print(f"  🔍 This looks like a token/authentication issue!")
                print(f"  💡 Solution: Implement automatic token refresh in iOS app")
    else:
        print(f"  ❌ Login failed: {login_response.text}")

def test_expired_token_behavior():
    """Test what happens with expired tokens"""
    print("\n⏰ Testing Expired Token Behavior...")
    
    # Try to make a request without a token
    print(f"  Testing request without token...")
    response = requests.get(f"{API_BASE}/get_all_users/", timeout=10)
    print(f"  No token request: {response.status_code}")
    
    # Try to make a request with invalid token
    print(f"  Testing request with invalid token...")
    invalid_headers = {"Authorization": "Bearer invalid_token_here"}
    response = requests.get(f"{API_BASE}/get_all_users/", headers=invalid_headers, timeout=10)
    print(f"  Invalid token request: {response.status_code}")
    
    if response.status_code == 401:
        print(f"  ✅ Properly rejecting invalid tokens")
    else:
        print(f"  ⚠️ Unexpected behavior with invalid token")

def main():
    """Run all token tests"""
    print("🧪 JWT TOKEN EXPIRATION TESTS")
    print("=" * 50)
    
    test_token_expiration()
    test_event_creation_with_token()
    test_expired_token_behavior()
    
    print("\n" + "=" * 50)
    print("🎯 DIAGNOSIS:")
    print("If event creation fails with authentication errors,")
    print("the issue is likely:")
    print("1. Access token expired (1 hour lifetime)")
    print("2. iOS app not refreshing tokens automatically")
    print("3. iOS app not handling token refresh errors")
    print("\n💡 SOLUTION:")
    print("Implement automatic token refresh in iOS app")

if __name__ == "__main__":
    main()
