#!/usr/bin/env python3
"""
Test to check if host can see join requests in database/API
"""

import requests
import json

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

def check_host_requests():
    """Check if host can see join requests"""
    print("🔍 Checking Host Join Requests")
    print("=" * 40)
    
    # Login as host
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
    
    # Get host's events
    print("\n2️⃣ Getting host's events...")
    events_result = make_request("GET", f"/api/get_study_events/{host_username}/", None, host_token)
    if not events_result or not events_result.get("events"):
        print("❌ No events found for host")
        return
    
    events = events_result.get("events", [])
    print(f"✅ Found {len(events)} events for host")
    
    # Check join requests for each event
    for event in events:
        event_id = event["id"]
        event_title = event["title"]
        print(f"\n3️⃣ Checking join requests for event: {event_title}")
        print(f"   Event ID: {event_id}")
        
        # Get join requests for this event
        requests_result = make_request("GET", f"/api/get_event_join_requests/{event_id}/", None, host_token)
        if requests_result and requests_result.get("success"):
            requests_list = requests_result.get("requests", [])
            print(f"   ✅ Found {len(requests_list)} join requests")
            
            for req in requests_list:
                print(f"      - User: {req['user']['username']}")
                print(f"        Status: {req['status']}")
                print(f"        Created: {req['created_at']}")
                print(f"        Message: {req['message'] or 'No message'}")
                if req.get('processed_at'):
                    print(f"        Processed: {req['processed_at']}")
                print(f"        Request ID: {req['id']}")
        else:
            print(f"   ❌ Failed to get join requests: {requests_result}")
    
    # Also check if there's a general endpoint for user's join requests
    print("\n4️⃣ Checking user's join requests...")
    user_requests_result = make_request("GET", f"/api/get_user_join_requests/{host_username}/", None, host_token)
    if user_requests_result:
        if user_requests_result.get("success"):
            user_requests = user_requests_result.get("requests", [])
            print(f"✅ Found {len(user_requests)} join requests for user")
            for req in user_requests:
                print(f"   - Event: {req['event']['title']}")
                print(f"     Status: {req['status']}")
                print(f"     Created: {req['created_at']}")
        else:
            print(f"❌ Failed to get user join requests: {user_requests_result}")
    else:
        print("❌ No response from user join requests endpoint")

if __name__ == "__main__":
    check_host_requests()
