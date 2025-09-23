#!/usr/bin/env python
import os
import sys
import random
import string
from datetime import datetime, timedelta, timezone
import json

# Set up Django environment
sys.path.append('.')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')

import django
django.setup()

from django.contrib.auth.models import User
from myapp.models import UserProfile, StudyEvent, EventInvitation, SKILL_LEVEL_CHOICES
from django.db import connection

# Define Austrian cities with locations
austria_cities = {
    "Vienna": [
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
    ],
    "Graz": [
        {"name": "Hauptplatz", "lat": 47.0707, "lon": 15.4395},
        {"name": "Graz University of Technology", "lat": 47.0694, "lon": 15.4490},
        {"name": "University of Graz", "lat": 47.0778, "lon": 15.4490},
        {"name": "Schlossberg", "lat": 47.0765, "lon": 15.4372},
        {"name": "Kunsthaus Graz", "lat": 47.0712, "lon": 15.4345},
    ],
    "Linz": [
        {"name": "Hauptplatz", "lat": 48.3059, "lon": 14.2862},
        {"name": "Johannes Kepler University", "lat": 48.3352, "lon": 14.3222},
        {"name": "Ars Electronica Center", "lat": 48.3097, "lon": 14.2840},
        {"name": "Lentos Art Museum", "lat": 48.3068, "lon": 14.2843},
    ],
    "Salzburg": [
        {"name": "Salzburg Old Town", "lat": 47.8011, "lon": 13.0430},
        {"name": "Mirabell Palace", "lat": 47.8057, "lon": 13.0425},
        {"name": "University of Salzburg", "lat": 47.7973, "lon": 13.0477},
        {"name": "Hohensalzburg Fortress", "lat": 47.7947, "lon": 13.0476},
    ],
    "Innsbruck": [
        {"name": "Old Town", "lat": 47.2692, "lon": 11.3939},
        {"name": "University of Innsbruck", "lat": 47.2634, "lon": 11.3847},
        {"name": "Golden Roof", "lat": 47.2687, "lon": 11.3936},
        {"name": "Imperial Palace", "lat": 47.2700, "lon": 11.3932},
    ],
    "Klagenfurt": [
        {"name": "Neuer Platz", "lat": 46.6225, "lon": 14.3090},
        {"name": "University of Klagenfurt", "lat": 46.6162, "lon": 14.2634},
        {"name": "Wörthersee", "lat": 46.6103, "lon": 14.2588},
    ],
    "Bregenz": [
        {"name": "Bregenz Harbor", "lat": 47.5034, "lon": 9.7449},
        {"name": "Vorarlberg University of Applied Sciences", "lat": 47.5007, "lon": 9.7461},
        {"name": "Pfänder Mountain", "lat": 47.5109, "lon": 9.7835},
    ],
    "Eisenstadt": [
        {"name": "Esterházy Palace", "lat": 47.8456, "lon": 16.5196},
        {"name": "University of Applied Sciences Burgenland", "lat": 47.8534, "lon": 16.5293},
    ],
    "St. Pölten": [
        {"name": "St. Pölten Main Square", "lat": 48.2046, "lon": 15.6224},
        {"name": "St. Pölten University of Applied Sciences", "lat": 48.2110, "lon": 15.6187},
    ]
}

# Flatten locations for easy access
all_locations = []
for city, locations in austria_cities.items():
    for location in locations:
        location["city"] = city
        all_locations.append(location)

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

# Define skill categories for users
skill_categories = {
    "Languages": [
        "German", "English", "French", "Spanish", "Italian", 
        "Russian", "Chinese", "Japanese", "Arabic", "Portuguese", 
        "Dutch", "Swedish", "Hungarian", "Czech", "Polish"
    ],
    "Technical": [
        "Python", "JavaScript", "Java", "C++", "SQL", 
        "HTML/CSS", "React", "Angular", "Node.js", "Data Analysis", 
        "Machine Learning", "Cloud Services", "Mobile Development", "DevOps", "Linux"
    ],
    "Soft Skills": [
        "Public Speaking", "Leadership", "Teamwork", "Project Management", "Time Management",
        "Critical Thinking", "Problem Solving", "Communication", "Presentation", "Negotiation"
    ],
    "Academic": [
        "Research Methods", "Academic Writing", "Statistics", "Data Visualization", "Literature Review",
        "Laboratory Techniques", "Paper Publication", "Peer Review", "Grant Writing", "Teaching"
    ],
    "Creative": [
        "Graphic Design", "Video Editing", "Photography", "Content Creation", "Writing",
        "Illustration", "Animation", "Music Production", "UI/UX Design", "3D Modeling"
    ]
}

# Flatten into a single list of interests and skills
all_interests = []
for category, interests in interest_categories.items():
    all_interests.extend(interests)

all_skills = []
for category, skills in skill_categories.items():
    all_skills.extend(skills)

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

def create_users(num_users=2000):
    """Create student users with profiles, interests and skills"""
    
    # Common first and last names from various European countries
    first_names = [
        "Anna", "Lukas", "Emma", "Felix", "Sophie", "David", "Laura", "Maximilian", 
        "Julia", "Alexander", "Maria", "Thomas", "Sarah", "Michael", "Lisa", "Andreas",
        "Melanie", "Stefan", "Nina", "Markus", "Christina", "Martin", "Katharina", "Daniel",
        "Eva", "Peter", "Teresa", "Jakob", "Victoria", "Florian", "Sophia", "Paul",
        "Elena", "Jan", "Chiara", "Philipp", "Lena", "Tobias", "Hannah", "Simon",
        "Olivia", "Benjamin", "Emilia", "Noah", "Mia", "Jonas", "Amelia", "Lucas",
        "Isabella", "Elias", "Charlotte", "Gabriel", "Julia", "Leo", "Sofia", "Samuel",
        "Valentina", "Rafael", "Ava", "Alessandro", "Alice", "Antonio", "Grace", "Carlos",
        "Leonie", "Sebastian", "Johanna", "Dominik", "Vanessa", "Christoph", "Isabella", "Julian",
        "Helena", "Christian", "Gabriela", "Mario", "Carina", "Roman", "Natalia", "Marco",
        "Klara", "Lukas", "Martina", "Franz", "Birgit", "Georg", "Theresa", "Werner",
        "Alexandra", "Manuel", "Silvia", "Herbert", "Sabine", "Josef", "Ursula", "Karl"
    ]
    
    last_names = [
        "Müller", "Schmidt", "Schneider", "Fischer", "Weber", "Meyer", "Wagner", "Becker",
        "Schulz", "Hoffmann", "Novak", "Horvath", "Kovacs", "Nagy", "Bauer", "Gruber",
        "Huber", "Steiner", "Mayer", "Hofer", "Pichler", "Moser", "Reiter", "Berger",
        "Rossi", "Ferrari", "Esposito", "Romano", "Ricci", "Marino", "Smith", "Johnson",
        "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Martin", "Anderson",
        "Garcia", "Martinez", "Rodriguez", "Hernandez", "Lopez", "Gonzalez", "Perez", "Sanchez",
        "Silva", "Santos", "Oliveira", "Souza", "Rodrigues", "Ferreira", "Almeida", "Costa",
        "Jovanovic", "Popovic", "Djordjevic", "Stojanovic", "Markovic", "Petrovic", "Nikolic", "Dimitrov",
        "Wallner", "Eder", "Fuchs", "Schmid", "Winkler", "Lang", "Baumgartner", "Auer",
        "Wieser", "Schwarz", "Haas", "Maier", "Lehner", "Koller", "Wolf", "Brunner",
        "Mayr", "Egger", "Leitner", "Kainz", "Löffler", "Strasser", "Hinteregger", "Schuster",
        "Wiesinger", "Schwaiger", "Pucher", "Trummer", "Ebner", "Riedl", "Feichtinger", "König"
    ]
    
    # Password for all users (simpler for testing)
    DEFAULT_PASSWORD = "password"
    
    print(f"Creating {num_users} student users...")
    created_users = []
    batch_size = 100  # Process users in batches for efficiency
    
    # Open file to save user credentials
    with open('user_credentials.txt', 'w') as cred_file:
        cred_file.write("Username,Password,First Name,Last Name,Interests,Skills\n")
        
        for i in range(num_users):
            first_name = random.choice(first_names)
            last_name = random.choice(last_names)
            username = generate_username(first_name, last_name)
            
            # Create users with simple passwords for testing
            user = User.objects.create_user(
                username=username,
                password=DEFAULT_PASSWORD,
                first_name=first_name,
                last_name=last_name
            )
            
            # Create user profile
            profile = UserProfile.objects.get(user=user)
            
            # Set random interests (3-8 interests per user)
            num_interests = random.randint(3, 8)
            user_interests = random.sample(all_interests, num_interests)
            profile.set_interests(user_interests)
            
            # Set random skills (2-6 skills per user with random skill levels)
            num_skills = random.randint(2, 6)
            user_skills = random.sample(all_skills, num_skills)
            skills_dict = {}
            for skill in user_skills:
                skill_level = random.choice([level[0] for level in SKILL_LEVEL_CHOICES])
                skills_dict[skill] = skill_level
            profile.set_skills(skills_dict)
            
            # Enable auto-matching for most users
            profile.auto_invite_enabled = random.random() < 0.8  # 80% likely to be enabled
            
            # Set preferred radius between 2-15 km
            profile.preferred_radius = round(random.uniform(2.0, 15.0), 1)
            
            # Certify some users (about 20%)
            profile.is_certified = random.random() < 0.2
            
            profile.save()
            created_users.append(user)
            
            # Save the credentials to the file
            cred_file.write(f"{username},{DEFAULT_PASSWORD},{first_name},{last_name},{','.join(user_interests)},{json.dumps(skills_dict)}\n")
            
            # Create some friend relationships (for 20% of users)
            if created_users and random.random() < 0.2:
                num_friends = random.randint(1, min(10, len(created_users)))
                potential_friends = random.sample([u for u in created_users if u != user], min(num_friends, len(created_users) - 1))
                
                for friend in potential_friends:
                    user.userprofile.friends.add(friend.userprofile)
                    friend.userprofile.friends.add(user.userprofile)
            
            if i % batch_size == 0 or i == num_users - 1:
                print(f"Created users {i-batch_size+1 if i >= batch_size else 0} to {i}/{num_users}")
    
    print(f"User credentials saved to user_credentials.txt")
    
    return created_users

def create_events(users, num_events=3000):
    """Create various study events across Austria"""
    print(f"\nCreating {num_events} events across Austria...")
    created_events = []
    batch_size = 100  # Process events in batches
    
    # Current time as reference point
    now = datetime.now(timezone.utc)
    
    for i in range(num_events):
        # Select a random host user
        host = random.choice(users)
        
        # Select a random location in Austria
        location = random.choice(all_locations)
        city = location["city"]
        
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
        if random.random() < 0.3:  # 30% chance to add city name to title
            title = f"{title} ({city})"
        
        description_template = random.choice(event_params["descriptions"])
        description = description_template.replace("{subject}", subject)
        if random.random() < 0.5:  # 50% chance to add location details
            description = f"{description} Located in {location['name']}, {city}."
        
        # Set event time (between now and 30 days in the future)
        days_ahead = random.randint(0, 30)
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
        
        # Log progress in batches
        if i % batch_size == 0 or i == num_events - 1:
            print(f"Created events {i-batch_size+1 if i >= batch_size else 0} to {i}/{num_events}")
    
    return created_events

def perform_auto_matching(events, users):
    """Perform auto-matching for events that have it enabled"""
    print("\nPerforming auto-matching...")
    
    # Clear existing auto-matched invitations
    EventInvitation.objects.filter(is_auto_matched=True).delete()
    print("Cleared existing auto-matched invitations")
    
    batch_size = 100
    matched_count = 0
    
    # Track matched users for each event
    event_matched_users = {}
    
    for i, event in enumerate(events):
        if not event.auto_matching_enabled:
            continue
        
        # Get the event's interest tags
        event_interests = event.get_interest_tags()
        if not event_interests:
            continue
        
        # Find potential matches
        event_host = event.host
        matched_users_for_event = []
        
        # Sample users for matching (for performance with large datasets)
        # Use a larger sample size to ensure we get more matches
        sampled_users = random.sample(users, min(500, len(users)))
        
        for user in sampled_users:
            # Skip if user is the host, already invited, or already attending
            if (user == event_host or 
                user in event.invited_friends.all() or 
                user in event.attendees.all()):
                continue
            
            # Get user's profile and interests
            profile = user.userprofile
            if not profile.auto_invite_enabled:
                continue
                
            user_interests = profile.get_interests()
            if not user_interests:
                continue
            
            # Calculate interest overlap
            matching_interests = set(user_interests).intersection(set(event_interests))
            
            # If there's at least one matching interest, create auto-match
            if matching_interests:
                try:
                    # Add to invited_friends
                    event.invited_friends.add(user)
                    
                    # Create invitation record
                    EventInvitation.objects.create(
                        event=event,
                        user=user,
                        is_auto_matched=True
                    )
                    
                    matched_count += 1
                    matched_users_for_event.append(user)
                except Exception as e:
                    # Silently continue if there's an error (likely duplicate)
                    pass
        
        # Store the matched users for this event
        event_matched_users[str(event.id)] = [u.username for u in matched_users_for_event]
        
        if i % batch_size == 0 or i == len(events) - 1:
            print(f"Processed auto-matching for events {i-batch_size+1 if i >= batch_size else 0} to {i}/{len(events)}")
    
    # Save auto-matching results to a file
    with open('auto_match_results.txt', 'w') as match_file:
        match_file.write("EventID,EventTitle,MatchedUsers\n")
        for event_id, matched_users in event_matched_users.items():
            try:
                event = StudyEvent.objects.get(id=event_id)
                match_file.write(f"{event_id},{event.title},{','.join(matched_users)}\n")
            except StudyEvent.DoesNotExist:
                pass
    
    print(f"\nCompleted auto-matching with {matched_count} matches")
    print(f"Auto-matching results saved to auto_match_results.txt")
    return matched_count

def create_friend_connections(users, num_connections=5000):
    """Create random friend connections between users"""
    print(f"\nCreating friend connections...")
    connections_made = 0
    
    for _ in range(num_connections):
        # Randomly select two users
        if len(users) < 2:
            break
            
        user1, user2 = random.sample(users, 2)
        
        # Skip if they're already friends
        if user2.userprofile in user1.userprofile.friends.all():
            continue
            
        # Make them friends
        user1.userprofile.friends.add(user2.userprofile)
        user2.userprofile.friends.add(user1.userprofile)
        connections_made += 1
        
        if connections_made % 500 == 0:
            print(f"Created {connections_made} friend connections")
    
    print(f"Created {connections_made} friend connections in total")
    return connections_made

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
    print("Beginning massive data population of Austria StudyCon database")
    print("This may take several minutes. Please be patient.\n")
    
    # Clear existing test data
    clear_existing_data()
    
    # Create users (2000 users)
    users = create_users(num_users=2000)
    
    # Create friend connections
    create_friend_connections(users, num_connections=5000)
    
    # Create events (3000 events across Austria)
    events = create_events(users, num_events=3000)
    
    # Perform auto-matching
    matched_count = perform_auto_matching(events, users)
    
    print("\nDatabase population completed!")
    print(f"Created {len(users)} users")
    print(f"Created {len(events)} events across multiple Austrian cities")
    print(f"Created {matched_count} auto-matches")
    print(f"Austria-wide student life simulation is ready!")
    print("\nUser credentials are saved in user_credentials.txt")
    print("Auto-matching results are saved in auto_match_results.txt")

if __name__ == "__main__":
    main() 