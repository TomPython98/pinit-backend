#!/usr/bin/env python3
"""
Test script to verify that friends and recent activities endpoints work for other users
"""

import requests
import json
import time
from datetime import datetime

# Configuration
BASE_URL = "https://pinit-backend-production.up.railway.app"
USERNAME = "tom"  # Test user
PASSWORD = "tomtom123A"

def log(message):
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {message}")

def make_request(method, endpoint, data=None, token=None):
    """Make HTTP request with proper headers"""
    url = f"{BASE_URL}{endpoint}"
    headers = {
        "Content-Type": "application/json",
    }
    
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    try:
        if method == "GET":
            response = requests.get(url, headers=headers)
        elif method == "POST":
            response = requests.post(url, headers=headers, json=data)
        
        log(f"{method} {endpoint} - Status: {response.status_code}")
        
        if response.status_code >= 400:
            log(f"Request failed: {response.status_code} - {response.text}")
            return None
        
        return response.json()
    except Exception as e:
        log(f"Request error: {e}")
        return None

def login_user(username, password):
    """Login and get JWT token"""
    log(f"Logging in user: {username}")
    
    login_data = {
        "username": username,
        "password": password
    }
    
    result = make_request("POST", "/api/login/", login_data)
    if result and "access_token" in result:
        log(f"Successfully logged in: {username}")
        return result["access_token"]
    else:
        log(f"Failed to login: {username}")
        log(f"Response: {result}")
        return None

def test_friends_endpoint(token, target_username):
    """Test friends endpoint for another user"""
    log(f"Testing friends endpoint for user: {target_username}")
    
    result = make_request("GET", f"/api/get_friends/{target_username}/", token=token)
    if result:
        friends = result.get("friends", [])
        log(f"✅ Friends endpoint works! Found {len(friends)} friends")
        if friends:
            log(f"Sample friends: {friends[:3]}")
        return True
    else:
        log("❌ Friends endpoint failed")
        return False

def test_recent_activity_endpoint(token, target_username):
    """Test recent activity endpoint for another user"""
    log(f"Testing recent activity endpoint for user: {target_username}")
    
    result = make_request("GET", f"/api/get_user_recent_activity/{target_username}/", token=token)
    if result:
        events = result.get("events", [])
        log(f"✅ Recent activity endpoint works! Found {len(events)} events")
        if events:
            log(f"Sample events: {[event['title'] for event in events[:3]]}")
        return True
    else:
        log("❌ Recent activity endpoint failed")
        return False

def main():
    log("Starting profile endpoints test...")
    
    # Login as test user
    token = login_user(USERNAME, PASSWORD)
    if not token:
        log("Failed to login. Exiting.")
        return
    
    # Test with one of the Buenos Aires users we created
    test_users = [
        "federico_flores_1",
        "martín_fernández_2", 
        "isabella_lópez_3",
        "alejandro_rivera_4",
        "lucía_pérez_5"
    ]
    
    success_count = 0
    total_tests = 0
    
    for test_user in test_users[:2]:  # Test first 2 users
        log(f"\n--- Testing profile for: {test_user} ---")
        
        # Test friends endpoint
        total_tests += 1
        if test_friends_endpoint(token, test_user):
            success_count += 1
        
        time.sleep(0.5)
        
        # Test recent activity endpoint
        total_tests += 1
        if test_recent_activity_endpoint(token, test_user):
            success_count += 1
        
        time.sleep(0.5)
    
    log(f"\n=== TEST RESULTS ===")
    log(f"Total tests: {total_tests}")
    log(f"Successful: {success_count}")
    log(f"Failed: {total_tests - success_count}")
    log(f"Success rate: {(success_count/total_tests)*100:.1f}%")
    
    if success_count == total_tests:
        log("🎉 All tests passed! Friends and recent activities should now show in profiles.")
    else:
        log("⚠️ Some tests failed. Check the logs above for details.")

if __name__ == "__main__":
    main()
