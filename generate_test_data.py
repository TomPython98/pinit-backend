#!/usr/bin/env python3
"""
Generate test data for PinIt app
Creates test users, events, and sample images for testing
"""

import requests
import json
import random
import string
from datetime import datetime, timedelta
import base64
import io
from PIL import Image, ImageDraw, ImageFont
import os

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app/api"

# Test user data
TEST_USERS = [
    {
        "username": "alex_student",
        "password": "testpass123",
        "full_name": "Alex Johnson",
        "university": "Stanford University",
        "degree": "Computer Science",
        "year": "Junior",
        "bio": "CS student passionate about AI and machine learning. Love studying with others!",
        "interests": ["Computer Science", "AI", "Study", "Technology"],
        "skills": {"Python": "Advanced", "JavaScript": "Intermediate", "Machine Learning": "Beginner"}
    },
    {
        "username": "sarah_med",
        "password": "testpass123",
        "full_name": "Sarah Chen",
        "university": "Harvard Medical School",
        "degree": "Medicine",
        "year": "Senior",
        "bio": "Pre-med student focused on cardiology. Looking for study partners for MCAT prep!",
        "interests": ["Medicine", "Study", "Academic", "Healthcare"],
        "skills": {"Biology": "Advanced", "Chemistry": "Advanced", "Anatomy": "Intermediate"}
    },
    {
        "username": "mike_business",
        "password": "testpass123",
        "full_name": "Mike Rodriguez",
        "university": "Wharton School",
        "degree": "Business Administration",
        "year": "Graduate",
        "bio": "MBA student specializing in entrepreneurship. Always up for networking!",
        "interests": ["Business", "Networking", "Social", "Leadership"],
        "skills": {"Finance": "Advanced", "Marketing": "Intermediate", "Management": "Advanced"}
    },
    {
        "username": "emma_arts",
        "password": "testpass123",
        "full_name": "Emma Wilson",
        "university": "NYU Tisch",
        "degree": "Fine Arts",
        "year": "Sophomore",
        "bio": "Art student exploring digital media and traditional painting. Creative study sessions welcome!",
        "interests": ["Arts", "Cultural", "Creative", "Social"],
        "skills": {"Painting": "Advanced", "Digital Art": "Intermediate", "Photography": "Beginner"}
    },
    {
        "username": "david_engineering",
        "password": "testpass123",
        "full_name": "David Kim",
        "university": "MIT",
        "degree": "Mechanical Engineering",
        "year": "Junior",
        "bio": "Engineering student working on robotics projects. Love collaborative problem solving!",
        "interests": ["Engineering", "Study", "Academic", "Technology"],
        "skills": {"CAD": "Advanced", "Robotics": "Intermediate", "Mathematics": "Advanced"}
    }
]

# Sample events data
SAMPLE_EVENTS = [
    {
        "title": "CS Study Group - Algorithms",
        "description": "Weekly study session for CS 161. We'll cover sorting algorithms and data structures.",
        "location": "Green Library, Room 201",
        "max_participants": 8,
        "event_type": "Study"
    },
    {
        "title": "MCAT Prep Session",
        "description": "Group study for MCAT biology section. Bring your practice tests!",
        "location": "Medical School Library",
        "max_participants": 6,
        "event_type": "Study"
    },
    {
        "title": "Business Case Study Workshop",
        "description": "Analyzing real business cases and developing solutions together.",
        "location": "Business School, Conference Room A",
        "max_participants": 10,
        "event_type": "Academic"
    },
    {
        "title": "Art Portfolio Review",
        "description": "Peer review session for art portfolios. Bring your work for feedback!",
        "location": "Art Studio 3",
        "max_participants": 5,
        "event_type": "Cultural"
    },
    {
        "title": "Engineering Project Collaboration",
        "description": "Working on robotics project together. All skill levels welcome!",
        "location": "Engineering Lab 2",
        "max_participants": 4,
        "event_type": "Academic"
    }
]

def generate_profile_picture(username, full_name):
    """Generate a simple profile picture with initials"""
    # Create a 200x200 image with a random background color
    colors = [
        (52, 152, 219),   # Blue
        (46, 204, 113),   # Green
        (155, 89, 182),   # Purple
        (241, 196, 15),   # Yellow
        (230, 126, 34),   # Orange
        (231, 76, 60),    # Red
    ]
    bg_color = random.choice(colors)
    
    img = Image.new('RGB', (200, 200), bg_color)
    draw = ImageDraw.Draw(img)
    
    # Get initials
    initials = ''.join([name[0].upper() for name in full_name.split()[:2]])
    
    # Try to use a font, fallback to default
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 60)
    except:
        font = ImageFont.load_default()
    
    # Draw initials in white
    bbox = draw.textbbox((0, 0), initials, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (200 - text_width) // 2
    y = (200 - text_height) // 2
    
    draw.text((x, y), initials, fill='white', font=font)
    
    # Convert to base64
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    img_str = base64.b64encode(buffer.getvalue()).decode()
    
    return img_str

def register_user(user_data):
    """Register a new user"""
    url = f"{BASE_URL}/register/"
    data = {
        "username": user_data["username"],
        "password": user_data["password"]
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f"✅ Registered user: {user_data['username']}")
            return True
        else:
            print(f"❌ Failed to register {user_data['username']}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error registering {user_data['username']}: {e}")
        return False

def login_user(username, password):
    """Login user and get token"""
    url = f"{BASE_URL}/login/"
    data = {
        "username": username,
        "password": password
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            return response.json().get('access')
        else:
            print(f"❌ Failed to login {username}: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error logging in {username}: {e}")
        return None

def update_user_profile(username, token, user_data):
    """Update user profile with additional data"""
    url = f"{BASE_URL}/update_profile/{username}/"
    headers = {"Authorization": f"Bearer {token}"}
    
    data = {
        "full_name": user_data["full_name"],
        "university": user_data["university"],
        "degree": user_data["degree"],
        "year": user_data["year"],
        "bio": user_data["bio"],
        "interests": user_data["interests"],
        "skills": user_data["skills"]
    }
    
    try:
        response = requests.put(url, json=data, headers=headers)
        if response.status_code == 200:
            print(f"✅ Updated profile for: {username}")
            return True
        else:
            print(f"❌ Failed to update profile for {username}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error updating profile for {username}: {e}")
        return False

def upload_profile_picture(username, token, image_data):
    """Upload profile picture"""
    url = f"{BASE_URL}/upload_user_image/"
    headers = {"Authorization": f"Bearer {token}"}
    
    data = {
        "username": username,
        "image_type": "profile",
        "is_primary": True,
        "image_data": image_data
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            print(f"✅ Uploaded profile picture for: {username}")
            return True
        else:
            print(f"❌ Failed to upload picture for {username}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error uploading picture for {username}: {e}")
        return False

def create_event(username, token, event_data):
    """Create a study event"""
    url = f"{BASE_URL}/create_study_event/"
    headers = {"Authorization": f"Bearer {token}"}
    
    # Generate random future date
    days_ahead = random.randint(1, 14)
    event_date = datetime.now() + timedelta(days=days_ahead)
    
    data = {
        "title": event_data["title"],
        "description": event_data["description"],
        "location": event_data["location"],
        "date": event_date.strftime("%Y-%m-%d"),
        "time": f"{random.randint(9, 18):02d}:00",
        "max_participants": event_data["max_participants"],
        "event_type": event_data["event_type"]
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 201:
            print(f"✅ Created event: {event_data['title']}")
            return True
        else:
            print(f"❌ Failed to create event: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error creating event: {e}")
        return False

def add_friends(username, token, friend_usernames):
    """Add friends for a user"""
    url = f"{BASE_URL}/send_friend_request/"
    headers = {"Authorization": f"Bearer {token}"}
    
    for friend_username in friend_usernames:
        if friend_username != username:
            data = {
                "receiver_username": friend_username
            }
            
            try:
                response = requests.post(url, json=data, headers=headers)
                if response.status_code == 201:
                    print(f"✅ Sent friend request from {username} to {friend_username}")
                else:
                    print(f"❌ Failed to send friend request: {response.text}")
            except Exception as e:
                print(f"❌ Error sending friend request: {e}")

def main():
    print("🚀 Starting test data generation...")
    
    # Register all users
    registered_users = []
    for user_data in TEST_USERS:
        if register_user(user_data):
            registered_users.append(user_data)
    
    print(f"\n📊 Registered {len(registered_users)} users")
    
    # Update profiles and upload pictures
    tokens = {}
    for user_data in registered_users:
        username = user_data["username"]
        token = login_user(username, user_data["password"])
        
        if token:
            tokens[username] = token
            update_user_profile(username, token, user_data)
            
            # Generate and upload profile picture
            image_data = generate_profile_picture(username, user_data["full_name"])
            upload_profile_picture(username, token, image_data)
    
    print(f"\n👥 Updated profiles for {len(tokens)} users")
    
    # Create events
    event_count = 0
    for username, token in tokens.items():
        # Each user creates 1-2 events
        num_events = random.randint(1, 2)
        for _ in range(num_events):
            event_data = random.choice(SAMPLE_EVENTS)
            if create_event(username, token, event_data):
                event_count += 1
    
    print(f"\n📅 Created {event_count} events")
    
    # Add some friend connections
    usernames = list(tokens.keys())
    for username, token in tokens.items():
        # Each user sends friend requests to 2-3 other users
        num_friends = random.randint(2, 3)
        friends = random.sample([u for u in usernames if u != username], num_friends)
        add_friends(username, token, friends)
    
    print(f"\n🤝 Added friend connections")
    
    print("\n✅ Test data generation complete!")
    print("\nTest users created:")
    for user in registered_users:
        print(f"  - {user['username']} ({user['full_name']}) - {user['university']}")
    
    print(f"\nYou can now test the app with these accounts!")
    print("All users have the password: testpass123")

if __name__ == "__main__":
    main()
