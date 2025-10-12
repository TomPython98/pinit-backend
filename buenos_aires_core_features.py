#!/usr/bin/env python3
"""
Buenos Aires Comprehensive Data Generation - Core Features Only
Creates users, events, and tests core functionality without friendships
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

def rsvp_event(token, event_id):
    """RSVP to an event"""
    log(f"RSVPing to event {event_id}")
    
    result = make_request("POST", "/api/rsvp_study_event/", {"event_id": event_id}, token)
    if result:
        log(f"Successfully RSVPed to event {event_id}")
        return True
    else:
        log(f"Failed to RSVP to event {event_id}")
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

def add_comment(token, event_id, text, username):
    """Add a comment to an event"""
    log(f"Adding comment to event {event_id}")
    
    comment_data = {
        "username": username,
        "event_id": event_id,
        "text": text
    }
    
    result = make_request("POST", "/api/events/comment/", comment_data, token)
    if result:
        log(f"Successfully added comment to event {event_id}")
        return True
    else:
        log(f"Failed to add comment to event {event_id}")
        return False

def like_event(token, event_id, username):
    """Like an event"""
    log(f"Liking event {event_id}")
    
    result = make_request("POST", "/api/events/like/", {"username": username, "event_id": event_id}, token)
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

def main():
    """Main execution function - Core features test"""
    log("Starting Buenos Aires core features data generation...")
    
    # Create 15 Argentine users
    argentine_users = []
    
    first_names = ["Alejandro", "María", "Carlos", "Ana", "Diego", "Sofia", "Martín", "Valentina", "Nicolás", "Camila", "Sebastián", "Lucía", "Federico", "Isabella", "Gabriel"]
    last_names = ["García", "Rodríguez", "Martínez", "Fernández", "López", "González", "Pérez", "Sánchez", "Ramírez", "Torres", "Flores", "Rivera", "Gómez", "Díaz", "Cruz"]
    universities = ["Universidad de Buenos Aires (UBA)", "Universidad de Palermo", "Universidad Torcuato Di Tella (UTDT)", "Universidad Argentina de la Empresa (UADE)", "Universidad Católica Argentina (UCA)"]
    degrees = ["Medicina", "Derecho", "Ingeniería", "Administración de Empresas", "Psicología", "Arquitectura", "Ciencias de la Computación", "Economía", "Comunicación Social", "Diseño Gráfico"]
    years = ["1er año", "2do año", "3er año", "4to año", "5to año"]
    interests_list = ["Derecho", "Medicina", "Ingeniería", "Tango", "Fútbol", "Mate", "Coding", "Arte", "Música", "Literatura", "Historia", "Política", "Deportes", "Viajes", "Fotografía", "Cine", "Teatro", "Gastronomía", "Idiomas"]
    skills_list = ["Spanish", "English", "Python", "Java", "JavaScript", "Leadership", "Design", "Public Speaking", "Teamwork", "Problem Solving", "Communication", "Project Management", "Data Analysis", "Marketing", "Sales", "Teaching", "Writing", "Research"]
    
    for i in range(15):
        first_name = random.choice(first_names)
        last_name = random.choice(last_names)
        username = f"{first_name.lower()}_{last_name.lower()}_{i+1}"
        full_name = f"{first_name} {last_name}"
        university = random.choice(universities)
        degree = random.choice(degrees)
        year = random.choice(years)
        
        bio_templates = [
            f"Estudiante de {degree} en {university}. Me gusta estudiar y conocer gente nueva.",
            f"Soy {first_name}, estudiante de {degree}. Amo Buenos Aires y su cultura.",
            f"Estudiante de {university}. Me interesa {random.choice(interests_list)} y {random.choice(interests_list)}.",
            f"Hola! Soy {first_name}, estudiante de {degree}. Siempre buscando nuevas experiencias.",
            f"Estudiante de {university}. Me gusta el mate, el fútbol y estudiar con amigos."
        ]
        bio = random.choice(bio_templates)
        
        user_interests = random.sample(interests_list, random.randint(3, 6))
        
        # Generate skills (2-4 skills) as dictionary with proficiency levels
        skill_names = random.sample(skills_list, random.randint(2, 4))
        proficiency_levels = ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"]
        user_skills = {}
        for skill in skill_names:
            user_skills[skill] = random.choice(proficiency_levels)
        
        user_data = {
            "username": username,
            "password": "test123456",
            "full_name": full_name,
            "university": university,
            "degree": degree,
            "year": year,
            "bio": bio,
            "interests": user_interests,
            "skills": user_skills
        }
        
        argentine_users.append(user_data)
    
    # Create users
    created_users = []
    for user_data in argentine_users:
        user = create_user(**user_data)
        if user:
            created_users.append(user)
        time.sleep(0.5)  # Rate limiting
    
    log(f"Created {len(created_users)} users")
    
    # Create diverse events across Buenos Aires
    ba_locations = [
        {"name": "UBA Facultad de Derecho", "lat": -34.5997, "lon": -58.3979},
        {"name": "Puerto Madero", "lat": -34.6037, "lon": -58.3656},
        {"name": "Bosques de Palermo", "lat": -34.5739, "lon": -58.4158},
        {"name": "Centro Cultural Recoleta", "lat": -34.5875, "lon": -58.3925},
        {"name": "Mercado de San Telmo", "lat": -34.6217, "lon": -58.3722},
        {"name": "Biblioteca Nacional", "lat": -34.5923, "lon": -58.3932},
        {"name": "MALBA", "lat": -34.5772, "lon": -58.4032},
        {"name": "Café Tortoni", "lat": -34.6082, "lon": -58.3756},
        {"name": "Jardín Botánico", "lat": -34.5815, "lon": -58.4190},
        {"name": "Plaza de Mayo", "lat": -34.6082, "lon": -58.3742}
    ]
    
    event_templates = [
        # Study Events
        {"title": "Grupo de Estudio - Derecho Civil", "desc": "Sesión de estudio para Derecho Civil. Repasaremos contratos y obligaciones.", "type": "study", "tags": ["Derecho", "Estudio", "Contratos"], "public": True, "auto": True},
        {"title": "Preparación CBC Medicina", "desc": "Grupo de estudio para el Ciclo Básico Común de Medicina. Química y Biología.", "type": "study", "tags": ["Medicina", "CBC", "Química"], "public": True, "auto": True},
        {"title": "Proyecto de Ingeniería - Robótica", "desc": "Colaboración en proyecto de robótica. Todos los niveles son bienvenidos.", "type": "study", "tags": ["Ingeniería", "Robótica", "Proyecto"], "public": False, "auto": True},
        
        # Party Events
        {"title": "Asado en Palermo", "desc": "Asado tradicional argentino en el parque. ¡Trae tu mate!", "type": "party", "tags": ["Asado", "Mate", "Social"], "public": False, "auto": False},
        {"title": "Pub Crawl Palermo", "desc": "Recorrido por los mejores bares de Palermo. ¡Vamos a divertirnos!", "type": "party", "tags": ["Bares", "Palermo", "Social"], "public": False, "auto": False},
        {"title": "Fiesta en Puerto Madero", "desc": "Fiesta en rooftop con vista al río. Dress code: elegante casual.", "type": "party", "tags": ["Puerto Madero", "Fiesta", "Rooftop"], "public": False, "auto": False},
        
        # Business Events
        {"title": "Networking de Startups", "desc": "Encuentro de emprendedores y startups. Presentaciones y networking.", "type": "business", "tags": ["Startups", "Emprendimiento", "Networking"], "public": True, "auto": True},
        {"title": "Workshop de Marketing Digital", "desc": "Taller práctico de marketing digital y redes sociales.", "type": "business", "tags": ["Marketing", "Digital", "Redes Sociales"], "public": True, "auto": True},
        
        # Cultural Events
        {"title": "Clase de Tango", "desc": "Aprende tango argentino con instructores profesionales. Todos los niveles.", "type": "other", "tags": ["Tango", "Danza", "Cultura Argentina"], "public": True, "auto": True},
        {"title": "Exposición de Arte Contemporáneo", "desc": "Visita guiada a la exposición de arte contemporáneo en MALBA.", "type": "other", "tags": ["Arte", "MALBA", "Cultura"], "public": True, "auto": True},
        
        # Other Events
        {"title": "Partido de Fútbol - Boca vs River", "desc": "Ver el superclásico juntos en un bar. ¡Vamos Boca!", "type": "other", "tags": ["Fútbol", "Boca", "Superclásico"], "public": True, "auto": True},
        {"title": "Círculo de Mate", "desc": "Ronda de mate y charla en el Jardín Botánico. ¡Trae tu mate y yerba!", "type": "other", "tags": ["Mate", "Jardín Botánico", "Charla"], "public": True, "auto": True}
    ]
    
    created_events = []
    
    # Create 20 events
    for i in range(20):
        template = random.choice(event_templates)
        location = random.choice(ba_locations)
        host = random.choice(created_users)
        
        # Generate event time (next 1-30 days, reasonable hours)
        days_ahead = random.randint(1, 30)
        hour = random.randint(9, 21)  # 9 AM to 9 PM
        minute = random.choice([0, 30])
        
        event_time = datetime.now() + timedelta(days=days_ahead, hours=hour, minutes=minute)
        end_time = event_time + timedelta(hours=random.randint(1, 4))
        
        event_data = {
            "title": template["title"],
            "description": template["desc"],
            "latitude": location["lat"],
            "longitude": location["lon"],
            "time": event_time.isoformat(),
            "end_time": end_time.isoformat(),
            "event_type": template["type"],
            "interest_tags": template["tags"],
            "is_public": template["public"],
            "auto_matching_enabled": template["auto"],
            "max_participants": random.randint(4, 15)
        }
        
        event_id = create_event(host["token"], event_data)
        if event_id:
            created_events.append({
                "id": event_id,
                "host": host["username"],
                "data": event_data
            })
        
        time.sleep(0.5)  # Rate limiting
    
    log(f"Created {len(created_events)} events")
    
    # RSVPs and social interactions
    log("Adding RSVPs and social interactions...")
    
    rsvp_count = 0
    comment_count = 0
    like_count = 0
    share_count = 0
    review_count = 0
    
    for event in created_events:
        # Random users RSVP to events
        num_rsvps = random.randint(2, 6)
        users_to_rsvp = random.sample(created_users, min(num_rsvps, len(created_users)))
        
        for user in users_to_rsvp:
            if user["username"] != event["host"]:  # Host doesn't RSVP to their own event
                if random.random() < 0.8:  # 80% chance to RSVP
                    if rsvp_event(user["token"], event["id"]):
                        rsvp_count += 1
                    time.sleep(0.2)
        
        # Add comments
        num_comments = random.randint(1, 4)
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
                if add_comment(commenter["token"], event["id"], comment_text, commenter["username"]):
                    comment_count += 1
                time.sleep(0.2)
        
        # Add likes
        num_likes = random.randint(2, 5)
        likers = random.sample(created_users, min(num_likes, len(created_users)))
        
        for liker in likers:
            if like_event(liker["token"], event["id"], liker["username"]):
                like_count += 1
            time.sleep(0.1)
        
        # Add shares
        platforms = ["whatsapp", "instagram", "facebook"]
        num_shares = random.randint(1, 2)
        sharers = random.sample(created_users, min(num_shares, len(created_users)))
        
        for sharer in sharers:
            platform = random.choice(platforms)
            if share_event(sharer["token"], event["id"], platform):
                share_count += 1
            time.sleep(0.2)
        
        # Add reviews for attendees
        attendees = random.sample(created_users, random.randint(2, 4))
        
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
                    
                    if add_review(reviewer["token"], reviewee["username"], event["id"], rating, reference):
                        review_count += 1
                    time.sleep(0.3)
    
    # Summary
    log("=== CORE FEATURES DATA GENERATION COMPLETE ===")
    log(f"Created {len(created_users)} users")
    log(f"Created {len(created_events)} events")
    log(f"Added {rsvp_count} RSVPs")
    log(f"Added {comment_count} comments")
    log(f"Added {like_count} likes")
    log(f"Added {share_count} shares")
    log(f"Added {review_count} reviews")
    log("Core PinIt features have been tested with realistic Buenos Aires data!")
    
    # Print sample data for verification
    log("\nSample users created:")
    for i, user in enumerate(created_users[:5]):
        log(f"  {i+1}. {user['username']}: {user['full_name']} ({user['degree']}, {user['year']})")
    
    log("\nSample events created:")
    for i, event in enumerate(created_events[:5]):
        log(f"  {i+1}. {event['data']['title']} (Host: {event['host']})")

if __name__ == "__main__":
    main()
