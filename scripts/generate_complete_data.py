#!/usr/bin/env python3
"""
Complete Data Generator for Production Server
Creates users, events, profiles, friend connections, invitations, comments, likes, and social interactions
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

# Buenos Aires base locations
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

COMMENTS = [
    "This looks amazing! Count me in!",
    "Great idea! I've been looking for something like this.",
    "Perfect timing! I was just thinking about this topic.",
    "Sounds interesting! What time should we meet?",
    "I'm definitely interested! This is exactly what I need.",
    "Count me in! Looking forward to it.",
    "This is going to be so much fun!",
    "I'm in! Can't wait to meet everyone.",
    "Sounds like a great opportunity to learn!",
    "I'm definitely joining! This is perfect for me.",
    "What a fantastic idea! I'm excited to participate.",
    "This is exactly what I was looking for!",
    "I'm so excited about this! Count me in.",
    "This sounds like it will be really helpful!",
    "I'm definitely interested! When do we start?",
    "This is going to be awesome! I'm in.",
    "Perfect! I've been wanting to do something like this.",
    "I'm definitely joining! This is great.",
    "This sounds like it will be really fun!",
    "I'm so excited! This is exactly what I need."
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
        lat_offset = (distance / 111.0) * math.cos(angle)
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

def create_friend_connections(users):
    """Create friend connections between users"""
    print("🤝 Creating friend connections...")
    connections_created = 0
    
    for user in users:
        # Each user sends 3-8 friend requests
        num_requests = random.randint(3, 8)
        potential_friends = [u for u in users if u != user]
        selected_friends = random.sample(potential_friends, min(num_requests, len(potential_friends)))
        
        for friend in selected_friends:
            # Send friend request
            friend_request_data = {
                "from_user": user,
                "to_user": friend
            }
            
            result = make_request("send_friend_request/", friend_request_data)
            if result and result.get('success'):
                connections_created += 1
                print(f"✅ Friend request: {user} -> {friend}")
            
            time.sleep(0.2)  # Rate limiting
    
    print(f"🤝 Created {connections_created} friend requests")
    
    # Accept some friend requests
    print("🤝 Accepting friend requests...")
    acceptances = 0
    for user in users:
        # Each user accepts 2-5 friend requests
        num_acceptances = random.randint(2, 5)
        for _ in range(num_acceptances):
            # Simulate accepting a random friend request
            accept_data = {
                "from_user": random.choice([u for u in users if u != user]),
                "to_user": user
            }
            
            result = make_request("accept_friend_request/", accept_data)
            if result and result.get('success'):
                acceptances += 1
                print(f"✅ Friend request accepted: {accept_data['from_user']} <-> {accept_data['to_user']}")
            
            time.sleep(0.2)
    
    print(f"🤝 Accepted {acceptances} friend connections")

def create_event_interactions(users, events):
    """Create RSVPs, comments, likes, and shares for events"""
    print("💬 Creating event interactions...")
    interactions_created = 0
    
    for event in events:
        event_id = event['event_id']
        
        # Random users RSVP to events
        num_rsvps = random.randint(2, 8)
        selected_users = random.sample(users, min(num_rsvps, len(users)))
        
        for user in selected_users:
            if user != event['host']:  # Don't RSVP to own events
                # RSVP to event
                rsvp_data = {
                    "username": user,
                    "event_id": event_id
                }
                
                result = make_request("rsvp_study_event/", rsvp_data)
                if result and result.get('success'):
                    interactions_created += 1
                    print(f"✅ RSVP: {user} -> {event['title']}")
                
                # Add comments
                if random.random() < 0.7:  # 70% chance to comment
                    comment_data = {
                        "username": user,
                        "event_id": event_id,
                        "text": random.choice(COMMENTS)
                    }
                    
                    result = make_request("events/comment/", comment_data)
                    if result and result.get('success'):
                        interactions_created += 1
                        print(f"✅ Comment: {user} on {event['title']}")
                
                # Like the event
                if random.random() < 0.6:  # 60% chance to like
                    like_data = {
                        "username": user,
                        "event_id": event_id
                    }
                    
                    result = make_request("events/like/", like_data)
                    if result and result.get('success'):
                        interactions_created += 1
                        print(f"✅ Like: {user} -> {event['title']}")
                
                # Share the event
                if random.random() < 0.3:  # 30% chance to share
                    share_data = {
                        "username": user,
                        "event_id": event_id,
                        "shared_platform": random.choice(['whatsapp', 'facebook', 'twitter', 'instagram', 'other'])
                    }
                    
                    result = make_request("events/share/", share_data)
                    if result and result.get('success'):
                        interactions_created += 1
                        print(f"✅ Share: {user} -> {event['title']}")
                
                time.sleep(0.2)  # Rate limiting
    
    print(f"💬 Created {interactions_created} event interactions")

def create_direct_invitations(users, events):
    """Create direct invitations to events"""
    print("📨 Creating direct invitations...")
    invitations_created = 0
    
    for event in events:
        event_id = event['event_id']
        host = event['host']
        
        # Host invites 2-5 friends to their event
        num_invites = random.randint(2, 5)
        potential_invitees = [u for u in users if u != host]
        selected_invitees = random.sample(potential_invitees, min(num_invites, len(potential_invitees)))
        
        for invitee in selected_invitees:
            invite_data = {
                "username": invitee,
                "event_id": event_id,
                "inviter": host
            }
            
            result = make_request("invite_user_to_event/", invite_data)
            if result and result.get('success'):
                invitations_created += 1
                print(f"✅ Direct invitation: {host} -> {invitee} for {event['title']}")
            
            time.sleep(0.2)
    
    print(f"📨 Created {invitations_created} direct invitations")

def run_auto_matching(events):
    """Run auto-matching for events"""
    print("🎯 Running auto-matching...")
    matches_created = 0
    
    for event in events:
        if event.get('auto_matching_enabled', False):
            auto_match_data = {
                "event_id": event['event_id']
            }
            
            result = make_request("run_auto_matching/", auto_match_data)
            if result and result.get('success'):
                matches_created += 1
                print(f"✅ Auto-matching: {event['title']}")
            
            time.sleep(0.5)
    
    print(f"🎯 Created {matches_created} auto-matches")

def main():
    print("🚀 Starting complete data generation for production server...")
    
    # Check if server is accessible
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
    for i in range(25):  # Create 25 users
        user_data = create_user()
        result = make_request("register/", user_data)
        if result and result.get('success'):
            users.append(user_data['username'])
            print(f"✅ Created user: {user_data['username']}")
        else:
            print(f"❌ Failed to create user: {user_data['username']}")
        time.sleep(0.5)
    
    print(f"👥 Created {len(users)} users")
    
    # Create events
    print("📅 Creating events...")
    events = []
    for i in range(60):  # Create 60 events
        if not users:
            break
            
        host = random.choice(users)
        event_data = create_event(host)
        result = make_request("create_study_event/", event_data)
        
        if result and result.get('success'):
            events.append({
                'event_id': result.get('event_id'),
                'title': event_data['title'],
                'host': host,
                'auto_matching_enabled': event_data['auto_matching_enabled']
            })
            print(f"✅ Created event: {event_data['title']} at ({event_data['latitude']:.6f}, {event_data['longitude']:.6f})")
        else:
            print(f"❌ Failed to create event: {event_data['title']}")
        time.sleep(0.5)
    
    print(f"📅 Created {len(events)} events")
    
    # Create friend connections
    create_friend_connections(users)
    
    # Create direct invitations
    create_direct_invitations(users, events)
    
    # Create event interactions
    create_event_interactions(users, events)
    
    # Run auto-matching
    run_auto_matching(events)
    
    print("🎉 Complete data generation finished!")
    print(f"📊 Summary:")
    print(f"   - Users: {len(users)}")
    print(f"   - Events: {len(events)}")
    print(f"   - Unique coordinates: {len(used_coordinates)}")
    print(f"   - Friend connections, invitations, comments, likes, and shares created!")

if __name__ == "__main__":
    main()
