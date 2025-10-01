#!/usr/bin/env python3
"""
Create social network connections on production server
"""

import requests
import json
import random
import time

# Production server URL
PRODUCTION_URL = "https://pinit-backend-production.up.railway.app/api"

def make_api_call(endpoint, method='GET', data=None):
    """Make API call to production server with error handling"""
    url = f"{PRODUCTION_URL}/{endpoint}"
    headers = {'Content-Type': 'application/json'}
    
    try:
        if method == 'GET':
            response = requests.get(url, headers=headers, timeout=30)
        elif method == 'POST':
            response = requests.post(url, headers=headers, json=data, timeout=30)
        
        if response.status_code in [200, 201]:
            return response.json() if response.content else {}
        else:
            print(f"❌ API Error {response.status_code}: {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Request Error: {e}")
        return None

def get_all_users():
    """Get all users from the server"""
    print("👥 Fetching all users...")
    
    result = make_api_call("get_all_users/")
    if result and isinstance(result, list):
        # Convert usernames to user objects
        users = [{"username": username} for username in result]
        print(f"✅ Found {len(users)} users")
        return users
    else:
        print("❌ Failed to get users")
        return []

def create_friend_connections(users, max_connections=500):
    """Create friend connections between users"""
    print(f"🤝 Creating friend connections (max {max_connections})...")
    
    connections_created = 0
    attempts = 0
    max_attempts = max_connections * 3  # Allow for some failures
    
    while connections_created < max_connections and attempts < max_attempts:
        # Select two random users
        user1, user2 = random.sample(users, 2)
        
        # Send friend request
        friend_data = {
            "from_user": user1['username'],
            "to_user": user2['username']
        }
        
        result = make_api_call("send_friend_request/", 'POST', friend_data)
        if result and result.get('success'):
            # Accept the friend request
            accept_data = {
                "from_user": user1['username'],
                "to_user": user2['username']
            }
            
            accept_result = make_api_call("accept_friend_request/", 'POST', accept_data)
            if accept_result and accept_result.get('success'):
                connections_created += 1
                if connections_created % 50 == 0:
                    print(f"✅ Created {connections_created} friend connections")
        
        attempts += 1
        time.sleep(0.1)  # Small delay to avoid overwhelming server
    
    print(f"🎉 Created {connections_created} friend connections")

def create_friend_requests(users, max_requests=200):
    """Create pending friend requests"""
    print(f"📨 Creating friend requests (max {max_requests})...")
    
    requests_created = 0
    attempts = 0
    max_attempts = max_requests * 3
    
    while requests_created < max_requests and attempts < max_attempts:
        # Select two random users
        user1, user2 = random.sample(users, 2)
        
        # Send friend request (don't accept it)
        friend_data = {
            "from_user": user1['username'],
            "to_user": user2['username']
        }
        
        result = make_api_call("send_friend_request/", 'POST', friend_data)
        if result and result.get('success'):
            requests_created += 1
            if requests_created % 25 == 0:
                print(f"✅ Created {requests_created} friend requests")
        
        attempts += 1
        time.sleep(0.1)
    
    print(f"🎉 Created {requests_created} friend requests")

def create_user_ratings(users, max_ratings=300):
    """Create user ratings and reviews"""
    print(f"⭐ Creating user ratings (max {max_ratings})...")
    
    ratings_created = 0
    attempts = 0
    max_attempts = max_ratings * 3
    
    while ratings_created < max_ratings and attempts < max_attempts:
        # Select two random users
        rater, rated = random.sample(users, 2)
        
        # Create rating
        rating_data = {
            "rater_username": rater['username'],
            "rated_username": rated['username'],
            "rating": random.randint(3, 5),  # Good ratings only
            "comment": random.choice([
                "Great study partner!",
                "Very helpful and friendly",
                "Excellent collaboration skills",
                "Reliable and punctual",
                "Great communication",
                "Fun to work with",
                "Very knowledgeable",
                "Helpful and supportive"
            ])
        }
        
        result = make_api_call("submit_user_rating/", 'POST', rating_data)
        if result and result.get('success'):
            ratings_created += 1
            if ratings_created % 50 == 0:
                print(f"✅ Created {ratings_created} user ratings")
        
        attempts += 1
        time.sleep(0.1)
    
    print(f"🎉 Created {ratings_created} user ratings")

def main():
    """Main function"""
    print("🚀 Creating Social Network on Production Server")
    print("=" * 60)
    
    # Get all users
    users = get_all_users()
    
    if len(users) < 2:
        print("❌ Need at least 2 users to create social network")
        return
    
    print(f"👥 Working with {len(users)} users")
    
    # Create friend connections
    create_friend_connections(users, 500)
    
    # Create pending friend requests
    create_friend_requests(users, 200)
    
    # Create user ratings
    create_user_ratings(users, 300)
    
    print("=" * 60)
    print("✅ Social network creation completed!")

if __name__ == "__main__":
    main()
