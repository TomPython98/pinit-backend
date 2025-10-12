#!/usr/bin/env python3
"""
Test to create a new join request and check if it appears in host's pending requests
"""

import requests
import json
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

def test_pending_requests():
    """Test pending join requests"""
    print("🔍 Testing Pending Join Requests")
    print("=" * 50)
    
    # 1. Login as host
    print("1️⃣ Logging in as host...")
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
    
    # 2. Create a new private event
    print("\n2️⃣ Creating new private event...")
    event_time = datetime.now() + timedelta(days=2, hours=18)
    end_time = event_time + timedelta(hours=2)
    
    event_data = {
        "title": "New Private Event - Pending Test",
        "description": "Testing pending join requests",
        "latitude": -34.6037,
        "longitude": -58.3816,
        "time": event_time.isoformat(),
        "end_time": end_time.isoformat(),
        "max_participants": 3,
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
    print(f"✅ New private event created: {event_id}")
    
    # 3. Create a new requester user
    print("\n3️⃣ Creating new requester user...")
    requester_data = {
        "username": "pending_requester_test_2",
        "email": "pending2@test.com",
        "password": "test123456",
        "first_name": "Pending",
        "last_name": "Requester"
    }
    
    requester_reg = make_request("POST", "/api/register/", requester_data)
    if not requester_reg or not requester_reg.get("success"):
        print("❌ Requester registration failed")
        return
    
    print("✅ New requester user created: pending_requester_test_2")
    
    # 4. Login as requester
    print("\n4️⃣ Logging in as requester...")
    requester_login = {
        "username": "pending_requester_test_2",
        "password": "test123456"
    }
    
    requester_result = make_request("POST", "/api/login/", requester_login)
    if not requester_result or not requester_result.get("success"):
        print("❌ Requester login failed")
        return
    
    requester_token = requester_result.get("access_token")
    requester_username = requester_result.get("username")
    print(f"✅ Requester logged in: {requester_username}")
    
    # 5. Requester RSVPs (creates pending join request)
    print("\n5️⃣ Requester RSVPs to create pending join request...")
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
        print(f"✅ Pending join request created! Request ID: {request_id}")
        
        # 6. Host checks for pending requests
        print("\n6️⃣ Host checks for pending join requests...")
        requests_result = make_request("GET", f"/api/get_event_join_requests/{event_id}/", None, host_token)
        if requests_result and requests_result.get("success"):
            requests_list = requests_result.get("requests", [])
            print(f"✅ Found {len(requests_list)} pending join requests")
            
            for req in requests_list:
                print(f"   - User: {req['user']['username']}")
                print(f"     Status: {req.get('status', 'unknown')}")
                print(f"     Created: {req.get('created_at', 'unknown')}")
                print(f"     Message: {req.get('message', 'No message')}")
                print(f"     Request ID: {req.get('id', 'unknown')}")
                print(f"     Full request data: {req}")
                
                # 7. Host approves the request
                print(f"\n7️⃣ Host approves request {req['id']}...")
                approve_data = {
                    "request_id": req['id']
                }
                
                approve_result = make_request("POST", "/api/approve_join_request/", approve_data, host_token)
                if approve_result and approve_result.get("success"):
                    print("✅ Join request approved!")
                else:
                    print("❌ Failed to approve request")
                
                # 8. Check if request is still in pending list
                print("\n8️⃣ Checking if request is still in pending list...")
                requests_result_after = make_request("GET", f"/api/get_event_join_requests/{event_id}/", None, host_token)
                if requests_result_after and requests_result_after.get("success"):
                    requests_after = requests_result_after.get("requests", [])
                    print(f"✅ Found {len(requests_after)} requests after approval")
                    if len(requests_after) == 0:
                        print("✅ Approved requests are removed from pending list (expected behavior)")
                    else:
                        print("❌ Approved requests still showing in pending list")
        else:
            print("❌ Failed to get pending join requests")
    else:
        print(f"❌ Unexpected RSVP response: {rsvp_result}")

if __name__ == "__main__":
    test_pending_requests()
