#!/usr/bin/env python3
"""
Quick test script to verify the fixed endpoints work correctly
"""

import requests
import json
import random
import time
from datetime import datetime, timedelta

BASE_URL = "https://pinit-backend-production.up.railway.app"

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
        
        if response.status_code in [200, 201]:
            return response.json()
        else:
            print(f"Request failed: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"Request error: {e}")
        return None

def test_login():
    """Test login with existing user"""
    print("🔐 Testing login...")
    
    login_data = {
        "username": "bárbara_álvarez_1",
        "password": "test123456"
    }
    
    result = make_request("POST", "/api/login/", login_data)
    if result and result.get("success"):
        token = result.get("access_token")
        if token:
            print(f"✅ Login successful! Token: {token[:20]}...")
            return token
        else:
            print("❌ No access_token in response")
            return None
    else:
        print("❌ Login failed")
        return None

def test_create_event(token):
    """Test event creation"""
    print("📅 Testing event creation...")
    
    # Generate event time (tomorrow at 6 PM)
    event_time = datetime.now() + timedelta(days=1, hours=18)
    end_time = event_time + timedelta(hours=2)
    
    event_data = {
        "title": "Test Study Session",
        "description": "Quick test event",
        "latitude": -34.6037,
        "longitude": -58.3816,
        "time": event_time.isoformat(),
        "end_time": end_time.isoformat(),
        "max_participants": 5,
        "event_type": "study",
        "interest_tags": ["study", "academic"],
        "is_public": True,
        "enable_auto_matching": False,
        "selected_friends": []
    }
    
    result = make_request("POST", "/api/create_study_event/", event_data, token)
    if result and result.get("success"):
        event_id = result.get("event_id")
        print(f"✅ Event created! ID: {event_id}")
        return event_id
    else:
        print("❌ Event creation failed")
        return None

def test_add_comment(token, username, event_id):
    """Test adding a comment"""
    print("💬 Testing comment addition...")
    
    comment_data = {
        "username": username,
        "event_id": event_id,
        "text": "This is a test comment!"
    }
    
    result = make_request("POST", "/api/events/comment/", comment_data, token)
    if result and result.get("success"):
        print("✅ Comment added successfully!")
        return True
    else:
        print("❌ Comment addition failed")
        return False

def test_like_event(token, username, event_id):
    """Test liking an event"""
    print("❤️ Testing event like...")
    
    like_data = {
        "username": username,
        "event_id": event_id
    }
    
    result = make_request("POST", "/api/events/like/", like_data, token)
    if result and result.get("success"):
        print("✅ Event liked successfully!")
        return True
    else:
        print("❌ Event like failed")
        return False

def test_invite_friend(token, event_id, friend_username):
    """Test inviting a friend to an event"""
    print("📨 Testing friend invitation...")
    
    invite_data = {
        "event_id": event_id,
        "username": friend_username
    }
    
    result = make_request("POST", "/invite_to_event/", invite_data, token)
    if result and result.get("success"):
        print(f"✅ Friend {friend_username} invited successfully!")
        return True
    else:
        print(f"❌ Friend invitation failed")
        return False

def main():
    print("🧪 Testing PinIt API Endpoints")
    print("=" * 50)
    
    # 1. Test login
    token = test_login()
    if not token:
        print("❌ Cannot proceed without valid token")
        return
    
    username = "bárbara_álvarez_1"
    print()
    
    # 2. Test event creation
    event_id = test_create_event(token)
    if not event_id:
        print("❌ Cannot proceed without valid event")
        return
    
    print()
    
    # 3. Test comment addition
    test_add_comment(token, username, event_id)
    print()
    
    # 4. Test event like
    test_like_event(token, username, event_id)
    print()
    
    # 5. Test friend invitation
    test_invite_friend(token, event_id, "maría_torres_2")
    print()
    
    print("🎉 All tests completed!")

if __name__ == "__main__":
    main()
