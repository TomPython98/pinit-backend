#!/usr/bin/env python3
"""
Buenos Aires International Students Simulation
Generates users, events, and data for Buenos Aires with international students
"""

import os
import sys
import django
import random
import uuid
from datetime import datetime, timedelta
from faker import Faker
import json

# Add the Django project directory to the Python path
sys.path.append('/Users/tombesinger/Desktop/Real_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import User, UserProfile, StudyEvent, EventInvitation, UserSkill, UserInterest, UserRating, UserTrustLevel, UserReputationStats
from django.contrib.auth.hashers import make_password

# Initialize Faker with Spanish locale for Buenos Aires
fake = Faker(['es_ES', 'en_US', 'pt_BR', 'fr_FR', 'de_DE', 'it_IT'])

# Buenos Aires neighborhoods and coordinates
BUENOS_AIRES_LOCATIONS = {
    'Palermo': {'lat': -34.5889, 'lng': -58.4108},
    'Recoleta': {'lat': -34.5875, 'lng': -58.3935},
    'San Telmo': {'lat': -34.6211, 'lng': -58.3731},
    'Puerto Madero': {'lat': -34.6108, 'lng': -58.3650},
    'Belgrano': {'lat': -34.5622, 'lng': -58.4561},
    'Caballito': {'lat': -34.6200, 'lng': -58.4400},
    'Villa Crespo': {'lat': -34.6000, 'lng': -58.4333},
    'Barracas': {'lat': -34.6500, 'lng': -58.3667},
    'La Boca': {'lat': -34.6344, 'lng': -58.3631},
    'Monserrat': {'lat': -34.6083, 'lng': -58.3731},
    'Retiro': {'lat': -34.5917, 'lng': -58.3750},
    'Congreso': {'lat': -34.6083, 'lng': -58.3917},
    'Almagro': {'lat': -34.6083, 'lng': -58.4167},
    'Boedo': {'lat': -34.6250, 'lng': -58.4167},
    'Flores': {'lat': -34.6333, 'lng': -58.4667}
}

# International universities in Buenos Aires
UNIVERSITIES = [
    'Universidad de Buenos Aires (UBA)',
    'Universidad Torcuato di Tella',
    'Universidad de San Andrés',
    'Universidad del Salvador',
    'Universidad Católica Argentina',
    'Universidad de Palermo',
    'Universidad Argentina de la Empresa',
    'Universidad de Belgrano',
    'Universidad Maimónides',
    'Universidad Favaloro'
]

# Study interests for international students
INTERESTS = [
    'Spanish Language', 'Tango', 'Argentine Literature', 'Latin American History',
    'International Business', 'Economics', 'Political Science', 'Cultural Exchange',
    'Photography', 'Cooking', 'Music', 'Art', 'Architecture', 'Travel',
    'Language Exchange', 'Volunteering', 'Environmental Studies', 'Journalism',
    'Film Studies', 'Psychology', 'Sociology', 'Anthropology', 'Philosophy',
    'International Relations', 'Development Studies', 'Human Rights', 'Gender Studies'
]

# Event types with Buenos Aires flavor
EVENT_TYPES = ['study', 'cultural', 'language_exchange', 'social', 'academic', 'networking']

# Event titles in Spanish and English
EVENT_TITLES = [
    'Spanish Conversation Club', 'Tango Lessons for Beginners', 'Argentine Literature Discussion',
    'International Students Meetup', 'Buenos Aires History Tour', 'Language Exchange Café',
    'Study Group: Economics', 'Cultural Exchange Dinner', 'Photography Walk in Palermo',
    'Academic Writing Workshop', 'Networking Event for Internationals', 'Cooking Argentine Food',
    'Museum Visit: MALBA', 'Study Session: Spanish Grammar', 'City Exploration Group',
    'International Film Club', 'Volunteer Work Together', 'Art Gallery Tour',
    'Study Group: Political Science', 'Cultural Festival Planning', 'Language Practice Group',
    'Academic Research Collaboration', 'International Students Support', 'Cultural Immersion Day',
    'Study Group: History', 'Language Exchange Partner', 'Cultural Activities Planning'
]

def generate_international_users(num_users=200):
    """Generate international students living in Buenos Aires"""
    users = []
    
    # Nationalities for international students
    nationalities = [
        'American', 'Brazilian', 'French', 'German', 'Italian', 'British', 'Canadian',
        'Australian', 'Spanish', 'Portuguese', 'Dutch', 'Swedish', 'Norwegian',
        'Japanese', 'Korean', 'Chinese', 'Indian', 'Mexican', 'Chilean', 'Colombian',
        'Peruvian', 'Uruguayan', 'Paraguayan', 'Bolivian', 'Ecuadorian', 'Venezuelan'
    ]
    
    for i in range(num_users):
        # Generate user data
        nationality = random.choice(nationalities)
        first_name = fake.first_name()
        last_name = fake.last_name()
        username = f"{first_name.lower()}_{last_name.lower()}_{random.randint(100, 999)}"
        email = f"{username}@example.com"
        
        # Create user
        user = User.objects.create(
            username=username,
            email=email,
            password=make_password('buenosaires123'),
            first_name=first_name,
            last_name=last_name
        )
        
        # Create user profile
        neighborhood = random.choice(list(BUENOS_AIRES_LOCATIONS.keys()))
        location = BUENOS_AIRES_LOCATIONS[neighborhood]
        
        # Generate interests for this user
        user_interests = random.sample(INTERESTS, random.randint(3, 8))
        
        # Update the automatically created profile
        profile = user.userprofile
        profile.bio = f"International student from {nationality} studying in Buenos Aires. Love exploring the city and meeting new people!"
        profile.university = random.choice(UNIVERSITIES)
        profile.degree = random.choice(['Bachelor', 'Master', 'PhD', 'Exchange Student'])
        profile.year = random.choice(['1st Year', '2nd Year', '3rd Year', '4th Year', 'Graduate'])
        profile.full_name = f"{first_name} {last_name}"
        profile.is_certified = random.choice([True, False])
        profile.interests = user_interests
        profile.skills = {interest: random.choice(['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT']) for interest in user_interests[:5]}
        profile.auto_invite_enabled = random.choice([True, False])
        profile.preferred_radius = random.uniform(5.0, 25.0)
        profile.save()
        
        # Add interests
        for interest in user_interests:
            UserInterest.objects.create(user_profile=profile, interest=interest)
        
        # Add skills
        skills = random.sample(INTERESTS, random.randint(2, 5))
        for skill in skills:
            UserSkill.objects.create(user_profile=profile, skill=skill, level=random.choice(['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT']))
        
        # Create reputation stats
        UserReputationStats.objects.create(
            user=user,
            total_ratings=random.randint(0, 20),
            average_rating=random.uniform(3.0, 5.0),
            events_hosted=random.randint(0, 5),
            events_attended=random.randint(0, 15)
        )
        
        users.append(user)
        print(f"Created user: {username} from {nationality}")
    
    return users

def generate_buenos_aires_events(users, num_events=150):
    """Generate study events in Buenos Aires"""
    events = []
    
    for i in range(num_events):
        # Select random host
        host = random.choice(users)
        neighborhood = random.choice(list(BUENOS_AIRES_LOCATIONS.keys()))
        location = BUENOS_AIRES_LOCATIONS[neighborhood]
        
        # Generate event data
        title = random.choice(EVENT_TITLES)
        event_type = random.choice(EVENT_TYPES)
        description = f"Join us for {title.lower()} in {neighborhood}! Perfect for international students looking to connect and learn."
        
        # Random date within next 30 days
        start_time = fake.date_time_between(start_date='now', end_date='+30d')
        
        # Generate interest tags for the event
        event_interests = random.sample(INTERESTS, random.randint(2, 5))
        
        event = StudyEvent.objects.create(
            id=str(uuid.uuid4()),
            title=title,
            description=description,
            event_type=event_type,
            latitude=location['lat'] + random.uniform(-0.005, 0.005),
            longitude=location['lng'] + random.uniform(-0.005, 0.005),
            time=start_time,
            host=host,
            max_participants=random.randint(5, 25),
            auto_matching_enabled=random.choice([True, False]),
            is_public=not (random.random() < 0.3),  # 30% private events
            interest_tags=event_interests
        )
        
        # Add some attendees
        num_attendees = random.randint(0, min(10, event.max_participants))
        attendees = random.sample([u for u in users if u != host], num_attendees)
        event.attendees.set(attendees)
        
        events.append(event)
        print(f"Created event: {title} in {neighborhood}")
    
    return events

def create_private_invitations(users, events):
    """Create private invitations for international students"""
    invitations = []
    
    # Select events that are private
    private_events = [e for e in events if not e.is_public]
    
    for event in private_events:
        # Create 3-8 private invitations per private event
        num_invitations = random.randint(3, 8)
        invited_users = random.sample([u for u in users if u != event.host], num_invitations)
        
        for user in invited_users:
            invitation = EventInvitation.objects.create(
                event=event,
                user=user,
                is_auto_matched=False
            )
            invitations.append(invitation)
            print(f"Created private invitation: {user.username} -> {event.title}")
    
    return invitations

def run_auto_matching(events):
    """Run auto-matching for events"""
    matched_events = 0
    
    for event in events:
        if event.auto_matching_enabled:
            # Find users with matching interests
            event_interests = event.interest_tags
            
            if event_interests:
                # Find users with at least 2 matching interests
                matching_users = User.objects.filter(
                    userprofile__interests__overlap=event_interests
                ).distinct().exclude(
                    id=event.host.id
                ).exclude(
                    id__in=event.attendees.all()
                )
                
                # Create auto-match invitations
                for user in matching_users[:5]:  # Limit to 5 auto-matches
                    EventInvitation.objects.create(
                        event=event,
                        user=user,
                        is_auto_matched=True
                    )
                
                matched_events += 1
                print(f"Auto-matched event: {event.title}")
    
    return matched_events

def main():
    print("🌎 Starting Buenos Aires International Students Simulation...")
    
    # Clear existing data (optional - comment out if you want to keep existing data)
    print("Clearing existing data...")
    User.objects.all().delete()
    
    # Generate users
    print("Creating international students...")
    users = generate_international_users(200)
    
    # Generate events
    print("Creating Buenos Aires events...")
    events = generate_buenos_aires_events(users, 150)
    
    # Create private invitations
    print("Creating private invitations...")
    invitations = create_private_invitations(users, events)
    
    # Run auto-matching
    print("Running auto-matching...")
    matched_events = run_auto_matching(events)
    
    # Generate some user ratings
    print("Creating user ratings...")
    for _ in range(100):
        rater = random.choice(users)
        rated_user = random.choice([u for u in users if u != rater])
        
        UserRating.objects.create(
            from_user=rater,
            to_user=rated_user,
            rating=random.randint(3, 5),
            reference=fake.sentence()
        )
    
    print(f"\n🎉 Buenos Aires Simulation Complete!")
    print(f"✅ Created {len(users)} international students")
    print(f"✅ Created {len(events)} events in Buenos Aires")
    print(f"✅ Created {len(invitations)} private invitations")
    print(f"✅ Auto-matched {matched_events} events")
    print(f"✅ Created 100 user ratings")
    
    # Save credentials
    credentials = []
    for user in users[:20]:  # Save first 20 for testing
        credentials.append(f"{user.username},buenosaires123,{user.email}")
    
    with open('buenos_aires_credentials.txt', 'w') as f:
        f.write("Buenos Aires International Students Credentials\n")
        f.write("=" * 50 + "\n\n")
        f.write("Username,Password,Email\n")
        for cred in credentials:
            f.write(cred + "\n")
    
    print(f"✅ Saved credentials to buenos_aires_credentials.txt")

if __name__ == "__main__":
    main()
