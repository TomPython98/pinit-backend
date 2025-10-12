#!/usr/bin/env python3
"""
Create events in Buenos Aires for local testing
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time

BASE_URL = "https://pinit-backend-production.up.railway.app"

# Buenos Aires coordinates
BUENOS_AIRES_COORDINATES = [
    {"lat": -34.6037, "lon": -58.3816, "name": "Centro"},
    {"lat": -34.6118, "lon": -58.3960, "name": "Palermo"},
    {"lat": -34.6097, "lon": -58.3731, "name": "Recoleta"},
    {"lat": -34.6205, "lon": -58.3731, "name": "Puerto Madero"},
    {"lat": -34.6158, "lon": -58.4333, "name": "Belgrano"},
]

def get_auth_token(username, password):
    """Get JWT token for authentication"""
    url = f"{BASE_URL}/api/token/"
    data = {"username": username, "password": password}
    
    try:
        response = requests.post(url, json=data)
        if response.status_code == 200:
            return response.json().get("access_token")
        else:
            print(f"❌ Failed to get token: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error getting token: {e}")
        return None

def create_buenos_aires_event(username, token):
    """Create an event in Buenos Aires"""
    url = f"{BASE_URL}/api/create_study_event/"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Pick random Buenos Aires location
    location = random.choice(BUENOS_AIRES_COORDINATES)
    
    # Generate future date and time
    days_ahead = random.randint(1, 14)
    event_date = datetime.now() + timedelta(days=days_ahead)
    
    hour = random.randint(14, 20)
    start_time = event_date.replace(hour=hour, minute=0, second=0, microsecond=0)
    end_time = start_time + timedelta(hours=2)
    
    # Buenos Aires event templates
    event_templates = [
        {
            "title": "Estudio Grupal en Palermo",
            "description": "Sesión de estudio colaborativo en Palermo. ¡Trae tu laptop y estudiemos juntos!",
            "location": f"Café en {location['name']}",
            "event_type": "study",
            "interest_tags": ["Estudio", "Académico", "Colaboración"]
        },
        {
            "title": "Networking Profesional",
            "description": "Evento de networking para profesionales. ¡Conecta con otros profesionales de Buenos Aires!",
            "location": f"Coworking en {location['name']}",
            "event_type": "business",
            "interest_tags": ["Networking", "Profesional", "Negocios"]
        },
        {
            "title": "Intercambio de Idiomas",
            "description": "Práctica de inglés y español. ¡Aprende idiomas mientras conoces gente nueva!",
            "location": f"Café en {location['name']}",
            "event_type": "other",
            "interest_tags": ["Idiomas", "Social", "Aprendizaje"]
        },
        {
            "title": "Proyecto de Programación",
            "description": "Colaboración en proyecto de desarrollo web. ¡Desarrolladores de todos los niveles bienvenidos!",
            "location": f"Espacio de trabajo en {location['name']}",
            "event_type": "study",
            "interest_tags": ["Programación", "Tecnología", "Desarrollo"]
        }
    ]
    
    event_data = random.choice(event_templates)
    
    data = {
        "host": username,
        "title": event_data["title"],
        "description": event_data["description"],
        "location": event_data["location"],
        "latitude": location["lat"],
        "longitude": location["lon"],
        "time": start_time.isoformat(),
        "end_time": end_time.isoformat(),
        "max_participants": random.randint(4, 8),
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
            print(f"✅ Created Buenos Aires event: {event_data['title']} at {location['name']} (ID: {event_id})")
            return event_id
        else:
            print(f"❌ Failed to create event: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error creating event: {e}")
        return None

def main():
    print("🇦🇷 Creating Buenos Aires events for local map testing...")
    
    # Use one of the test users
    username = "alex_cs_stanford_1760310792"
    password = "password123"
    
    # Get auth token
    print(f"🔑 Getting auth token for {username}...")
    token = get_auth_token(username, password)
    if not token:
        print("❌ Failed to get auth token")
        return
    
    print("✅ Got auth token")
    
    # Create 5 Buenos Aires events
    print("\n📍 Creating Buenos Aires events...")
    event_ids = []
    
    for i in range(5):
        event_id = create_buenos_aires_event(username, token)
        if event_id:
            event_ids.append(event_id)
        time.sleep(2)  # Delay between events
    
    print(f"\n🎉 Created {len(event_ids)} Buenos Aires events!")
    print(f"\n📍 Events created in Buenos Aires neighborhoods:")
    print(f"   - Centro, Palermo, Recoleta, Puerto Madero, Belgrano")
    print(f"\n🗺️ Now check your map - events should be visible!")
    print(f"\n🔑 Login credentials:")
    print(f"   Username: {username}")
    print(f"   Password: {password}")

if __name__ == "__main__":
    main()
