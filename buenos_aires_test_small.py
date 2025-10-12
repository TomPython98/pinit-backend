#!/usr/bin/env python3
"""
Buenos Aires Test Data Generation - Small Scale Test
Creates 5 users and 3 events to test the system
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

def create_event(token, event_data):
    """Create an event with all parameters"""
    log(f"Creating event: {event_data['title']}")
    
    result = make_request("POST", "/api/create_study_event/", event_data, token)
    if result and result.get("success"):
        event_id = result.get("event_id")
        log(f"Successfully created event: {event_data['title']} (ID: {event_id})")
        return event_id
    else:
        log(f"Failed to create event: {event_data['title']}")
        return None

def main():
    """Main execution function - Small scale test"""
    log("Starting Buenos Aires small scale data generation test...")
    
    # Create 5 test users
    test_users = [
        {
            "username": "alejandro_med_uba",
            "password": "test123456",
            "full_name": "Alejandro García",
            "university": "Universidad de Buenos Aires (UBA)",
            "degree": "Medicina",
            "year": "3er año",
            "bio": "Estudiante de medicina en UBA. Me gusta estudiar y conocer gente nueva.",
            "interests": ["Medicina", "Estudio", "Mate"],
            "skills": ["Spanish", "English", "Leadership"]
        },
        {
            "username": "maria_derecho_uba",
            "password": "test123456",
            "full_name": "María Rodríguez",
            "university": "Universidad de Buenos Aires (UBA)",
            "degree": "Derecho",
            "year": "2do año",
            "bio": "Estudiante de derecho. Amo Buenos Aires y su cultura.",
            "interests": ["Derecho", "Política", "Historia"],
            "skills": ["Spanish", "Public Speaking", "Research"]
        },
        {
            "username": "carlos_ing_uba",
            "password": "test123456",
            "full_name": "Carlos Martínez",
            "university": "Universidad de Buenos Aires (UBA)",
            "degree": "Ingeniería",
            "year": "4to año",
            "bio": "Estudiante de ingeniería. Siempre buscando nuevas experiencias.",
            "interests": ["Ingeniería", "Coding", "Proyectos"],
            "skills": ["Python", "Java", "Problem Solving"]
        },
        {
            "username": "ana_psicologia_uba",
            "password": "test123456",
            "full_name": "Ana Fernández",
            "university": "Universidad de Buenos Aires (UBA)",
            "degree": "Psicología",
            "year": "1er año",
            "bio": "Estudiante de psicología. Me gusta el mate, el fútbol y estudiar con amigos.",
            "interests": ["Psicología", "Arte", "Música"],
            "skills": ["Spanish", "Communication", "Empathy"]
        },
        {
            "username": "diego_business_uba",
            "password": "test123456",
            "full_name": "Diego López",
            "university": "Universidad de Buenos Aires (UBA)",
            "degree": "Administración de Empresas",
            "year": "5to año",
            "bio": "Estudiante de administración. Me interesa el emprendimiento y networking.",
            "interests": ["Business", "Emprendimiento", "Networking"],
            "skills": ["Leadership", "Marketing", "Teamwork"]
        }
    ]
    
    created_users = []
    
    # Create users
    for user_data in test_users:
        user = create_user(**user_data)
        if user:
            created_users.append(user)
        time.sleep(1)  # Rate limiting
    
    log(f"Created {len(created_users)} users")
    
    # Create 3 test events
    test_events = [
        {
            "title": "Grupo de Estudio - Medicina UBA",
            "description": "Sesión de estudio para Anatomía. Repasaremos sistema cardiovascular.",
            "latitude": -34.5997,
            "longitude": -58.3979,
            "time": (datetime.now() + timedelta(days=2, hours=14)).isoformat(),
            "end_time": (datetime.now() + timedelta(days=2, hours=16)).isoformat(),
            "event_type": "study",
            "interest_tags": ["Medicina", "Anatomía", "Estudio"],
            "is_public": True,
            "auto_matching_enabled": True,
            "max_participants": 8
        },
        {
            "title": "Asado en Palermo",
            "description": "Asado tradicional argentino en Bosques de Palermo. ¡Trae tu mate!",
            "latitude": -34.5739,
            "longitude": -58.4158,
            "time": (datetime.now() + timedelta(days=5, hours=12)).isoformat(),
            "end_time": (datetime.now() + timedelta(days=5, hours=16)).isoformat(),
            "event_type": "party",
            "interest_tags": ["Asado", "Mate", "Social"],
            "is_public": False,
            "auto_matching_enabled": False,
            "max_participants": 10
        },
        {
            "title": "Networking de Emprendedores",
            "description": "Encuentro de emprendedores y startups en Puerto Madero.",
            "latitude": -34.6037,
            "longitude": -58.3656,
            "time": (datetime.now() + timedelta(days=7, hours=18)).isoformat(),
            "end_time": (datetime.now() + timedelta(days=7, hours=21)).isoformat(),
            "event_type": "business",
            "interest_tags": ["Startups", "Emprendimiento", "Networking"],
            "is_public": True,
            "auto_matching_enabled": True,
            "max_participants": 15
        }
    ]
    
    created_events = []
    
    # Create events
    for i, event_data in enumerate(test_events):
        host = created_users[i % len(created_users)]  # Rotate hosts
        
        event_id = create_event(host["token"], event_data)
        if event_id:
            created_events.append({
                "id": event_id,
                "host": host["username"],
                "data": event_data
            })
        
        time.sleep(1)  # Rate limiting
    
    log(f"Created {len(created_events)} events")
    
    # Summary
    log("=== SMALL SCALE TEST COMPLETE ===")
    log(f"Created {len(created_users)} users")
    log(f"Created {len(created_events)} events")
    log("Test completed successfully!")
    
    # Print user details for verification
    log("\nCreated users:")
    for user in created_users:
        log(f"  - {user['username']}: {user['full_name']} ({user['degree']}, {user['year']})")
    
    log("\nCreated events:")
    for event in created_events:
        log(f"  - {event['data']['title']} (Host: {event['host']})")

if __name__ == "__main__":
    main()
