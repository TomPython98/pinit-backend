#!/usr/bin/env python3
"""
Quick test to check friends endpoint response format
"""

import requests
import json

BASE_URL = "https://pinit-backend-production.up.railway.app"
USERNAME = "tom"
PASSWORD = "tomtom123A"

def login():
    login_data = {"username": USERNAME, "password": PASSWORD}
    response = requests.post(f"{BASE_URL}/api/login/", json=login_data)
    if response.status_code == 200:
        return response.json()["access_token"]
    return None

def test_friends_endpoint(token, target_username):
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/api/get_friends/{target_username}/", headers=headers)
    print(f"Friends endpoint for {target_username}:")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def test_recent_activity_endpoint(token, target_username):
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/api/get_user_recent_activity/{target_username}/", headers=headers)
    print(f"Recent activity endpoint for {target_username}:")
    print(f"Status: {response.status_code}")
    print(f"Response: {response.json()}")
    print()

def main():
    token = login()
    if not token:
        print("Failed to login")
        return
    
    test_users = ["federico_flores_1", "martín_fernández_2"]
    
    for user in test_users:
        test_friends_endpoint(token, user)
        test_recent_activity_endpoint(token, user)

if __name__ == "__main__":
    main()
