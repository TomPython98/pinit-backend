#!/usr/bin/env python3
"""
Fix Test User Data Script
Creates friend connections, user reviews, and ensures proper event visibility
"""

import requests
import json
import random
import time

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

def make_api_call(endpoint, method='GET', data=None):
    """Make API call to production server"""
    url = f"{PRODUCTION_BASE_URL}{endpoint}"
    headers = {'Content-Type': 'application/json'}
    try:
        if method == 'POST':
            response = requests.post(url, headers=headers, data=json.dumps(data))
        else:
            response = requests.get(url, headers=headers)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.HTTPError as e:
        print(f"❌ API Error {e.response.status_code}: {e.response.text}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        return None

def create_friend_connections():
    """Create friend connections between test users"""
    print("🤝 Creating friend connections...")
    
    # Get all users
    users_result = make_api_call("get_all_users/")
    if not users_result:
        print("❌ Failed to get users")
        return
    
    users = users_result
    print(f"Found {len(users)} users: {users}")
    
    # Create friend connections for test_lucas_perez
    target_user = "test_lucas_perez"
    other_users = [u for u in users if u != target_user]
    
    connections_created = 0
    
    for friend in other_users[:4]:  # Connect to 4 other users
        # Send friend request from target_user to friend
        request_data = {
            "from_user": target_user,
            "to_user": friend
        }
        
        print(f"Sending friend request: {target_user} -> {friend}")
        result = make_api_call("send_friend_request/", 'POST', request_data)
        
        if result and result.get('success'):
            # Accept the friend request (simulate friend accepting)
            accept_data = {
                "from_user": target_user,
                "to_user": friend
            }
            
            print(f"Accepting friend request: {friend} accepts from {target_user}")
            accept_result = make_api_call("accept_friend_request/", 'POST', accept_data)
            
            if accept_result and accept_result.get('success'):
                connections_created += 1
                print(f"✅ {target_user} ↔️ {friend} are now friends")
            else:
                print(f"⚠️ Friend request sent but not accepted: {friend}")
        else:
            print(f"❌ Failed to send friend request to {friend}")
        
        time.sleep(0.5)
    
    print(f"🤝 Created {connections_created} friend connections for {target_user}")

def create_user_reviews():
    """Create user reviews for test_lucas_perez"""
    print("⭐ Creating user reviews...")
    
    # Get all users
    users_result = make_api_call("get_all_users/")
    if not users_result:
        print("❌ Failed to get users")
        return
    
    users = users_result
    target_user = "test_lucas_perez"
    other_users = [u for u in users if u != target_user]
    
    reviews_created = 0
    
    # Create reviews FROM other users TO test_lucas_perez
    for reviewer in other_users[:3]:  # 3 reviews
        review_data = {
            "from_username": reviewer,
            "to_username": target_user,
            "rating": random.randint(4, 5),  # High ratings
            "reference": random.choice([
                "Great study partner! Very helpful and organized.",
                "Excellent event host. Everything was well planned.",
                "Friendly and knowledgeable. Would study with again!",
                "Professional and punctual. Highly recommended.",
                "Great communication and very reliable."
            ])
        }
        
        print(f"Creating review: {reviewer} -> {target_user}")
        result = make_api_call("submit_user_rating/", 'POST', review_data)
        
        if result and result.get('success'):
            reviews_created += 1
            print(f"✅ Review created: {reviewer} rated {target_user} {review_data['rating']}/5")
        else:
            print(f"❌ Failed to create review from {reviewer}")
        
        time.sleep(0.5)
    
    # Create reviews FROM test_lucas_perez TO other users
    for reviewee in other_users[:2]:  # 2 reviews given
        review_data = {
            "from_username": target_user,
            "to_username": reviewee,
            "rating": random.randint(4, 5),
            "reference": random.choice([
                "Amazing study session! Very productive.",
                "Great organizer and friendly person.",
                "Excellent communication and planning.",
                "Would definitely study with again!",
                "Very helpful and knowledgeable."
            ])
        }
        
        print(f"Creating review: {target_user} -> {reviewee}")
        result = make_api_call("submit_user_rating/", 'POST', review_data)
        
        if result and result.get('success'):
            reviews_created += 1
            print(f"✅ Review created: {target_user} rated {reviewee} {review_data['rating']}/5")
        else:
            print(f"❌ Failed to create review to {reviewee}")
        
        time.sleep(0.5)
    
    print(f"⭐ Created {reviews_created} user reviews")

def create_private_events():
    """Create some private events that test_lucas_perez can see"""
    print("🔒 Creating private events...")
    
    # Buenos Aires locations
    locations = [
        {'name': 'Palermo', 'lat': -34.5889, 'lng': -58.4108},
        {'name': 'Recoleta', 'lat': -34.5875, 'lng': -58.3935},
        {'name': 'San Telmo', 'lat': -34.6211, 'lng': -58.3731}
    ]
    
    # Get all users for invitations
    users_result = make_api_call("get_all_users/")
    if not users_result:
        print("❌ Failed to get users")
        return
    
    users = users_result
    target_user = "test_lucas_perez"
    
    events_created = 0
    
    for i in range(3):  # Create 3 private events
        location = random.choice(locations)
        
        # Create event hosted by test_lucas_perez
        start_time = "2025-01-15T10:00:00+00:00"
        end_time = "2025-01-15T12:00:00+00:00"
        
        event_data = {
            "title": f"Private Study Session - {location['name']}",
            "description": f"Exclusive study session in {location['name']} for close friends only.",
            "latitude": location['lat'],
            "longitude": location['lng'],
            "time": start_time,
            "end_time": end_time,
            "max_participants": 5,
            "host": target_user,
            "is_public": False,  # Private event
            "event_type": "study",
            "auto_matching_enabled": False,
            "interest_tags": ["Study Groups", "Networking"]
        }
        
        print(f"Creating private event: {event_data['title']}")
        result = make_api_call("create_study_event/", 'POST', event_data)
        
        if result and result.get('success'):
            event_id = result.get('event_id')
            events_created += 1
            print(f"✅ Created private event: {event_data['title']}")
            
            # Invite some friends to the private event
            other_users = [u for u in users if u != target_user]
            friends_to_invite = random.sample(other_users, min(3, len(other_users)))
            
            for friend in friends_to_invite:
                invite_data = {
                    "event_id": event_id,
                    "username": friend
                }
                
                invite_result = make_api_call("invite_to_event/", 'POST', invite_data)
                if invite_result and invite_result.get('success'):
                    print(f"✅ Invited {friend} to private event")
                else:
                    print(f"❌ Failed to invite {friend}")
                
                time.sleep(0.3)
        else:
            print(f"❌ Failed to create private event")
        
        time.sleep(0.5)
    
    print(f"🔒 Created {events_created} private events")

def main():
    """Main function to fix test user data"""
    print("🔧 Fixing test user data for test_lucas_perez...")
    
    # Create friend connections
    create_friend_connections()
    
    # Create user reviews
    create_user_reviews()
    
    # Create private events
    create_private_events()
    
    print("\n🎉 Test user data fixes complete!")
    print("✅ Friend connections created")
    print("✅ User reviews created")
    print("✅ Private events created")
    
    # Verify the fixes
    print("\n🔍 Verifying fixes...")
    
    # Check friends
    friends_result = make_api_call("get_friends/test_lucas_perez/")
    if friends_result:
        print(f"👥 Friends: {len(friends_result.get('friends', []))}")
    
    # Check reputation
    reputation_result = make_api_call("get_user_reputation/test_lucas_perez/")
    if reputation_result:
        print(f"⭐ Total ratings: {reputation_result.get('total_ratings', 0)}")
        print(f"⭐ Average rating: {reputation_result.get('average_rating', 0)}")
    
    # Check individual ratings
    ratings_result = make_api_call("get_user_ratings/test_lucas_perez/")
    if ratings_result:
        print(f"📝 Ratings received: {len(ratings_result.get('ratings_received', []))}")
        print(f"📝 Ratings given: {len(ratings_result.get('ratings_given', []))}")

if __name__ == "__main__":
    main()
