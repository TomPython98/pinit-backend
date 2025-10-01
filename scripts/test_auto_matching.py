#!/usr/bin/env python3
"""
Test auto-matching functionality on production server
"""

import requests
import json
import time

PRODUCTION_URL = "https://pinit-backend-production.up.railway.app/api"

def test_auto_matching():
    """Test auto-matching for a few events"""
    print("🧪 Testing Auto-Matching on Production Server")
    print("=" * 50)
    
    # Get a few events to test with
    print("📋 Getting events to test...")
    
    # Test with testuser
    events_response = requests.get(f"{PRODUCTION_URL}/get_study_events/testuser/")
    if events_response.status_code == 200:
        events_data = events_response.json()
        events = events_data.get('events', [])
        
        # Find events with auto-matching enabled
        auto_match_events = [e for e in events if e.get('auto_matching_enabled')]
        
        print(f"✅ Found {len(auto_match_events)} events with auto-matching enabled")
        
        if auto_match_events:
            # Test with the first few events
            test_events = auto_match_events[:3]
            
            for i, event in enumerate(test_events):
                event_id = event.get('id')
                title = event.get('title', 'Unknown')
                
                print(f"\n🔄 Testing event {i+1}/3: {title}")
                print(f"   Event ID: {event_id}")
                
                # Test auto-matching
                payload = {"event_id": event_id}
                response = requests.post(
                    f"{PRODUCTION_URL}/advanced_auto_match/",
                    headers={'Content-Type': 'application/json'},
                    data=json.dumps(payload),
                    timeout=30
                )
                
                print(f"   Status: {response.status_code}")
                if response.status_code == 200:
                    result = response.json()
                    print(f"   ✅ Success: {result}")
                else:
                    print(f"   ❌ Error: {response.text}")
                
                time.sleep(2)  # Wait between requests
        else:
            print("❌ No events with auto-matching enabled found")
    else:
        print(f"❌ Failed to get events: {events_response.status_code}")

if __name__ == "__main__":
    test_auto_matching()
