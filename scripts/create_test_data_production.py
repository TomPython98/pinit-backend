#!/usr/bin/env python3
"""
Small Test Data Generator for Production Server
Creates 10 users with complete interactions, events, comments, and social features
"""

import requests
import json
import random
import time
from datetime import datetime, timedelta

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

# Sample data lists
FIRST_NAMES = ['Ana', 'Carlos', 'Maria', 'Diego', 'Sofia', 'Lucas', 'Valentina', 'Mateo', 'Isabella', 'Santiago']
LAST_NAMES = ['Garcia', 'Rodriguez', 'Martinez', 'Lopez', 'Gonzalez', 'Perez', 'Sanchez', 'Ramirez', 'Cruz', 'Flores']
COUNTRIES = ['Argentina', 'Brazil', 'Chile', 'Colombia', 'Mexico', 'Spain', 'France', 'Germany', 'Italy', 'Portugal']

# Buenos Aires locations
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
    'Monserrat': {'lat': -34.6083, 'lng': -58.3731}
}

# Data lists
UNIVERSITIES = [
    'Universidad de Buenos Aires (UBA)',
    'Universidad Torcuato di Tella',
    'Universidad de San Andrés',
    'Universidad del Salvador',
    'Universidad Católica Argentina'
]

DEGREES = [
    'Computer Science', 'Business Administration', 'International Relations',
    'Economics', 'Psychology', 'Engineering', 'Medicine', 'Law',
    'Architecture', 'Marketing', 'Finance', 'Spanish Literature'
]

YEARS = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduate', 'PhD']

INTERESTS = [
    'Language Exchange', 'Cultural Events', 'Study Groups', 'Networking',
    'Travel', 'Food', 'Music', 'Art', 'Sports', 'Technology', 'Photography',
    'Dancing', 'Cooking', 'Reading', 'Movies', 'Gaming', 'Fitness',
    'Volunteering', 'Entrepreneurship', 'Sustainability'
]

SKILLS = {
    'Spanish': ['Beginner', 'Intermediate', 'Advanced', 'Native'],
    'English': ['Beginner', 'Intermediate', 'Advanced', 'Native'],
    'Portuguese': ['Beginner', 'Intermediate', 'Advanced', 'Native'],
    'French': ['Beginner', 'Intermediate', 'Advanced', 'Native'],
    'German': ['Beginner', 'Intermediate', 'Advanced', 'Native'],
    'Programming': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    'Design': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    'Marketing': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    'Photography': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    'Cooking': ['Beginner', 'Intermediate', 'Advanced', 'Expert']
}

EVENT_TYPES = ['study', 'party', 'business', 'cultural', 'academic', 'networking', 'social', 'language_exchange', 'other']

def make_api_call(endpoint, method='GET', data=None):
    """Make API call to production server"""
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
        print(f"❌ API Error {e.response.status_code}: {e.response.text}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        return None

def create_test_users(count=10):
    """Create test users with profiles"""
    print(f"👥 Creating {count} test users...")
    
    created_users = []
    credentials_file = open('test_credentials_production.txt', 'w')
    
    for i in range(count):
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        username = f"test_{first_name.lower()}_{last_name.lower()}"
        password = "testpass123"
        email = f"{username}@example.com"
        
        # Register user
        user_data = {
            "username": username,
            "password": password
        }
        
        result = make_api_call("register/", 'POST', user_data)
        
        if result and result.get('success'):
            # Create profile
            profile_data = {
                "username": username,
                "full_name": f"{first_name} {last_name}",
                "bio": f"International student from {random.choice(COUNTRIES)} studying in Buenos Aires. Love exploring the city and meeting new people!",
                "university": random.choice(UNIVERSITIES),
                "degree": random.choice(DEGREES),
                "year": random.choice(YEARS),
                "interests": random.sample(INTERESTS, random.randint(3, 6)),
                "skills": {skill: random.choice(levels) for skill, levels in random.sample(list(SKILLS.items()), random.randint(2, 4))},
                "auto_invite_enabled": random.choice([True, False]),
                "preferred_radius": random.uniform(5.0, 25.0)
            }
            
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
            
            time.sleep(0.5)  # Rate limiting
        else:
            print(f"❌ Failed to create user {i+1}/{count}: {username}")
    
    credentials_file.close()
    print(f"📝 Credentials saved to test_credentials_production.txt")
    return created_users

def create_test_events(users, count=15):
    """Create test events"""
    print(f"📚 Creating {count} test events...")
    
    created_events = []
    
    for i in range(count):
        host = random.choice(users)
        location = random.choice(list(BUENOS_AIRES_LOCATIONS.items()))
        
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
        
        result = make_api_call("create_study_event/", 'POST', event_data)
        
        if result and result.get('success'):
            created_events.append({
                'event_id': result.get('event_id'),
                'host': host['username'],
                'data': event_data
            })
            print(f"✅ Created event {i+1}/{count}: {event_data['title']}")
        else:
            print(f"❌ Failed to create event {i+1}/{count}")
        
        time.sleep(0.5)  # Rate limiting
    
    return created_events

def create_friend_connections(users):
    """Create friend connections between users"""
    print("🤝 Creating friend connections...")
    
    connections_created = 0
    
    for user in users:
        # Each user sends 2-4 friend requests
        num_requests = random.randint(2, 4)
        potential_friends = [u for u in users if u['username'] != user['username']]
        selected_friends = random.sample(potential_friends, min(num_requests, len(potential_friends)))
        
        for friend in selected_friends:
            # Send friend request
            request_data = {
                "from_user": user['username'],
                "to_user": friend['username']
            }
            
            result = make_api_call("send_friend_request/", 'POST', request_data)
            
            if result and result.get('success'):
                # Randomly accept some requests
                if random.choice([True, False]):
                    accept_data = {
                        "from_user": friend['username'],
                        "to_user": user['username']
                    }
                    
                    accept_result = make_api_call("accept_friend_request/", 'POST', accept_data)
                    if accept_result and accept_result.get('success'):
                        connections_created += 1
                        print(f"✅ {user['username']} ↔️ {friend['username']} are now friends")
            
            time.sleep(0.3)
    
    print(f"🤝 Created {connections_created} friend connections")

def create_event_interactions(users, events):
    """Create RSVPs, comments, likes, and shares for events"""
    print("💬 Creating event interactions...")
    
    interactions_created = 0
    
    for event in events:
        # Random users RSVP to events
        num_rsvps = random.randint(2, 6)
        selected_users = random.sample(users, min(num_rsvps, len(users)))
        
        for user in selected_users:
            if user['username'] != event['host']:  # Don't RSVP to own events
                # RSVP to event
                rsvp_data = {
                    "username": user['username'],
                    "event_id": event['event_id']
                }
                
                rsvp_result = make_api_call("rsvp_study_event/", 'POST', rsvp_data)
                
                if rsvp_result and rsvp_result.get('success'):
                    interactions_created += 1
                    
                    # Randomly add comments
                    if random.choice([True, False]):
                        comment_data = {
                            "username": user['username'],
                            "event_id": event['event_id'],
                            "comment": random.choice([
                                "Looking forward to this!",
                                "Great event idea!",
                                "Can't wait to meet everyone",
                                "Perfect timing for me",
                                "This sounds amazing!"
                            ])
                        }
                        
                        make_api_call("events/comment/", 'POST', comment_data)
                    
                    # Randomly like the event
                    if random.choice([True, False]):
                        like_data = {
                            "username": user['username'],
                            "event_id": event['event_id']
                        }
                        
                        make_api_call("events/like/", 'POST', like_data)
                    
                    # Randomly share the event
                    if random.choice([True, False]):
                        share_data = {
                            "username": user['username'],
                            "event_id": event['event_id']
                        }
                        
                        make_api_call("events/share/", 'POST', share_data)
                
                time.sleep(0.2)
    
    print(f"💬 Created {interactions_created} event interactions")

def run_auto_matching(events):
    """Run auto-matching for events"""
    print("🎯 Running auto-matching...")
    
    matches_created = 0
    
    for event in events:
        if event['data']['auto_matching_enabled']:
            auto_match_data = {
                "event_id": event['event_id']
            }
            
            result = make_api_call("advanced_auto_match/", 'POST', auto_match_data)
            
            if result and result.get('success'):
                matches_created += 1
                print(f"✅ Auto-matched users for event: {event['data']['title']}")
            
            time.sleep(0.5)
    
    print(f"🎯 Created {matches_created} auto-matches")

def main():
    """Main function to create complete test data"""
    print("🚀 Starting test data creation for production server...")
    print(f"🌐 Target: {PRODUCTION_BASE_URL}")
    
    # Create users
    users = create_test_users(10)
    
    if not users:
        print("❌ No users created, stopping...")
        return
    
    # Create events
    events = create_test_events(users, 15)
    
    if not events:
        print("❌ No events created, stopping...")
        return
    
    # Create social connections
    create_friend_connections(users)
    
    # Create event interactions
    create_event_interactions(users, events)
    
    # Run auto-matching
    run_auto_matching(events)
    
    print("\n🎉 Test data creation complete!")
    print(f"✅ Created {len(users)} users")
    print(f"✅ Created {len(events)} events")
    print(f"✅ Created social connections and interactions")
    print(f"✅ Ran auto-matching")
    print("\n📝 Login credentials saved to: test_credentials_production.txt")

if __name__ == "__main__":
    main()
