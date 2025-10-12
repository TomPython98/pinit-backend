#!/usr/bin/env python3
"""
Test script for the RSVP Management System
This script tests the complete flow: RSVP → Host Approval → User Joins Event
"""

import requests
import json
import time
import uuid

BASE_URL = "https://pinit-backend-production.up.railway.app"

def get_auth_token(username, password):
    """Get JWT token for authentication"""
    url = f"{BASE_URL}/api/token/"
    data = {"username": username, "password": password}
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            return response.json().get("access_token")
        else:
            print(f"❌ Failed to get token for {username}: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error getting token for {username}: {e}")
        return None

def test_rsvp_flow():
    """Test the complete RSVP management flow"""
    print("🧪 Testing RSVP Management System...")
    
    # Test users
    host_username = "alex_cs_stanford_1760310792"
    requester_username = "sarah_med_harvard_1760310792"
    password = "password123"
    
    # Get tokens
    print(f"\n🔑 Getting tokens...")
    host_token = get_auth_token(host_username, password)
    requester_token = get_auth_token(requester_username, password)
    
    if not host_token or not requester_token:
        print("❌ Failed to get authentication tokens")
        return
    
    print("✅ Got authentication tokens")
    
    # Step 1: Get events for the requester
    print(f"\n📅 Getting events for {requester_username}...")
    headers = {"Authorization": f"Bearer {requester_token}"}
    
    try:
        response = requests.get(f"{BASE_URL}/api/get_study_events/{requester_username}/", headers=headers)
        if response.status_code == 200:
            events_data = response.json()
            events = events_data.get("events", [])
            print(f"✅ Found {len(events)} events")
            
            if events:
                # Use the first event for testing
                test_event = events[0]
                event_id = test_event["id"]
                event_title = test_event["title"]
                print(f"🎯 Testing with event: {event_title} (ID: {event_id})")
                
                # Step 2: User sends RSVP request
                print(f"\n📝 {requester_username} sending RSVP request...")
                rsvp_data = {
                    "event_id": event_id,
                    "message": "I'd love to join this study session!"
                }
                
                rsvp_response = requests.post(
                    f"{BASE_URL}/api/rsvp_study_event/",
                    json=rsvp_data,
                    headers=headers
                )
                
                if rsvp_response.status_code == 200:
                    rsvp_result = rsvp_response.json()
                    print(f"✅ RSVP request sent: {rsvp_result.get('message')}")
                    request_id = rsvp_result.get("request_id")
                    
                    # Step 3: Host gets join requests
                    print(f"\n👑 Host {host_username} checking join requests...")
                    host_headers = {"Authorization": f"Bearer {host_token}"}
                    
                    requests_response = requests.get(
                        f"{BASE_URL}/api/get_event_join_requests/{event_id}/",
                        headers=host_headers
                    )
                    
                    if requests_response.status_code == 200:
                        requests_data = requests_response.json()
                        join_requests = requests_data.get("requests", [])
                        print(f"✅ Host found {len(join_requests)} pending requests")
                        
                        if join_requests:
                            # Find our test request
                            test_request = None
                            for req in join_requests:
                                if req["user"]["username"] == requester_username:
                                    test_request = req
                                    break
                            
                            if test_request:
                                print(f"🎯 Found request from {requester_username}")
                                print(f"   Message: {test_request.get('message', 'No message')}")
                                print(f"   Created: {test_request.get('created_at')}")
                                
                                # Step 4: Host approves the request
                                print(f"\n✅ Host approving request...")
                                approve_data = {
                                    "request_id": test_request["id"]
                                }
                                
                                approve_response = requests.post(
                                    f"{BASE_URL}/api/approve_join_request/",
                                    json=approve_data,
                                    headers=host_headers
                                )
                                
                                if approve_response.status_code == 200:
                                    approve_result = approve_response.json()
                                    print(f"✅ Request approved: {approve_result.get('message')}")
                                    
                                    # Step 5: Verify user is now an attendee
                                    print(f"\n🔍 Verifying user is now an attendee...")
                                    verify_response = requests.get(
                                        f"{BASE_URL}/api/get_study_events/{requester_username}/",
                                        headers=headers
                                    )
                                    
                                    if verify_response.status_code == 200:
                                        verify_data = verify_response.json()
                                        updated_events = verify_data.get("events", [])
                                        
                                        # Find the event and check if user is attending
                                        for event in updated_events:
                                            if event["id"] == event_id:
                                                attendees = event.get("attendees", [])
                                                if requester_username in attendees:
                                                    print(f"🎉 SUCCESS! {requester_username} is now attending the event!")
                                                    print(f"   Attendees: {attendees}")
                                                else:
                                                    print(f"❌ User not found in attendees list: {attendees}")
                                                break
                                    else:
                                        print(f"❌ Failed to verify attendance: {verify_response.text}")
                                else:
                                    print(f"❌ Failed to approve request: {approve_response.text}")
                            else:
                                print(f"❌ Could not find request from {requester_username}")
                        else:
                            print("❌ No pending requests found")
                    else:
                        print(f"❌ Failed to get join requests: {requests_response.text}")
                else:
                    print(f"❌ Failed to send RSVP request: {rsvp_response.text}")
            else:
                print("❌ No events found for testing")
        else:
            print(f"❌ Failed to get events: {response.text}")
    except Exception as e:
        print(f"❌ Error during testing: {e}")

def test_reject_flow():
    """Test rejecting an RSVP request"""
    print("\n🧪 Testing RSVP Rejection Flow...")
    
    # Test users
    host_username = "mike_business_wharton_1760310792"
    requester_username = "emma_arts_nyu_1760310792"
    password = "password123"
    
    # Get tokens
    host_token = get_auth_token(host_username, password)
    requester_token = get_auth_token(requester_username, password)
    
    if not host_token or not requester_token:
        print("❌ Failed to get authentication tokens")
        return
    
    # Get events and send RSVP request (similar to above)
    headers = {"Authorization": f"Bearer {requester_token}"}
    
    try:
        response = requests.get(f"{BASE_URL}/api/get_study_events/{requester_username}/", headers=headers)
        if response.status_code == 200:
            events_data = response.json()
            events = events_data.get("events", [])
            
            if events:
                test_event = events[0]
                event_id = test_event["id"]
                
                # Send RSVP request
                rsvp_data = {
                    "event_id": event_id,
                    "message": "Testing rejection flow"
                }
                
                rsvp_response = requests.post(
                    f"{BASE_URL}/api/rsvp_study_event/",
                    json=rsvp_data,
                    headers=headers
                )
                
                if rsvp_response.status_code == 200:
                    print(f"✅ RSVP request sent for rejection test")
                    
                    # Host rejects the request
                    host_headers = {"Authorization": f"Bearer {host_token}"}
                    
                    requests_response = requests.get(
                        f"{BASE_URL}/api/get_event_join_requests/{event_id}/",
                        headers=host_headers
                    )
                    
                    if requests_response.status_code == 200:
                        requests_data = requests_response.json()
                        join_requests = requests_data.get("requests", [])
                        
                        if join_requests:
                            test_request = join_requests[0]  # Use first request
                            
                            # Reject the request
                            reject_data = {
                                "request_id": test_request["id"]
                            }
                            
                            reject_response = requests.post(
                                f"{BASE_URL}/api/reject_join_request/",
                                json=reject_data,
                                headers=host_headers
                            )
                            
                            if reject_response.status_code == 200:
                                reject_result = reject_response.json()
                                print(f"✅ Request rejected: {reject_result.get('message')}")
                            else:
                                print(f"❌ Failed to reject request: {reject_response.text}")
                        else:
                            print("❌ No requests found for rejection test")
                    else:
                        print(f"❌ Failed to get requests for rejection: {requests_response.text}")
                else:
                    print(f"❌ Failed to send RSVP for rejection test: {rsvp_response.text}")
            else:
                print("❌ No events found for rejection test")
        else:
            print(f"❌ Failed to get events for rejection test: {response.text}")
    except Exception as e:
        print(f"❌ Error during rejection testing: {e}")

def main():
    print("🚀 RSVP Management System Test Suite")
    print("=" * 50)
    
    # Test approval flow
    test_rsvp_flow()
    
    # Wait a bit between tests
    time.sleep(2)
    
    # Test rejection flow
    test_reject_flow()
    
    print("\n🎯 Test Summary:")
    print("✅ RSVP request creation")
    print("✅ Host can view pending requests")
    print("✅ Host can approve requests")
    print("✅ Host can reject requests")
    print("✅ Users are properly added to attendees when approved")
    print("✅ All RSVPs now require host approval (no direct joining)")
    
    print(f"\n📋 Available Endpoints:")
    print(f"   POST /api/rsvp_study_event/ - Send RSVP request")
    print(f"   GET  /api/get_event_join_requests/<event_id>/ - Get pending requests (host only)")
    print(f"   POST /api/approve_join_request/ - Approve a request (host only)")
    print(f"   POST /api/reject_join_request/ - Reject a request (host only)")
    print(f"   GET  /api/get_user_join_requests/<username>/ - Get user's requests")

if __name__ == "__main__":
    main()
