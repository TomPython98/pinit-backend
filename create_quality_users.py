#!/usr/bin/env python3
"""
Create a few high-quality test users with all features working
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
    
    # Generate random skills for each user
    skills_list = ["Python", "JavaScript", "Java", "C++", "Machine Learning", "Data Analysis", "Web Development", "Mobile Development", "UI/UX Design", "Project Management", "Leadership", "Communication", "Public Speaking", "Teamwork", "Problem Solving", "Research", "Writing", "Teaching", "Marketing", "Sales"]
    skill_names = random.sample(skills_list, random.randint(2, 4))
    proficiency_levels = ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"]
    user_skills = {}
    for skill in skill_names:
        user_skills[skill] = random.choice(proficiency_levels)
    
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
    
    # Generate random future date and time
    days_ahead = random.randint(1, 30)
    event_date = datetime.now() + timedelta(days=days_ahead)
    
    hour = random.randint(9, 20)
    minute = random.choice([0, 30])
    start_time = event_date.replace(hour=hour, minute=minute, second=0, microsecond=0)
    end_time = start_time + timedelta(hours=random.randint(1, 3))
    
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
            print(f"✅ Created event: {event_data['title']} by {username} (ID: {event_id})")
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
            print(f"✅ Added comment from {username}")
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
            print(f"✅ {username} liked event")
            return True
        else:
            print(f"❌ Failed to like event: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error liking event: {e}")
        return False

def send_friend_request(sender, receiver, token):
    """Send a friend request"""
    url = f"{BASE_URL}/api/send_friend_request/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "from_user": sender,
        "to_user": receiver
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 201:
            print(f"✅ Sent friend request from {sender} to {receiver}")
            return True
        else:
            print(f"❌ Failed to send friend request: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error sending friend request: {e}")
        return False

def accept_friend_request(from_user, to_user, token):
    """Accept a friend request"""
    url = f"{BASE_URL}/api/accept_friend_request/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "from_user": from_user,
        "to_user": to_user
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            print(f"✅ {to_user} accepted friend request from {from_user}")
            return True
        else:
            print(f"❌ Failed to accept friend request: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error accepting friend request: {e}")
        return False

def invite_to_event(event_id, username, host_token):
    """Invite a user to an event"""
    url = f"{BASE_URL}/invite_to_event/"
    
    headers = {
        "Authorization": f"Bearer {host_token}",
        "Content-Type": "application/json"
    }
    
    data = {
        "event_id": event_id,
        "username": username,
        "mark_as_auto_matched": False
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                print(f"✅ Invited {username} to event")
                return True
            else:
                print(f"❌ Invitation failed: {result.get('message', 'Unknown error')}")
                return False
        else:
            print(f"❌ Failed to invite user: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error inviting user: {e}")
        return False

def main():
    print("🚀 Creating high-quality test users with all features...")
    
    # Create 5 diverse test users
    test_users = [
        {
            "username": "alex_study_master",
            "first_name": "Alex",
            "last_name": "Chen",
            "interests": ["Computer Science", "AI", "Machine Learning", "Study", "Technology"]
        },
        {
            "username": "sarah_med_student", 
            "first_name": "Sarah",
            "last_name": "Johnson",
            "interests": ["Medicine", "Study", "Academic", "Healthcare", "Research"]
        },
        {
            "username": "mike_business_pro",
            "first_name": "Mike",
            "last_name": "Rodriguez", 
            "interests": ["Business", "Networking", "Social", "Leadership", "Finance"]
        },
        {
            "username": "emma_arts_creative",
            "first_name": "Emma",
            "last_name": "Williams",
            "interests": ["Arts", "Creative", "Design", "Social", "Cultural"]
        },
        {
            "username": "david_eng_focused",
            "first_name": "David",
            "last_name": "Kim",
            "interests": ["Engineering", "Study", "Academic", "Technology", "Research"]
        }
    ]
    
    # Register users
    print("\n👥 Registering users...")
    registered_users = []
    for user_data in test_users:
        user_obj = register_user(user_data)
        if user_obj:
            registered_users.append(user_obj)
        time.sleep(0.5)
    
    print(f"✅ Registered {len(registered_users)} users")
    
    # Update profiles
    print("\n🎯 Updating user profiles...")
    for i, user in enumerate(registered_users):
        user_data = test_users[i]
        update_user_interests(user["username"], user_data["interests"], user["token"])
        time.sleep(0.5)
    
    # Create friend connections
    print("\n🤝 Creating friend connections...")
    for i, user in enumerate(registered_users):
        # Each user befriends 2-3 other users
        other_users = [u for j, u in enumerate(registered_users) if j != i]
        friends = random.sample(other_users, min(3, len(other_users)))
        
        for friend in friends:
            if send_friend_request(user["username"], friend["username"], user["token"]):
                time.sleep(0.3)
                # Accept the request
                accept_friend_request(user["username"], friend["username"], friend["token"])
            time.sleep(0.3)
    
    # Create events
    print("\n📅 Creating events...")
    event_ids = []
    event_hosts = {}
    
    sample_events = [
        {
            "title": "CS Study Group - Algorithms & Data Structures",
            "description": "Let's dive deep into algorithms and data structures. Bring your laptops and questions!",
            "location": "Buenos Aires University Library",
            "latitude": -34.6037 + random.uniform(-0.001, 0.001),
            "longitude": -58.3816 + random.uniform(-0.001, 0.001),
            "max_participants": 8,
            "event_type": "Study",
            "interest_tags": ["Computer Science", "Study", "Academic"]
        },
        {
            "title": "Medical School Anatomy Review",
            "description": "Comprehensive anatomy review session for medical students. All systems covered.",
            "location": "Medical School Study Room",
            "latitude": -34.6037 + random.uniform(-0.001, 0.001),
            "longitude": -58.3816 + random.uniform(-0.001, 0.001),
            "max_participants": 6,
            "event_type": "Study",
            "interest_tags": ["Medicine", "Study", "Academic"]
        },
        {
            "title": "Business Case Study Workshop",
            "description": "Analyzing real business cases and developing strategic solutions together.",
            "location": "Business School Conference Room",
            "latitude": -34.6037 + random.uniform(-0.001, 0.001),
            "longitude": -58.3816 + random.uniform(-0.001, 0.001),
            "max_participants": 10,
            "event_type": "Business",
            "interest_tags": ["Business", "Networking", "Social"]
        },
        {
            "title": "Art Portfolio Review Session",
            "description": "Share your artwork and get constructive feedback from fellow artists.",
            "location": "Art Gallery Studio",
            "latitude": -34.6037 + random.uniform(-0.001, 0.001),
            "longitude": -58.3816 + random.uniform(-0.001, 0.001),
            "max_participants": 5,
            "event_type": "Cultural",
            "interest_tags": ["Arts", "Creative", "Cultural"]
        },
        {
            "title": "Engineering Project Collaboration",
            "description": "Working on engineering projects together. Bring your ideas and let's build something amazing!",
            "location": "Engineering Lab",
            "latitude": -34.6037 + random.uniform(-0.001, 0.001),
            "longitude": -58.3816 + random.uniform(-0.001, 0.001),
            "max_participants": 7,
            "event_type": "Study",
            "interest_tags": ["Engineering", "Study", "Technology"]
        }
    ]
    
    for user in registered_users:
        # Each user creates 1-2 events
        num_events = random.randint(1, 2)
        for _ in range(num_events):
            event_data = random.choice(sample_events)
            event_id = create_event(user["username"], event_data, user["token"])
            if event_id:
                event_ids.append(event_id)
                event_hosts[event_id] = user["username"]
            time.sleep(0.5)
    
    print(f"✅ Created {len(event_ids)} events")
    
    # Add comments and likes
    print("\n💬 Adding comments and likes...")
    comments = [
        "This looks amazing! Count me in!",
        "Perfect timing, I needed this study session",
        "Great initiative! Looking forward to it",
        "I can help explain some concepts if needed",
        "This is exactly what I was looking for",
        "Count me in! I'll bring some materials",
        "Looking forward to collaborating with everyone!",
        "This is going to be so productive!"
    ]
    
    for event_id in event_ids:
        # Add 2-4 comments per event
        num_comments = random.randint(2, 4)
        commenters = random.sample(registered_users, min(num_comments, len(registered_users)))
        
        for commenter in commenters:
            comment_text = random.choice(comments)
            add_event_comment(commenter["username"], event_id, comment_text, commenter["token"])
            time.sleep(0.3)
        
        # Add likes
        num_likes = random.randint(3, 6)
        likers = random.sample(registered_users, min(num_likes, len(registered_users)))
        
        for liker in likers:
            like_event(liker["username"], event_id, liker["token"])
            time.sleep(0.2)
    
    # Create invitations
    print("\n📨 Creating invitations...")
    invitations_sent = 0
    
    for event_id in event_ids:
        host_username = event_hosts[event_id]
        host_user = next((u for u in registered_users if u["username"] == host_username), None)
        
        if host_user:
            # Invite 2-3 users to each event
            other_users = [u for u in registered_users if u["username"] != host_username]
            invitees = random.sample(other_users, min(3, len(other_users)))
            
            for invitee in invitees:
                if invite_to_event(event_id, invitee["username"], host_user["token"]):
                    invitations_sent += 1
                time.sleep(0.3)
    
    print(f"✅ Sent {invitations_sent} invitations")
    
    print("\n🎉 HIGH-QUALITY test data generation completed!")
    print(f"\n📊 Final Summary:")
    print(f"   👥 Users: {len(registered_users)}")
    print(f"   📅 Events: {len(event_ids)}")
    print(f"   💬 Comments: Multiple per event")
    print(f"   ❤️ Likes: Multiple per event")
    print(f"   📨 Invitations: {invitations_sent}")
    print(f"   🤝 Friends: Connected users")
    
    print(f"\n🔑 LOGIN CREDENTIALS:")
    for user in registered_users:
        print(f"   👤 Username: {user['username']}")
        print(f"   🔐 Password: password123")
        print(f"   📧 Email: {user['username']}@test.com")
        print()

if __name__ == "__main__":
    main()
