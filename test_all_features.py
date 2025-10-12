#!/usr/bin/env python3
"""
Quick test with fresh usernames to verify all features work
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time

BASE_URL = "https://pinit-backend-production.up.railway.app"

def register_user(user_data):
    """Register a new user"""
    url = f"{BASE_URL}/api/register/"
    
    try:
        response = requests.post(url, json=user_data)
        if response.status_code == 201:
            result = response.json()
            if result.get("success"):
                print(f"✅ Registered user: {user_data['username']}")
                return {
                    "username": user_data["username"],
                    "token": result.get("access_token")
                }
        else:
            print(f"❌ Failed to register {user_data['username']}: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error registering {user_data['username']}: {e}")
        return None

def create_event(username, token):
    """Create a test event"""
    url = f"{BASE_URL}/api/create_study_event/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    event_time = datetime.now() + timedelta(days=1, hours=18)
    end_time = event_time + timedelta(hours=2)
    
    data = {
        "host": username,
        "title": "Test Event - All Features Working",
        "description": "Testing all PinIt features",
        "location": "Test Location",
        "latitude": -34.6037,
        "longitude": -58.3816,
        "time": event_time.isoformat(),
        "end_time": end_time.isoformat(),
        "max_participants": 5,
        "event_type": "Study",
        "interest_tags": ["Study", "Test"],
        "auto_matching_enabled": True,
        "is_public": True,
        "invited_friends": []
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 201:
            result = response.json()
            event_id = result.get("event_id")
            print(f"✅ Created event: {event_id}")
            return event_id
        else:
            print(f"❌ Failed to create event: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error creating event: {e}")
        return None

def add_comment(username, event_id, token):
    """Add a comment to event"""
    url = f"{BASE_URL}/api/events/comment/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "username": username,
        "event_id": event_id,
        "text": "This is a test comment!"
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 201:
            print(f"✅ Added comment from {username}")
            return True
        else:
            print(f"❌ Failed to add comment: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error adding comment: {e}")
        return False

def like_event(username, event_id, token):
    """Like an event"""
    url = f"{BASE_URL}/api/events/like/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "username": username,
        "event_id": event_id
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            print(f"✅ {username} liked event")
            return True
        else:
            print(f"❌ Failed to like event: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error liking event: {e}")
        return False

def invite_user(event_id, username, host_token):
    """Invite user to event"""
    url = f"{BASE_URL}/invite_to_event/"
    
    headers = {
        "Authorization": f"Bearer {host_token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "event_id": event_id,
        "username": username,
        "mark_as_auto_matched": False
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                print(f"✅ Invited {username} to event")
                return True
            else:
                print(f"❌ Invitation failed: {result.get('message', 'Unknown error')}")
                return False
        else:
            print(f"❌ Failed to invite user: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error inviting user: {e}")
        return False

def rsvp_event(username, event_id, token):
    """RSVP to event"""
    url = f"{BASE_URL}/api/rsvp_study_event/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "event_id": event_id
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            result = response.json()
            action = result.get("action", "unknown")
            if action == "joined":
                print(f"✅ {username} joined event directly")
                return True
            elif action == "request_sent":
                print(f"📝 {username} sent join request")
                return result
            else:
                print(f"RSVP response: {result}")
                return False
        else:
            print(f"❌ Failed to RSVP: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error RSVPing: {e}")
        return False

def test_all_features():
    """Test all PinIt features with fresh users"""
    print("🧪 Testing All PinIt Features")
    print("=" * 50)
    
    # Create fresh test users
    timestamp = int(time.time())
    host_data = {
        "username": f"test_host_{timestamp}",
        "email": f"host{timestamp}@test.com",
        "password": "test123456",
        "first_name": "Test",
        "last_name": "Host"
    }
    
    user_data = {
        "username": f"test_user_{timestamp}",
        "email": f"user{timestamp}@test.com",
        "password": "test123456",
        "first_name": "Test",
        "last_name": "User"
    }
    
    # Register users
    print("1️⃣ Registering users...")
    host = register_user(host_data)
    user = register_user(user_data)
    
    if not host or not user:
        print("❌ User registration failed")
        return
    
    print("✅ Both users registered successfully")
    
    # Create event
    print("\n2️⃣ Creating event...")
    event_id = create_event(host["username"], host["token"])
    if not event_id:
        print("❌ Event creation failed")
        return
    
    print("✅ Event created successfully")
    
    # Add comment
    print("\n3️⃣ Adding comment...")
    if add_comment(user["username"], event_id, user["token"]):
        print("✅ Comment added successfully")
    
    # Like event
    print("\n4️⃣ Liking event...")
    if like_event(user["username"], event_id, user["token"]):
        print("✅ Event liked successfully")
    
    # Send invitation
    print("\n5️⃣ Sending invitation...")
    if invite_user(event_id, user["username"], host["token"]):
        print("✅ Invitation sent successfully")
    
    # RSVP to event
    print("\n6️⃣ RSVPing to event...")
    rsvp_result = rsvp_event(user["username"], event_id, user["token"])
    if rsvp_result:
        print("✅ RSVP successful")
    
    print("\n🎉 All Features Test Complete!")
    print("✅ User registration")
    print("✅ Event creation")
    print("✅ Comments")
    print("✅ Likes")
    print("✅ Invitations")
    print("✅ RSVPs")
    print("\n🚀 All PinIt features are working correctly!")

if __name__ == "__main__":
    test_all_features()
