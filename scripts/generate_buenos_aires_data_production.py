#!/usr/bin/env python3
"""
Buenos Aires International Students Simulation - Production Server Version
Generates users, events, and data for Buenos Aires with international students
Targets the production server via API calls
"""

import requests
import json
import random
import uuid
from datetime import datetime, timedelta
from faker import Faker
import time

# Production server URL
PRODUCTION_URL = "https://pinit-backend-production.up.railway.app/api"

# Initialize Faker with Spanish locale for Buenos Aires
fake = Faker(['es_ES', 'en_US', 'pt_BR', 'fr_FR', 'de_DE', 'it_IT'])

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

# International universities in Buenos Aires
UNIVERSITIES = [
    'Universidad de Buenos Aires (UBA)',
    'Universidad Torcuato di Tella',
    'Universidad de San Andrés',
    'Universidad del Salvador',
    'Universidad Católica Argentina',
    'Universidad de Palermo',
    'Universidad Argentina de la Empresa',
    'Universidad de Belgrano',
    'Universidad Abierta Interamericana',
    'Universidad Tecnológica Nacional'
]

# Degrees
DEGREES = [
    'Bachelor', 'Master', 'PhD', 'Certificate', 'Diploma'
]

# Academic years
YEARS = [
    '1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year', 'Graduate', 'Postgraduate'
]

# Common interests for international students
INTERESTS = [
    'Spanish Language', 'Cultural Exchange', 'Photography', 'Travel', 'Food & Cooking',
    'Music', 'Art & Design', 'Technology', 'Business', 'International Relations',
    'Literature', 'History', 'Architecture', 'Dance', 'Sports', 'Volunteering',
    'Language Exchange', 'Networking', 'Entrepreneurship', 'Sustainability'
]

# Skills with levels
SKILLS = {
    'Spanish Language': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'NATIVE'],
    'English Language': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'NATIVE'],
    'Cultural Exchange': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
    'Photography': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
    'Cooking': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
    'Music': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
    'Art & Design': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
    'Technology': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
    'Business': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'],
    'Networking': ['BEGINNER', 'INTERMEDIATE', 'ADVANCED']
}

# Event types
EVENT_TYPES = [
    'study', 'party', 'business', 'cultural', 'academic', 'networking', 'social', 'language_exchange', 'other'
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
        elif method == 'PUT':
            response = requests.put(url, headers=headers, json=data, timeout=30)
        
        if response.status_code in [200, 201]:
            return response.json() if response.content else {}
        else:
            print(f"❌ API Error {response.status_code}: {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        return None

def generate_international_users(count=200):
    """Generate international students in Buenos Aires"""
    print(f"🌍 Generating {count} international students...")
    
    created_users = []
    credentials_file = open('buenos_aires_credentials_production.txt', 'w')
    
    for i in range(count):
        # Generate user data
        first_name = fake.first_name()
        last_name = fake.last_name()
        username = f"{first_name.lower()}_{last_name.lower()}_{random.randint(100, 999)}"
        password = "buenosaires123"
        email = f"{username}@example.com"
        
        # Register user
        user_data = {
            "username": username,
            "password": password
        }
        
        result = make_api_call("register/", 'POST', user_data)
        
        if result and result.get('success'):
            # Update user profile using the update_user_interests endpoint
            profile_data = {
                "username": username,
                "full_name": f"{first_name} {last_name}",
                "bio": f"International student from {fake.country()} studying in Buenos Aires. Love exploring the city and meeting new people!",
                "university": random.choice(UNIVERSITIES),
                "degree": random.choice(DEGREES),
                "year": random.choice(YEARS),
                "interests": random.sample(INTERESTS, random.randint(3, 6)),
                "skills": {skill: random.choice(levels) for skill, levels in random.sample(list(SKILLS.items()), random.randint(2, 4))},
                "auto_invite_enabled": random.choice([True, False]),
                "preferred_radius": random.uniform(5.0, 25.0)
            }
            
            # Update profile via API
            profile_result = make_api_call("update_user_interests/", 'POST', profile_data)
            
            if profile_result and profile_result.get('success'):
                credentials_file.write(f"Username: {username}\nPassword: {password}\nEmail: {email}\nFull Name: {first_name} {last_name}\nUniversity: {profile_data['university']}\n\n")
                
                created_users.append({
                    'username': username,
                    'password': password,
                    'profile': profile_data
                })
                
                print(f"✅ Created user {i+1}/{count}: {username}")
            else:
                print(f"⚠️ User {username} created but profile update failed")
            
            # Small delay to avoid overwhelming the server
            time.sleep(0.2)
        else:
            print(f"❌ Failed to create user {i+1}/{count}: {username}")
    
    credentials_file.close()
    print(f"📝 Credentials saved to buenos_aires_credentials_production.txt")
    return created_users

def generate_buenos_aires_events(users, count=150):
    """Generate study events in Buenos Aires"""
    print(f"📚 Generating {count} study events...")
    
    created_events = []
    
    for i in range(count):
        # Select random host
        host = random.choice(users)
        location = random.choice(list(BUENOS_AIRES_LOCATIONS.items()))
        
        # Generate event data - using the correct field names from Django view
        event_data = {
            "title": f"{random.choice(['Study Session', 'Group Study', 'Language Exchange', 'Cultural Discussion', 'Academic Workshop'])} - {location[0]}",
            "description": f"Join us for a {random.choice(['productive', 'fun', 'engaging', 'collaborative'])} study session in {location[0]}. Perfect for international students looking to connect and learn together!",
            "location": f"{location[0]}, Buenos Aires, Argentina",
            "latitude": location[1]['lat'],
            "longitude": location[1]['lng'],
            "event_time": (datetime.now() + timedelta(days=random.randint(1, 30), hours=random.randint(9, 21))).strftime("%Y-%m-%d %H:%M:%S"),
            "max_participants": random.randint(3, 12),
            "host": host['username'],  # Changed from host_username to host
            "is_private": random.choice([True, False]),
            "event_type": random.choice(EVENT_TYPES),
            "auto_matching_enabled": random.choice([True, False]),
            "interest_tags": random.sample(INTERESTS, random.randint(2, 5))
        }
        
        # Create event via API
        result = make_api_call("create_study_event/", 'POST', event_data)
        
        if result and result.get('success'):
            # Add the event ID from the response
            event_data['id'] = result.get('event_id')
            created_events.append(event_data)
            print(f"✅ Created event {i+1}/{count}: {event_data['title']}")
        else:
            print(f"❌ Failed to create event {i+1}/{count}: {result}")
        
        # Small delay
        time.sleep(0.2)
    
    return created_events

def create_private_invitations(users, events):
    """Create private invitations"""
    print(f"📨 Creating private invitations...")
    
    invitation_count = 0
    
    for event in events:
        if event.get('is_private') and event.get('id'):
            # Select random attendees
            attendees = random.sample(users, random.randint(1, min(5, len(users))))
            
            for attendee in attendees:
                if attendee['username'] != event['host']:
                    invitation_data = {
                        "event_id": event.get('id'),
                        "invited_username": attendee['username']
                    }
                    
                    result = make_api_call("invite_to_event/", 'POST', invitation_data)
                    if result and result.get('success'):
                        invitation_count += 1
                    
                    time.sleep(0.1)
    
    print(f"✅ Created {invitation_count} private invitations")

def run_auto_matching(events):
    """Run auto-matching for events"""
    print(f"🤖 Running auto-matching...")
    
    matched_count = 0
    
    for event in events:
        if event.get('auto_matching_enabled') and event.get('id'):
            # Trigger auto-matching via API
            result = make_api_call("advanced_auto_match/", 'POST', {"event_id": event.get('id')})
            if result and result.get('success'):
                matched_count += 1
            
            time.sleep(0.2)
    
    print(f"✅ Auto-matched {matched_count} events")

def main():
    """Main function to generate all data"""
    print("🚀 Starting Buenos Aires International Students Simulation on Production Server")
    print("=" * 80)
    
    # Generate users
    users = generate_international_users(200)
    print(f"✅ Generated {len(users)} users")
    
    # Generate events
    events = generate_buenos_aires_events(users, 150)
    print(f"✅ Generated {len(events)} events")
    
    # Create invitations
    create_private_invitations(users, events)
    
    # Run auto-matching
    run_auto_matching(events)
    
    print("=" * 80)
    print("🎉 Buenos Aires simulation completed!")
    print(f"📊 Summary:")
    print(f"   👥 Users: {len(users)}")
    print(f"   📚 Events: {len(events)}")
    print(f"   📝 Credentials saved to: buenos_aires_credentials_production.txt")

if __name__ == "__main__":
    main()
