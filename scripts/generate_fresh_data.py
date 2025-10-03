#!/usr/bin/env python3
"""
Fresh Data Generator for Production Server
Creates users and events with guaranteed unique coordinates
"""

import requests
import json
import random
import time
from datetime import datetime, timedelta
import math

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

# Sample data lists
FIRST_NAMES = ['Ana', 'Carlos', 'Maria', 'Diego', 'Sofia', 'Lucas', 'Valentina', 'Mateo', 'Isabella', 'Santiago', 'Camila', 'Sebastian', 'Lucia', 'Nicolas', 'Fernanda', 'Andres', 'Gabriela', 'Alejandro', 'Paula', 'Daniel']
LAST_NAMES = ['Garcia', 'Rodriguez', 'Martinez', 'Lopez', 'Gonzalez', 'Perez', 'Sanchez', 'Ramirez', 'Cruz', 'Flores', 'Herrera', 'Jimenez', 'Moreno', 'Alvarez', 'Ruiz', 'Diaz', 'Torres', 'Vargas', 'Ramos', 'Mendoza']
COUNTRIES = ['Argentina', 'Brazil', 'Chile', 'Colombia', 'Mexico', 'Spain', 'France', 'Germany', 'Italy', 'Portugal', 'Uruguay', 'Peru', 'Ecuador', 'Venezuela', 'Bolivia']

# Buenos Aires base locations with more variety
BUENOS_AIRES_BASE_LOCATIONS = {
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
    'Villa Urquiza': {'lat': -34.5700, 'lng': -58.4800},
    'Nunez': {'lat': -34.5500, 'lng': -58.4600},
    'Colegiales': {'lat': -34.5800, 'lng': -58.4500},
    'Chacarita': {'lat': -34.5900, 'lng': -58.4400},
    'Almagro': {'lat': -34.6100, 'lng': -58.4200}
}

UNIVERSITIES = [
    'Universidad de Buenos Aires (UBA)',
    'Universidad Torcuato di Tella',
    'Universidad de San Andrés',
    'Universidad del Salvador',
    'Universidad Católica Argentina',
    'Universidad Nacional de La Plata',
    'Universidad de Belgrano',
    'Universidad de Palermo'
]

DEGREES = [
    'Computer Science', 'Business Administration', 'International Relations',
    'Economics', 'Psychology', 'Engineering', 'Medicine', 'Law',
    'Architecture', 'Marketing', 'Finance', 'Spanish Literature',
    'Mathematics', 'Physics', 'Chemistry', 'Biology', 'History',
    'Philosophy', 'Political Science', 'Sociology', 'Anthropology'
]

YEARS = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduate', 'PhD']

INTERESTS = [
    'Music', 'Sports', 'Art', 'Technology', 'Travel', 'Food', 'Photography',
    'Reading', 'Gaming', 'Fitness', 'Dancing', 'Movies', 'Languages',
    'Volunteering', 'Entrepreneurship', 'Research', 'Writing', 'Design',
    'Environment', 'Politics', 'Culture', 'Fashion', 'Cooking', 'Nature'
]

EVENT_TYPES = ['study', 'party', 'business', 'cultural', 'academic', 'networking', 'social', 'language_exchange', 'other']

EVENT_TITLES = [
    'Study Session', 'Group Study', 'Language Exchange', 'Cultural Discussion',
    'Academic Workshop', 'Networking Event', 'Social Gathering', 'Study Group',
    'Research Meeting', 'Project Collaboration', 'Exam Preparation', 'Thesis Discussion',
    'Cultural Showcase', 'International Meetup', 'Study Buddy Session', 'Academic Seminar'
]

# Global set to track used coordinates
used_coordinates = set()

def generate_unique_coordinates(base_location, radius_km=0.5):
    """Generate unique coordinates within a radius of a base location"""
    max_attempts = 100
    attempts = 0
    
    while attempts < max_attempts:
        # Generate random offset in km
        angle = random.uniform(0, 2 * math.pi)
        distance = random.uniform(0, radius_km)
        
        # Convert to lat/lng offset
        lat_offset = (distance / 111.0) * math.cos(angle)  # 1 degree lat ≈ 111 km
        lng_offset = (distance / (111.0 * math.cos(math.radians(base_location['lat'])))) * math.sin(angle)
        
        new_lat = base_location['lat'] + lat_offset
        new_lng = base_location['lng'] + lng_offset
        
        # Round to 6 decimal places for uniqueness
        coord_key = (round(new_lat, 6), round(new_lng, 6))
        
        if coord_key not in used_coordinates:
            used_coordinates.add(coord_key)
            return {'lat': new_lat, 'lng': new_lng}
        
        attempts += 1
    
    # If we can't find unique coordinates, add a small random offset
    coord_key = (round(base_location['lat'] + random.uniform(-0.001, 0.001), 6), 
                 round(base_location['lng'] + random.uniform(-0.001, 0.001), 6))
    used_coordinates.add(coord_key)
    return {'lat': coord_key[0], 'lng': coord_key[1]}

def create_user():
    """Create a user with complete profile"""
    first_name = random.choice(FIRST_NAMES)
    last_name = random.choice(LAST_NAMES)
    username = f"{first_name.lower()}_{last_name.lower()}_{random.randint(100, 999)}"
    
    user_data = {
        "username": username,
        "password": "password123",
        "first_name": first_name,
        "last_name": last_name,
        "email": f"{username}@example.com",
        "university": random.choice(UNIVERSITIES),
        "degree": random.choice(DEGREES),
        "year": random.choice(YEARS),
        "country": random.choice(COUNTRIES),
        "bio": f"Hi! I'm {first_name}, a {random.choice(YEARS).lower()} student studying {random.choice(DEGREES).lower()}. I love {', '.join(random.sample(INTERESTS, 3))} and I'm excited to meet new people!",
        "interests": random.sample(INTERESTS, random.randint(3, 8)),
        "skills": random.sample(['Leadership', 'Communication', 'Problem Solving', 'Teamwork', 'Creativity', 'Analytical Thinking'], random.randint(2, 4)),
        "auto_invite_preference": random.choice([True, False]),
        "preferred_radius": random.randint(1, 10)
    }
    
    return user_data

def create_event(host_username):
    """Create an event with unique coordinates"""
    location_name = random.choice(list(BUENOS_AIRES_BASE_LOCATIONS.keys()))
    base_location = BUENOS_AIRES_BASE_LOCATIONS[location_name]
    coordinates = generate_unique_coordinates(base_location)
    
    # Generate event times
    start_time = datetime.now() + timedelta(days=random.randint(1, 30), hours=random.randint(9, 20))
    end_time = start_time + timedelta(hours=random.randint(1, 4))
    
    event_type = random.choice(EVENT_TYPES)
    title = random.choice(EVENT_TITLES)
    
    event_data = {
        "host": host_username,
        "title": f"{title} - {location_name}",
        "description": f"Join us for a {random.choice(['productive', 'fun', 'engaging', 'collaborative'])} {title.lower()} in {location_name}. Perfect for students looking to connect and learn together!",
        "latitude": coordinates['lat'],
        "longitude": coordinates['lng'],
        "time": start_time.isoformat(),
        "end_time": end_time.isoformat(),
        "max_participants": random.randint(5, 20),
        "event_type": event_type,
        "interest_tags": random.sample(INTERESTS, random.randint(2, 5)),
        "auto_matching_enabled": random.choice([True, False])
    }
    
    return event_data

def make_request(endpoint, data, method='POST'):
    """Make API request with error handling"""
    url = f"{PRODUCTION_BASE_URL}{endpoint}"
    
    try:
        if method == 'POST':
            response = requests.post(url, json=data, timeout=30)
        elif method == 'GET':
            response = requests.get(url, timeout=30)
        
        if response.status_code in [200, 201]:
            return response.json()
        else:
            print(f"Error {response.status_code} for {endpoint}: {response.text}")
            return None
    except Exception as e:
        print(f"Request failed for {endpoint}: {str(e)}")
        return None

def main():
    print("🚀 Starting fresh data generation for production server...")
    
    # Check if server is accessible by trying to register a test user
    print("🔍 Checking server connectivity...")
    test_user = {
        "username": f"test_connectivity_{random.randint(1000, 9999)}",
        "password": "test123"
    }
    test_result = make_request("register/", test_user)
    if test_result and (test_result.get('success') or "already exists" in str(test_result)):
        print("✅ Server is accessible!")
    else:
        print("❌ Server not accessible. Please check the URL and try again.")
        return
    
    # Create users
    print("👥 Creating users...")
    users = []
    for i in range(20):  # Create 20 users
        user_data = create_user()
        result = make_request("register/", user_data)
        if result and result.get('success'):
            users.append(user_data['username'])
            print(f"✅ Created user: {user_data['username']}")
        else:
            print(f"❌ Failed to create user: {user_data['username']}")
        time.sleep(0.5)  # Rate limiting
    
    print(f"👥 Created {len(users)} users")
    
    # Create events
    print("📅 Creating events...")
    events_created = 0
    for i in range(50):  # Create 50 events
        if not users:
            break
            
        host = random.choice(users)
        event_data = create_event(host)
        result = make_request("create_study_event/", event_data)
        
        if result and result.get('success'):
            events_created += 1
            print(f"✅ Created event: {event_data['title']} at ({event_data['latitude']:.6f}, {event_data['longitude']:.6f})")
        else:
            print(f"❌ Failed to create event: {event_data['title']}")
        time.sleep(0.5)  # Rate limiting
    
    print(f"📅 Created {events_created} events")
    print(f"📍 Used {len(used_coordinates)} unique coordinate pairs")
    
    # Verify no duplicate coordinates
    print("🔍 Verifying coordinate uniqueness...")
    if len(used_coordinates) == events_created:
        print("✅ All coordinates are unique!")
    else:
        print(f"⚠️  Warning: {events_created - len(used_coordinates)} events may have duplicate coordinates")
    
    print("🎉 Data generation complete!")
    print(f"📊 Summary:")
    print(f"   - Users: {len(users)}")
    print(f"   - Events: {events_created}")
    print(f"   - Unique coordinates: {len(used_coordinates)}")

if __name__ == "__main__":
    main()
