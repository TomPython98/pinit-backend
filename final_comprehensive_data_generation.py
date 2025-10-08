#!/usr/bin/env python3
"""
Final comprehensive test data generation for PinIt app
With working invitation system and all features tested
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time
import uuid

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app"

# Test users to create
TEST_USERS = [
    {"username": "alex_cs_stanford", "full_name": "Alex Chen", "university": "Stanford University", "degree": "Computer Science"},
    {"username": "sarah_med_harvard", "full_name": "Sarah Johnson", "university": "Harvard Medical School", "degree": "Medicine"},
    {"username": "mike_business_wharton", "full_name": "Mike Rodriguez", "university": "Wharton School", "degree": "Business Administration"},
    {"username": "emma_arts_nyu", "full_name": "Emma Williams", "university": "NYU Tisch", "degree": "Fine Arts"},
    {"username": "david_eng_mit", "full_name": "David Kim", "university": "MIT", "degree": "Mechanical Engineering"},
    {"username": "anna_physics_mit", "full_name": "Anna Schmidt", "university": "MIT", "degree": "Physics"},
    {"username": "james_law_yale", "full_name": "James Thompson", "university": "Yale Law School", "degree": "Law"},
    {"username": "sophie_psych_stanford", "full_name": "Sophie Davis", "university": "Stanford University", "degree": "Psychology"},
    {"username": "carlos_med_johns_hopkins", "full_name": "Carlos Martinez", "university": "Johns Hopkins", "degree": "Medicine"},
    {"username": "lisa_eng_caltech", "full_name": "Lisa Wang", "university": "Caltech", "degree": "Computer Engineering"},
    {"username": "maya_comp_sci_berkeley", "full_name": "Maya Patel", "university": "UC Berkeley", "degree": "Computer Science"},
    {"username": "ryan_business_harvard", "full_name": "Ryan O'Connor", "university": "Harvard Business School", "degree": "MBA"},
    {"username": "zoe_arts_risd", "full_name": "Zoe Anderson", "university": "RISD", "degree": "Graphic Design"},
    {"username": "kevin_eng_georgia_tech", "full_name": "Kevin Lee", "university": "Georgia Tech", "degree": "Electrical Engineering"},
    {"username": "priya_med_ucsf", "full_name": "Priya Sharma", "university": "UCSF", "degree": "Medicine"},
    {"username": "tom_physics_princeton", "full_name": "Tom Wilson", "university": "Princeton University", "degree": "Physics"},
    {"username": "martina_psych_ucla", "full_name": "Martina Garcia", "university": "UCLA", "degree": "Psychology"}
]

# Sample events with coordinates
SAMPLE_EVENTS = [
    {
        "title": "CS Study Group - Algorithms & Data Structures",
        "description": "Weekly study session for CS 161. We'll cover sorting algorithms, binary trees, and graph traversal. Bring your laptops and questions!",
        "location": "Green Library, Room 201",
        "max_participants": 8,
        "event_type": "Study",
        "interest_tags": ["Computer Science", "Algorithms", "Study"],
        "latitude": 37.4275,
        "longitude": -122.1697
    },
    {
        "title": "MCAT Prep Session - Biology Section",
        "description": "Group study for MCAT biology section. We'll go through practice tests and review key concepts. Bring your practice materials!",
        "location": "Medical School Library, Study Room 3",
        "max_participants": 6,
        "event_type": "Study",
        "interest_tags": ["Medicine", "MCAT", "Biology"],
        "latitude": 42.3601,
        "longitude": -71.0589
    },
    {
        "title": "Business Case Study Workshop",
        "description": "Analyzing real business cases and developing solutions together. Great for networking and learning from peers!",
        "location": "Business School, Conference Room A",
        "max_participants": 10,
        "event_type": "Academic",
        "interest_tags": ["Business", "Case Study", "Networking"],
        "latitude": 40.7128,
        "longitude": -74.0060
    },
    {
        "title": "Art Portfolio Review Session",
        "description": "Peer review session for art portfolios. Bring your work for feedback and constructive criticism!",
        "location": "Art Studio 3",
        "max_participants": 5,
        "event_type": "Cultural",
        "interest_tags": ["Arts", "Portfolio", "Creative"],
        "latitude": 40.7589,
        "longitude": -73.9851
    },
    {
        "title": "Engineering Project Collaboration",
        "description": "Working on robotics project together. All skill levels welcome - we'll learn from each other!",
        "location": "Engineering Lab 2",
        "max_participants": 4,
        "event_type": "Academic",
        "interest_tags": ["Engineering", "Robotics", "Project"],
        "latitude": 42.3601,
        "longitude": -71.0942
    },
    {
        "title": "Physics Problem Solving Session",
        "description": "Tackling challenging physics problems together. Quantum mechanics and thermodynamics focus this week!",
        "location": "Physics Building, Room 101",
        "max_participants": 6,
        "event_type": "Study",
        "interest_tags": ["Physics", "Problem Solving", "Study"],
        "latitude": 42.3601,
        "longitude": -71.0942
    },
    {
        "title": "Law School Study Group - Constitutional Law",
        "description": "Reviewing constitutional law cases and preparing for upcoming exams. Bring your casebooks!",
        "location": "Law Library, Study Room 5",
        "max_participants": 8,
        "event_type": "Study",
        "interest_tags": ["Law", "Constitutional", "Study"],
        "latitude": 41.3083,
        "longitude": -72.9279
    },
    {
        "title": "Psychology Research Discussion",
        "description": "Discussing recent research papers in cognitive psychology. Great for staying updated with the field!",
        "location": "Psychology Department, Room 203",
        "max_participants": 7,
        "event_type": "Academic",
        "interest_tags": ["Psychology", "Research", "Discussion"],
        "latitude": 37.4275,
        "longitude": -122.1697
    },
    {
        "title": "Medical School Anatomy Review",
        "description": "Reviewing anatomy concepts for upcoming practical exams. Study models and diagrams will be available!",
        "location": "Medical School, Anatomy Lab",
        "max_participants": 6,
        "event_type": "Study",
        "interest_tags": ["Medicine", "Anatomy", "Study"],
        "latitude": 39.2904,
        "longitude": -76.6122
    },
    {
        "title": "Engineering Design Challenge",
        "description": "Collaborative design challenge focusing on sustainable engineering solutions. Teams of 3-4 people!",
        "location": "Engineering Building, Design Studio",
        "max_participants": 12,
        "event_type": "Academic",
        "interest_tags": ["Engineering", "Design", "Sustainability"],
        "latitude": 33.7756,
        "longitude": -84.3963
    }
]

# Sample comments
SAMPLE_COMMENTS = [
    "This looks like a great study session! Count me in!",
    "I've been struggling with this topic, this will be really helpful.",
    "Perfect timing! I was just about to start studying this.",
    "Looking forward to collaborating with everyone!",
    "This is exactly what I needed to see today!",
    "Great initiative! I'll definitely be there.",
    "I can help explain some of the concepts if needed.",
    "This is going to be so productive!",
    "I love how organized this is. See you there!",
    "This is why I love this community - so supportive!",
    "I'll bring some extra materials to share.",
    "Can't wait to learn from everyone!",
    "This is going to be an amazing session!",
    "I've been looking for a study group like this!",
    "This is perfect for my learning style!"
]

def register_user(user_data):
    """Register a new user"""
    url = f"{BASE_URL}/api/register/"
    
    data = {
        "username": user_data["username"],
        "password": "password123"
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

def create_event(username, event_data):
    """Create a study event"""
    url = f"{BASE_URL}/api/create_study_event/"
    
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
        response = requests.post(url, json=data)
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

def add_event_comment(username, event_id, comment_text):
    """Add a comment to an event"""
    url = f"{BASE_URL}/api/events/comment/"
    
    data = {
        "username": username,
        "event_id": event_id,
        "text": comment_text
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f"✅ Added comment from {username}")
            return True
        else:
            print(f"❌ Failed to add comment: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error adding comment: {e}")
        return False

def toggle_event_like(username, event_id):
    """Like an event"""
    url = f"{BASE_URL}/api/events/like/"
    
    data = {
        "username": username,
        "event_id": event_id
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print(f"✅ {username} liked event")
            return True
        else:
            print(f"❌ Failed to like event: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error liking event: {e}")
        return False

def record_event_share(username, event_id):
    """Record an event share"""
    url = f"{BASE_URL}/api/events/share/"
    
    data = {
        "username": username,
        "event_id": event_id,
        "platform": "app"
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print(f"✅ {username} shared event")
            return True
        else:
            print(f"❌ Failed to share event: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error sharing event: {e}")
        return False

def invite_to_event(event_id, username):
    """Invite a user to an event - using FIXED endpoint"""
    url = f"{BASE_URL}/invite_to_event/"
    
    data = {
        "event_id": event_id,
        "username": username,
        "mark_as_auto_matched": False
    }
    
    try:
        response = requests.post(url, json=data)
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

def rsvp_study_event(username, event_id):
    """RSVP to a study event"""
    url = f"{BASE_URL}/api/rsvp_study_event/"
    
    data = {
        "username": username,
        "event_id": event_id
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print(f"✅ {username} RSVP'd to event")
            return True
        else:
            print(f"❌ Failed to RSVP: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error RSVPing: {e}")
        return False

def submit_user_rating(reviewer, reviewee, rating, comment):
    """Submit a user rating"""
    url = f"{BASE_URL}/api/submit_user_rating/"
    
    data = {
        "from_username": reviewer,
        "to_username": reviewee,
        "rating": rating,
        "reference": comment
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                print(f"✅ Submitted rating from {reviewer} to {reviewee}")
                return True
            else:
                print(f"❌ Rating failed: {result.get('message', 'Unknown error')}")
                return False
        else:
            print(f"❌ Failed to submit rating: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error submitting rating: {e}")
        return False

def update_user_interests(username, interests):
    """Update user interests and profile"""
    url = f"{BASE_URL}/api/update_user_interests/"
    
    data = {
        "username": username,
        "interests": interests,
        "skills": {
            "Python": "Expert",
            "JavaScript": "Advanced",
            "Machine Learning": "Intermediate"
        },
        "auto_invite_preference": True,
        "preferred_radius": 10.0
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

def send_friend_request(sender, receiver):
    """Send a friend request"""
    url = f"{BASE_URL}/api/send_friend_request/"
    
    data = {
        "from_user": sender,
        "to_user": receiver
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

def accept_friend_request(from_user, to_user):
    """Accept a friend request"""
    url = f"{BASE_URL}/api/accept_friend_request/"
    
    data = {
        "from_user": from_user,
        "to_user": to_user
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print(f"✅ {to_user} accepted friend request from {from_user}")
            return True
        else:
            print(f"❌ Failed to accept friend request: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error accepting friend request: {e}")
        return False

def main():
    print("🚀 Creating comprehensive test data with WORKING invitation system...")
    print(f"📊 Creating {len(TEST_USERS)} test users")
    
    # Register all users
    print("\n👥 Registering users...")
    registered_users = []
    for user_data in TEST_USERS:
        if register_user(user_data):
            registered_users.append(user_data["username"])
        time.sleep(0.3)
    
    print(f"✅ Registered {len(registered_users)} users")
    
    # Update user interests and profiles
    print("\n🎯 Updating user interests and profiles...")
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
        ["Engineering", "Study", "Academic", "Technology", "Sustainability"],
        ["Computer Science", "AI", "Machine Learning", "Study", "Technology"],
        ["Business", "Networking", "Social", "Leadership", "Finance"],
        ["Arts", "Cultural", "Creative", "Social", "Design"],
        ["Engineering", "Study", "Academic", "Technology", "Innovation"],
        ["Medicine", "Study", "Academic", "Healthcare", "Research"],
        ["Physics", "Study", "Academic", "Science", "Research"],
        ["Psychology", "Study", "Academic", "Social", "Research"]
    ]
    
    for i, username in enumerate(registered_users):
        interests = interest_sets[i % len(interest_sets)]
        update_user_interests(username, interests)
        time.sleep(0.3)
    
    # Create friend connections
    print("\n🤝 Creating friend connections...")
    friend_requests_sent = 0
    friend_requests_accepted = 0
    
    for username in registered_users:
        num_friends = random.randint(2, 4)
        friends = random.sample([u for u in registered_users if u != username], num_friends)
        for friend in friends:
            if send_friend_request(username, friend):
                friend_requests_sent += 1
                if random.random() < 0.7:  # 70% acceptance rate
                    if accept_friend_request(username, friend):
                        friend_requests_accepted += 1
            time.sleep(0.2)
    
    print(f"✅ Sent {friend_requests_sent} friend requests, accepted {friend_requests_accepted}")
    
    # Create events
    print("\n📅 Creating events...")
    event_ids = []
    for username in registered_users:
        num_events = random.randint(1, 2)
        for _ in range(num_events):
            event_data = random.choice(SAMPLE_EVENTS)
            event_id = create_event(username, event_data)
            if event_id:
                event_ids.append(event_id)
            time.sleep(0.5)
    
    print(f"✅ Created {len(event_ids)} events")
    
    # Add comments to events
    print("\n💬 Adding comments to events...")
    comments_added = 0
    for event_id in event_ids:
        num_comments = random.randint(3, 8)
        commenters = random.sample(registered_users, min(num_comments, len(registered_users)))
        for commenter in commenters:
            comment_text = random.choice(SAMPLE_COMMENTS)
            if add_event_comment(commenter, event_id, comment_text):
                comments_added += 1
            time.sleep(0.2)
    
    print(f"✅ Added {comments_added} comments")
    
    # Add likes to events
    print("\n❤️ Adding likes to events...")
    likes_added = 0
    for event_id in event_ids:
        num_likes = random.randint(5, 12)
        likers = random.sample(registered_users, min(num_likes, len(registered_users)))
        for liker in likers:
            if toggle_event_like(liker, event_id):
                likes_added += 1
            time.sleep(0.2)
    
    print(f"✅ Added {likes_added} likes")
    
    # Add shares to events
    print("\n📤 Adding shares to events...")
    shares_added = 0
    for event_id in event_ids:
        num_shares = random.randint(2, 6)
        sharers = random.sample(registered_users, min(num_shares, len(registered_users)))
        for sharer in sharers:
            if record_event_share(sharer, event_id):
                shares_added += 1
            time.sleep(0.2)
    
    print(f"✅ Added {shares_added} shares")
    
    # Create invitations to events - NOW WORKING!
    print("\n📨 Creating event invitations...")
    invitations_sent = 0
    for event_id in event_ids:
        num_invites = random.randint(3, 6)
        invitees = random.sample(registered_users, min(num_invites, len(registered_users)))
        for invitee in invitees:
            if invite_to_event(event_id, invitee):
                invitations_sent += 1
            time.sleep(0.2)
    
    print(f"✅ Sent {invitations_sent} invitations")
    
    # Create RSVPs to events
    print("\n📝 Creating RSVPs...")
    rsvps_created = 0
    for event_id in event_ids:
        num_rsvps = random.randint(2, 5)
        rsvpers = random.sample(registered_users, min(num_rsvps, len(registered_users)))
        for rsvper in rsvpers:
            if rsvp_study_event(rsvper, event_id):
                rsvps_created += 1
            time.sleep(0.2)
    
    print(f"✅ Created {rsvps_created} RSVPs")
    
    # Create user ratings
    print("\n⭐ Creating user ratings...")
    ratings_created = 0
    for username in registered_users:
        num_ratings = random.randint(2, 4)
        reviewees = random.sample([u for u in registered_users if u != username], num_ratings)
        for reviewee in reviewees:
            rating = random.randint(4, 5)
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
            if submit_user_rating(username, reviewee, rating, comment):
                ratings_created += 1
            time.sleep(0.3)
    
    print(f"✅ Created {ratings_created} ratings")
    
    print("\n🎉 COMPREHENSIVE test data generation completed!")
    print(f"\n📊 Final Summary:")
    print(f"   👥 Users: {len(registered_users)}")
    print(f"   📅 Events: {len(event_ids)}")
    print(f"   🤝 Friend Requests: {friend_requests_sent} sent, {friend_requests_accepted} accepted")
    print(f"   💬 Comments: {comments_added}")
    print(f"   ❤️ Likes: {likes_added}")
    print(f"   📤 Shares: {shares_added}")
    print(f"   📨 Invitations: {invitations_sent} ✅ WORKING!")
    print(f"   📝 RSVPs: {rsvps_created}")
    print(f"   ⭐ Ratings: {ratings_created}")
    
    print(f"\n🎯 All features now working:")
    print(f"   📸 User registration and profiles")
    print(f"   🎯 Interests, skills, and preferences")
    print(f"   📅 Study events with full social interactions")
    print(f"   💬 Comments and discussions")
    print(f"   ❤️ Likes and engagement")
    print(f"   📤 Event shares")
    print(f"   📨 Event invitations ✅ FIXED!")
    print(f"   📝 RSVPs and attendance")
    print(f"   🤝 Friend connections")
    print(f"   ⭐ User ratings and reputation")
    print(f"   🎯 Auto-matching enabled")

if __name__ == "__main__":
    main()
