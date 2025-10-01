#!/usr/bin/env python3
"""
Populate Production Database Like Local
Creates comprehensive data that matches what was working locally
"""

import requests
import json
import random
import time
from datetime import datetime, timedelta

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

# Sample data lists
FIRST_NAMES = ['Ana', 'Carlos', 'Maria', 'Diego', 'Sofia', 'Lucas', 'Valentina', 'Mateo', 'Isabella', 'Santiago', 'Camila', 'Alejandro', 'Gabriela', 'Sebastian', 'Natalia', 'Andres', 'Paula', 'Felipe', 'Daniela', 'Nicolas']
LAST_NAMES = ['Garcia', 'Rodriguez', 'Martinez', 'Lopez', 'Gonzalez', 'Perez', 'Sanchez', 'Ramirez', 'Cruz', 'Flores', 'Torres', 'Rivera', 'Gomez', 'Diaz', 'Reyes', 'Morales', 'Jimenez', 'Hernandez', 'Ruiz', 'Vargas']
COUNTRIES = ['Argentina', 'Brazil', 'Chile', 'Colombia', 'Mexico', 'Spain', 'France', 'Germany', 'Italy', 'Portugal', 'Uruguay', 'Peru', 'Ecuador', 'Venezuela', 'Bolivia']

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
    'Monserrat': {'lat': -34.6083, 'lng': -58.3731},
    'Retiro': {'lat': -34.5917, 'lng': -58.3750},
    'Congreso': {'lat': -34.6083, 'lng': -58.3917},
    'Almagro': {'lat': -34.6083, 'lng': -58.4167},
    'Boedo': {'lat': -34.6250, 'lng': -58.4167},
    'Flores': {'lat': -34.6333, 'lng': -58.4667}
}

UNIVERSITIES = [
    'Universidad de Buenos Aires (UBA)',
    'Universidad Torcuato di Tella',
    'Universidad de San Andrés',
    'Universidad del Salvador',
    'Universidad Católica Argentina',
    'Universidad de Palermo',
    'Universidad Argentina de la Empresa',
    'Universidad de Belgrano',
    'Universidad Tecnológica Nacional',
    'Universidad Nacional de La Plata'
]

DEGREES = [
    'Computer Science', 'Business Administration', 'International Relations',
    'Economics', 'Psychology', 'Engineering', 'Medicine', 'Law',
    'Architecture', 'Marketing', 'Finance', 'Spanish Literature',
    'Political Science', 'Journalism', 'Design', 'Education'
]

YEARS = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduate', 'PhD']

INTERESTS = [
    'Language Exchange', 'Cultural Events', 'Study Groups', 'Networking',
    'Travel', 'Food', 'Music', 'Art', 'Sports', 'Technology', 'Photography',
    'Dancing', 'Cooking', 'Reading', 'Movies', 'Gaming', 'Fitness',
    'Volunteering', 'Entrepreneurship', 'Sustainability', 'Politics',
    'History', 'Literature', 'Science', 'Mathematics', 'Languages'
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
    'Cooking': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    'Writing': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    'Public Speaking': ['Beginner', 'Intermediate', 'Advanced', 'Expert']
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

def create_comprehensive_users(count=50):
    """Create comprehensive user base"""
    print(f"👥 Creating {count} comprehensive users...")
    
    created_users = []
    credentials_file = open('production_credentials_comprehensive.txt', 'w')
    
    for i in range(count):
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
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
            # Create comprehensive profile
            profile_data = {
                "username": username,
                "full_name": f"{first_name} {last_name}",
                "bio": f"International student from {random.choice(COUNTRIES)} studying in Buenos Aires. Passionate about {random.choice(INTERESTS)} and {random.choice(INTERESTS)}. Love exploring the city and meeting new people!",
                "university": random.choice(UNIVERSITIES),
                "degree": random.choice(DEGREES),
                "year": random.choice(YEARS),
                "interests": random.sample(INTERESTS, random.randint(4, 8)),
                "skills": {skill: random.choice(levels) for skill, levels in random.sample(list(SKILLS.items()), random.randint(3, 6))},
                "auto_invite_enabled": random.choice([True, False]),
                "preferred_radius": random.uniform(5.0, 30.0)
            }
            
            profile_result = make_api_call("update_user_interests/", 'POST', profile_data)
            
            if profile_result and profile_result.get('success'):
                credentials_file.write(f"Username: {username}\nPassword: {password}\nEmail: {email}\nFull Name: {first_name} {last_name}\nUniversity: {profile_data['university']}\nDegree: {profile_data['degree']}\nYear: {profile_data['year']}\nInterests: {', '.join(profile_data['interests'])}\n\n")
                
                created_users.append({
                    'username': username,
                    'password': password,
                    'profile': profile_data
                })
                
                print(f"✅ Created user {i+1}/{count}: {username}")
            else:
                print(f"⚠️ User {username} created but profile update failed")
            
            time.sleep(0.3)
        else:
            print(f"❌ Failed to create user {i+1}/{count}: {username}")
    
    credentials_file.close()
    print(f"📝 Credentials saved to production_credentials_comprehensive.txt")
    return created_users

def create_comprehensive_events(users, count=100):
    """Create comprehensive event base"""
    print(f"📚 Creating {count} comprehensive events...")
    
    created_events = []
    
    for i in range(count):
        host = random.choice(users)
        location = random.choice(list(BUENOS_AIRES_LOCATIONS.items()))
        
        # Create events across different time periods
        days_ahead = random.randint(1, 60)
        start_time = datetime.now() + timedelta(days=days_ahead, hours=random.randint(8, 22))
        end_time = start_time + timedelta(hours=random.randint(1, 6))
        
        event_titles = [
            f"Study Session - {location[0]}",
            f"Language Exchange - {location[0]}",
            f"Cultural Discussion - {location[0]}",
            f"Academic Workshop - {location[0]}",
            f"Group Study - {location[0]}",
            f"Networking Event - {location[0]}",
            f"Social Gathering - {location[0]}",
            f"Business Meeting - {location[0]}",
            f"Party Night - {location[0]}",
            f"Study Marathon - {location[0]}"
        ]
        
        event_data = {
            "title": random.choice(event_titles),
            "description": f"Join us for a {random.choice(['productive', 'fun', 'engaging', 'collaborative', 'exciting', 'educational'])} {random.choice(['study session', 'meeting', 'gathering', 'workshop', 'discussion'])} in {location[0]}. Perfect for international students looking to connect and learn together!",
            "latitude": location[1]['lat'],
            "longitude": location[1]['lng'],
            "time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "max_participants": random.randint(3, 15),
            "host": host['username'],
            "is_public": random.choice([True, False]),
            "event_type": random.choice(EVENT_TYPES),
            "auto_matching_enabled": random.choice([True, False]),
            "interest_tags": random.sample(INTERESTS, random.randint(2, 6))
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
        
        time.sleep(0.3)
    
    return created_events

def create_comprehensive_social_network(users):
    """Create comprehensive social network"""
    print("🤝 Creating comprehensive social network...")
    
    connections_created = 0
    
    for user in users:
        # Each user connects with 3-8 other users
        num_connections = random.randint(3, 8)
        other_users = [u for u in users if u['username'] != user['username']]
        selected_friends = random.sample(other_users, min(num_connections, len(other_users)))
        
        for friend in selected_friends:
            # Send friend request
            request_data = {
                "from_user": user['username'],
                "to_user": friend['username']
            }
            
            result = make_api_call("send_friend_request/", 'POST', request_data)
            
            if result and result.get('success'):
                # Randomly accept some requests (70% acceptance rate)
                if random.random() < 0.7:
                    accept_data = {
                        "from_user": friend['username'],
                        "to_user": user['username']
                    }
                    
                    accept_result = make_api_call("accept_friend_request/", 'POST', accept_data)
                    if accept_result and accept_result.get('success'):
                        connections_created += 1
            
            time.sleep(0.2)
    
    print(f"🤝 Created {connections_created} friend connections")

def create_comprehensive_event_interactions(users, events):
    """Create comprehensive event interactions"""
    print("💬 Creating comprehensive event interactions...")
    
    interactions_created = 0
    
    for event in events:
        # Random users interact with events
        num_interactions = random.randint(3, 10)
        selected_users = random.sample(users, min(num_interactions, len(users)))
        
        for user in selected_users:
            if user['username'] != event['host']:
                # RSVP to event
                rsvp_data = {
                    "username": user['username'],
                    "event_id": event['event_id']
                }
                
                rsvp_result = make_api_call("rsvp_study_event/", 'POST', rsvp_data)
                
                if rsvp_result and rsvp_result.get('success'):
                    interactions_created += 1
                    
                    # Add comments (30% chance)
                    if random.random() < 0.3:
                        comment_data = {
                            "username": user['username'],
                            "event_id": event['event_id'],
                            "comment": random.choice([
                                "Looking forward to this!",
                                "Great event idea!",
                                "Can't wait to meet everyone",
                                "Perfect timing for me",
                                "This sounds amazing!",
                                "Count me in!",
                                "Excited to join!",
                                "Great initiative!"
                            ])
                        }
                        
                        make_api_call("events/comment/", 'POST', comment_data)
                    
                    # Like the event (40% chance)
                    if random.random() < 0.4:
                        like_data = {
                            "username": user['username'],
                            "event_id": event['event_id']
                        }
                        
                        make_api_call("events/like/", 'POST', like_data)
                    
                    # Share the event (20% chance)
                    if random.random() < 0.2:
                        share_data = {
                            "username": user['username'],
                            "event_id": event['event_id']
                        }
                        
                        make_api_call("events/share/", 'POST', share_data)
                
                time.sleep(0.1)
    
    print(f"💬 Created {interactions_created} event interactions")

def create_comprehensive_reviews(users):
    """Create comprehensive user reviews"""
    print("⭐ Creating comprehensive user reviews...")
    
    reviews_created = 0
    
    for user in users:
        # Each user gets 2-5 reviews
        num_reviews = random.randint(2, 5)
        other_users = [u for u in users if u['username'] != user['username']]
        reviewers = random.sample(other_users, min(num_reviews, len(other_users)))
        
        for reviewer in reviewers:
            review_data = {
                "from_username": reviewer['username'],
                "to_username": user['username'],
                "rating": random.randint(3, 5),  # Mostly positive reviews
                "reference": random.choice([
                    "Great study partner! Very helpful and organized.",
                    "Excellent event host. Everything was well planned.",
                    "Friendly and knowledgeable. Would study with again!",
                    "Professional and punctual. Highly recommended.",
                    "Great communication and very reliable.",
                    "Amazing study session! Very productive.",
                    "Great organizer and friendly person.",
                    "Excellent communication and planning.",
                    "Would definitely study with again!",
                    "Very helpful and knowledgeable."
                ])
            }
            
            result = make_api_call("submit_user_rating/", 'POST', review_data)
            
            if result and result.get('success'):
                reviews_created += 1
            
            time.sleep(0.2)
    
    print(f"⭐ Created {reviews_created} user reviews")

def run_comprehensive_auto_matching(events):
    """Run comprehensive auto-matching"""
    print("🎯 Running comprehensive auto-matching...")
    
    matches_created = 0
    
    for event in events:
        if event['data']['auto_matching_enabled']:
            auto_match_data = {
                "event_id": event['event_id']
            }
            
            result = make_api_call("advanced_auto_match/", 'POST', auto_match_data)
            
            if result and result.get('success'):
                matches_created += 1
            
            time.sleep(0.3)
    
    print(f"🎯 Created {matches_created} auto-matches")

def main():
    """Main function to create comprehensive production data"""
    print("🚀 Creating comprehensive production data like local...")
    print(f"🌐 Target: {PRODUCTION_BASE_URL}")
    
    # Create comprehensive users
    users = create_comprehensive_users(50)
    
    if not users:
        print("❌ No users created, stopping...")
        return
    
    # Create comprehensive events
    events = create_comprehensive_events(users, 100)
    
    if not events:
        print("❌ No events created, stopping...")
        return
    
    # Create comprehensive social network
    create_comprehensive_social_network(users)
    
    # Create comprehensive event interactions
    create_comprehensive_event_interactions(users, events)
    
    # Create comprehensive reviews
    create_comprehensive_reviews(users)
    
    # Run comprehensive auto-matching
    run_comprehensive_auto_matching(events)
    
    print("\n🎉 Comprehensive production data creation complete!")
    print(f"✅ Created {len(users)} users")
    print(f"✅ Created {len(events)} events")
    print(f"✅ Created comprehensive social network")
    print(f"✅ Created comprehensive interactions and reviews")
    print(f"✅ Ran comprehensive auto-matching")
    print("\n📝 Login credentials saved to: production_credentials_comprehensive.txt")
    print("\n🔍 The iOS app should now show comprehensive data like it did locally!")

if __name__ == "__main__":
    main()
