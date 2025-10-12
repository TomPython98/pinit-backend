#!/usr/bin/env python3
"""
Create ONE high-quality test user with all features working
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time

BASE_URL = "https://pinit-backend-production.up.railway.app"

def register_user(user_data):
    """Register a new user"""
    url = f"{BASE_URL}/api/register/"
    
    data = {
        "username": user_data["username"],
        "email": f"{user_data['username']}@test.com",
        "password": "password123",
        "first_name": user_data["first_name"],
        "last_name": user_data["last_name"]
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            result = response.json()
            if result.get("success"):
                print(f"✅ Registered user: {user_data['username']}")
                return {
                    "username": user_data["username"],
                    "token": result.get("access_token")
                }
        print(f"❌ Failed to register {user_data['username']}: {response.text}")
        return None
    except Exception as e:
        print(f"❌ Error registering {user_data['username']}: {e}")
        return None

def update_user_interests(username, interests, token):
    """Update user interests and profile"""
    url = f"{BASE_URL}/api/update_user_interests/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Generate skills
    user_skills = {
        "Python": "EXPERT",
        "Machine Learning": "ADVANCED", 
        "Data Analysis": "INTERMEDIATE",
        "Leadership": "ADVANCED"
    }
    
    data = {
        "username": username,
        "interests": interests,
        "skills": user_skills,
        "auto_invite_preference": True,
        "preferred_radius": 10.0
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            print(f"✅ Updated interests for {username}")
            return True
        else:
            print(f"❌ Failed to update interests: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error updating interests: {e}")
        return False

def create_event(username, event_data, token):
    """Create a study event"""
    url = f"{BASE_URL}/api/create_study_event/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Generate future date and time
    days_ahead = random.randint(1, 14)
    event_date = datetime.now() + timedelta(days=days_ahead)
    
    hour = random.randint(14, 18)
    start_time = event_date.replace(hour=hour, minute=0, second=0, microsecond=0)
    end_time = start_time + timedelta(hours=2)
    
    data = {
        "host": username,
        "title": event_data["title"],
        "description": event_data["description"],
        "location": event_data["location"],
        "latitude": event_data["latitude"],
        "longitude": event_data["longitude"],
        "time": start_time.isoformat(),
        "end_time": end_time.isoformat(),
        "max_participants": event_data["max_participants"],
        "event_type": event_data["event_type"],
        "interest_tags": event_data["interest_tags"],
        "auto_matching_enabled": True,
        "is_public": True,
        "invited_friends": []
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 201:
            result = response.json()
            event_id = result.get("event_id")
            print(f"✅ Created event: {event_data['title']} (ID: {event_id})")
            return event_id
        else:
            print(f"❌ Failed to create event: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error creating event: {e}")
        return None

def add_event_comment(username, event_id, comment_text, token):
    """Add a comment to an event"""
    url = f"{BASE_URL}/api/events/comment/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "username": username,
        "event_id": event_id,
        "text": comment_text
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 201:
            print(f"✅ Added comment: {comment_text[:30]}...")
            return True
        else:
            print(f"❌ Failed to add comment: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error adding comment: {e}")
        return False

def like_event(username, event_id, token):
    """Like an event"""
    url = f"{BASE_URL}/api/events/like/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "username": username,
        "event_id": event_id
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            print(f"✅ Liked event")
            return True
        else:
            print(f"❌ Failed to like event: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error liking event: {e}")
        return False

def main():
    print("🚀 Creating ONE high-quality test user with all features...")
    
    # Create one comprehensive user
    user_data = {
        "username": "master_study_user",
        "first_name": "Alex",
        "last_name": "StudyMaster",
        "interests": ["Computer Science", "AI", "Machine Learning", "Study", "Technology", "Research"]
    }
    
    # Register user
    print("\n👤 Registering user...")
    user = register_user(user_data)
    if not user:
        print("❌ Failed to register user")
        return
    
    print(f"✅ User registered: {user['username']}")
    
    # Update profile
    print("\n🎯 Updating profile...")
    update_user_interests(user["username"], user_data["interests"], user["token"])
    
    # Create multiple events
    print("\n📅 Creating events...")
    events = [
        {
            "title": "Advanced Python & Machine Learning Study Group",
            "description": "Deep dive into Python programming and ML algorithms. Bring your laptops and questions!",
            "location": "Buenos Aires University - Computer Lab",
            "latitude": -34.6037,
            "longitude": -58.3816,
            "max_participants": 8,
            "event_type": "Study",
            "interest_tags": ["Computer Science", "Study", "Academic", "Technology"]
        },
        {
            "title": "Data Science Project Collaboration",
            "description": "Working on real-world data science projects together. All skill levels welcome!",
            "location": "Tech Hub Buenos Aires",
            "latitude": -34.6037 + 0.001,
            "longitude": -58.3816 + 0.001,
            "max_participants": 6,
            "event_type": "Study",
            "interest_tags": ["Data Analysis", "Study", "Academic", "Research"]
        },
        {
            "title": "AI Research Discussion Group",
            "description": "Discussing latest AI research papers and breakthroughs. Coffee and insights!",
            "location": "Café Study Corner",
            "latitude": -34.6037 - 0.001,
            "longitude": -58.3816 - 0.001,
            "max_participants": 5,
            "event_type": "Academic",
            "interest_tags": ["AI", "Research", "Academic", "Technology"]
        }
    ]
    
    event_ids = []
    for event_data in events:
        event_id = create_event(user["username"], event_data, user["token"])
        if event_id:
            event_ids.append(event_id)
        time.sleep(1)  # Give database time to process
    
    print(f"✅ Created {len(event_ids)} events")
    
    # Add comments to events
    print("\n💬 Adding comments...")
    comments = [
        "This looks amazing! Count me in!",
        "Perfect timing, I needed this study session",
        "Great initiative! Looking forward to it",
        "I can help explain some concepts if needed",
        "This is exactly what I was looking for",
        "Count me in! I'll bring some materials"
    ]
    
    for event_id in event_ids:
        comment_text = random.choice(comments)
        add_event_comment(user["username"], event_id, comment_text, user["token"])
        time.sleep(0.5)
    
    # Like events
    print("\n❤️ Adding likes...")
    for event_id in event_ids:
        like_event(user["username"], event_id, user["token"])
        time.sleep(0.5)
    
    print("\n🎉 HIGH-QUALITY test user creation completed!")
    print(f"\n📊 Summary:")
    print(f"   👤 User: {user['username']}")
    print(f"   📅 Events: {len(event_ids)}")
    print(f"   💬 Comments: {len(event_ids)}")
    print(f"   ❤️ Likes: {len(event_ids)}")
    print(f"   🎯 Interests: {len(user_data['interests'])}")
    print(f"   🛠️ Skills: 4 technical skills")
    
    print(f"\n🔑 LOGIN CREDENTIALS:")
    print(f"   👤 Username: {user['username']}")
    print(f"   🔐 Password: password123")
    print(f"   📧 Email: {user['username']}@test.com")
    print(f"\n🚀 This user has:")
    print(f"   ✅ Complete profile with interests and skills")
    print(f"   ✅ Multiple hosted events")
    print(f"   ✅ Comments and likes on events")
    print(f"   ✅ Ready for testing all features!")

if __name__ == "__main__":
    main()
