#!/usr/bin/env python3
"""
Test script to verify that hosts are automatically added to attendees when creating events.
"""

import requests
import json
from datetime import datetime, timedelta

# Test configuration
BASE_URL = "http://127.0.0.1:8000/api"
TEST_USER = "Tatalia"  # The user mentioned in the issue

def test_event_creation():
    """Test that hosts are automatically added to attendees."""
    
    # Create a test event
    event_data = {
        "host": TEST_USER,
        "title": "Test Event - Host Attendance",
        "description": "Testing that hosts are automatically added to attendees",
        "latitude": 48.2082,
        "longitude": 16.3738,
        "time": (datetime.now() + timedelta(hours=1)).isoformat(),
        "end_time": (datetime.now() + timedelta(hours=2)).isoformat(),
        "is_public": True,
        "event_type": "study",
        "invited_friends": [],
        "attendees": [],  # Empty - should be populated with host
        "max_participants": 10
    }
    
    print(f"🔍 Testing event creation for host: {TEST_USER}")
    print(f"📝 Event data: {json.dumps(event_data, indent=2)}")
    
    try:
        # Create the event
        response = requests.post(
            f"{BASE_URL}/create_study_event/",
            json=event_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"📡 Response status: {response.status_code}")
        print(f"📦 Response: {response.text}")
        
        if response.status_code == 201:
            result = response.json()
            event_id = result.get("event_id")
            print(f"✅ Event created successfully with ID: {event_id}")
            
            # Now fetch the event to check if host is in attendees
            fetch_response = requests.get(f"{BASE_URL}/get_study_events/{TEST_USER}/")
            
            if fetch_response.status_code == 200:
                events_data = fetch_response.json()
                events = events_data.get("events", [])
                
                # Find our test event
                test_event = None
                for event in events:
                    if event.get("title") == "Test Event - Host Attendance":
                        test_event = event
                        break
                
                if test_event:
                    attendees = test_event.get("attendees", [])
                    host = test_event.get("host")
                    
                    print(f"🎯 Found test event:")
                    print(f"   Host: {host}")
                    print(f"   Attendees: {attendees}")
                    
                    if TEST_USER in attendees:
                        print("✅ SUCCESS: Host is automatically added to attendees!")
                        return True
                    else:
                        print("❌ FAILURE: Host is NOT in attendees list")
                        return False
                else:
                    print("❌ FAILURE: Could not find test event in fetched events")
                    return False
            else:
                print(f"❌ FAILURE: Could not fetch events: {fetch_response.status_code}")
                return False
        else:
            print(f"❌ FAILURE: Could not create event: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        return False

if __name__ == "__main__":
    print("🧪 Testing host attendance functionality...")
    success = test_event_creation()
    
    if success:
        print("\n🎉 All tests passed! Hosts are now automatically added to attendees.")
    else:
        print("\n💥 Tests failed! There's still an issue with host attendance.") 