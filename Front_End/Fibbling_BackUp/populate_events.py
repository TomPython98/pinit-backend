#!/usr/bin/env python3
"""
Fibbling App Event Population Script
-----------------------------------
This script generates realistic study events and social activities in Vienna,
creating a mix of auto-matched events, direct invites, and friend connections.
"""

import requests
import json
import random
import datetime
import time
from typing import List, Dict, Any, Tuple

# Base URL for API
BASE_URL = "http://127.0.0.1:8000/api/"

# Vienna university and study locations with coordinates
VIENNA_LOCATIONS = [
    {
        "name": "University of Vienna",
        "description": "Main campus of the University of Vienna",
        "lat": 48.213,
        "lng": 16.360,
        "vicinity": [
            "University Library", "Main Building", "NIG Building", "Faculty of Computer Science"
        ]
    },
    {
        "name": "Vienna University of Technology (TU Wien)",
        "description": "Technical university campus",
        "lat": 48.199,
        "lng": 16.368,
        "vicinity": [
            "Main Building", "Informatics Building", "Library", "FH Building", "Karlsplatz"
        ]
    },
    {
        "name": "Vienna University of Economics and Business (WU)",
        "description": "Modern campus near Prater",
        "lat": 48.213,
        "lng": 16.408,
        "vicinity": [
            "Learning Center", "Library & Learning Center", "Teaching Center", "Executive Academy"
        ]
    },
    {
        "name": "Medical University of Vienna",
        "description": "Medical studies campus",
        "lat": 48.219,
        "lng": 16.346,
        "vicinity": [
            "General Hospital", "MedUni Campus", "Research Centers", "Lecture Halls"
        ]
    },
    {
        "name": "Cafe Central",
        "description": "Historic Viennese coffee house, popular for meetings",
        "lat": 48.211,
        "lng": 16.365,
        "vicinity": ["Main Hall", "Reading Area", "Quiet Corner"]
    },
    {
        "name": "Museumsquartier",
        "description": "Cultural area with many study spots",
        "lat": 48.203,
        "lng": 16.358,
        "vicinity": ["Main Courtyard", "Leopold Museum", "MUMOK", "Cafe Leopold"]
    },
    {
        "name": "Stadtpark",
        "description": "City park - good for outdoor study groups",
        "lat": 48.206,
        "lng": 16.380,
        "vicinity": ["Main Lawn", "Near the Pond", "Under the Trees", "Pavilion"]
    },
    {
        "name": "Austrian National Library",
        "description": "Historic library with study spaces",
        "lat": 48.206,
        "lng": 16.367,
        "vicinity": ["Main Reading Room", "Reference Section", "Quiet Study Area"]
    }
]

# List of realistic usernames (expand as needed)
USERS = [
    {"username": "vienna_student", "password": "testpass123", "interests": ["programming", "machine learning", "data science", "mathematics"]},
    {"username": "med_student", "password": "testpass123", "interests": ["medicine", "biology", "anatomy", "chemistry", "research"]},
    {"username": "art_history", "password": "testpass123", "interests": ["art", "history", "museum", "architecture", "culture"]},
    {"username": "tech_geek", "password": "testpass123", "interests": ["programming", "computer science", "ai", "technology", "software"]},
    {"username": "math_wizard", "password": "testpass123", "interests": ["mathematics", "statistics", "probability", "algebra", "calculus"]},
    {"username": "language_lover", "password": "testpass123", "interests": ["languages", "linguistics", "german", "english", "communication"]},
    {"username": "business_major", "password": "testpass123", "interests": ["business", "economics", "finance", "marketing", "entrepreneurship"]},
    {"username": "psych_student", "password": "testpass123", "interests": ["psychology", "social sciences", "mental health", "cognition", "research"]},
    {"username": "law_student", "password": "testpass123", "interests": ["law", "politics", "international relations", "human rights", "criminal law"]},
    {"username": "bio_researcher", "password": "testpass123", "interests": ["biology", "genetics", "molecular biology", "ecology", "research"]}
]

# Study event topics with relevant tags
STUDY_TOPICS = [
    {
        "title": "Python Programming Workshop",
        "description": "Collaborative coding session focusing on Python fundamentals and data structures. Bring your laptop!",
        "tags": ["python", "programming", "computer science", "coding", "software development"],
        "event_type": "study"
    },
    {
        "title": "Machine Learning Study Group",
        "description": "We'll be diving into neural networks and discussing the latest papers in machine learning research.",
        "tags": ["machine learning", "ai", "neural networks", "data science", "algorithms"],
        "event_type": "study"
    },
    {
        "title": "Medical School Exam Prep",
        "description": "Group study session for upcoming anatomy exams. We'll focus on the cardiovascular system.",
        "tags": ["medicine", "anatomy", "medical school", "exam prep", "healthcare"],
        "event_type": "study"
    },
    {
        "title": "German Language Exchange",
        "description": "Practice your German conversation skills. All levels welcome!",
        "tags": ["german", "languages", "linguistics", "conversation", "language learning"],
        "event_type": "study"
    },
    {
        "title": "Business Case Analysis",
        "description": "Working through Harvard Business School cases with a focus on strategy and innovation.",
        "tags": ["business", "management", "strategy", "case study", "entrepreneurship"],
        "event_type": "business"
    },
    {
        "title": "Organic Chemistry Study Session",
        "description": "Reviewing reaction mechanisms and preparing for the mid-term exam.",
        "tags": ["chemistry", "organic chemistry", "science", "molecular structures", "reactions"],
        "event_type": "study"
    },
    {
        "title": "Philosophy Reading Group",
        "description": "Discussing Kant's 'Critique of Pure Reason' - chapters 3-4 this week.",
        "tags": ["philosophy", "literature", "critical thinking", "reading", "ethics"],
        "event_type": "study"
    },
    {
        "title": "Mathematics Problem Solving",
        "description": "Working through challenging calculus and linear algebra problems together.",
        "tags": ["mathematics", "calculus", "linear algebra", "problem solving", "equations"],
        "event_type": "study"
    },
    {
        "title": "Art History Research Group",
        "description": "Collaborative session on Renaissance art techniques and iconography.",
        "tags": ["art history", "renaissance", "art", "history", "culture"],
        "event_type": "study"
    },
    {
        "title": "Law School Moot Court Prep",
        "description": "Practice arguments and case preparation for upcoming moot court competition.",
        "tags": ["law", "moot court", "legal studies", "debate", "case law"],
        "event_type": "study"
    },
    {
        "title": "Economics Study Group",
        "description": "Reviewing macroeconomic models and current economic policies.",
        "tags": ["economics", "finance", "macro", "policy", "models"],
        "event_type": "study"
    },
    {
        "title": "AI Ethics Discussion",
        "description": "Debate on ethical implications of artificial intelligence in society.",
        "tags": ["ai", "ethics", "technology", "philosophy", "society"],
        "event_type": "study"
    },
    {
        "title": "Psychology Research Methods",
        "description": "Session focused on experimental design and statistical analysis for psychology studies.",
        "tags": ["psychology", "research methods", "statistics", "experimental design", "social science"],
        "event_type": "study"
    },
    {
        "title": "Startup Networking Mixer",
        "description": "Connect with fellow entrepreneurs and discuss your business ideas!",
        "tags": ["entrepreneurship", "networking", "business", "startups", "innovation"],
        "event_type": "business"
    },
    {
        "title": "End-of-Term Celebration",
        "description": "Let's celebrate the end of exams with food, drinks, and music!",
        "tags": ["celebration", "social", "party", "student life", "networking"],
        "event_type": "party"
    }
]

# API helper functions
def create_user(username: str, password: str, interests: List[str]) -> bool:
    """Create a new user with given interests"""
    url = f"{BASE_URL}register/"
    data = {
        "username": username,
        "password": password,
        "interests": interests
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code in (200, 201):
            print(f"✅ Created user: {username}")
            return True
        else:
            print(f"⚠️ User likely exists already: {username} - Status: {response.status_code}")
            return True  # Consider existing users a success
    except Exception as e:
        print(f"❌ Failed to create user {username}: {str(e)}")
        return False

def login_user(username: str, password: str) -> bool:
    """Login the user - returns success flag since we don't use tokens"""
    url = f"{BASE_URL}login/"
    data = {
        "username": username,
        "password": password
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            resp_data = response.json()
            if resp_data.get("success", False):
                print(f"✅ Logged in as: {username}")
                return True
        print(f"⚠️ Login failed for {username} - Status: {response.status_code}")
        try:
            print(f"Response: {response.json()}")
        except:
            print(f"Response: {response.text}")
        return False
    except Exception as e:
        print(f"❌ Login error for {username}: {str(e)}")
        return False

def create_event(username: str, event_data: Dict[str, Any]) -> Tuple[bool, str]:
    """Create a new event and return success status and event ID"""
    url = f"{BASE_URL}create_study_event/"
    # No token needed
    
    try:
        response = requests.post(url, json=event_data)
        if response.status_code in (200, 201):
            resp_data = response.json()
            event_id = resp_data.get("event_id", "")
            print(f"✅ Created event: {event_data['title']} - ID: {event_id}")
            return True, event_id
        else:
            print(f"⚠️ Failed to create event: {event_data['title']} - Status: {response.status_code}")
            try:
                print(f"Response: {response.json()}")
            except:
                print(f"Response: {response.text}")
            return False, ""
    except Exception as e:
        print(f"❌ Error creating event {event_data['title']}: {str(e)}")
        return False, ""

def rsvp_to_event(username: str, event_id: str) -> bool:
    """RSVP to an event"""
    url = f"{BASE_URL}rsvp_study_event/"
    # No token needed
    data = {
        "username": username,
        "event_id": event_id
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code in (200, 201):
            print(f"✅ User {username} RSVPed to event {event_id}")
            return True
        else:
            print(f"⚠️ Failed RSVP: {username} to event {event_id} - Status: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error RSVPing {username} to {event_id}: {str(e)}")
        return False

def generate_random_time(min_days=1, max_days=14, 
                         min_hour=9, max_hour=20,
                         min_duration=1, max_duration=3):
    """Generate a random start and end time for an event"""
    days_ahead = random.randint(min_days, max_days)
    hour = random.randint(min_hour, max_hour)
    minute = random.choice([0, 15, 30, 45])
    
    start_date = datetime.datetime.now() + datetime.timedelta(days=days_ahead)
    start_date = start_date.replace(hour=hour, minute=minute, second=0, microsecond=0)
    
    duration_hours = random.randint(min_duration, max_duration)
    end_date = start_date + datetime.timedelta(hours=duration_hours)
    
    # Format dates for API
    iso_format = "%Y-%m-%dT%H:%M:%S.%fZ"
    return start_date.strftime(iso_format), end_date.strftime(iso_format)

def get_random_location():
    """Get a random Vienna location with slight coordinate variation"""
    location = random.choice(VIENNA_LOCATIONS)
    vicinity = random.choice(location["vicinity"]) if location["vicinity"] else ""
    
    # Add slight randomness to coordinates (±0.003 degrees, approx 100-200m)
    lat_variation = random.uniform(-0.003, 0.003)
    lng_variation = random.uniform(-0.003, 0.003)
    
    location_name = f"{location['name']} - {vicinity}" if vicinity else location["name"]
    
    return {
        "name": location_name,
        "lat": location["lat"] + lat_variation,
        "lng": location["lng"] + lng_variation,
        "description": location["description"]
    }

def generate_event_data(host_username: str, topic: Dict[str, Any], 
                        auto_matching: bool = False, invited_friends: List[str] = None):
    """Generate complete event data ready for API submission"""
    location = get_random_location()
    start_time, end_time = generate_random_time()
    
    is_public = random.random() > 0.2  # 80% chance of being public
    invited_friends = invited_friends or []
    
    event_data = {
        "host": host_username,
        "title": topic["title"],
        "description": f"{topic['description']} Location: {location['name']}",
        "latitude": location["lat"],
        "longitude": location["lng"],
        "time": start_time,
        "end_time": end_time,
        "is_public": is_public,
        "invited_friends": invited_friends,
        "attendees": [host_username],  # Host is automatically attending
        "event_type": topic["event_type"],
        "interest_tags": topic["tags"][:5]  # Use up to 5 tags
    }
    
    if auto_matching:
        event_data["auto_matching_enabled"] = True
        event_data["max_participants"] = random.randint(5, 15)
        event_data["match_threshold"] = 1  # Make matching easier
    
    return event_data

# Main execution script
def main():
    """Main function to populate the application with events"""
    print("🚀 Starting Fibbling app population script")
    print("==========================================")
    
    # Step 1: Create/ensure users exist
    print("\n📝 Creating users...")
    for user in USERS:
        create_user(user["username"], user["password"], user["interests"])
    
    # Step 2: Create events with different patterns
    print("\n📅 Creating events...")
    event_ids = []
    
    for i, user in enumerate(USERS):
        # Login as this user
        login_success = login_user(user["username"], user["password"])
        if not login_success:
            continue
            
        # Each user creates 1-3 events
        for _ in range(random.randint(1, 3)):
            # Pick a topic that matches at least one of the user's interests
            matching_topics = [t for t in STUDY_TOPICS 
                             if any(interest in t["tags"] for interest in user["interests"])]
            topic = random.choice(matching_topics if matching_topics else STUDY_TOPICS)
            
            # Decide if this will be auto-matched
            auto_matching = random.random() > 0.3  # 70% chance of auto-matching
            
            # For some events, add direct invites
            invited_friends = []
            if random.random() > 0.5:  # 50% chance of inviting friends
                # Invite 1-3 other random users
                potential_invitees = [u["username"] for u in USERS if u["username"] != user["username"]]
                num_invites = min(len(potential_invitees), random.randint(1, 3))
                invited_friends = random.sample(potential_invitees, num_invites)
            
            # Generate and create the event
            event_data = generate_event_data(
                user["username"], 
                topic,
                auto_matching=auto_matching,
                invited_friends=invited_friends
            )
            
            success, event_id = create_event(user["username"], event_data)
            if success and event_id:
                event_ids.append({
                    "id": event_id,
                    "title": event_data["title"],
                    "host": user["username"]
                })
            
            # Add some delay between events
            time.sleep(0.5)
    
    # Step 3: Have users RSVP to events they didn't create
    print("\n🔔 Creating RSVPs...")
    for user in USERS:
        # Login as this user
        login_success = login_user(user["username"], user["password"])
        if not login_success:
            continue
            
        # Find events this user didn't create (excluding their own events)
        other_events = [e for e in event_ids if e["host"] != user["username"]]
        
        # RSVP to 0-3 random events
        if other_events:
            num_rsvps = min(len(other_events), random.randint(0, 3))
            for event in random.sample(other_events, num_rsvps):
                rsvp_to_event(user["username"], event["id"])
                # Small delay
                time.sleep(0.3)
    
    print("\n✅ Event population complete!")
    print(f"Created {len(event_ids)} events with a mix of auto-matching and direct invites")
    print("Check your Fibbling app to see the new events")

if __name__ == "__main__":
    main()
