#!/usr/bin/env python3
"""
Check for events with identical coordinates in the production database
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
            print(f"🔍 Debug: Response type: {type(data)}")
            print(f"🔍 Debug: Response content: {data}")
            
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

def check_duplicate_locations():
    """Check for events with identical coordinates"""
    print("🔍 Checking for events with identical coordinates...")
    
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
    
    if duplicates:
        print(f"\n🎯 Found {len(duplicates)} locations with multiple events:")
        print("=" * 80)
        
        total_duplicate_events = 0
        for coord, events_list in duplicates.items():
            lat, lng = coord
            count = len(events_list)
            total_duplicate_events += count
            
            print(f"\n📍 Location: ({lat}, {lng}) - {count} events")
            print("-" * 50)
            
            for i, event in enumerate(events_list, 1):
                print(f"  {i}. ID: {event['id']} - {event['title']}")
        
        print(f"\n📈 Summary:")
        print(f"  • Locations with duplicates: {len(duplicates)}")
        print(f"  • Total events at duplicate locations: {total_duplicate_events}")
        print(f"  • Events that would cluster: {total_duplicate_events - len(duplicates)}")
        
        # Check if this explains the clustering
        if total_duplicate_events - len(duplicates) > 0:
            print(f"\n✅ This explains why you see clusters!")
            print(f"   {total_duplicate_events - len(duplicates)} events are at the same locations")
            print(f"   and would naturally cluster together on both iOS and Android.")
        
    else:
        print("\n✅ No duplicate locations found!")
        print("   All events have unique coordinates.")
        print("   Clustering might be due to proximity thresholds.")

def check_coordinate_precision():
    """Check the precision of coordinates in the database"""
    print("\n🔍 Checking coordinate precision...")
    
    # Use ana_cruz_567 as test user
    test_user = "ana_cruz_567"
    events = get_events_for_user(test_user)
    if not events:
        return
    
    lat_precisions = []
    lng_precisions = []
    
    for event in events:
        lat = event.get('latitude')
        lng = event.get('longitude')
        
        if lat is not None and lng is not None:
            lat_str = str(float(lat))
            lng_str = str(float(lng))
            
            # Count decimal places
            lat_decimals = len(lat_str.split('.')[-1]) if '.' in lat_str else 0
            lng_decimals = len(lng_str.split('.')[-1]) if '.' in lng_str else 0
            
            lat_precisions.append(lat_decimals)
            lng_precisions.append(lng_decimals)
    
    if lat_precisions:
        print(f"📊 Latitude precision: min={min(lat_precisions)}, max={max(lat_precisions)}, avg={sum(lat_precisions)/len(lat_precisions):.1f}")
        print(f"📊 Longitude precision: min={min(lng_precisions)}, max={max(lng_precisions)}, avg={sum(lng_precisions)/len(lng_precisions):.1f}")
        
        # Estimate precision in meters
        avg_lat_precision = sum(lat_precisions) / len(lat_precisions)
        avg_lng_precision = sum(lng_precisions) / len(lng_precisions)
        
        # Rough conversion: 1 degree ≈ 111km, so 6 decimals ≈ 0.1m
        lat_meters = 111000 / (10 ** avg_lat_precision)
        lng_meters = 111000 / (10 ** avg_lng_precision)
        
        print(f"📏 Estimated precision: ~{lat_meters:.1f}m (lat), ~{lng_meters:.1f}m (lng)")

if __name__ == "__main__":
    check_duplicate_locations()
    check_coordinate_precision()
