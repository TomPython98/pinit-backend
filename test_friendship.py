#!/usr/bin/env python3
"""
Test friendship creation with correct parameters
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time

BASE_URL = "https://pinit-backend-production.up.railway.app"

def log(message):
    """Print timestamped log message"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    print(f"[{timestamp}] {message}")

def make_request(method, endpoint, data=None, token=None, retries=3):
    """Make HTTP request with retry logic"""
    url = f"{BASE_URL}{endpoint}"
    headers = {"Content-Type": "application/json"}
    
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    for attempt in range(retries):
        try:
            if method == "GET":
                response = requests.get(url, headers=headers, timeout=10)
            elif method == "POST":
                response = requests.post(url, headers=headers, json=data, timeout=10)
            elif method == "PUT":
                response = requests.put(url, headers=headers, json=data, timeout=10)
            elif method == "DELETE":
                response = requests.delete(url, headers=headers, timeout=10)
            
            if response.status_code in [200, 201]:
                return response.json()
            else:
                log(f"Request failed: {response.status_code} - {response.text}")
                if attempt < retries - 1:
                    time.sleep(1)
                    continue
                return None
                
        except Exception as e:
            log(f"Request error (attempt {attempt + 1}): {e}")
            if attempt < retries - 1:
                time.sleep(1)
                continue
            return None
    
    return None

def create_user(username, password, full_name, university, degree, year, bio, interests, skills):
    """Create a complete user account with profile"""
    log(f"Creating user: {username}")
    
    # Register user
    register_data = {
        "username": username,
        "password": password
    }
    
    result = make_request("POST", "/api/register/", register_data)
    if not result or not result.get("success"):
        log(f"Failed to register user {username}")
        return None
    
    token = result.get("access_token")
    if not token:
        log(f"No token received for {username}")
        return None
    
    # Update profile
    profile_data = {
        "username": username,
        "full_name": full_name,
        "university": university,
        "degree": degree,
        "year": year,
        "bio": bio,
        "interests": interests,
        "skills": skills
    }
    
    result = make_request("POST", "/api/update_user_interests/", profile_data, token)
    if not result:
        log(f"Failed to update profile for {username}")
        return None
    
    log(f"Successfully created user: {username}")
    return {
        "username": username,
        "token": token,
        "full_name": full_name,
        "university": university,
        "degree": degree,
        "year": year,
        "bio": bio,
        "interests": interests,
        "skills": skills
    }

def create_friendship(user1_token, user2_username):
    """Create friendship between two users"""
    log(f"Creating friendship with {user2_username}")
    
    # Send friend request
    request_data = {"to_user": user2_username}
    result = make_request("POST", "/api/send_friend_request/", request_data, user1_token)
    
    if result:
        log(f"Friend request sent to {user2_username}")
        return True
    else:
        log(f"Failed to send friend request to {user2_username}")
        return False

def accept_friend_request(token, from_username):
    """Accept a friend request"""
    log(f"Accepting friend request from {from_username}")
    
    result = make_request("POST", f"/api/accept_friend_request/", {"from_user": from_username}, token)
    if result:
        log(f"Accepted friend request from {from_username}")
        return True
    else:
        log(f"Failed to accept friend request from {from_username}")
        return False

def main():
    """Test friendship creation"""
    log("Testing friendship creation...")
    
    # Create 2 test users
    user1_data = {
        "username": f"test_friend_1_{random.randint(1000, 9999)}",
        "password": "test123456",
        "full_name": "Test User 1",
        "university": "Universidad de Buenos Aires (UBA)",
        "degree": "Medicina",
        "year": "3er año",
        "bio": "Test user 1",
        "interests": ["Medicina", "Estudio"],
        "skills": ["Spanish", "English"]
    }
    
    user2_data = {
        "username": f"test_friend_2_{random.randint(1000, 9999)}",
        "password": "test123456",
        "full_name": "Test User 2",
        "university": "Universidad de Buenos Aires (UBA)",
        "degree": "Derecho",
        "year": "2do año",
        "bio": "Test user 2",
        "interests": ["Derecho", "Política"],
        "skills": ["Spanish", "Leadership"]
    }
    
    # Create users
    user1 = create_user(**user1_data)
    if not user1:
        log("Failed to create user1")
        return
    
    time.sleep(1)
    
    user2 = create_user(**user2_data)
    if not user2:
        log("Failed to create user2")
        return
    
    time.sleep(1)
    
    # Test friendship creation
    log("Testing friendship creation...")
    
    # User1 sends friend request to User2
    success1 = create_friendship(user1["token"], user2["username"])
    
    time.sleep(1)
    
    # User2 accepts friend request from User1
    success2 = accept_friend_request(user2["token"], user1["username"])
    
    if success1 and success2:
        log("✅ Friendship creation test successful!")
    else:
        log("❌ Friendship creation test failed!")

if __name__ == "__main__":
    main()
