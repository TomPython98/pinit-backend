#!/usr/bin/env python3

import requests
import json

PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

def debug_ana_cruz_events():
    """Debug what events ana_cruz sees and categorize them"""
    print("🔍 Debugging ana_cruz events...")
    
    # Get events for ana_cruz
    url = f"{PRODUCTION_BASE_URL}get_study_events/ana_cruz/"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        
        events = data.get('events', [])
        print(f"📊 Total events returned: {len(events)}")
        
        # Categorize events
        hosting_events = []
        attending_events = []
        invited_events = []
        auto_matched_events = []
        
        for event in events:
            title = event.get('title', 'Unknown')
            host = event.get('host', 'Unknown')
            attendees = event.get('attendees', [])
            invited_friends = event.get('invitedFriends', [])
            is_auto_matched = event.get('isAutoMatched', False)
            
            # Check categories
            is_hosting = host == 'ana_cruz'
            is_attending = 'ana_cruz' in attendees
            is_invited = 'ana_cruz' in invited_friends
            
            if is_hosting:
                hosting_events.append(title)
            if is_attending:
                attending_events.append(title)
            if is_invited:
                invited_events.append(title)
            if is_auto_matched:
                auto_matched_events.append(title)
        
        print(f"\n📋 Event Categories:")
        print(f"🏠 Hosting: {len(hosting_events)} events")
        for event in hosting_events:
            print(f"   - {event}")
        
        print(f"\n👤 Attending: {len(attending_events)} events")
        for event in attending_events:
            print(f"   - {event}")
        
        print(f"\n📩 Invited: {len(invited_events)} events")
        for event in invited_events:
            print(f"   - {event}")
        
        print(f"\n🎯 Auto-Matched: {len(auto_matched_events)} events")
        for event in auto_matched_events:
            print(f"   - {event}")
        
        # Calculate "My Events" (hosting + attending)
        my_events = len(hosting_events) + len(attending_events)
        print(f"\n✅ 'My Events' should be: {my_events} (hosting: {len(hosting_events)} + attending: {len(attending_events)})")
        
        # Show some sample events with full details
        print(f"\n🔍 Sample Event Details:")
        for i, event in enumerate(events[:3]):  # Show first 3 events
            print(f"\nEvent {i+1}: {event.get('title', 'Unknown')}")
            print(f"  Host: {event.get('host', 'Unknown')}")
            print(f"  Attendees: {event.get('attendees', [])}")
            print(f"  Invited: {event.get('invitedFriends', [])}")
            print(f"  Auto-Matched: {event.get('isAutoMatched', False)}")
            print(f"  Event Type: {event.get('event_type', 'Unknown')}")
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Error: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    debug_ana_cruz_events()

