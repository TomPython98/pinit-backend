#!/usr/bin/env python3
"""
Create events on production server
"""

import requests
import json
import random
import time
from datetime import datetime, timedelta

# Production server URL
PRODUCTION_URL = "https://pinit-backend-production.up.railway.app/api"

# Buenos Aires neighborhoods and coordinates
BUENOS_AIRES_LOCATIONS = {
    'Palermo': {'lat': -34.5889, 'lng': -58.4108},
    'Recoleta': {'lat': -34.5875, 'lng': -58.3935},
    'San Telmo': {'lat': -34.6211, 'lng': -58.3731},
    'Puerto Madero': {'lat': -34.6108, 'lng': -58.3650},
    'Belgrano': {'lat': -34.5622, 'lng': -58.4561},
    'Caballito': {'lat': -34.6200, 'lng': -58.4400},
    'Villa Crespo': {'lat': -34.6000, 'lng': -58.4333},
    'Barracas': {'lat': -34.6500, 'lng': -58.3667},
    'La Boca': {'lat': -34.6344, 'lng': -58.3631},
    'Monserrat': {'lat': -34.6083, 'lng': -58.3731},
    'Retiro': {'lat': -34.5917, 'lng': -58.3750},
    'Congreso': {'lat': -34.6083, 'lng': -58.3917},
    'Almagro': {'lat': -34.6083, 'lng': -58.4167},
    'Boedo': {'lat': -34.6250, 'lng': -58.4167},
    'Flores': {'lat': -34.6333, 'lng': -58.4667}
}

# Event types
EVENT_TYPES = [
    'study', 'party', 'business', 'cultural', 'academic', 'networking', 'social', 'language_exchange', 'other'
]

# Common interests for international students
INTERESTS = [
    'Spanish Language', 'Cultural Exchange', 'Photography', 'Travel', 'Food & Cooking',
    'Music', 'Art & Design', 'Technology', 'Business', 'International Relations',
    'Literature', 'History', 'Architecture', 'Dance', 'Sports', 'Volunteering',
    'Language Exchange', 'Networking', 'Entrepreneurship', 'Sustainability'
]

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

def get_users():
    """Get all users from the server"""
    print("👥 Fetching users...")
    
    result = make_api_call("get_all_users/")
    if result and isinstance(result, list):
        # Convert usernames to user objects
        users = [{"username": username} for username in result]
        print(f"✅ Found {len(users)} users")
        return users
    else:
        print("❌ Failed to get users")
        return []

def create_events(users, count=50):
    """Create study events"""
    print(f"📚 Creating {count} study events...")
    
    created_events = []
    
    for i in range(count):
        # Select random host
        host = random.choice(users)
        location = random.choice(list(BUENOS_AIRES_LOCATIONS.items()))
        
        # Generate event data
        start_time = datetime.now() + timedelta(days=random.randint(1, 30), hours=random.randint(9, 21))
        end_time = start_time + timedelta(hours=random.randint(1, 4))
        
        event_data = {
            "title": f"{random.choice(['Study Session', 'Group Study', 'Language Exchange', 'Cultural Discussion', 'Academic Workshop'])} - {location[0]}",
            "description": f"Join us for a {random.choice(['productive', 'fun', 'engaging', 'collaborative'])} study session in {location[0]}. Perfect for international students looking to connect and learn together!",
            "latitude": location[1]['lat'],
            "longitude": location[1]['lng'],
            "time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "max_participants": random.randint(3, 12),
            "host": host['username'],
            "is_public": random.choice([True, False]),
            "event_type": random.choice(EVENT_TYPES),
            "auto_matching_enabled": random.choice([True, False]),
            "interest_tags": random.sample(INTERESTS, random.randint(2, 5))
        }
        
        # Create event via API
        result = make_api_call("create_study_event/", 'POST', event_data)
        
        if result and result.get('success'):
            event_data['id'] = result.get('event_id')
            created_events.append(event_data)
            print(f"✅ Created event {i+1}/{count}: {event_data['title']}")
        else:
            print(f"❌ Failed to create event {i+1}/{count}")
        
        # Small delay
        time.sleep(0.3)
    
    return created_events

def main():
    """Main function"""
    print("🚀 Creating Events on Production Server")
    print("=" * 50)
    
    # Get users
    users = get_users()
    
    if not users:
        print("❌ No users found. Please create users first.")
        return
    
    # Create events
    events = create_events(users, 50)
    
    print("=" * 50)
    print(f"✅ Created {len(events)} events!")

if __name__ == "__main__":
    main()
