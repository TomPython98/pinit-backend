#!/usr/bin/env python3
"""
Complete Profile and Social Data Generator
Creates users with complete profiles, social connections, and interactions
"""

import requests
import json
import random
import time
from datetime import datetime, timedelta
import math

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

# Enhanced data lists
FIRST_NAMES = ['Ana', 'Carlos', 'Maria', 'Diego', 'Sofia', 'Lucas', 'Valentina', 'Mateo', 'Isabella', 'Santiago', 'Camila', 'Sebastian', 'Lucia', 'Nicolas', 'Fernanda', 'Andres', 'Gabriela', 'Alejandro', 'Paula', 'Daniel', 'Emma', 'Liam', 'Olivia', 'Noah', 'Ava', 'William', 'Sophia', 'James', 'Charlotte', 'Benjamin']
LAST_NAMES = ['Garcia', 'Rodriguez', 'Martinez', 'Lopez', 'Gonzalez', 'Perez', 'Sanchez', 'Ramirez', 'Cruz', 'Flores', 'Herrera', 'Jimenez', 'Moreno', 'Alvarez', 'Ruiz', 'Diaz', 'Torres', 'Vargas', 'Ramos', 'Mendoza', 'Silva', 'Castro', 'Rivera', 'Morales', 'Gutierrez', 'Ortiz', 'Chavez', 'Reyes', 'Mendoza', 'Herrera']

UNIVERSITIES = [
    'Universidad de Buenos Aires (UBA)',
    'Universidad Torcuato di Tella',
    'Universidad de San Andrés',
    'Universidad del Salvador',
    'Universidad Católica Argentina',
    'Universidad Nacional de La Plata',
    'Universidad de Belgrano',
    'Universidad de Palermo',
    'Universidad de Buenos Aires - Facultad de Ciencias Exactas',
    'Universidad de Buenos Aires - Facultad de Ingeniería'
]

DEGREES = [
    'Computer Science', 'Business Administration', 'International Relations',
    'Economics', 'Psychology', 'Engineering', 'Medicine', 'Law',
    'Architecture', 'Marketing', 'Finance', 'Spanish Literature',
    'Mathematics', 'Physics', 'Chemistry', 'Biology', 'History',
    'Philosophy', 'Political Science', 'Sociology', 'Anthropology',
    'Data Science', 'Cybersecurity', 'Environmental Science', 'Journalism'
]

YEARS = ['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduate', 'PhD', 'Masters']

COUNTRIES = ['Argentina', 'Brazil', 'Chile', 'Colombia', 'Mexico', 'Spain', 'France', 'Germany', 'Italy', 'Portugal', 'Uruguay', 'Peru', 'Ecuador', 'Venezuela', 'Bolivia', 'Paraguay', 'United States', 'Canada', 'United Kingdom', 'Australia']

INTERESTS = [
    'Music', 'Sports', 'Art', 'Technology', 'Travel', 'Food', 'Photography',
    'Reading', 'Gaming', 'Fitness', 'Dancing', 'Movies', 'Languages',
    'Volunteering', 'Entrepreneurship', 'Research', 'Writing', 'Design',
    'Environment', 'Politics', 'Culture', 'Fashion', 'Cooking', 'Nature',
    'Programming', 'Data Analysis', 'Machine Learning', 'Sustainability',
    'Social Justice', 'Mental Health', 'Education', 'Innovation'
]

SKILLS = [
    'Leadership', 'Communication', 'Problem Solving', 'Teamwork', 'Creativity',
    'Analytical Thinking', 'Project Management', 'Public Speaking', 'Writing',
    'Research', 'Data Analysis', 'Programming', 'Design', 'Marketing',
    'Negotiation', 'Time Management', 'Critical Thinking', 'Adaptability',
    'Mentoring', 'Strategic Planning', 'Customer Service', 'Sales'
]

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
    'Villa Urquiza': {'lat': -34.5700, 'lng': -58.4800},
    'Nunez': {'lat': -34.5500, 'lng': -58.4600},
    'Colegiales': {'lat': -34.5800, 'lng': -58.4500},
    'Chacarita': {'lat': -34.5900, 'lng': -58.4400},
    'Almagro': {'lat': -34.6100, 'lng': -58.4200}
}

EVENT_TITLES = [
    'Study Session', 'Group Study', 'Language Exchange', 'Cultural Discussion',
    'Academic Workshop', 'Networking Event', 'Social Gathering', 'Study Group',
    'Research Meeting', 'Project Collaboration', 'Exam Preparation', 'Thesis Discussion',
    'Cultural Showcase', 'International Meetup', 'Study Buddy Session', 'Academic Seminar',
    'Hackathon', 'Case Study Analysis', 'Peer Review Session', 'Study Marathon'
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

used_coordinates = set()

def generate_unique_coordinates(base_location, radius_km=0.3):
    """Generate unique coordinates within a radius"""
    max_attempts = 50
    attempts = 0
    
    while attempts < max_attempts:
        angle = random.uniform(0, 2 * math.pi)
        distance = random.uniform(0, radius_km)
        
        lat_offset = (distance / 111.0) * math.cos(angle)
        lng_offset = (distance / (111.0 * math.cos(math.radians(base_location['lat'])))) * math.sin(angle)
        
        new_lat = base_location['lat'] + lat_offset
        new_lng = base_location['lng'] + lng_offset
        
        coord_key = (round(new_lat, 6), round(new_lng, 6))
        
        if coord_key not in used_coordinates:
            used_coordinates.add(coord_key)
            return {'lat': new_lat, 'lng': new_lng}
        
        attempts += 1
    
    # Fallback with small random offset
    coord_key = (round(base_location['lat'] + random.uniform(-0.001, 0.001), 6), 
                 round(base_location['lng'] + random.uniform(-0.001, 0.001), 6))
    used_coordinates.add(coord_key)
    return {'lat': coord_key[0], 'lng': coord_key[1]}

def create_complete_user():
    """Create a user with 100% complete profile"""
    first_name = random.choice(FIRST_NAMES)
    last_name = random.choice(LAST_NAMES)
    username = f"{first_name.lower()}_{last_name.lower()}_{random.randint(100, 999)}"
    
    # Generate comprehensive bio
    university = random.choice(UNIVERSITIES)
    degree = random.choice(DEGREES)
    year = random.choice(YEARS)
    country = random.choice(COUNTRIES)
    interests = random.sample(INTERESTS, random.randint(4, 8))
    skills = random.sample(SKILLS, random.randint(3, 6))
    
    bio_templates = [
        f"Hi! I'm {first_name}, a {year.lower()} student studying {degree.lower()} at {university}. I'm passionate about {', '.join(interests[:3])} and love connecting with fellow students who share similar interests. I'm always up for study sessions, cultural exchanges, and meaningful conversations!",
        f"Hello! I'm {first_name} from {country}, currently pursuing {degree.lower()} at {university}. As a {year.lower()} student, I'm deeply interested in {', '.join(interests[:3])} and enjoy collaborating on projects and study groups. Let's learn and grow together!",
        f"Hey there! I'm {first_name}, a {year.lower()} {degree.lower()} student at {university}. I'm originally from {country} and I'm passionate about {', '.join(interests[:3])}. I believe in the power of community and love meeting new people through shared academic interests!"
    ]
    
    user_data = {
        "username": username,
        "password": "password123",
        "first_name": first_name,
        "last_name": last_name,
        "email": f"{username}@example.com",
        "university": university,
        "degree": degree,
        "year": year,
        "country": country,
        "bio": random.choice(bio_templates),
        "interests": interests,
        "skills": skills,
        "auto_invite_preference": random.choice([True, False]),
        "preferred_radius": random.randint(2, 15)
    }
    
    return user_data

def create_enhanced_event(host_username):
    """Create an event with enhanced details"""
    location_name = random.choice(list(BUENOS_AIRES_LOCATIONS.keys()))
    base_location = BUENOS_AIRES_LOCATIONS[location_name]
    coordinates = generate_unique_coordinates(base_location)
    
    start_time = datetime.now() + timedelta(days=random.randint(1, 45), hours=random.randint(9, 19))
    end_time = start_time + timedelta(hours=random.randint(1, 4))
    
    event_type = random.choice(['study', 'cultural', 'academic', 'social', 'networking'])
    title = random.choice(EVENT_TITLES)
    
    # Enhanced description
    description_templates = [
        f"Join us for an engaging {title.lower()} in {location_name}! This is a perfect opportunity to connect with fellow students, share knowledge, and build lasting friendships. We'll focus on {', '.join(random.sample(INTERESTS, 2))} and create a collaborative learning environment.",
        f"Come participate in our {title.lower()} session in {location_name}. Whether you're looking to study, network, or simply meet new people, this event offers something for everyone. Let's learn together and make the most of our academic journey!",
        f"Don't miss this exciting {title.lower()} in {location_name}! We're bringing together students from various backgrounds to share experiences, learn from each other, and create meaningful connections. Perfect for anyone interested in {', '.join(random.sample(INTERESTS, 2))}."
    ]
    
    event_data = {
        "host": host_username,
        "title": f"{title} - {location_name}",
        "description": random.choice(description_templates),
        "latitude": coordinates['lat'],
        "longitude": coordinates['lng'],
        "time": start_time.isoformat(),
        "end_time": end_time.isoformat(),
        "max_participants": random.randint(5, 25),
        "event_type": event_type,
        "interest_tags": random.sample(INTERESTS, random.randint(3, 6)),
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

def create_social_network(users):
    """Create a comprehensive social network"""
    print("🤝 Creating comprehensive social network...")
    
    connections_created = 0
    invitations_sent = 0
    
    for i, user in enumerate(users):
        # Each user connects with 3-8 other users
        num_connections = random.randint(3, 8)
        other_users = [u for u in users if u != user]
        selected_friends = random.sample(other_users, min(num_connections, len(other_users)))
        
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
            
            time.sleep(0.1)
        
        # Accept some friend requests (simulate mutual connections)
        if i < len(users) - 1:
            num_acceptances = random.randint(2, 5)
            for _ in range(num_acceptances):
                # Simulate accepting a request from another user
                requester = random.choice([u for u in users if u != user])
                accept_data = {
                    "from_user": requester,
                    "to_user": user
                }
                
                result = make_request("accept_friend_request/", accept_data)
                if result and result.get('success'):
                    connections_created += 1
                    print(f"✅ Friend connection: {requester} <-> {user}")
                
                time.sleep(0.1)
    
    print(f"🤝 Created {connections_created} social connections")
    return connections_created

def create_event_ecosystem(users, events):
    """Create comprehensive event interactions"""
    print("💬 Creating comprehensive event ecosystem...")
    
    interactions_created = 0
    
    for event in events:
        event_id = event['event_id']
        host = event['host']
        
        # Get random participants (excluding host)
        other_users = [u for u in users if u != host]
        num_participants = random.randint(3, min(8, len(other_users)))
        participants = random.sample(other_users, num_participants)
        
        for user in participants:
            # RSVP to event
            rsvp_data = {"username": user, "event_id": event_id}
            result = make_request("rsvp_study_event/", rsvp_data)
            if result and result.get('success'):
                interactions_created += 1
                print(f"✅ RSVP: {user} -> {event['title']}")
            
            # Add comment (70% chance)
            if random.random() < 0.7:
                comment_data = {
                    "username": user,
                    "event_id": event_id,
                    "text": random.choice(COMMENTS)
                }
                result = make_request("events/comment/", comment_data)
                if result and result.get('success'):
                    interactions_created += 1
                    print(f"✅ Comment: {user} on {event['title']}")
            
            # Like event (60% chance)
            if random.random() < 0.6:
                like_data = {"username": user, "event_id": event_id}
                result = make_request("events/like/", like_data)
                if result and result.get('success'):
                    interactions_created += 1
                    print(f"✅ Like: {user} -> {event['title']}")
            
            # Share event (30% chance)
            if random.random() < 0.3:
                share_data = {
                    "username": user,
                    "event_id": event_id,
                    "shared_platform": random.choice(['whatsapp', 'facebook', 'twitter', 'instagram', 'linkedin'])
                }
                result = make_request("events/share/", share_data)
                if result and result.get('success'):
                    interactions_created += 1
                    print(f"✅ Share: {user} -> {event['title']}")
            
            time.sleep(0.1)
    
    print(f"💬 Created {interactions_created} event interactions")
    return interactions_created

def main():
    """Main data generation function"""
    print("🚀 Complete Profile and Social Data Generation")
    print("=" * 60)
    
    # Create users with complete profiles
    print("👥 Creating users with complete profiles...")
    users = []
    for i in range(30):  # Create 30 users
        user_data = create_complete_user()
        result = make_request("register/", user_data)
        if result and result.get('success'):
            users.append(user_data['username'])
            print(f"✅ Created user: {user_data['username']} ({user_data['first_name']} {user_data['last_name']})")
        else:
            print(f"❌ Failed to create user: {user_data['username']}")
        time.sleep(0.3)
    
    print(f"👥 Created {len(users)} users with complete profiles")
    
    # Create events
    print("\n📅 Creating events...")
    events = []
    for i in range(80):  # Create 80 events
        if not users:
            break
            
        host = random.choice(users)
        event_data = create_enhanced_event(host)
        result = make_request("create_study_event/", event_data)
        
        if result and result.get('success'):
            events.append({
                'event_id': result.get('event_id'),
                'title': event_data['title'],
                'host': host
            })
            print(f"✅ Created event: {event_data['title']} at ({event_data['latitude']:.6f}, {event_data['longitude']:.6f})")
        else:
            print(f"❌ Failed to create event: {event_data['title']}")
        time.sleep(0.3)
    
    print(f"📅 Created {len(events)} events")
    
    # Create social network
    social_connections = create_social_network(users)
    
    # Create event ecosystem
    event_interactions = create_event_ecosystem(users, events)
    
    print("\n🎉 Complete data generation finished!")
    print("=" * 60)
    print(f"📊 FINAL SUMMARY:")
    print(f"   - Users: {len(users)} (100% complete profiles)")
    print(f"   - Events: {len(events)} (unique coordinates)")
    print(f"   - Social Connections: {social_connections}")
    print(f"   - Event Interactions: {event_interactions}")
    print(f"   - Unique Coordinates: {len(used_coordinates)}")
    print(f"\n🔑 SAMPLE LOGIN CREDENTIALS (Password: password123):")
    for i, user in enumerate(users[:10]):
        print(f"   {i+1}. {user}")
    
    print(f"\n✅ All users have complete profiles with:")
    print(f"   - Full personal information")
    print(f"   - University and academic details")
    print(f"   - Comprehensive bios")
    print(f"   - Multiple interests and skills")
    print(f"   - Social connections")
    print(f"   - Event participation")

if __name__ == "__main__":
    main()
