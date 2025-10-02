#!/usr/bin/env python3
"""
Delete duplicate events at identical locations from the production database
Keeps only one event per location (the first one found)
"""

import requests
import json
from collections import defaultdict

PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

def get_events_for_user(username):
    """Get events for a specific user from the production server"""
    url = f"{PRODUCTION_BASE_URL}get_study_events/{username}/"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            data = response.json()
            
            # Handle different response formats
            if isinstance(data, dict) and 'events' in data:
                return data['events']
            elif isinstance(data, list):
                return data
            else:
                print(f"⚠️ Unexpected response format: {type(data)}")
                return []
        else:
            print(f"❌ Failed to fetch events for {username}: {response.status_code} - {response.text}")
            return []
    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        return []

def delete_event(event_id):
    """Delete an event by ID"""
    url = f"{PRODUCTION_BASE_URL}delete_study_event/"
    payload = {"event_id": event_id}
    
    try:
        response = requests.post(url, json=payload)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                return True
            else:
                print(f"❌ Delete failed: {result.get('message', 'Unknown error')}")
                return False
        else:
            print(f"❌ Delete request failed: {response.status_code} - {response.text}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        return False

def find_and_delete_duplicates():
    """Find events at identical locations and delete duplicates"""
    print("🔍 Finding events with identical coordinates...")
    
    # Use ana_cruz_567 as test user (we know they have events)
    test_user = "ana_cruz_567"
    events = get_events_for_user(test_user)
    if not events:
        print(f"❌ No events found for user {test_user}")
        return
    
    print(f"📊 Total events: {len(events)}")
    
    # Group events by coordinates
    location_groups = defaultdict(list)
    
    for event in events:
        lat = event.get('latitude')
        lng = event.get('longitude')
        title = event.get('title', 'Unknown')
        event_id = event.get('id', 'Unknown')
        
        if lat is not None and lng is not None:
            # Round to 6 decimal places (about 0.1m precision)
            coord_key = (round(float(lat), 6), round(float(lng), 6))
            location_groups[coord_key].append({
                'id': event_id,
                'title': title,
                'lat': lat,
                'lng': lng
            })
    
    # Find duplicates
    duplicates = {coord: events for coord, events in location_groups.items() if len(events) > 1}
    
    if not duplicates:
        print("\n✅ No duplicate locations found!")
        print("   All events have unique coordinates.")
        return
    
    print(f"\n🎯 Found {len(duplicates)} locations with multiple events:")
    print("=" * 80)
    
    total_deleted = 0
    total_kept = 0
    
    for coord, events_list in duplicates.items():
        lat, lng = coord
        count = len(events_list)
        
        print(f"\n📍 Location: ({lat}, {lng}) - {count} events")
        print("-" * 50)
        
        # Keep the first event, delete the rest
        keep_event = events_list[0]
        delete_events = events_list[1:]
        
        print(f"  ✅ KEEPING: {keep_event['title']} (ID: {keep_event['id']})")
        total_kept += 1
        
        for i, event in enumerate(delete_events, 1):
            print(f"  🗑️ DELETING {i}: {event['title']} (ID: {event['id']})")
            
            # Delete the event
            if delete_event(event['id']):
                print(f"     ✅ Successfully deleted")
                total_deleted += 1
            else:
                print(f"     ❌ Failed to delete")
    
    print(f"\n📈 Summary:")
    print(f"  • Locations processed: {len(duplicates)}")
    print(f"  • Events kept: {total_kept}")
    print(f"  • Events deleted: {total_deleted}")
    print(f"  • Total events remaining: {len(events) - total_deleted}")
    
    if total_deleted > 0:
        print(f"\n🎉 Successfully cleaned up duplicate events!")
        print(f"   The map should now show individual events instead of clusters.")
    else:
        print(f"\n⚠️ No events were deleted. Check the delete endpoint.")

def verify_cleanup():
    """Verify that duplicates have been removed"""
    print("\n🔍 Verifying cleanup...")
    
    test_user = "ana_cruz_567"
    events = get_events_for_user(test_user)
    if not events:
        print(f"❌ No events found for user {test_user}")
        return
    
    print(f"📊 Remaining events: {len(events)}")
    
    # Check for remaining duplicates
    location_groups = defaultdict(list)
    
    for event in events:
        lat = event.get('latitude')
        lng = event.get('longitude')
        title = event.get('title', 'Unknown')
        event_id = event.get('id', 'Unknown')
        
        if lat is not None and lng is not None:
            coord_key = (round(float(lat), 6), round(float(lng), 6))
            location_groups[coord_key].append({
                'id': event_id,
                'title': title,
                'lat': lat,
                'lng': lng
            })
    
    remaining_duplicates = {coord: events for coord, events in location_groups.items() if len(events) > 1}
    
    if remaining_duplicates:
        print(f"⚠️ Still found {len(remaining_duplicates)} locations with duplicates:")
        for coord, events_list in remaining_duplicates.items():
            lat, lng = coord
            print(f"  📍 ({lat}, {lng}): {len(events_list)} events")
    else:
        print("✅ No duplicate locations remaining!")
        print("   All events now have unique coordinates.")

if __name__ == "__main__":
    find_and_delete_duplicates()
    verify_cleanup()

