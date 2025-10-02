#!/usr/bin/env python3
"""
Fix duplicate coordinates by adding small random offsets to make events slightly different
This will prevent clustering while keeping all events
"""

import requests
import json
import random
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

def update_event_location(event_id, new_lat, new_lng):
    """Update an event's location coordinates"""
    url = f"{PRODUCTION_BASE_URL}update_event_location/"
    payload = {
        "event_id": event_id,
        "latitude": new_lat,
        "longitude": new_lng
    }
    
    try:
        response = requests.post(url, json=payload)
        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                return True
            else:
                print(f"❌ Update failed: {result.get('message', 'Unknown error')}")
                return False
        else:
            print(f"❌ Update request failed: {response.status_code} - {response.text}")
            return False
    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        return False

def add_random_offset(lat, lng, max_offset_meters=50):
    """Add a small random offset to coordinates (max 50 meters)"""
    # Convert meters to degrees (rough approximation)
    # 1 degree ≈ 111,000 meters
    max_offset_degrees = max_offset_meters / 111000.0
    
    # Add random offset
    lat_offset = random.uniform(-max_offset_degrees, max_offset_degrees)
    lng_offset = random.uniform(-max_offset_degrees, max_offset_degrees)
    
    new_lat = lat + lat_offset
    new_lng = lng + lng_offset
    
    return new_lat, new_lng

def fix_duplicate_coordinates():
    """Fix duplicate coordinates by adding small random offsets"""
    print("🔧 Fixing duplicate coordinates by adding small random offsets...")
    
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
    
    total_updated = 0
    total_kept = 0
    
    for coord, events_list in duplicates.items():
        lat, lng = coord
        count = len(events_list)
        
        print(f"\n📍 Location: ({lat}, {lng}) - {count} events")
        print("-" * 50)
        
        # Keep the first event as-is, update the rest with small offsets
        keep_event = events_list[0]
        update_events = events_list[1:]
        
        print(f"  ✅ KEEPING: {keep_event['title']} (ID: {keep_event['id']})")
        total_kept += 1
        
        for i, event in enumerate(update_events, 1):
            # Add small random offset (10-50 meters)
            offset_meters = random.randint(10, 50)
            new_lat, new_lng = add_random_offset(event['lat'], event['lng'], offset_meters)
            
            print(f"  🔧 UPDATING {i}: {event['title']} (ID: {event['id']})")
            print(f"     Old: ({event['lat']:.6f}, {event['lng']:.6f})")
            print(f"     New: ({new_lat:.6f}, {new_lng:.6f}) - Offset: ~{offset_meters}m")
            
            # Update the event location
            if update_event_location(event['id'], new_lat, new_lng):
                print(f"     ✅ Successfully updated")
                total_updated += 1
            else:
                print(f"     ❌ Failed to update")
    
    print(f"\n📈 Summary:")
    print(f"  • Locations processed: {len(duplicates)}")
    print(f"  • Events kept unchanged: {total_kept}")
    print(f"  • Events updated: {total_updated}")
    
    if total_updated > 0:
        print(f"\n🎉 Successfully fixed duplicate coordinates!")
        print(f"   Events now have unique locations and should not cluster.")
    else:
        print(f"\n⚠️ No events were updated. The update endpoint might not exist.")
        print(f"   Alternative: We can regenerate the data with better coordinate distribution.")

def verify_fix():
    """Verify that duplicates have been fixed"""
    print("\n🔍 Verifying fix...")
    
    test_user = "ana_cruz_567"
    events = get_events_for_user(test_user)
    if not events:
        print(f"❌ No events found for user {test_user}")
        return
    
    print(f"📊 Total events: {len(events)}")
    
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
    fix_duplicate_coordinates()
    verify_fix()

