#!/usr/bin/env python3
"""
Run auto-matching for existing events on production server
"""

import requests
import json
import time

# Production server URL
PRODUCTION_URL = "https://pinit-backend-production.up.railway.app/api"

def make_api_call(endpoint, method='GET', data=None):
    """Make API call to production server with error handling"""
    url = f"{PRODUCTION_URL}/{endpoint}"
    headers = {'Content-Type': 'application/json'}
    
    try:
        if method == 'GET':
            response = requests.get(url, headers=headers, timeout=30)
        elif method == 'POST':
            response = requests.post(url, headers=headers, json=data, timeout=30)
        
        if response.status_code in [200, 201]:
            return response.json() if response.content else {}
        else:
            print(f"❌ API Error {response.status_code}: {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        return None

def get_all_events():
    """Get all events from the server"""
    print("📋 Fetching all events...")
    
    # Get all users first to get their events
    users_result = make_api_call("get_all_users/")
    if not users_result or not isinstance(users_result, list):
        print("❌ Failed to get users")
        return []
    
    all_events = []
    users = users_result  # users_result is already a list of usernames
    
    for username in users:
        if username:
            events_result = make_api_call(f"get_study_events/{username}/")
            if events_result and events_result.get('events'):
                events = events_result.get('events', [])
                all_events.extend(events)
                print(f"✅ Fetched {len(events)} events for user {username}")
            time.sleep(0.1)
    
    print(f"📊 Total events found: {len(all_events)}")
    return all_events

def run_auto_matching_for_events(events):
    """Run auto-matching for events that have it enabled"""
    print("🤖 Running auto-matching for events...")
    
    matched_count = 0
    auto_match_events = [event for event in events if event.get('auto_matching_enabled')]
    
    print(f"🎯 Found {len(auto_match_events)} events with auto-matching enabled")
    
    for i, event in enumerate(auto_match_events):
        event_id = event.get('id')
        if event_id:
            print(f"🔄 Auto-matching event {i+1}/{len(auto_match_events)}: {event.get('title', 'Unknown')}")
            
            result = make_api_call("advanced_auto_match/", 'POST', {"event_id": event_id})
            if result and result.get('success'):
                matched_count += 1
                print(f"✅ Auto-matched event: {event.get('title', 'Unknown')}")
            else:
                print(f"❌ Failed to auto-match event: {event.get('title', 'Unknown')}")
            
            time.sleep(0.3)  # Longer delay to avoid overwhelming server
    
    print(f"🎉 Auto-matching completed! {matched_count}/{len(auto_match_events)} events matched")

def main():
    """Main function"""
    print("🚀 Starting Auto-Matching on Production Server")
    print("=" * 60)
    
    # Get all events
    events = get_all_events()
    
    if not events:
        print("❌ No events found. Please create some events first.")
        return
    
    # Run auto-matching
    run_auto_matching_for_events(events)
    
    print("=" * 60)
    print("✅ Auto-matching process completed!")

if __name__ == "__main__":
    main()
