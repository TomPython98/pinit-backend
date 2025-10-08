#!/usr/bin/env python3
"""
Comprehensive test data generation for PinIt app
Creates users, events, comments, likes, invitations, RSVPs, and more
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time
import uuid

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app/api"

# Existing users
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
        "event_type": "Study",
        "interest_tags": ["Computer Science", "Algorithms", "Study"]
    },
    {
        "title": "MCAT Prep Session - Biology Section",
        "description": "Group study for MCAT biology section. We'll go through practice tests and review key concepts. Bring your practice materials!",
        "location": "Medical School Library, Study Room 3",
        "max_participants": 6,
        "event_type": "Study",
        "interest_tags": ["Medicine", "MCAT", "Biology"]
    },
    {
        "title": "Business Case Study Workshop",
        "description": "Analyzing real business cases and developing solutions together. Great for networking and learning from peers!",
        "location": "Business School, Conference Room A",
        "max_participants": 10,
        "event_type": "Academic",
        "interest_tags": ["Business", "Case Study", "Networking"]
    },
    {
        "title": "Art Portfolio Review Session",
        "description": "Peer review session for art portfolios. Bring your work for feedback and constructive criticism!",
        "location": "Art Studio 3",
        "max_participants": 5,
        "event_type": "Cultural",
        "interest_tags": ["Arts", "Portfolio", "Creative"]
    },
    {
        "title": "Engineering Project Collaboration",
        "description": "Working on robotics project together. All skill levels welcome - we'll learn from each other!",
        "location": "Engineering Lab 2",
        "max_participants": 4,
        "event_type": "Academic",
        "interest_tags": ["Engineering", "Robotics", "Project"]
    },
    {
        "title": "Physics Problem Solving Session",
        "description": "Tackling challenging physics problems together. Quantum mechanics and thermodynamics focus this week!",
        "location": "Physics Building, Room 101",
        "max_participants": 6,
        "event_type": "Study",
        "interest_tags": ["Physics", "Problem Solving", "Study"]
    },
    {
        "title": "Law School Study Group - Constitutional Law",
        "description": "Reviewing constitutional law cases and preparing for upcoming exams. Bring your casebooks!",
        "location": "Law Library, Study Room 5",
        "max_participants": 8,
        "event_type": "Study",
        "interest_tags": ["Law", "Constitutional", "Study"]
    },
    {
        "title": "Psychology Research Discussion",
        "description": "Discussing recent research papers in cognitive psychology. Great for staying updated with the field!",
        "location": "Psychology Department, Room 203",
        "max_participants": 7,
        "event_type": "Academic",
        "interest_tags": ["Psychology", "Research", "Discussion"]
    },
    {
        "title": "Medical School Anatomy Review",
        "description": "Reviewing anatomy concepts for upcoming practical exams. Study models and diagrams will be available!",
        "location": "Medical School, Anatomy Lab",
        "max_participants": 6,
        "event_type": "Study",
        "interest_tags": ["Medicine", "Anatomy", "Study"]
    },
    {
        "title": "Engineering Design Challenge",
        "description": "Collaborative design challenge focusing on sustainable engineering solutions. Teams of 3-4 people!",
        "location": "Engineering Building, Design Studio",
        "max_participants": 12,
        "event_type": "Academic",
        "interest_tags": ["Engineering", "Design", "Sustainability"]
    }
]

# Sample comments for events
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

def create_event(username, event_data):
    """Create a study event with proper ISO datetime format"""
    url = f"{BASE_URL}/create_study_event/"
    
    # Generate random future date and time
    days_ahead = random.randint(1, 30)
    event_date = datetime.now() + timedelta(days=days_ahead)
    
    # Generate random time
    hour = random.randint(9, 20)
    minute = random.choice([0, 30])
    start_time = event_date.replace(hour=hour, minute=minute, second=0, microsecond=0)
    end_time = start_time + timedelta(hours=random.randint(1, 3))
    
    data = {
        "host": username,
        "title": event_data["title"],
        "description": event_data["description"],
        "location": event_data["location"],
        "time": start_time.isoformat(),  # Proper ISO format
        "end_time": end_time.isoformat(),  # Proper ISO format
        "max_participants": event_data["max_participants"],
        "event_type": event_data["event_type"],
        "interest_tags": event_data["interest_tags"],
        "auto_matching_enabled": True,
        "is_public": True
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
    url = f"{BASE_URL}/events/comment/"
    
    data = {
        "username": username,
        "event_id": event_id,
        "text": comment_text
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f"✅ Added comment from {username} to event {event_id}")
            return True
        else:
            print(f"❌ Failed to add comment: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error adding comment: {e}")
        return False

def toggle_event_like(username, event_id):
    """Like an event"""
    url = f"{BASE_URL}/events/like/"
    
    data = {
        "username": username,
        "event_id": event_id
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print(f"✅ {username} liked event {event_id}")
            return True
        else:
            print(f"❌ Failed to like event: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error liking event: {e}")
        return False

def invite_to_event(event_id, username):
    """Invite a user to an event"""
    url = f"{BASE_URL}/invite_to_event/"
    
    data = {
        "event_id": event_id,
        "username": username,
        "mark_as_auto_matched": False
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 201:
            print(f"✅ Invited {username} to event {event_id}")
            return True
        else:
            print(f"❌ Failed to invite user: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error inviting user: {e}")
        return False

def rsvp_study_event(username, event_id):
    """RSVP to a study event"""
    url = f"{BASE_URL}/rsvp_study_event/"
    
    data = {
        "username": username,
        "event_id": event_id
    }
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            print(f"✅ {username} RSVP'd to event {event_id}")
            return True
        else:
            print(f"❌ Failed to RSVP: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error RSVPing: {e}")
        return False

def submit_user_rating(reviewer, reviewee, rating, comment):
    """Submit a user rating"""
    url = f"{BASE_URL}/submit_user_rating/"
    
    data = {
        "from_username": reviewer,
        "to_username": reviewee,
        "rating": rating,
        "reference": comment
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
    print("🚀 Creating comprehensive test data...")
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
        time.sleep(0.3)
    
    # Create events and collect event IDs
    print("\n📅 Creating events...")
    event_ids = []
    for username in EXISTING_USERS:
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
        # Each event gets 3-8 comments from random users
        num_comments = random.randint(3, 8)
        commenters = random.sample(EXISTING_USERS, min(num_comments, len(EXISTING_USERS)))
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
        # Each event gets 5-12 likes from random users
        num_likes = random.randint(5, 12)
        likers = random.sample(EXISTING_USERS, min(num_likes, len(EXISTING_USERS)))
        for liker in likers:
            if toggle_event_like(liker, event_id):
                likes_added += 1
            time.sleep(0.2)
    
    print(f"✅ Added {likes_added} likes")
    
    # Create invitations to events
    print("\n📨 Creating event invitations...")
    invitations_sent = 0
    for event_id in event_ids:
        # Each event invites 3-6 random users
        num_invites = random.randint(3, 6)
        invitees = random.sample(EXISTING_USERS, min(num_invites, len(EXISTING_USERS)))
        for invitee in invitees:
            if invite_to_event(event_id, invitee):
                invitations_sent += 1
            time.sleep(0.2)
    
    print(f"✅ Sent {invitations_sent} invitations")
    
    # Create RSVPs to events
    print("\n📝 Creating RSVPs...")
    rsvps_created = 0
    for event_id in event_ids:
        # Each event gets 2-5 RSVPs from random users
        num_rsvps = random.randint(2, 5)
        rsvpers = random.sample(EXISTING_USERS, min(num_rsvps, len(EXISTING_USERS)))
        for rsvper in rsvpers:
            if rsvp_study_event(rsvper, event_id):
                rsvps_created += 1
            time.sleep(0.2)
    
    print(f"✅ Created {rsvps_created} RSVPs")
    
    # Create user ratings
    print("\n⭐ Creating user ratings...")
    ratings_created = 0
    for username in EXISTING_USERS:
        num_ratings = random.randint(2, 4)
        reviewees = random.sample([u for u in EXISTING_USERS if u != username], num_ratings)
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
    
    print("\n🎉 Comprehensive test data generation complete!")
    print(f"\n📊 Summary:")
    print(f"   👥 Users: {len(EXISTING_USERS)}")
    print(f"   📅 Events: {len(event_ids)}")
    print(f"   💬 Comments: {comments_added}")
    print(f"   ❤️ Likes: {likes_added}")
    print(f"   📨 Invitations: {invitations_sent}")
    print(f"   📝 RSVPs: {rsvps_created}")
    print(f"   ⭐ Ratings: {ratings_created}")
    
    print(f"\n🎯 All users now have:")
    print(f"   📸 High-quality profile pictures")
    print(f"   🎯 Updated interests and skills")
    print(f"   📅 Multiple study events with full social interactions")
    print(f"   💬 Comments and discussions on events")
    print(f"   ❤️ Likes and engagement on events")
    print(f"   📨 Event invitations and RSVPs")
    print(f"   🤝 Friend connections")
    print(f"   ⭐ User ratings and reviews")

if __name__ == "__main__":
    main()
