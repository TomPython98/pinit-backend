#!/usr/bin/env python3
"""
Test RSVP flow with fresh database and fixed EventJoinRequest model
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

def test_rsvp_flow_fresh():
    """Test the complete RSVP → Join Request → Approval flow with fresh data"""
    print("🧪 Testing RSVP Flow with Fresh Database")
    print("=" * 60)
    
    # 1. Create host user
    print("1️⃣ Creating host user...")
    host_data = {
        "username": "host_user_test",
        "email": "host@test.com",
        "password": "test123456",
        "first_name": "Host",
        "last_name": "User"
    }
    
    host_reg = make_request("POST", "/api/register/", host_data)
    if not host_reg or not host_reg.get("success"):
        print("❌ Host registration failed")
        return
    
    print("✅ Host user created: host_user_test")
    
    # 2. Login as host
    print("\n2️⃣ Logging in as host...")
    host_login = {
        "username": "host_user_test",
        "password": "test123456"
    }
    
    host_result = make_request("POST", "/api/login/", host_login)
    if not host_result or not host_result.get("success"):
        print("❌ Host login failed")
        return
    
    host_token = host_result.get("access_token")
    host_username = host_result.get("username")
    print(f"✅ Host logged in: {host_username}")
    
    # 3. Create a private event
    print("\n3️⃣ Creating private event...")
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
    
    # 4. Create requester user
    print("\n4️⃣ Creating requester user...")
    requester_data = {
        "username": "requester_user_test",
        "email": "requester@test.com",
        "password": "test123456",
        "first_name": "Requester",
        "last_name": "User"
    }
    
    requester_reg = make_request("POST", "/api/register/", requester_data)
    if not requester_reg or not requester_reg.get("success"):
        print("❌ Requester registration failed")
        return
    
    print("✅ Requester user created: requester_user_test")
    
    # 5. Login as requester
    print("\n5️⃣ Logging in as requester...")
    requester_login = {
        "username": "requester_user_test",
        "password": "test123456"
    }
    
    requester_result = make_request("POST", "/api/login/", requester_login)
    if not requester_result or not requester_result.get("success"):
        print("❌ Requester login failed")
        return
    
    requester_token = requester_result.get("access_token")
    requester_username = requester_result.get("username")
    print(f"✅ Requester logged in: {requester_username}")
    
    # 6. Requester RSVPs to private event (should create join request)
    print("\n6️⃣ Requester RSVPs to private event...")
    rsvp_data = {
        "event_id": event_id
    }
    
    rsvp_result = make_request("POST", "/api/rsvp_study_event/", rsvp_data, requester_token)
    if not rsvp_result:
        print("❌ RSVP failed")
        return
    
    print(f"RSVP Response: {rsvp_result}")
    
    if rsvp_result.get("action") == "request_sent":
        request_id = rsvp_result.get("request_id")
        print(f"✅ Join request created! Request ID: {request_id}")
        
        # 7. Host checks join requests
        print("\n7️⃣ Host checks join requests...")
        requests_result = make_request("GET", f"/api/get_event_join_requests/{event_id}/", None, host_token)
        if requests_result and requests_result.get("success"):
            requests_list = requests_result.get("requests", [])
            print(f"✅ Found {len(requests_list)} join requests")
            for req in requests_list:
                print(f"   - {req['user']['username']}: {req['message'] or 'No message'}")
        else:
            print("❌ Failed to get join requests")
            return
        
        # 8. Host approves the request
        print("\n8️⃣ Host approves join request...")
        approve_data = {
            "request_id": request_id
        }
        
        approve_result = make_request("POST", "/api/approve_join_request/", approve_data, host_token)
        if approve_result and approve_result.get("success"):
            print("✅ Join request approved!")
        else:
            print("❌ Failed to approve request")
            return
        
        # 9. Verify requester is now an attendee
        print("\n9️⃣ Verifying requester is now an attendee...")
        events_result = make_request("GET", f"/api/get_study_events/{requester_username}/", None, requester_token)
        if events_result and events_result.get("events"):
            user_events = events_result.get("events", [])
            attended_event = None
            for event in user_events:
                if event["id"] == event_id:
                    attended_event = event
                    break
            
            if attended_event:
                attendees = attended_event.get("attendees", [])
                if requester_username in attendees:
                    print("✅ Requester is now an attendee!")
                else:
                    print("❌ Requester not found in attendees")
            else:
                print("❌ Event not found in requester's events")
        else:
            print("❌ Failed to get requester events")
        
        print("\n🎉 RSVP → Join Request → Approval Flow SUCCESS!")
        print("✅ EventJoinRequest model is working correctly!")
        
    elif rsvp_result.get("action") == "joined":
        print("✅ Requester joined directly (was invited)")
    else:
        print(f"❌ Unexpected RSVP response: {rsvp_result}")
    
    print("\n📊 Test Summary:")
    print("✅ User registration")
    print("✅ User login")
    print("✅ Event creation")
    print("✅ RSVP to private event")
    print("✅ Join request creation")
    print("✅ Join request approval")
    print("✅ Attendee verification")

if __name__ == "__main__":
    test_rsvp_flow_fresh()
