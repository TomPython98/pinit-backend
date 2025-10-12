#!/usr/bin/env python3
"""
Test script to verify the RSVP → Join Request → Approval flow
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

def test_rsvp_flow():
    """Test the complete RSVP → Join Request → Approval flow"""
    print("🧪 Testing RSVP → Join Request → Approval Flow")
    print("=" * 60)
    
    # 1. Login as host
    print("1️⃣ Logging in as host...")
    host_login = {
        "username": "bárbara_álvarez_1",
        "password": "test123456"
    }
    
    host_result = make_request("POST", "/api/login/", host_login)
    if not host_result or not host_result.get("success"):
        print("❌ Host login failed")
        return
    
    host_token = host_result.get("access_token")
    host_username = host_result.get("username")
    print(f"✅ Host logged in: {host_username}")
    
    # 2. Create a private event (so RSVP creates join requests)
    print("\n2️⃣ Creating private event...")
    event_time = datetime.now() + timedelta(days=1, hours=18)
    end_time = event_time + timedelta(hours=2)
    
    event_data = {
        "title": "Private Study Session - RSVP Test",
        "description": "Testing RSVP flow with join requests",
        "latitude": -34.6037,
        "longitude": -58.3816,
        "time": event_time.isoformat(),
        "end_time": end_time.isoformat(),
        "max_participants": 5,
        "event_type": "study",
        "interest_tags": ["study", "academic"],
        "is_public": False,  # Private event
        "enable_auto_matching": False,
        "selected_friends": []
    }
    
    event_result = make_request("POST", "/api/create_study_event/", event_data, host_token)
    if not event_result or not event_result.get("success"):
        print("❌ Event creation failed")
        return
    
    event_id = event_result.get("event_id")
    print(f"✅ Private event created: {event_id}")
    
    # 3. Login as different user (not invited)
    print("\n3️⃣ Logging in as non-invited user...")
    user_login = {
        "username": "maría_torres_2",
        "password": "test123456"
    }
    
    user_result = make_request("POST", "/api/login/", user_login)
    if not user_result or not user_result.get("success"):
        print("❌ User login failed")
        return
    
    user_token = user_result.get("access_token")
    user_username = user_result.get("username")
    print(f"✅ User logged in: {user_username}")
    
    # 4. User RSVPs to private event (should create join request)
    print("\n4️⃣ User RSVPs to private event...")
    rsvp_data = {
        "event_id": event_id
    }
    
    rsvp_result = make_request("POST", "/api/rsvp_study_event/", rsvp_data, user_token)
    if not rsvp_result:
        print("❌ RSVP failed")
        return
    
    print(f"RSVP Response: {rsvp_result}")
    
    if rsvp_result.get("action") == "request_sent":
        request_id = rsvp_result.get("request_id")
        print(f"✅ Join request created! Request ID: {request_id}")
        
        # 5. Host checks join requests
        print("\n5️⃣ Host checks join requests...")
        requests_result = make_request("GET", f"/api/get_event_join_requests/{event_id}/", None, host_token)
        if requests_result and requests_result.get("success"):
            requests_list = requests_result.get("requests", [])
            print(f"✅ Found {len(requests_list)} join requests")
            for req in requests_list:
                print(f"   - {req['user']['username']}: {req['message'] or 'No message'}")
        else:
            print("❌ Failed to get join requests")
            return
        
        # 6. Host approves the request
        print("\n6️⃣ Host approves join request...")
        approve_data = {
            "request_id": request_id
        }
        
        approve_result = make_request("POST", "/api/approve_join_request/", approve_data, host_token)
        if approve_result and approve_result.get("success"):
            print("✅ Join request approved!")
        else:
            print("❌ Failed to approve request")
            return
        
        # 7. Verify user is now an attendee
        print("\n7️⃣ Verifying user is now an attendee...")
        events_result = make_request("GET", f"/api/get_study_events/{user_username}/", None, user_token)
        if events_result and events_result.get("events"):
            user_events = events_result.get("events", [])
            attended_event = None
            for event in user_events:
                if event["id"] == event_id:
                    attended_event = event
                    break
            
            if attended_event:
                attendees = attended_event.get("attendees", [])
                if user_username in attendees:
                    print("✅ User is now an attendee!")
                else:
                    print("❌ User not found in attendees")
            else:
                print("❌ Event not found in user's events")
        else:
            print("❌ Failed to get user events")
    
    elif rsvp_result.get("action") == "joined":
        print("✅ User joined directly (was invited)")
    else:
        print(f"❌ Unexpected RSVP response: {rsvp_result}")
    
    print("\n🎉 RSVP Flow Test Complete!")

if __name__ == "__main__":
    test_rsvp_flow()
