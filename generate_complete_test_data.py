#!/usr/bin/env python3
"""
Complete test data generation for PinIt app using existing backend endpoints
Creates users, events, friend requests, ratings, and more
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
import time

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app/api"

# Enhanced test user data with more variety
ENHANCED_USERS = [
    {
        "username": "alex_cs_stanford",
        "password": "testpass123",
        "full_name": "Alex Chen",
        "university": "Stanford University",
        "degree": "Computer Science",
        "year": "Graduate",
        "bio": "PhD student in AI/ML. Passionate about deep learning and computer vision. Love collaborating on research projects!",
        "interests": ["Computer Science", "AI", "Machine Learning", "Research", "Study"],
        "skills": {"Python": "Expert", "TensorFlow": "Advanced", "PyTorch": "Advanced", "Research": "Expert"},
        "profile_color": (52, 152, 219)  # Blue
    },
    {
        "username": "sarah_med_harvard",
        "password": "testpass123",
        "full_name": "Sarah Johnson",
        "university": "Harvard Medical School",
        "degree": "Medicine",
        "year": "Senior",
        "bio": "Pre-med student focused on cardiology. MCAT prep study groups are my thing! Always looking for study partners.",
        "interests": ["Medicine", "Study", "Academic", "Healthcare", "Research"],
        "skills": {"Biology": "Expert", "Chemistry": "Expert", "Anatomy": "Advanced", "MCAT": "Advanced"},
        "profile_color": (231, 76, 60)  # Red
    },
    {
        "username": "mike_business_wharton",
        "password": "testpass123",
        "full_name": "Michael Rodriguez",
        "university": "Wharton School",
        "degree": "Business Administration",
        "year": "Graduate",
        "bio": "MBA student specializing in fintech and entrepreneurship. Love networking and case study discussions!",
        "interests": ["Business", "Networking", "Social", "Leadership", "Finance"],
        "skills": {"Finance": "Expert", "Marketing": "Advanced", "Management": "Expert", "Networking": "Expert"},
        "profile_color": (46, 204, 113)  # Green
    },
    {
        "username": "emma_arts_nyu",
        "password": "testpass123",
        "full_name": "Emma Wilson",
        "university": "NYU Tisch",
        "degree": "Fine Arts",
        "year": "Sophomore",
        "bio": "Digital media artist exploring the intersection of technology and creativity. Always up for creative collaborations!",
        "interests": ["Arts", "Cultural", "Creative", "Social", "Technology"],
        "skills": {"Digital Art": "Expert", "Photography": "Advanced", "Design": "Expert", "Creative": "Expert"},
        "profile_color": (155, 89, 182)  # Purple
    },
    {
        "username": "david_eng_mit",
        "password": "testpass123",
        "full_name": "David Kim",
        "university": "MIT",
        "degree": "Mechanical Engineering",
        "year": "Junior",
        "bio": "Robotics enthusiast working on autonomous systems. Love problem-solving and collaborative engineering projects!",
        "interests": ["Engineering", "Study", "Academic", "Technology", "Robotics"],
        "skills": {"CAD": "Expert", "Robotics": "Advanced", "Mathematics": "Expert", "Engineering": "Expert"},
        "profile_color": (230, 126, 34)  # Orange
    },
    {
        "username": "anna_physics_mit",
        "password": "testpass123",
        "full_name": "Anna Schmidt",
        "university": "MIT",
        "degree": "Physics",
        "year": "Graduate",
        "bio": "Quantum physics researcher exploring the mysteries of the universe. Coffee-fueled study sessions welcome!",
        "interests": ["Physics", "Study", "Academic", "Science", "Research"],
        "skills": {"Physics": "Expert", "Mathematics": "Expert", "Research": "Expert", "Quantum": "Advanced"},
        "profile_color": (241, 196, 15)  # Yellow
    },
    {
        "username": "james_law_yale",
        "password": "testpass123",
        "full_name": "James Wilson",
        "university": "Yale Law School",
        "degree": "Law",
        "year": "Senior",
        "bio": "Law student preparing for the bar exam. Study groups and case discussions are essential for success!",
        "interests": ["Law", "Study", "Academic", "Professional", "Justice"],
        "skills": {"Law": "Expert", "Research": "Advanced", "Writing": "Expert", "Analysis": "Expert"},
        "profile_color": (26, 188, 156)  # Turquoise
    },
    {
        "username": "sophie_psych_stanford",
        "password": "testpass123",
        "full_name": "Sophie Martinez",
        "university": "Stanford University",
        "degree": "Psychology",
        "year": "Junior",
        "bio": "Psychology major with focus on cognitive science. Love studying human behavior and mental processes!",
        "interests": ["Psychology", "Study", "Academic", "Social", "Research"],
        "skills": {"Psychology": "Expert", "Research": "Advanced", "Statistics": "Advanced", "Analysis": "Advanced"},
        "profile_color": (142, 68, 173)  # Dark Purple
    },
    {
        "username": "carlos_med_johns_hopkins",
        "password": "testpass123",
        "full_name": "Carlos Rodriguez",
        "university": "Johns Hopkins Medical School",
        "degree": "Medicine",
        "year": "Graduate",
        "bio": "Medical student specializing in cardiology. Study groups help with complex medical material!",
        "interests": ["Medicine", "Study", "Academic", "Healthcare", "Research"],
        "skills": {"Medicine": "Expert", "Biology": "Expert", "Chemistry": "Expert", "Anatomy": "Expert"},
        "profile_color": (39, 174, 96)  # Dark Green
    },
    {
        "username": "lisa_eng_caltech",
        "password": "testpass123",
        "full_name": "Lisa Chen",
        "university": "Caltech",
        "degree": "Electrical Engineering",
        "year": "Senior",
        "bio": "Electrical engineering student working on renewable energy systems. Collaborative problem solving is key!",
        "interests": ["Engineering", "Study", "Academic", "Technology", "Sustainability"],
        "skills": {"Electrical": "Expert", "Mathematics": "Expert", "Programming": "Advanced", "Engineering": "Expert"},
        "profile_color": (211, 84, 0)  # Dark Orange
    }
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
    }
]

def generate_high_quality_profile_picture(username, full_name, profile_color):
    """Generate a high-quality profile picture with initials and gradient background"""
    # Create a 400x400 image for better quality
    size = 400
    img = Image.new('RGB', (size, size), profile_color)
    draw = ImageDraw.Draw(img)
    
    # Create gradient effect
    for y in range(size):
        alpha = int(255 * (1 - y / size) * 0.3)  # Fade to transparent
        color = tuple(max(0, c - alpha) for c in profile_color)
        draw.line([(0, y), (size, y)], fill=color)
    
    # Get initials
    initials = ''.join([name[0].upper() for name in full_name.split()[:2]])
    
    # Try to use a high-quality font
    try:
        font_size = int(size * 0.3)
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
    except:
        font = ImageFont.load_default()
    
    # Draw initials in white with shadow
    bbox = draw.textbbox((0, 0), initials, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (size - text_width) // 2
    y = (size - text_height) // 2
    
    # Draw shadow
    draw.text((x + 2, y + 2), initials, fill=(0, 0, 0, 100), font=font)
    # Draw main text
    draw.text((x, y), initials, fill='white', font=font)
    
    # Add a subtle border
    draw.ellipse([2, 2, size-2, size-2], outline=(255, 255, 255, 50), width=3)
    
    # Convert to base64
    buffer = io.BytesIO()
    img.save(buffer, format='PNG', quality=95)
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

def upload_profile_picture(username, image_data):
    """Upload profile picture using form data"""
    url = f"{BASE_URL}/upload_user_image/"
    
    # Convert base64 to bytes
    image_bytes = base64.b64decode(image_data)
    
    # Create a file-like object
    image_file = io.BytesIO(image_bytes)
    
    # Prepare form data
    files = {
        'image': ('profile.jpg', image_file, 'image/jpeg')
    }
    
    data = {
        'username': username,
        'image_type': 'profile',
        'is_primary': 'true',
        'caption': ''
    }
    
    try:
        response = requests.post(url, files=files, data=data)
        if response.status_code == 200:
            print(f"✅ Uploaded profile picture for: {username}")
            return True
        else:
            print(f"❌ Failed to upload picture for {username}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error uploading picture for {username}: {e}")
        return False

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
    print("🚀 Starting complete test data generation...")
    
    # Register all users
    registered_users = []
    for user_data in ENHANCED_USERS:
        if register_user(user_data):
            registered_users.append(user_data)
        time.sleep(0.5)  # Rate limiting
    
    print(f"\n📊 Successfully registered {len(registered_users)} users")
    
    # Upload profile pictures
    print("\n📸 Uploading high-quality profile pictures...")
    for user_data in registered_users:
        username = user_data["username"]
        full_name = user_data["full_name"]
        profile_color = user_data["profile_color"]
        
        image_data = generate_high_quality_profile_picture(username, full_name, profile_color)
        upload_profile_picture(username, image_data)
        time.sleep(0.5)  # Rate limiting
    
    # Update user interests
    print("\n🎯 Updating user interests...")
    for user_data in registered_users:
        update_user_interests(user_data["username"], user_data["interests"])
        time.sleep(0.3)  # Rate limiting
    
    # Create events
    print("\n📅 Creating events...")
    event_count = 0
    for user_data in registered_users:
        # Each user creates 1-2 events
        num_events = random.randint(1, 2)
        for _ in range(num_events):
            event_data = random.choice(SAMPLE_EVENTS)
            if create_event(user_data["username"], event_data):
                event_count += 1
            time.sleep(0.5)  # Rate limiting
    
    print(f"✅ Created {event_count} events")
    
    # Create friend connections
    print("\n🤝 Creating friend connections...")
    usernames = [user["username"] for user in registered_users]
    friend_requests_sent = 0
    
    for user_data in registered_users:
        # Each user sends friend requests to 2-4 other users
        num_friends = random.randint(2, 4)
        friends = random.sample([u for u in usernames if u != user_data["username"]], num_friends)
        for friend in friends:
            if send_friend_request(user_data["username"], friend):
                friend_requests_sent += 1
            time.sleep(0.3)  # Rate limiting
    
    print(f"✅ Sent {friend_requests_sent} friend requests")
    
    # Create user ratings
    print("\n⭐ Creating user ratings...")
    ratings_created = 0
    for user_data in registered_users:
        # Each user rates 2-3 other users
        num_ratings = random.randint(2, 3)
        reviewees = random.sample([u for u in usernames if u != user_data["username"]], num_ratings)
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
                "Amazing problem-solving skills"
            ])
            if submit_user_rating(user_data["username"], reviewee, rating, comment):
                ratings_created += 1
            time.sleep(0.3)  # Rate limiting
    
    print(f"✅ Created {ratings_created} ratings")
    
    print("\n🎉 Complete test data generation finished!")
    print(f"\n📊 Summary:")
    print(f"   👥 Users: {len(registered_users)}")
    print(f"   📅 Events: {event_count}")
    print(f"   🤝 Friend Requests: {friend_requests_sent}")
    print(f"   ⭐ Ratings: {ratings_created}")
    
    print(f"\n🎯 Test accounts created:")
    for user in registered_users:
        print(f"   👤 {user['username']} ({user['full_name']}) - {user['university']}")
        print(f"      Degree: {user['degree']} - {user['year']}")
        print(f"      Bio: {user['bio']}")
        print(f"      Skills: {', '.join(list(user['skills'].keys())[:3])}...")
        print(f"      Password: testpass123")
        print()

if __name__ == "__main__":
    main()
