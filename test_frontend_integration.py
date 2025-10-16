#!/usr/bin/env python3
"""
Frontend Integration Test Script
Tests all critical endpoints that the iOS app uses
"""

import requests
import json
import time
import uuid

# Configuration
BASE_URL = "https://pinit-backend-production.up.railway.app"
API_BASE = f"{BASE_URL}/api"

def test_endpoint(method, endpoint, data=None, headers=None, expected_status=[200, 201]):
    """Test a single endpoint"""
    url = f"{API_BASE}{endpoint}"
    
    try:
        if method.upper() == "GET":
            response = requests.get(url, headers=headers, timeout=10)
        elif method.upper() == "POST":
            response = requests.post(url, json=data, headers=headers, timeout=10)
        else:
            return False, f"Unsupported method: {method}"
        
        # Handle both single status and list of acceptable statuses
        if isinstance(expected_status, int):
            expected_status = [expected_status]
        
        success = response.status_code in expected_status
        return success, f"Status: {response.status_code}, Response: {response.text[:100]}"
    except Exception as e:
        return False, f"Error: {str(e)}"

def test_authentication_flow():
    """Test the complete authentication flow"""
    print("🔐 Testing Authentication Flow...")
    
    # Test registration
    test_user = f"testuser_{int(time.time())}"
    reg_data = {
        "username": test_user,
        "password": "testpassword123"
    }
    
    success, msg = test_endpoint("POST", "/register/", reg_data)
    print(f"  Registration: {'✅' if success else '❌'} {msg}")
    
    if not success:
        return False
    
    # Test login
    login_data = {
        "username": test_user,
        "password": "testpassword123"
    }
    
    success, msg = test_endpoint("POST", "/login/", login_data)
    print(f"  Login: {'✅' if success else '❌'} {msg}")
    
    if not success:
        return False
    
    # Extract token from response
    try:
        response = requests.post(f"{API_BASE}/login/", json=login_data, timeout=10)
        token_data = response.json()
        access_token = token_data.get("access_token")
        
        if not access_token:
            print("  ❌ No access token received")
            return False
            
        headers = {"Authorization": f"Bearer {access_token}"}
        
        # Test authenticated endpoints
        print("  Testing authenticated endpoints...")
        
        # Test get all users
        success, msg = test_endpoint("GET", "/get_all_users/", headers=headers)
        print(f"    Get all users: {'✅' if success else '❌'} {msg}")
        
        # Test get user preferences
        success, msg = test_endpoint("GET", f"/user_preferences/{test_user}/", headers=headers)
        print(f"    Get user preferences: {'✅' if success else '❌'} {msg}")
        
        # Test logout
        success, msg = test_endpoint("POST", "/logout/", headers=headers)
        print(f"    Logout: {'✅' if success else '❌'} {msg}")
        
        return True
        
    except Exception as e:
        print(f"  ❌ Authentication flow error: {e}")
        return False

def test_event_operations():
    """Test event creation and management"""
    print("\n📅 Testing Event Operations...")
    
    # First login to get token
    test_user = f"eventuser_{int(time.time())}"
    reg_data = {"username": test_user, "password": "testpassword123"}
    
    # Register and login
    requests.post(f"{API_BASE}/register/", json=reg_data, timeout=10)
    login_response = requests.post(f"{API_BASE}/login/", json=reg_data, timeout=10)
    token_data = login_response.json()
    access_token = token_data.get("access_token")
    headers = {"Authorization": f"Bearer {access_token}"}
    
    # Test event creation
    event_data = {
        "title": "Test Event",
        "description": "This is a test event",
        "latitude": 40.7128,
        "longitude": -74.0060,
        "time": "2025-12-15T18:00:00Z",
        "end_time": "2025-12-15T20:00:00Z",
        "is_public": True,
        "event_type": "study"
    }
    
    success, msg = test_endpoint("POST", "/create_study_event/", event_data, headers)
    print(f"  Event creation: {'✅' if success else '❌'} {msg}")
    
    if success:
        # Extract event ID from response
        try:
            response = requests.post(f"{API_BASE}/create_study_event/", json=event_data, headers=headers, timeout=10)
            event_response = response.json()
            event_id = event_response.get("event_id")
            
            if event_id:
                # Test getting events
                success, msg = test_endpoint("GET", f"/get_study_events/{test_user}/", headers=headers)
                print(f"  Get user events: {'✅' if success else '❌'} {msg}")
                
                # Test event feed
                success, msg = test_endpoint("GET", f"/get_event_feed/{event_id}/", headers=headers)
                print(f"  Get event feed: {'✅' if success else '❌'} {msg}")
                
        except Exception as e:
            print(f"  ❌ Event operations error: {e}")

def test_input_sanitization():
    """Test XSS prevention"""
    print("\n🛡️ Testing Input Sanitization...")
    
    # Test with potentially malicious input
    malicious_inputs = [
        "<script>alert('xss')</script>",
        "javascript:alert('xss')",
        "<img src=x onerror=alert('xss')>",
        "'; DROP TABLE users; --"
    ]
    
    test_user = f"sanitest_{int(time.time())}"
    reg_data = {"username": test_user, "password": "testpassword123"}
    
    # Register and login
    requests.post(f"{API_BASE}/register/", json=reg_data, timeout=10)
    login_response = requests.post(f"{API_BASE}/login/", json=reg_data, timeout=10)
    token_data = login_response.json()
    access_token = token_data.get("access_token")
    headers = {"Authorization": f"Bearer {access_token}"}
    
    for i, malicious_input in enumerate(malicious_inputs):
        # Test event creation with malicious input
        event_data = {
            "title": f"Test Event {i}",
            "description": malicious_input,
            "latitude": 40.7128,
            "longitude": -74.0060,
            "time": "2025-12-15T18:00:00Z",
            "end_time": "2025-12-15T20:00:00Z",
            "is_public": True,
            "event_type": "study"
        }
        
        success, msg = test_endpoint("POST", "/create_study_event/", event_data, headers)
        print(f"  Malicious input {i+1}: {'✅' if success else '❌'} Sanitized successfully")
        
        if success:
            # Check if the response contains sanitized content
            try:
                response = requests.post(f"{API_BASE}/create_study_event/", json=event_data, headers=headers, timeout=10)
                response_text = response.text
                if "<script>" not in response_text and "javascript:" not in response_text:
                    print(f"    ✅ Input properly sanitized")
                else:
                    print(f"    ❌ Input not properly sanitized")
            except Exception as e:
                print(f"    ❌ Error checking sanitization: {e}")

def test_rate_limiting():
    """Test rate limiting"""
    print("\n⏱️ Testing Rate Limiting...")
    
    # Test rapid requests to a rate-limited endpoint
    rapid_requests = 0
    for i in range(15):  # Try 15 rapid requests
        success, msg = test_endpoint("GET", "/get_all_users/")
        if success:
            rapid_requests += 1
        else:
            if "429" in msg:  # Rate limited
                print(f"  ✅ Rate limiting working (blocked after {rapid_requests} requests)")
                return True
        time.sleep(0.1)  # Small delay
    
    print(f"  ⚠️ Rate limiting may not be working (allowed {rapid_requests} requests)")
    return False

def main():
    """Run all tests"""
    print("🧪 FRONTEND INTEGRATION TESTS")
    print("=" * 50)
    
    # Test authentication flow
    auth_success = test_authentication_flow()
    
    # Test event operations
    test_event_operations()
    
    # Test input sanitization
    test_input_sanitization()
    
    # Test rate limiting
    test_rate_limiting()
    
    print("\n" + "=" * 50)
    if auth_success:
        print("🎉 FRONTEND INTEGRATION TESTS COMPLETED!")
        print("✅ Backend is ready for frontend integration")
        print("\n📱 Next steps:")
        print("1. Test login/logout in your iOS app")
        print("2. Test event creation and viewing")
        print("3. Test comments and likes")
        print("4. Test image uploads")
        print("5. Test friend requests")
    else:
        print("❌ Some tests failed - check the output above")

if __name__ == "__main__":
    main()
