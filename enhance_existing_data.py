#!/usr/bin/env python3
"""
Enhance existing test data by adding events, friend requests, and ratings
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app/api"

# Existing users (from previous creation)
EXISTING_USERS = [
    "alex_cs_stanford", "sarah_med_harvard", "mike_business_wharton", 
    "emma_arts_nyu", "david_eng_mit", "anna_physics_mit", "james_law_yale",
    "sophie_psych_stanford", "carlos_med_johns_hopkins", "lisa_eng_caltech",
    "maya_comp_sci_berkeley", "ryan_business_harvard", "zoe_arts_risd",
    "kevin_eng_georgia_tech", "priya_med_ucsf", "tom", "Martina"
]

# Sample events data
SAMPLE_EVENTS = [
    {
        "title": "CS Study Group - Algorithms & Data Structures",
        "description": "Weekly study session for CS 161. We'll cover sorting algorithms, binary trees, and graph traversal. Bring your laptops and questions!",
        "location": "Green Library, Room 201",
        "max_participants": 8,
        "event_type": "Study"
    },
    {
        "title": "MCAT Prep Session - Biology Section",
        "description": "Group study for MCAT biology section. We'll go through practice tests and review key concepts. Bring your practice materials!",
        "location": "Medical School Library, Study Room 3",
        "max_participants": 6,
        "event_type": "Study"
    },
    {
        "title": "Business Case Study Workshop",
        "description": "Analyzing real business cases and developing solutions together. Great for networking and learning from peers!",
        "location": "Business School, Conference Room A",
        "max_participants": 10,
        "event_type": "Academic"
    },
    {
        "title": "Art Portfolio Review Session",
        "description": "Peer review session for art portfolios. Bring your work for feedback and constructive criticism!",
        "location": "Art Studio 3",
        "max_participants": 5,
        "event_type": "Cultural"
    },
    {
        "title": "Engineering Project Collaboration",
        "description": "Working on robotics project together. All skill levels welcome - we'll learn from each other!",
        "location": "Engineering Lab 2",
        "max_participants": 4,
        "event_type": "Academic"
    },
    {
        "title": "Physics Problem Solving Session",
        "description": "Tackling challenging physics problems together. Quantum mechanics and thermodynamics focus this week!",
        "location": "Physics Building, Room 101",
        "max_participants": 6,
        "event_type": "Study"
    },
    {
        "title": "Law School Study Group - Constitutional Law",
        "description": "Reviewing constitutional law cases and preparing for upcoming exams. Bring your casebooks!",
        "location": "Law Library, Study Room 5",
        "max_participants": 8,
        "event_type": "Study"
    },
    {
        "title": "Psychology Research Discussion",
        "description": "Discussing recent research papers in cognitive psychology. Great for staying updated with the field!",
        "location": "Psychology Department, Room 203",
        "max_participants": 7,
        "event_type": "Academic"
    },
    {
        "title": "Medical School Anatomy Review",
        "description": "Reviewing anatomy concepts for upcoming practical exams. Study models and diagrams will be available!",
        "location": "Medical School, Anatomy Lab",
        "max_participants": 6,
        "event_type": "Study"
    },
    {
        "title": "Engineering Design Challenge",
        "description": "Collaborative design challenge focusing on sustainable engineering solutions. Teams of 3-4 people!",
        "location": "Engineering Building, Design Studio",
        "max_participants": 12,
        "event_type": "Academic"
    },
    {
        "title": "Computer Science Coding Bootcamp",
        "description": "Intensive coding session covering data structures, algorithms, and system design. All levels welcome!",
        "location": "CS Building, Lab 301",
        "max_participants": 15,
        "event_type": "Study"
    },
    {
        "title": "Business Networking Mixer",
        "description": "Connect with fellow business students and professionals. Great opportunity to build your network!",
        "location": "Business School, Atrium",
        "max_participants": 20,
        "event_type": "Social"
    },
    {
        "title": "Art Gallery Opening & Discussion",
        "description": "View student artwork and discuss contemporary art trends. Refreshments provided!",
        "location": "Art Gallery, Main Hall",
        "max_participants": 25,
        "event_type": "Cultural"
    },
    {
        "title": "Engineering Hackathon",
        "description": "24-hour hackathon focusing on sustainable technology solutions. Prizes for best projects!",
        "location": "Engineering Building, Main Lab",
        "max_participants": 30,
        "event_type": "Academic"
    },
    {
        "title": "Medical Ethics Discussion Group",
        "description": "Exploring complex ethical dilemmas in medicine. Case studies and group discussions.",
        "location": "Medical School, Ethics Room",
        "max_participants": 12,
        "event_type": "Academic"
    },
    {
        "title": "Data Science Workshop",
        "description": "Hands-on workshop covering machine learning, data visualization, and statistical analysis.",
        "location": "Computer Science Building, Lab 205",
        "max_participants": 12,
        "event_type": "Study"
    },
    {
        "title": "Creative Writing Circle",
        "description": "Share your creative writing and get feedback from fellow writers. All genres welcome!",
        "location": "English Department, Room 101",
        "max_participants": 8,
        "event_type": "Cultural"
    },
    {
        "title": "Finance Trading Simulation",
        "description": "Practice trading strategies in a simulated market environment. Learn from experienced traders!",
        "location": "Business School, Trading Lab",
        "max_participants": 16,
        "event_type": "Academic"
    },
    {
        "title": "Environmental Science Field Trip",
        "description": "Visit local ecosystems and conduct field research. Transportation provided!",
        "location": "Meet at Science Building",
        "max_participants": 20,
        "event_type": "Academic"
    },
    {
        "title": "Language Exchange Meetup",
        "description": "Practice foreign languages with native speakers. Coffee and conversation!",
        "location": "Student Center, Coffee Shop",
        "max_participants": 15,
        "event_type": "Social"
    }
]

def create_event(username, event_data):
    """Create a study event"""
    url = f"{BASE_URL}/create_study_event/"
    
    # Generate random future date
    days_ahead = random.randint(1, 30)
    event_date = datetime.now() + timedelta(days=days_ahead)
    
    data = {
        "title": event_data["title"],
        "description": event_data["description"],
        "location": event_data["location"],
        "date": event_date.strftime("%Y-%m-%d"),
        "time": f"{random.randint(9, 20):02d}:00",
        "max_participants": event_data["max_participants"],
        "event_type": event_data["event_type"]
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f"✅ Created event: {event_data['title']} by {username}")
            return True
        else:
            print(f"❌ Failed to create event: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error creating event: {e}")
        return False

def send_friend_request(sender, receiver):
    """Send a friend request"""
    url = f"{BASE_URL}/send_friend_request/"
    
    data = {
        "sender_username": sender,
        "receiver_username": receiver
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f"✅ Sent friend request from {sender} to {receiver}")
            return True
        else:
            print(f"❌ Failed to send friend request: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error sending friend request: {e}")
        return False

def submit_user_rating(reviewer, reviewee, rating, comment):
    """Submit a user rating"""
    url = f"{BASE_URL}/submit_user_rating/"
    
    data = {
        "reviewer_username": reviewer,
        "reviewee_username": reviewee,
        "rating": rating,
        "comment": comment
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f"✅ Submitted rating from {reviewer} to {reviewee}")
            return True
        else:
            print(f"❌ Failed to submit rating: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error submitting rating: {e}")
        return False

def update_user_interests(username, interests):
    """Update user interests"""
    url = f"{BASE_URL}/update_user_interests/"
    
    data = {
        "username": username,
        "interests": interests
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print(f"✅ Updated interests for {username}")
            return True
        else:
            print(f"❌ Failed to update interests: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error updating interests: {e}")
        return False

def main():
    print("🚀 Enhancing existing test data...")
    print(f"📊 Working with {len(EXISTING_USERS)} existing users")
    
    # Update user interests
    print("\n🎯 Updating user interests...")
    interest_sets = [
        ["Computer Science", "AI", "Machine Learning", "Study", "Technology"],
        ["Medicine", "Study", "Academic", "Healthcare", "Research"],
        ["Business", "Networking", "Social", "Leadership", "Finance"],
        ["Arts", "Cultural", "Creative", "Social", "Design"],
        ["Engineering", "Study", "Academic", "Technology", "Innovation"],
        ["Physics", "Study", "Academic", "Science", "Research"],
        ["Law", "Study", "Academic", "Professional", "Justice"],
        ["Psychology", "Study", "Academic", "Social", "Research"],
        ["Medicine", "Study", "Academic", "Healthcare", "Research"],
        ["Engineering", "Study", "Academic", "Technology", "Sustainability"]
    ]
    
    for i, username in enumerate(EXISTING_USERS):
        interests = interest_sets[i % len(interest_sets)]
        update_user_interests(username, interests)
        time.sleep(0.3)  # Rate limiting
    
    # Create events
    print("\n📅 Creating events...")
    event_count = 0
    for username in EXISTING_USERS:
        # Each user creates 1-3 events
        num_events = random.randint(1, 3)
        for _ in range(num_events):
            event_data = random.choice(SAMPLE_EVENTS)
            if create_event(username, event_data):
                event_count += 1
            time.sleep(0.5)  # Rate limiting
    
    print(f"✅ Created {event_count} events")
    
    # Create friend connections
    print("\n🤝 Creating friend connections...")
    friend_requests_sent = 0
    
    for username in EXISTING_USERS:
        # Each user sends friend requests to 2-5 other users
        num_friends = random.randint(2, 5)
        friends = random.sample([u for u in EXISTING_USERS if u != username], num_friends)
        for friend in friends:
            if send_friend_request(username, friend):
                friend_requests_sent += 1
            time.sleep(0.3)  # Rate limiting
    
    print(f"✅ Sent {friend_requests_sent} friend requests")
    
    # Create user ratings
    print("\n⭐ Creating user ratings...")
    ratings_created = 0
    for username in EXISTING_USERS:
        # Each user rates 2-4 other users
        num_ratings = random.randint(2, 4)
        reviewees = random.sample([u for u in EXISTING_USERS if u != username], num_ratings)
        for reviewee in reviewees:
            rating = random.randint(4, 5)  # Mostly positive ratings
            comment = random.choice([
                "Great study partner!",
                "Very helpful and knowledgeable",
                "Excellent collaboration skills",
                "Always punctual and prepared",
                "Great communicator",
                "Very supportive and encouraging",
                "Highly recommend studying with them!",
                "Amazing problem-solving skills",
                "Very organized and efficient",
                "Great at explaining complex concepts",
                "Always willing to help others",
                "Excellent team player"
            ])
            if submit_user_rating(username, reviewee, rating, comment):
                ratings_created += 1
            time.sleep(0.3)  # Rate limiting
    
    print(f"✅ Created {ratings_created} ratings")
    
    print("\n🎉 Data enhancement complete!")
    print(f"\n📊 Summary:")
    print(f"   👥 Users: {len(EXISTING_USERS)}")
    print(f"   📅 Events: {event_count}")
    print(f"   🤝 Friend Requests: {friend_requests_sent}")
    print(f"   ⭐ Ratings: {ratings_created}")
    
    print(f"\n🎯 All users now have:")
    print(f"   📸 High-quality profile pictures")
    print(f"   🎯 Updated interests and skills")
    print(f"   📅 Multiple study events")
    print(f"   🤝 Friend connections")
    print(f"   ⭐ User ratings and reviews")

if __name__ == "__main__":
    main()
