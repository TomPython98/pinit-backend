#!/usr/bin/env python
import os
import sys
import random
import string
import pytz
import uuid
from datetime import datetime, timedelta

# Set up Django environment
sys.path.append('.')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')

import django
django.setup()

from django.contrib.auth.models import User
from myapp.models import UserProfile, StudyEvent, EventInvitation

# Define locations across Vienna
vienna_locations = [
    # City Center
    {"name": "Stephansplatz", "lat": 48.2085, "lon": 16.3733},
    {"name": "Karlsplatz", "lat": 48.2007, "lon": 16.3703},
    {"name": "Museumsquartier", "lat": 48.2039, "lon": 16.3586},
    {"name": "Heldenplatz", "lat": 48.2065, "lon": 16.3663},
    # University Areas
    {"name": "University of Vienna", "lat": 48.2139, "lon": 16.3600},
    {"name": "Vienna University of Technology", "lat": 48.1990, "lon": 16.3670},
    {"name": "Vienna University of Economics and Business", "lat": 48.2140, "lon": 16.4104},
    {"name": "Medical University of Vienna", "lat": 48.2159, "lon": 16.3476},
    # Popular Student Areas
    {"name": "Naschmarkt", "lat": 48.1981, "lon": 16.3636},
    {"name": "Mariahilfer Straße", "lat": 48.1962, "lon": 16.3525},
    {"name": "Prater", "lat": 48.2163, "lon": 16.3977},
    {"name": "Donauinsel", "lat": 48.2262, "lon": 16.4159},
    # Coffee Shops & Study Spots
    {"name": "Café Central", "lat": 48.2108, "lon": 16.3660},
    {"name": "Phil", "lat": 48.1988, "lon": 16.3614},
    {"name": "Café Sperl", "lat": 48.1993, "lon": 16.3604},
    # Student Dorms/Residential Areas
    {"name": "Stuwerzzentrum", "lat": 48.2197, "lon": 16.4066},
    {"name": "OeAD Student Housing", "lat": 48.2103, "lon": 16.3731},
    # Parks
    {"name": "Stadtpark", "lat": 48.2052, "lon": 16.3820},
    {"name": "Augarten", "lat": 48.2199, "lon": 16.3776},
    {"name": "Burggarten", "lat": 48.2040, "lon": 16.3654},
]

# Define interest categories
interest_categories = {
    "Academic": [
        "Mathematics", "Computer Science", "Physics", "Chemistry", "Biology", 
        "Medicine", "Psychology", "Sociology", "Economics", "Business", 
        "Law", "Political Science", "History", "Philosophy", "Literature",
        "Languages", "Engineering", "Architecture", "Statistics", "Data Science"
    ],
    "Arts & Culture": [
        "Painting", "Drawing", "Photography", "Film", "Theater", 
        "Music", "Dance", "Sculpture", "Art History", "Design", 
        "Creative Writing", "Poetry", "Fashion", "Architecture", "Classical Music"
    ],
    "Sports & Fitness": [
        "Football", "Basketball", "Volleyball", "Tennis", "Running", 
        "Swimming", "Yoga", "Fitness", "Cycling", "Hiking", 
        "Martial Arts", "Rock Climbing", "Skiing", "Snowboarding", "Gym Workouts"
    ],
    "Leisure & Hobbies": [
        "Gaming", "Board Games", "Reading", "Cooking", "Baking", 
        "Travel", "Hiking", "Photography", "Gardening", "Crafts", 
        "Collecting", "DIY Projects", "Volunteering", "Meditation", "Wine Tasting"
    ],
    "Technology": [
        "Programming", "Web Development", "App Development", "Artificial Intelligence", "Machine Learning", 
        "Data Science", "Robotics", "Cybersecurity", "Blockchain", "AR/VR", 
        "Hardware", "UX/UI Design", "Game Development", "Open Source", "Cloud Computing"
    ]
}

# Flatten into a single list of interests
all_interests = []
for category, interests in interest_categories.items():
    all_interests.extend(interests)

# Event types with parameters (title templates, descriptions, durations)
event_types = {
    "study": {
        "titles": [
            "{subject} Study Group", 
            "{subject} Study Session", 
            "{subject} Exam Prep", 
            "{subject} Discussion Group",
            "{subject} Research Group",
            "Let's Study {subject} Together",
            "{subject} Workshop",
            "{subject} Tutoring Circle",
            "{subject} Problem Solving",
            "{subject} Reading Group"
        ],
        "descriptions": [
            "Join this study group to prepare for upcoming exams in {subject}. All levels welcome!",
            "Need help with {subject}? Let's study together and share notes.",
            "Intensive {subject} study session. Bring your materials and questions!",
            "Weekly {subject} study group. We'll go through practice problems and review key concepts.",
            "Let's tackle difficult {subject} topics together. Perfect for deepening your understanding."
        ],
        "duration": {"min": 1.5, "max": 3},
        "max_participants": {"min": 3, "max": 10}
    },
    "party": {
        "titles": [
            "Student Mixer", 
            "{subject} Department Party", 
            "International Student Gathering", 
            "Weekend Party",
            "End of Semester Celebration",
            "Thematic Party: {subject}",
            "Rooftop Social",
            "Dorm Party",
            "Welcome Party",
            "Farewell Party"
        ],
        "descriptions": [
            "Come meet fellow students and make new friends! Drinks and snacks provided.",
            "Time to relax after exams! Join us for a fun evening with music and good company.",
            "International student mixer - share your culture and meet people from around the world!",
            "End of semester celebration! Let's celebrate our hard work this term.",
            "Join us for a relaxed social gathering with games, music, and great conversations."
        ],
        "duration": {"min": 3, "max": 6},
        "max_participants": {"min": 10, "max": 50}
    },
    "trip": {
        "titles": [
            "Day Trip to {subject}", 
            "{subject} Exploration", 
            "Weekend Trip: {subject}", 
            "Student Trip to {subject}",
            "Hiking Trip: {subject}",
            "Cultural Visit: {subject}",
            "Adventure: {subject}",
            "Field Trip: {subject}",
            "Exploring {subject} Together",
            "Group Visit to {subject}"
        ],
        "descriptions": [
            "Join this day trip to explore {subject}. Transportation organized!",
            "Weekend getaway to {subject}. Great opportunity to relax and make new friends!",
            "Educational trip to {subject}. Expand your knowledge outside the classroom.",
            "Group hiking trip to {subject}. All fitness levels welcome.",
            "Exploring the cultural highlights of {subject}. Perfect for international students!"
        ],
        "duration": {"min": 5, "max": 72},
        "max_participants": {"min": 5, "max": 20}
    },
    "coffee": {
        "titles": [
            "Coffee & Chat", 
            "Coffee Break: {subject} Discussion", 
            "Morning Coffee Meetup", 
            "Coffee & Study",
            "Language Exchange over Coffee",
            "Coffee with {subject} Students",
            "Networking Coffee",
            "Coffee and Career Chat",
            "International Coffee Hour",
            "Subject Discussion over Coffee"
        ],
        "descriptions": [
            "Casual coffee meetup to discuss {subject} and get to know fellow students.",
            "Coffee break between classes. Come chat about {subject} or just relax.",
            "Weekly coffee gathering for students interested in {subject}.",
            "Practice languages over coffee in a relaxed atmosphere.",
            "Quick coffee break to decompress and meet new people."
        ],
        "duration": {"min": 1, "max": 2},
        "max_participants": {"min": 2, "max": 8}
    },
    "business": {
        "titles": [
            "Networking Event: {subject}", 
            "{subject} Industry Meetup", 
            "Startup Pitch: {subject}", 
            "Business Workshop: {subject}",
            "Career Panel: {subject}",
            "Professional Skills in {subject}",
            "Entrepreneur Meetup",
            "Job Search Strategies for {subject}",
            "Industry Insights: {subject}",
            "Business Case Competition"
        ],
        "descriptions": [
            "Networking event for students interested in careers in {subject}.",
            "Meet industry professionals and learn about opportunities in {subject}.",
            "Workshop on entrepreneurship and business skills for {subject} students.",
            "Career preparation event focusing on the {subject} industry.",
            "Develop your professional network and skills in the {subject} field."
        ],
        "duration": {"min": 1.5, "max": 3},
        "max_participants": {"min": 10, "max": 30}
    },
    "other": {
        "titles": [
            "Movie Night: {subject}", 
            "Game Night", 
            "Cooking Together: {subject} Cuisine", 
            "Sports: {subject}",
            "Book Club: {subject}",
            "Art Workshop: {subject}",
            "Music Jam Session",
            "Debate: {subject}",
            "Volunteer Activity",
            "Cultural Exchange"
        ],
        "descriptions": [
            "Casual movie night featuring films related to {subject}.",
            "Join us for board games and fun with fellow students!",
            "Learn to cook dishes from different cultures. This week: {subject} cuisine!",
            "Weekly sports activity focusing on {subject}. All skill levels welcome.",
            "Relaxed gathering for students to share interests in {subject}."
        ],
        "duration": {"min": 2, "max": 4},
        "max_participants": {"min": 4, "max": 15}
    }
}

def generate_username(first_name, last_name):
    """Generate a unique username based on name"""
    username = f"{first_name.lower()}_{last_name.lower()}"
    # Add a random number if needed to make it unique
    if User.objects.filter(username=username).exists():
        username = f"{username}{random.randint(1, 999)}"
    return username

def create_users(num_users=50):
    """Create student users with profiles and interests"""
    
    # Common first and last names from various countries
    first_names = [
        "Anna", "Lukas", "Emma", "Felix", "Sophie", "David", "Laura", "Maximilian", 
        "Julia", "Alexander", "Maria", "Thomas", "Sarah", "Michael", "Lisa", "Andreas",
        "Melanie", "Stefan", "Nina", "Markus", "Christina", "Martin", "Katharina", "Daniel",
        "Eva", "Peter", "Teresa", "Jakob", "Victoria", "Florian", "Sophia", "Paul",
        "Elena", "Jan", "Chiara", "Philipp", "Lena", "Tobias", "Hannah", "Simon",
        "Olivia", "Benjamin", "Emilia", "Noah", "Mia", "Jonas", "Amelia", "Lucas",
        "Isabella", "Elias", "Charlotte", "Gabriel", "Julia", "Leo", "Sofia", "Samuel",
        "Valentina", "Rafael", "Ava", "Alessandro", "Alice", "Antonio", "Grace", "Carlos"
    ]
    
    last_names = [
        "Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner", "Becker",
        "Schulz", "Hoffmann", "Novak", "Horvath", "Kovacs", "Nagy", "Bauer", "Gruber",
        "Huber", "Steiner", "Mayer", "Hofer", "Pichler", "Moser", "Reiter", "Berger",
        "Rossi", "Ferrari", "Esposito", "Romano", "Ricci", "Marino", "Smith", "Johnson",
        "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Martin", "Anderson",
        "Garcia", "Martinez", "Rodriguez", "Hernandez", "Lopez", "Gonzalez", "Perez", "Sanchez",
        "Silva", "Santos", "Oliveira", "Souza", "Rodrigues", "Ferreira", "Almeida", "Costa",
        "Jovanovic", "Popovic", "Djordjevic", "Stojanovic", "Markovic", "Petrovic", "Nikolic", "Dimitrov"
    ]
    
    print(f"Creating {num_users} student users...")
    created_users = []
    
    for i in range(num_users):
        first_name = random.choice(first_names)
        last_name = random.choice(last_names)
        username = generate_username(first_name, last_name)
        
        # Create users with simple passwords for testing
        user = User.objects.create_user(
            username=username,
            password="password123",
            first_name=first_name,
            last_name=last_name
        )
        
        # Create user profile
        profile = UserProfile.objects.get(user=user)
        
        # Set random interests (3-8 interests per user)
        num_interests = random.randint(3, 8)
        user_interests = random.sample(all_interests, num_interests)
        
        # Ensure interests are properly set
        if hasattr(profile, 'set_interests'):
            profile.set_interests(user_interests)
            # Verify that interests were properly saved
            saved_interests = profile.get_interests() if hasattr(profile, 'get_interests') else []
            print(f"  User {username} interests: {', '.join(saved_interests) if saved_interests else 'None'}")
        else:
            # Fallback: store as a basic list
            profile.interests = user_interests
            profile.save()
            print(f"  User {username} interests (fallback): {', '.join(user_interests)}")
        
        # Enable auto-matching for most users
        profile.auto_invite_enabled = random.random() < 0.8  # 80% likely to be enabled
        
        # Set preferred radius between 2-15 km
        profile.preferred_radius = round(random.uniform(2.0, 15.0), 1)
        
        # Certify some users (about 20%)
        profile.is_certified = random.random() < 0.2
        
        profile.save()
        created_users.append(user)
        
        print(f"Created user {i+1}/{num_users}: {username}")
    
    return created_users

def create_events(users, num_events=100):
    """Create various study events across Vienna"""
    print(f"\nCreating {num_events} events across Vienna...")
    created_events = []
    
    # Current time as reference point
    now = datetime.now(pytz.UTC)
    
    for i in range(num_events):
        # Select a random host user
        host = random.choice(users)
        
        # Select a random location in Vienna
        location = random.choice(vienna_locations)
        
        # Determine if event is public (80% chance) or private
        is_public = random.random() < 0.8
        
        # Select random event type
        event_type = random.choice(list(event_types.keys()))
        event_params = event_types[event_type]
        
        # Pick a random interest as the subject
        subject = random.choice(all_interests)
        
        # Generate title and description
        title_template = random.choice(event_params["titles"])
        title = title_template.replace("{subject}", subject)
        
        description_template = random.choice(event_params["descriptions"])
        description = description_template.replace("{subject}", subject)
        
        # Set event time (between now and 14 days in the future)
        days_ahead = random.randint(0, 14)
        hours_ahead = random.randint(0, 23)
        event_start = now + timedelta(days=days_ahead, hours=hours_ahead)
        
        # Set event duration
        duration_hours = random.uniform(event_params["duration"]["min"], event_params["duration"]["max"])
        event_end = event_start + timedelta(hours=duration_hours)
        
        # Set max participants
        max_participants = random.randint(
            event_params["max_participants"]["min"], 
            event_params["max_participants"]["max"]
        )
        
        # Determine if auto-matching should be enabled (60% chance)
        auto_matching_enabled = random.random() < 0.6
        
        # Create the event
        event = StudyEvent.objects.create(
            title=title,
            description=description,
            host=host,
            latitude=location["lat"] + random.uniform(-0.005, 0.005),  # Add small random variation
            longitude=location["lon"] + random.uniform(-0.005, 0.005),
            time=event_start,
            end_time=event_end,
            is_public=is_public,
            event_type=event_type,
            max_participants=max_participants,
            auto_matching_enabled=auto_matching_enabled
        )
        
        # Set interest tags (include the subject plus 0-3 random additional interests)
        interest_tags = [subject]
        num_additional = random.randint(0, 3)
        additional_interests = random.sample(all_interests, num_additional)
        for interest in additional_interests:
            if interest not in interest_tags:
                interest_tags.append(interest)
        
        event.set_interest_tags(interest_tags)
        
        # Invite 0-5 friends
        num_invites = random.randint(0, 5)
        potential_invitees = [u for u in users if u != host]
        if potential_invitees and num_invites > 0:
            invitees = random.sample(potential_invitees, min(num_invites, len(potential_invitees)))
            for invitee in invitees:
                event.invite_user(invitee, is_auto_matched=False)
        
        # Make some users attend the event (0-3 friends)
        num_attendees = random.randint(0, 3)
        potential_attendees = [u for u in users if u != host]
        if potential_attendees and num_attendees > 0:
            attendees = random.sample(potential_attendees, min(num_attendees, len(potential_attendees)))
            for attendee in attendees:
                event.attendees.add(attendee)
        
        event.save()
        created_events.append(event)
        
        # Log progress
        print(f"Created event {i+1}/{num_events}: {title}")
    
    return created_events

def perform_auto_matching(events, users):
    """Perform auto-matching for events that have it enabled"""
    print("\nPerforming auto-matching...")
    
    # Debug: Print user interests
    print("\nUser Interests:")
    for user in users:
        interests = user.userprofile.get_interests() if hasattr(user.userprofile, 'get_interests') else []
        print(f"User {user.username}: {', '.join(interests) if interests else 'No interests found'}")
    
    matched_count = 0
    for event in events:
        if not event.auto_matching_enabled:
            continue
        
        # Get the event's interest tags
        event_interests = event.get_interest_tags() if hasattr(event, 'get_interest_tags') else []
        if not event_interests:
            print(f"Warning: Event {event.id} ({event.title}) has no interest tags")
            continue
        
        print(f"\nLooking for matches for event: {event.title}")
        print(f"Event interests: {', '.join(event_interests)}")
        
        # Find potential matches
        event_host = event.host
        matched_users_for_event = 0
        
        for user in users:
            # Skip if user is the host, already invited, or already attending
            if (user == event_host or 
                user in event.invited_friends.all() or 
                user in event.attendees.all()):
                continue
            
            # Get user's profile and interests
            profile = user.userprofile
            if not profile.auto_invite_enabled:
                continue
                
            user_interests = profile.get_interests() if hasattr(profile, 'get_interests') else []
            if not user_interests:
                continue
            
            # Debug output
            print(f"  Checking user {user.username} with interests: {', '.join(user_interests)}")
            
            # Calculate interest overlap
            matching_interests = set(user_interests).intersection(set(event_interests))
            
            # If there's at least one matching interest, create auto-match
            if matching_interests:
                try:
                    # First add to invited_friends (many-to-many field)
                    event.invited_friends.add(user)
                    
                    # Then create the invitation record
                    EventInvitation.objects.create(
                        event=event,
                        user=user,
                        is_auto_matched=True
                    )
                    
                    matched_count += 1
                    matched_users_for_event += 1
                    print(f"  ✓ Auto-matched user {user.username} to event '{event.title}' based on interests: {', '.join(matching_interests)}")
                except Exception as e:
                    print(f"  ✗ Failed to auto-match user {user.username} to event '{event.title}': {str(e)}")
            else:
                print(f"  ✗ No matching interests between user {user.username} and event")
        
        print(f"Total matches for event '{event.title}': {matched_users_for_event}")
    
    print(f"\nCompleted auto-matching with {matched_count} matches")

def clear_existing_data():
    """Clear existing users and events before populating"""
    # Don't delete the admin/superuser accounts
    regular_users = User.objects.filter(is_superuser=False, is_staff=False)
    regular_user_count = regular_users.count()
    if regular_user_count > 0:
        print(f"Deleting {regular_user_count} existing regular users...")
        regular_users.delete()
    
    # Count and delete existing events
    events_count = StudyEvent.objects.count()
    if events_count > 0:
        print(f"Deleting {events_count} existing events...")
        StudyEvent.objects.all().delete()
    
    # Also clear invitations
    invitations_count = EventInvitation.objects.count()
    if invitations_count > 0:
        print(f"Deleting {invitations_count} existing invitations...")
        EventInvitation.objects.all().delete()

def main():
    # Clear existing test data
    clear_existing_data()
    
    # Create users
    users = create_users(num_users=50)
    
    # Create events
    events = create_events(users, num_events=100)
    
    # Perform auto-matching
    perform_auto_matching(events, users)
    
    print("\nDatabase population completed!")
    print(f"Created {len(users)} users")
    print(f"Created {len(events)} events")
    print(f"Vienna student life simulation is ready!")

if __name__ == "__main__":
    main() 