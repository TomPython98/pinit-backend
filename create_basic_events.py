#!/usr/bin/env python3
"""
Create basic events for existing users
"""

import requests
import json
import random
from datetime import datetime, timedelta

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app/api"

# Existing users
USERS = [
    "alex_cs_stanford", "sarah_med_harvard", "mike_business_wharton", 
    "emma_arts_nyu", "david_eng_mit", "anna_physics_mit", "james_law_yale",
    "sophie_psych_stanford", "carlos_med_johns_hopkins", "lisa_eng_caltech",
    "maya_comp_sci_berkeley", "ryan_business_harvard", "zoe_arts_risd",
    "kevin_eng_georgia_tech", "priya_med_ucsf"
]

# Sample events
EVENTS = [
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

def main():
    print("🚀 Creating events for existing users...")
    
    events_created = 0
    
    # Each user creates 1-2 events
    for username in USERS:
        num_events = random.randint(1, 2)
        for _ in range(num_events):
            event_data = random.choice(EVENTS)
            if create_event(username, event_data):
                events_created += 1
    
    print(f"\n✅ Successfully created {events_created} events")
    print(f"📊 Average events per user: {events_created / len(USERS):.1f}")

if __name__ == "__main__":
    main()
