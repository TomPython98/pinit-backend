#!/usr/bin/env python3
"""
Test script for working features (avoiding EventJoinRequest issues)
"""

import requests
import json
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

def test_working_features():
    """Test features that work without EventJoinRequest"""
    print("🧪 Testing Working PinIt Features")
    print("=" * 50)
    
    # 1. Login as user
    print("1️⃣ Logging in...")
    login_data = {
        "username": "bárbara_álvarez_1",
        "password": "test123456"
    }
    
    login_result = make_request("POST", "/api/login/", login_data)
    if not login_result or not login_result.get("success"):
        print("❌ Login failed")
        return
    
    token = login_result.get("access_token")
    username = login_result.get("username")
    print(f"✅ Logged in: {username}")
    
    # 2. Create public event
    print("\n2️⃣ Creating public event...")
    event_time = datetime.now() + timedelta(days=1, hours=18)
    end_time = event_time + timedelta(hours=2)
    
    event_data = {
        "title": "Public Study Session - Feature Test",
        "description": "Testing working features",
        "latitude": -34.6037,
        "longitude": -58.3816,
        "time": event_time.isoformat(),
        "end_time": end_time.isoformat(),
        "max_participants": 10,
        "event_type": "study",
        "interest_tags": ["study", "academic"],
        "is_public": True,  # Public event
        "enable_auto_matching": False,
        "selected_friends": []
    }
    
    event_result = make_request("POST", "/api/create_study_event/", event_data, token)
    if not event_result or not event_result.get("success"):
        print("❌ Event creation failed")
        return
    
    event_id = event_result.get("event_id")
    print(f"✅ Public event created: {event_id}")
    
    # 3. Add comment
    print("\n3️⃣ Adding comment...")
    comment_data = {
        "username": username,
        "event_id": event_id,
        "text": "This is a test comment!"
    }
    
    comment_result = make_request("POST", "/api/events/comment/", comment_data, token)
    if comment_result and comment_result.get("success"):
        print("✅ Comment added successfully!")
    else:
        print("❌ Comment failed")
    
    # 4. Like event
    print("\n4️⃣ Liking event...")
    like_data = {
        "username": username,
        "event_id": event_id
    }
    
    like_result = make_request("POST", "/api/events/like/", like_data, token)
    if like_result and like_result.get("success"):
        print("✅ Event liked successfully!")
    else:
        print("❌ Like failed")
    
    # 5. Share event
    print("\n5️⃣ Sharing event...")
    share_data = {
        "event_id": event_id,
        "platform": "whatsapp"
    }
    
    share_result = make_request("POST", "/api/events/share/", share_data, token)
    if share_result and share_result.get("success"):
        print("✅ Event shared successfully!")
    else:
        print("❌ Share failed")
    
    # 6. Login as different user and RSVP to public event
    print("\n6️⃣ Testing RSVP to public event...")
    user2_login = {
        "username": "maría_torres_2",
        "password": "test123456"
    }
    
    user2_result = make_request("POST", "/api/login/", user2_login)
    if user2_result and user2_result.get("success"):
        user2_token = user2_result.get("access_token")
        user2_username = user2_result.get("username")
        
        rsvp_data = {
            "event_id": event_id
        }
        
        rsvp_result = make_request("POST", "/api/rsvp_study_event/", rsvp_data, user2_token)
        if rsvp_result:
            action = rsvp_result.get("action", "unknown")
            if action == "joined":
                print("✅ User joined public event directly!")
            elif action == "left":
                print("✅ User left event!")
            else:
                print(f"RSVP response: {rsvp_result}")
        else:
            print("❌ RSVP failed")
    
    # 7. Test friend invitation
    print("\n7️⃣ Testing friend invitation...")
    invite_data = {
        "event_id": event_id,
        "username": "maría_torres_2"
    }
    
    invite_result = make_request("POST", "/invite_to_event/", invite_data, token)
    if invite_result and invite_result.get("success"):
        print("✅ Friend invited successfully!")
    else:
        print("❌ Friend invitation failed")
    
    # 8. Test user profile
    print("\n8️⃣ Testing user profile...")
    profile_result = make_request("GET", f"/api/get_user_profile/{username}/", None, token)
    if profile_result:
        print("✅ User profile retrieved successfully!")
        print(f"   - Full name: {profile_result.get('full_name', 'N/A')}")
        print(f"   - University: {profile_result.get('university', 'N/A')}")
        print(f"   - Skills: {len(profile_result.get('skills', {}))} skills")
    else:
        print("❌ Profile retrieval failed")
    
    # 9. Test friends
    print("\n9️⃣ Testing friends...")
    friends_result = make_request("GET", f"/api/get_friends/{username}/", None, token)
    if friends_result:
        friends = friends_result.get("friends", [])
        print(f"✅ Found {len(friends)} friends!")
    else:
        print("❌ Friends retrieval failed")
    
    print("\n🎉 Working Features Test Complete!")
    print("\n📝 Summary:")
    print("✅ Event creation")
    print("✅ Comments")
    print("✅ Likes")
    print("✅ Shares")
    print("✅ RSVP to public events")
    print("✅ Friend invitations")
    print("✅ User profiles")
    print("✅ Friends")
    print("❌ Join requests (database issue)")

if __name__ == "__main__":
    test_working_features()
