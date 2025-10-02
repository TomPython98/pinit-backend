#!/usr/bin/env python3
"""
Regenerate events with unique coordinates by adding small random offsets
This will create new events with slightly different coordinates to avoid clustering
"""

import requests
import json
import random
from datetime import datetime, timedelta

PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

# Buenos Aires locations with base coordinates
BUENOS_AIRES_LOCATIONS = {
    "Congreso": {"lat": -34.6083, "lng": -58.3917},
    "Caballito": {"lat": -34.62, "lng": -58.44},
    "Recoleta": {"lat": -34.5875, "lng": -58.3935},
    "Belgrano": {"lat": -34.5622, "lng": -58.4561},
    "San Telmo": {"lat": -34.6211, "lng": -58.3731},
    "Villa Crespo": {"lat": -34.6, "lng": -58.4333},
    "Monserrat": {"lat": -34.6083, "lng": -58.3731},
    "Palermo": {"lat": -34.5889, "lng": -58.4108},
    "Flores": {"lat": -34.6333, "lng": -58.4667},
    "Barracas": {"lat": -34.65, "lng": -58.3667},
    "Almagro": {"lat": -34.6083, "lng": -58.4167},
    "La Boca": {"lat": -34.6344, "lng": -58.3631},
    "Puerto Madero": {"lat": -34.6108, "lng": -58.365},
    "Boedo": {"lat": -34.625, "lng": -58.4167}
}

EVENT_TYPES = ['study', 'party', 'business', 'cultural', 'academic', 'networking', 'social', 'language_exchange', 'other']
INTERESTS = ['Technology', 'Music', 'Sports', 'Art', 'Literature', 'Languages', 'Cooking', 'Travel', 'Photography', 'Gaming', 'Fitness', 'Science', 'History', 'Politics', 'Entrepreneurship', 'Study Groups', 'Cultural Events', 'Dancing', 'Food', 'Reading', 'Networking', 'Volunteering', 'Mathematics', 'Language Exchange', 'Sustainability']

def add_random_offset(lat, lng, max_offset_meters=100):
    """Add a small random offset to coordinates (max 100 meters)"""
    # Convert meters to degrees (rough approximation)
    # 1 degree ≈ 111,000 meters
    max_offset_degrees = max_offset_meters / 111000.0
    
    # Add random offset
    lat_offset = random.uniform(-max_offset_degrees, max_offset_degrees)
    lng_offset = random.uniform(-max_offset_degrees, max_offset_degrees)
    
    new_lat = lat + lat_offset
    new_lng = lng + lng_offset
    
    return new_lat, new_lng

def make_api_call(endpoint, method='GET', data=None):
    url = f"{PRODUCTION_BASE_URL}{endpoint}"
    headers = {'Content-Type': 'application/json'}
    try:
        if method == 'POST':
            response = requests.post(url, headers=headers, data=json.dumps(data))
        else:
            response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.HTTPError as e:
        print(f"❌ API Error {e.response.status_code}: {e.response.json()}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        return None

def create_unique_events(count=20):
    """Create events with unique coordinates"""
    print(f"🎯 Creating {count} events with unique coordinates...")
    
    created_events = []
    
    for i in range(count):
        # Choose a random location
        location_name = random.choice(list(BUENOS_AIRES_LOCATIONS.keys()))
        base_coords = BUENOS_AIRES_LOCATIONS[location_name]
        
        # Add random offset to make coordinates unique
        lat, lng = add_random_offset(base_coords["lat"], base_coords["lng"], max_offset_meters=200)
        
        # Generate event data
        start_time = datetime.now() + timedelta(days=random.randint(1, 30), hours=random.randint(9, 21))
        end_time = start_time + timedelta(hours=random.randint(1, 4))
        
        event_data = {
            "title": f"Unique Event {i+1} - {location_name}",
            "description": f"Join us for a unique event in {location_name}. This event has unique coordinates to avoid clustering!",
            "latitude": lat,
            "longitude": lng,
            "time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "max_participants": random.randint(3, 12),
            "host": "ana_cruz_567",  # Use our test user as host
            "is_public": True,
            "event_type": random.choice(EVENT_TYPES),
            "auto_matching_enabled": random.choice([True, False]),
            "interest_tags": random.sample(INTERESTS, random.randint(2, 5))
        }
        
        result = make_api_call("create_study_event/", 'POST', event_data)
        
        if result and result.get('success'):
            event_id = result['event_id']
            created_events.append({
                'id': event_id,
                'title': event_data['title'],
                'lat': lat,
                'lng': lng,
                'location': location_name
            })
            print(f"✅ Created event {i+1}/{count}: {event_data['title']}")
            print(f"   Location: {location_name} ({lat:.6f}, {lng:.6f})")
        else:
            print(f"❌ Failed to create event {i+1}/{count}")
    
    print(f"\n📈 Summary:")
    print(f"  • Events created: {len(created_events)}")
    print(f"  • All events have unique coordinates")
    print(f"  • No clustering should occur")
    
    return created_events

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

def verify_unique_coordinates():
    """Verify that new events have unique coordinates"""
    print("\n🔍 Verifying unique coordinates...")
    
    test_user = "ana_cruz_567"
    events = get_events_for_user(test_user)
    if not events:
        print(f"❌ No events found for user {test_user}")
        return
    
    print(f"📊 Total events: {len(events)}")
    
    # Check for duplicates
    location_groups = {}
    
    for event in events:
        lat = event.get('latitude')
        lng = event.get('longitude')
        title = event.get('title', 'Unknown')
        
        if lat is not None and lng is not None:
            # Round to 4 decimal places (about 11m precision)
            coord_key = (round(float(lat), 4), round(float(lng), 4))
            if coord_key not in location_groups:
                location_groups[coord_key] = []
            location_groups[coord_key].append(title)
    
    duplicates = {coord: events for coord, events in location_groups.items() if len(events) > 1}
    
    if duplicates:
        print(f"⚠️ Still found {len(duplicates)} locations with duplicates:")
        for coord, events_list in duplicates.items():
            lat, lng = coord
            print(f"  📍 ({lat}, {lng}): {len(events_list)} events")
            for event_title in events_list:
                print(f"    - {event_title}")
    else:
        print("✅ No duplicate locations found!")
        print("   All events have unique coordinates.")

if __name__ == "__main__":
    create_unique_events(15)  # Create 15 new events with unique coordinates
    verify_unique_coordinates()
