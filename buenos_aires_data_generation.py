#!/usr/bin/env python3
"""
Buenos Aires Comprehensive Test Data Generation
Tests ALL PinIt features with realistic Argentine data
"""

import requests
import json
import random
from datetime import datetime, timedelta
import time
import uuid

# Backend URL
BASE_URL = "https://pinit-backend-production.up.railway.app"

# Argentine Universities
UNIVERSITIES = [
    "Universidad de Buenos Aires (UBA)",
    "Universidad de Palermo",
    "Universidad Torcuato Di Tella (UTDT)",
    "Universidad Argentina de la Empresa (UADE)",
    "Universidad Católica Argentina (UCA)"
]

# Argentine Names (mix of Spanish/Italian heritage)
FIRST_NAMES = [
    "Alejandro", "María", "Carlos", "Ana", "Diego", "Sofia", "Martín", "Valentina",
    "Nicolás", "Camila", "Sebastián", "Lucía", "Federico", "Isabella", "Gabriel", "Martina",
    "Matías", "Agustina", "Tomás", "Catalina", "Santiago", "Florencia", "Lucas", "Victoria",
    "Emiliano", "Antonella", "Facundo", "Constanza", "Ignacio", "Bárbara", "Joaquín", "Rocío"
]

LAST_NAMES = [
    "García", "Rodríguez", "Martínez", "Fernández", "López", "González", "Pérez", "Sánchez",
    "Ramírez", "Torres", "Flores", "Rivera", "Gómez", "Díaz", "Cruz", "Morales",
    "Gutiérrez", "Ruiz", "Herrera", "Jiménez", "Moreno", "Muñoz", "Álvarez", "Romero",
    "Navarro", "Ramos", "Vargas", "Castillo", "Mendoza", "Silva", "Reyes", "Herrera"
]

# Degrees
DEGREES = [
    "Medicina", "Derecho", "Ingeniería", "Administración de Empresas", "Psicología",
    "Arquitectura", "Ciencias de la Computación", "Economía", "Comunicación Social",
    "Diseño Gráfico", "Contabilidad", "Marketing", "Relaciones Internacionales"
]

# Argentine Interests
INTERESTS = [
    "Derecho", "Medicina", "Ingeniería", "Tango", "Fútbol", "Mate", "Coding",
    "Arte", "Música", "Literatura", "Historia", "Política", "Deportes",
    "Viajes", "Fotografía", "Cine", "Teatro", "Gastronomía", "Idiomas"
]

# Skills
SKILLS = [
    "Spanish", "English", "Python", "Java", "JavaScript", "Leadership", "Design",
    "Public Speaking", "Teamwork", "Problem Solving", "Communication", "Project Management",
    "Data Analysis", "Marketing", "Sales", "Teaching", "Writing", "Research"
]

# Buenos Aires Event Locations
BA_LOCATIONS = [
    {
        "name": "UBA Facultad de Derecho",
        "latitude": -34.5997,
        "longitude": -58.3979,
        "description": "Facultad de Derecho de la Universidad de Buenos Aires"
    },
    {
        "name": "Puerto Madero",
        "latitude": -34.6037,
        "longitude": -58.3656,
        "description": "Modern neighborhood with restaurants and bars"
    },
    {
        "name": "Bosques de Palermo",
        "latitude": -34.5739,
        "longitude": -58.4158,
        "description": "Large park area perfect for outdoor activities"
    },
    {
        "name": "Centro Cultural Recoleta",
        "latitude": -34.5875,
        "longitude": -58.3925,
        "description": "Cultural center with exhibitions and events"
    },
    {
        "name": "Mercado de San Telmo",
        "latitude": -34.6217,
        "longitude": -58.3722,
        "description": "Historic market with antiques and crafts"
    },
    {
        "name": "Biblioteca Nacional",
        "latitude": -34.5923,
        "longitude": -58.3932,
        "description": "National Library of Argentina"
    },
    {
        "name": "MALBA",
        "latitude": -34.5772,
        "longitude": -58.4032,
        "description": "Museum of Latin American Art"
    },
    {
        "name": "Café Tortoni",
        "latitude": -34.6082,
        "longitude": -58.3756,
        "description": "Historic café in downtown Buenos Aires"
    },
    {
        "name": "Jardín Botánico",
        "latitude": -34.5815,
        "longitude": -58.4190,
        "description": "Botanical Garden of Buenos Aires"
    },
    {
        "name": "Plaza de Mayo",
        "latitude": -34.6082,
        "longitude": -58.3742,
        "description": "Historic square in downtown Buenos Aires"
    }
]

# Event Templates
EVENT_TEMPLATES = [
    # Study Events
    {
        "title": "Grupo de Estudio - Derecho Civil",
        "description": "Sesión de estudio para Derecho Civil. Repasaremos contratos y obligaciones. ¡Trae tus apuntes!",
        "event_type": "study",
        "interest_tags": ["Derecho", "Estudio", "Contratos"],
        "is_public": True,
        "auto_matching_enabled": True
    },
    {
        "title": "Preparación CBC Medicina",
        "description": "Grupo de estudio para el Ciclo Básico Común de Medicina. Química y Biología.",
        "event_type": "study",
        "interest_tags": ["Medicina", "CBC", "Química", "Biología"],
        "is_public": True,
        "auto_matching_enabled": True
    },
    {
        "title": "Proyecto de Ingeniería - Robótica",
        "description": "Colaboración en proyecto de robótica. Todos los niveles son bienvenidos.",
        "event_type": "study",
        "interest_tags": ["Ingeniería", "Robótica", "Proyecto"],
        "is_public": False,
        "auto_matching_enabled": True
    },
    
    # Party Events
    {
        "title": "Asado en Palermo",
        "description": "Asado tradicional argentino en el parque. ¡Trae tu mate!",
        "event_type": "party",
        "interest_tags": ["Asado", "Mate", "Social"],
        "is_public": False,
        "auto_matching_enabled": False
    },
    {
        "title": "Pub Crawl Palermo",
        "description": "Recorrido por los mejores bares de Palermo. ¡Vamos a divertirnos!",
        "event_type": "party",
        "interest_tags": ["Bares", "Palermo", "Social"],
        "is_public": False,
        "auto_matching_enabled": False
    },
    {
        "title": "Fiesta en Puerto Madero",
        "description": "Fiesta en rooftop con vista al río. Dress code: elegante casual.",
        "event_type": "party",
        "interest_tags": ["Puerto Madero", "Fiesta", "Rooftop"],
        "is_public": False,
        "auto_matching_enabled": False
    },
    
    # Business Events
    {
        "title": "Networking de Startups",
        "description": "Encuentro de emprendedores y startups. Presentaciones y networking.",
        "event_type": "business",
        "interest_tags": ["Startups", "Emprendimiento", "Networking"],
        "is_public": True,
        "auto_matching_enabled": True
    },
    {
        "title": "Workshop de Marketing Digital",
        "description": "Taller práctico de marketing digital y redes sociales.",
        "event_type": "business",
        "interest_tags": ["Marketing", "Digital", "Redes Sociales"],
        "is_public": True,
        "auto_matching_enabled": True
    },
    
    # Cultural Events
    {
        "title": "Clase de Tango",
        "description": "Aprende tango argentino con instructores profesionales. Todos los niveles.",
        "event_type": "other",
        "interest_tags": ["Tango", "Danza", "Cultura Argentina"],
        "is_public": True,
        "auto_matching_enabled": True
    },
    {
        "title": "Exposición de Arte Contemporáneo",
        "description": "Visita guiada a la exposición de arte contemporáneo en MALBA.",
        "event_type": "other",
        "interest_tags": ["Arte", "MALBA", "Cultura"],
        "is_public": True,
        "auto_matching_enabled": True
    },
    
    # Other Events
    {
        "title": "Partido de Fútbol - Boca vs River",
        "description": "Ver el superclásico juntos en un bar. ¡Vamos Boca!",
        "event_type": "other",
        "interest_tags": ["Fútbol", "Boca", "Superclásico"],
        "is_public": True,
        "auto_matching_enabled": True
    },
    {
        "title": "Círculo de Mate",
        "description": "Ronda de mate y charla en el Jardín Botánico. ¡Trae tu mate y yerba!",
        "event_type": "other",
        "interest_tags": ["Mate", "Jardín Botánico", "Charla"],
        "is_public": True,
        "auto_matching_enabled": True
    }
]

# Global storage for created data
created_users = []
user_tokens = {}
created_events = []
created_friendships = []

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
    """Create bidirectional friendship between two users"""
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

def invite_friends_to_event(token, event_id, friend_usernames):
    """Invite friends to an event"""
    if not friend_usernames:
        return True
    
    log(f"Inviting {len(friend_usernames)} friends to event {event_id}")
    
    success_count = 0
    for friend_username in friend_usernames:
        invite_data = {
            "event_id": event_id,
            "username": friend_username
        }
        
        result = make_request("POST", "/api/invite_to_event/", invite_data, token)
        if result:
            success_count += 1
            log(f"Successfully invited {friend_username} to event {event_id}")
        else:
            log(f"Failed to invite {friend_username} to event {event_id}")
    
    log(f"Successfully invited {success_count}/{len(friend_usernames)} friends to event {event_id}")
    return success_count > 0

def rsvp_event(token, event_id):
    """RSVP to an event - now handles join requests"""
    log(f"RSVPing to event {event_id}")
    
    result = make_request("POST", "/api/rsvp_study_event/", {"event_id": event_id}, token)
    if result:
        # Check the response to see if it was a direct join or a request
        if isinstance(result, dict):
            action = result.get("action", "unknown")
            if action == "joined":
                log(f"Successfully joined event {event_id} directly")
                return True
            elif action == "request_sent":
                log(f"Join request sent for event {event_id}")
                return result  # Return the result with request_id for approval
            elif action == "request_pending":
                log(f"Request already pending for event {event_id}")
                return False
        else:
            log(f"Successfully RSVPed to event {event_id}")
            return True
    else:
        log(f"Failed to RSVP to event {event_id}")
        return False

def decline_invite(token, event_id):
    """Decline an event invitation"""
    log(f"Declining invitation to event {event_id}")
    
    result = make_request("POST", "/api/decline_invitation/", {"event_id": event_id}, token)
    if result:
        log(f"Successfully declined invitation to event {event_id}")
        return True
    else:
        log(f"Failed to decline invitation to event {event_id}")
        return False

def approve_join_request(token, request_id):
    """Approve a join request (host only)"""
    log(f"Approving join request {request_id}")
    
    result = make_request("POST", "/api/approve_join_request/", {"request_id": request_id}, token)
    if result:
        log(f"Successfully approved join request {request_id}")
        return True
    else:
        log(f"Failed to approve join request {request_id}")
        return False

def reject_join_request(token, request_id):
    """Reject a join request (host only)"""
    log(f"Rejecting join request {request_id}")
    
    result = make_request("POST", "/api/reject_join_request/", {"request_id": request_id}, token)
    if result:
        log(f"Successfully rejected join request {request_id}")
        return True
    else:
        log(f"Failed to reject join request {request_id}")
        return False

def add_review(from_token, to_username, event_id, rating, reference):
    """Add a review/rating for a user"""
    log(f"Adding review for {to_username} (rating: {rating})")
    
    review_data = {
        "to_username": to_username,
        "event_id": event_id,
        "rating": rating,
        "reference": reference
    }
    
    result = make_request("POST", "/api/submit_user_rating/", review_data, from_token)
    if result:
        log(f"Successfully added review for {to_username}")
        return True
    else:
        log(f"Failed to add review for {to_username}")
        return False

def add_comment(token, username, event_id, text, parent_id=None):
    """Add a comment to an event"""
    log(f"Adding comment to event {event_id}")
    
    comment_data = {
        "username": username,
        "event_id": event_id,
        "text": text,
        "parent_id": parent_id
    }
    
    result = make_request("POST", "/api/events/comment/", comment_data, token)
    if result:
        log(f"Successfully added comment to event {event_id}")
        return True
    else:
        log(f"Failed to add comment to event {event_id}")
        return False

def like_event(token, username, event_id):
    """Like an event"""
    log(f"Liking event {event_id}")
    
    like_data = {
        "username": username,
        "event_id": event_id
    }
    
    result = make_request("POST", "/api/events/like/", like_data, token)
    if result:
        log(f"Successfully liked event {event_id}")
        return True
    else:
        log(f"Failed to like event {event_id}")
        return False

def share_event(token, event_id, platform):
    """Share an event on a platform"""
    log(f"Sharing event {event_id} on {platform}")
    
    share_data = {
        "event_id": event_id,
        "platform": platform
    }
    
    result = make_request("POST", "/api/events/share/", share_data, token)
    if result:
        log(f"Successfully shared event {event_id} on {platform}")
        return True
    else:
        log(f"Failed to share event {event_id} on {platform}")
        return False

def invite_friends_to_event(token, event_id, friend_usernames):
    """Invite friends to an event"""
    if not friend_usernames:
        return True
    
    log(f"Inviting {len(friend_usernames)} friends to event {event_id}")
    
    success_count = 0
    for friend_username in friend_usernames:
        invite_data = {
            "event_id": event_id,
            "username": friend_username
        }
        
        result = make_request("POST", "/invite_to_event/", invite_data, token)
        if result:
            success_count += 1
            log(f"Successfully invited {friend_username} to event {event_id}")
        else:
            log(f"Failed to invite {friend_username} to event {event_id}")
    
    log(f"Successfully invited {success_count}/{len(friend_usernames)} friends to event {event_id}")
    return success_count > 0

def generate_argentine_users():
    """Generate 25 Argentine users with realistic data"""
    users = []
    
    for i in range(25):
        # Generate unique username
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        username = f"{first_name.lower()}_{last_name.lower()}_{i+1}"
        
        # Ensure unique username
        while any(user["username"] == username for user in users):
            username = f"{first_name.lower()}_{last_name.lower()}_{i+1}_{random.randint(100, 999)}"
        
        full_name = f"{first_name} {last_name}"
        university = random.choice(UNIVERSITIES)
        degree = random.choice(DEGREES)
        year = random.choice(["1er año", "2do año", "3er año", "4to año", "5to año"])
        
        # Generate bio
        bio_templates = [
            f"Estudiante de {degree} en {university}. Me gusta estudiar y conocer gente nueva.",
            f"Soy {first_name}, estudiante de {degree}. Amo Buenos Aires y su cultura.",
            f"Estudiante de {university}. Me interesa {random.choice(INTERESTS)} y {random.choice(INTERESTS)}.",
            f"Hola! Soy {first_name}, estudiante de {degree}. Siempre buscando nuevas experiencias.",
            f"Estudiante de {university}. Me gusta el mate, el fútbol y estudiar con amigos."
        ]
        bio = random.choice(bio_templates)
        
        # Generate interests (3-6 interests)
        user_interests = random.sample(INTERESTS, random.randint(3, 6))
        
        # Generate skills (2-4 skills) as dictionary with proficiency levels
        skill_names = random.sample(SKILLS, random.randint(2, 4))
        proficiency_levels = ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"]
        user_skills = {}
        for skill in skill_names:
            user_skills[skill] = random.choice(proficiency_levels)
        
        users.append({
            "username": username,
            "password": "test123456",
            "full_name": full_name,
            "university": university,
            "degree": degree,
            "year": year,
            "bio": bio,
            "interests": user_interests,
            "skills": user_skills
        })
    
    return users

def generate_events():
    """Generate diverse events across Buenos Aires"""
    events = []
    
    for i, template in enumerate(EVENT_TEMPLATES):
        # Select random location and add small randomization to avoid exact duplicates
        location = random.choice(BA_LOCATIONS)
        
        # Add small random offset to coordinates to avoid exact duplicates
        # This adds ±0.001 degrees (roughly ±100m) to each coordinate
        lat_offset = random.uniform(-0.001, 0.001)
        lon_offset = random.uniform(-0.001, 0.001)
        
        randomized_lat = location["latitude"] + lat_offset
        randomized_lon = location["longitude"] + lon_offset
        
        # Generate event time (next 1-30 days, reasonable hours)
        days_ahead = random.randint(1, 30)
        hour = random.randint(9, 21)  # 9 AM to 9 PM
        minute = random.choice([0, 30])
        
        event_time = datetime.now() + timedelta(days=days_ahead, hours=hour, minutes=minute)
        end_time = event_time + timedelta(hours=random.randint(1, 4))
        
        event_data = {
            "title": template["title"],
            "description": template["description"],
            "latitude": randomized_lat,
            "longitude": randomized_lon,
            "time": event_time.isoformat(),
            "end_time": end_time.isoformat(),
            "event_type": template["event_type"],
            "interest_tags": template["interest_tags"],
            "is_public": template["is_public"],
            "auto_matching_enabled": template["auto_matching_enabled"],
            "max_participants": random.randint(4, 15)
        }
        
        events.append(event_data)
    
    return events

def main():
    """Main execution function"""
    log("Starting Buenos Aires comprehensive data generation...")
    
    # 1. Generate user data
    log("Generating Argentine users...")
    argentine_users = generate_argentine_users()
    
    # 2. Create all users
    log("Creating user accounts...")
    for user_data in argentine_users:
        user = create_user(**user_data)
        if user:
            created_users.append(user)
            user_tokens[user["username"]] = user["token"]
        time.sleep(0.5)  # Rate limiting
    
    log(f"Created {len(created_users)} users")
    
    # 3. Create friendships (web of connections)
    log("Creating friendships...")
    friendship_pairs = []
    
    # Create a web of friendships
    for i in range(len(created_users)):
        # Each user befriends 3-6 other users
        num_friends = random.randint(3, 6)
        potential_friends = [u for u in created_users if u["username"] != created_users[i]["username"]]
        friends = random.sample(potential_friends, min(num_friends, len(potential_friends)))
        
        for friend in friends:
            pair = tuple(sorted([created_users[i]["username"], friend["username"]]))
            if pair not in friendship_pairs:
                friendship_pairs.append(pair)
                create_friendship(created_users[i]["token"], friend["username"])
                time.sleep(0.3)
    
    # Accept friend requests (simulate bidirectional friendships)
    log("Accepting friend requests...")
    for user in created_users:
        # Get pending friend requests and accept some
        # For now, we'll simulate by having users accept requests from their friends
        for friend_pair in friendship_pairs:
            if user["username"] in friend_pair:
                other_user = friend_pair[0] if friend_pair[1] == user["username"] else friend_pair[1]
                if other_user in user_tokens:
                    accept_friend_request(user["token"], other_user)
                    time.sleep(0.2)
    
    log(f"Created {len(friendship_pairs)} friendships")
    
    # 4. Generate and create events
    log("Generating events...")
    events = generate_events()
    
    log("Creating events...")
    for i, event_data in enumerate(events):
        # Select random host
        host = random.choice(created_users)
        
        # Create event
        event_id = create_event(host["token"], event_data)
        if event_id:
            created_events.append({
                "id": event_id,
                "host": host["username"],
                "data": event_data
            })
            
            # Invite friends to private events
            if not event_data["is_public"]:
                # Select 2-4 friends to invite
                host_friends = [u for u in created_users if u["username"] != host["username"]]
                friends_to_invite = random.sample(host_friends, min(random.randint(2, 4), len(host_friends)))
                friend_usernames = [f["username"] for f in friends_to_invite]
                
                invite_friends_to_event(host["token"], event_id, friend_usernames)
                time.sleep(0.3)
        
        time.sleep(0.5)  # Rate limiting
    
    log(f"Created {len(created_events)} events")
    
    # 5. RSVPs and join requests with approval
    log("Processing RSVPs and join requests...")
    pending_requests = []  # Store requests that need approval
    
    for event in created_events:
        # Random users try to RSVP to events
        num_rsvps = random.randint(2, 8)
        users_to_rsvp = random.sample(created_users, min(num_rsvps, len(created_users)))
        
        for user in users_to_rsvp:
            if user["username"] != event["host"]:  # Host doesn't RSVP to their own event
                if random.random() < 0.8:  # 80% chance to RSVP
                    result = rsvp_event(user["token"], event["id"])
                    if isinstance(result, dict) and result.get("action") == "request_sent":
                        # Store the request for later approval
                        pending_requests.append({
                            "request_id": result.get("request_id"),
                            "event_id": event["id"],
                            "event_host": event["host"],
                            "requester": user["username"]
                        })
                else:  # 20% chance to decline
                    decline_invite(user["token"], event["id"])
                time.sleep(0.2)
    
    # 6. Approve join requests (simulate host approval)
    log(f"Processing {len(pending_requests)} join requests...")
    approved_requests = 0
    rejected_requests = 0
    
    for request in pending_requests:
        # Find the host's token
        host_token = None
        for user in created_users:
            if user["username"] == request["event_host"]:
                host_token = user["token"]
                break
        
        if host_token:
            # Randomly approve or reject requests (80% approval rate)
            if random.random() < 0.8:
                if approve_join_request(host_token, request["request_id"]):
                    approved_requests += 1
                    log(f"Approved request from {request['requester']} to event {request['event_id']}")
            else:
                if reject_join_request(host_token, request["request_id"]):
                    rejected_requests += 1
                    log(f"Rejected request from {request['requester']} to event {request['event_id']}")
            time.sleep(0.3)
    
    log(f"Approved {approved_requests} requests, rejected {rejected_requests} requests")
    
    # 7. Add reviews (test reputation system)
    log("Adding reviews and ratings...")
    review_count = 0
    
    for event in created_events:
        # Get attendees and have them rate each other
        attendees = random.sample(created_users, random.randint(2, 5))
        
        for i, reviewer in enumerate(attendees):
            for j, reviewee in enumerate(attendees):
                if reviewer["username"] != reviewee["username"] and reviewer["username"] != event["host"]:
                    rating = random.randint(3, 5)  # Mostly positive ratings
                    reference_templates = [
                        f"Excelente compañero de estudio en {event['data']['title']}",
                        f"Muy buena persona, recomendado para futuros eventos",
                        f"Gran experiencia estudiando juntos",
                        f"Se portó muy bien en el evento",
                        f"Buena energía y actitud positiva"
                    ]
                    reference = random.choice(reference_templates)
                    
                    add_review(reviewer["token"], reviewee["username"], event["id"], rating, reference)
                    review_count += 1
                    time.sleep(0.3)
    
    log(f"Added {review_count} reviews")
    
    # 7. Social interactions (comments, likes, shares)
    log("Adding social interactions...")
    
    for event in created_events:
        # Add comments
        num_comments = random.randint(2, 6)
        commenters = random.sample(created_users, min(num_comments, len(created_users)))
        
        comment_templates = [
            "¡Excelente evento! Me divertí mucho",
            "Gracias por organizar esto",
            "¿Cuándo es el próximo?",
            "Muy buena experiencia",
            "Recomiendo este tipo de eventos",
            "¿Alguien más quiere estudiar después?",
            "¡Qué buena onda todos!"
        ]
        
        for commenter in commenters:
            if commenter["username"] != event["host"]:
                comment_text = random.choice(comment_templates)
                add_comment(commenter["token"], commenter["username"], event["id"], comment_text)
                time.sleep(0.2)
        
        # Add likes
        num_likes = random.randint(3, 8)
        likers = random.sample(created_users, min(num_likes, len(created_users)))
        
        for liker in likers:
            like_event(liker["token"], liker["username"], event["id"])
            time.sleep(0.1)
        
        # Add shares
        platforms = ["whatsapp", "instagram", "facebook"]
        num_shares = random.randint(1, 3)
        sharers = random.sample(created_users, min(num_shares, len(created_users)))
        
        for sharer in sharers:
            platform = random.choice(platforms)
            share_event(sharer["token"], event["id"], platform)
            time.sleep(0.2)
    
    # 8. Summary
    log("=== DATA GENERATION COMPLETE ===")
    log(f"Created {len(created_users)} users")
    log(f"Created {len(friendship_pairs)} friendships")
    log(f"Created {len(created_events)} events")
    log(f"Added {review_count} reviews")
    log("All PinIt features have been tested with realistic Buenos Aires data!")

if __name__ == "__main__":
    main()
