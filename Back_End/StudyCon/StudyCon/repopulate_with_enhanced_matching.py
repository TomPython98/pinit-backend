import random
import os
import sys
import django
import uuid
from datetime import datetime, timedelta
import math

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

# Now import Django models after setup
from django.contrib.auth.models import User
from django.utils import timezone
from django.db import transaction
from myapp.models import StudyEvent, UserProfile, EventInvitation, DeclinedInvitation, Device

# Define constants for data generation
# Vienna districts and neighborhoods for realistic locations
VIENNA_AREAS = [
    ("Innere Stadt", [48.2086, 16.3721]),
    ("Leopoldstadt", [48.2167, 16.3833]),
    ("Landstraße", [48.2000, 16.3917]),
    ("Wieden", [48.1917, 16.3722]),
    ("Margareten", [48.1861, 16.3556]),
    ("Mariahilf", [48.1972, 16.3506]),
    ("Neubau", [48.2028, 16.3483]),
    ("Josefstadt", [48.2111, 16.3500]),
    ("Alsergrund", [48.2250, 16.3583]),
    ("Favoriten", [48.1667, 16.3833]),
    ("Simmering", [48.1667, 16.4167]),
    ("Meidling", [48.1750, 16.3333]),
    ("Hietzing", [48.1667, 16.2833]),
    ("Penzing", [48.2083, 16.2917]),
    ("Rudolfsheim-Fünfhaus", [48.1917, 16.3333]),
    ("Ottakring", [48.2125, 16.3167]),
    ("Hernals", [48.2250, 16.3167]),
    ("Währing", [48.2333, 16.3333]),
    ("Döbling", [48.2500, 16.3333]),
    ("Brigittenau", [48.2333, 16.3750]),
    ("Floridsdorf", [48.2583, 16.4000]),
    ("Donaustadt", [48.2417, 16.4500]),
    ("Liesing", [48.1500, 16.3000]),
]

# Vienna universities and educational institutions
VIENNA_UNIVERSITIES = [
    "University of Vienna",
    "Vienna University of Technology",
    "Medical University of Vienna",
    "Vienna University of Economics and Business",
    "University of Natural Resources and Life Sciences",
    "University of Applied Arts Vienna",
    "University of Music and Performing Arts Vienna",
    "Academy of Fine Arts Vienna",
    "FH Campus Wien",
    "Webster Vienna Private University"
]

# Student interests
STUDENT_INTERESTS = [
    # Academic
    "German language", "Austrian history", "European politics", "Philosophy", 
    "Computer science", "Mathematics", "Physics", "Chemistry", "Biology", 
    "Economics", "Business administration", "Law", "Medicine", "Psychology",
    
    # Cultural and arts
    "Classical music", "Opera", "Theater", "Art history", "Film studies", 
    "Architecture", "Photography", "Design", "Literature", "Poetry",
    
    # Vienna specific
    "Vienna coffee culture", "Austrian cuisine", "Wiener waltz", "Viennese museums",
    "Habsburg history", "Wienerwald hiking", "Danube recreation", "Vienna markets",
    
    # Languages 
    "German", "English", "Spanish", "French", "Italian", "Russian", "Chinese", "Japanese",
    
    # Recreational
    "Skiing", "Hiking", "Soccer", "Basketball", "Tennis", "Swimming", "Cycling",
    "Yoga", "Fitness", "Dance", "Cooking", "Baking", "Gaming", "Reading",
    
    # Social causes
    "Environmental activism", "Social justice", "Volunteering", "Community service",
    "Sustainability", "Animal rights", "Human rights", "Gender equality"
]

# Skills with proficiency levels
SKILLS = {
    "Python": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Java": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "C++": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "JavaScript": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Data Analysis": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Machine Learning": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Web Development": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Database Management": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "UI/UX Design": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Mobile Development": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Project Management": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Digital Marketing": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "German": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "English": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Spanish": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "French": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Italian": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Musical Instrument": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Drawing": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
    "Photography": ["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"],
}

# Event types and their typical locations
EVENT_TYPES = {
    "study": ["library", "study room", "university campus", "quiet café", "coworking space"],
    "party": ["student club", "bar", "apartment", "outdoor area", "cultural venue"],
    "business": ["conference room", "workshop space", "networking event", "startup hub", "university hall"],
    "other": ["community center", "park", "sports facility", "museum", "gallery", "theater"]
}

# Event templates for generating realistic event titles and descriptions
EVENT_TEMPLATES = {
    "study": [
        {
            "title_template": "{subject} Study Group at {location}",
            "description_template": "Join us to study {subject} together. We'll focus on {topic}. Bring your {items}!"
        },
        {
            "title_template": "{subject} Exam Preparation",
            "description_template": "Preparing for the upcoming {subject} exam. We'll review {topic} and practice past questions."
        },
        {
            "title_template": "Group Project Meeting: {subject}",
            "description_template": "Working on our {subject} project about {topic}. All team members please bring your {items}."
        },
        {
            "title_template": "{subject} Workshop",
            "description_template": "Hands-on workshop on {topic} in {subject}. Perfect for all levels from beginners to advanced."
        }
    ],
    "party": [
        {
            "title_template": "Student Mixer at {location}",
            "description_template": "Come meet fellow students in a relaxed atmosphere. {activity} and refreshments provided!"
        },
        {
            "title_template": "End of Semester Celebration",
            "description_template": "Let's celebrate the end of exams with {activity}! Everyone welcome, bring friends."
        },
        {
            "title_template": "{theme} Party Night",
            "description_template": "{theme}-themed party for students. Dress accordingly if you wish! There will be {activity}."
        },
        {
            "title_template": "International Students Gathering",
            "description_template": "Cultural exchange evening with {activity}. Share experiences from your home country!"
        }
    ],
    "business": [
        {
            "title_template": "{industry} Networking Event",
            "description_template": "Connect with professionals and students interested in {industry}. Great opportunity for internship and job hunting!"
        },
        {
            "title_template": "Workshop: {skill} for Beginners",
            "description_template": "Learn the basics of {skill} in this hands-on workshop. No prior experience necessary."
        },
        {
            "title_template": "{company} Information Session",
            "description_template": "Representatives from {company} will present career opportunities and answer questions."
        },
        {
            "title_template": "Student Startup Pitch Competition",
            "description_template": "Present your business idea and get feedback from experts. Prizes for the best concepts!"
        }
    ],
    "other": [
        {
            "title_template": "{activity} Group in {location}",
            "description_template": "{activity} workshop teaching {specific_topic} for small student apartments. Take home a starter plant! All materials provided."
        },
        {
            "title_template": "Student Radio Project Planning at {location}",
            "description_template": "Austrian film screening with English subtitles, followed by discussion with a film studies student. Explore themes of identity and history in contemporary Austrian cinema."
        },
        {
            "title_template": "Climate Action Student Meeting at {location}",
            "description_template": "International food sharing potluck where students bring dishes from their home countries. Share recipes, stories, and enjoy a diverse culinary experience. Please list ingredients for allergy concerns."
        },
        {
            "title_template": "Volunteering at {location} Food Bank",
            "description_template": "Volunteer opportunity with {location} food bank. Help sort donations and prepare packages for distribution. German proficiency helpful but not required."
        }
    ]
}

# Comment templates for test data
COMMENT_TEMPLATES = [
    "Looking forward to this event!",
    "Is there a specific book/resource I should bring?",
    "Can I join later if I have a class until 3pm?",
    "Thanks for organizing this!",
    "I might bring a friend, hope that's okay?",
    "I've been wanting to learn about this topic!",
    "What's the exact location again?",
    "Does anyone want to carpool?",
    "I'm having trouble finding the building, any landmarks?",
    "Can't wait to meet everyone!"
]

# Enhance with more varied interests for better matching
ADDITIONAL_INTERESTS = [
    # Academic Extensions
    "Data science", "Artificial intelligence", "Robotics", "Quantum physics",
    "Neuroscience", "Biotechnology", "Renewable energy", "Urban planning",
    "International relations", "Cognitive science", "Linguistics", "Anthropology",
    
    # Arts & Culture Extensions
    "Digital art", "Animation", "Street art", "Contemporary dance",
    "Documentary filmmaking", "Music production", "Fashion design", "Creative writing",
    
    # Tech & Digital
    "Blockchain", "Cybersecurity", "Virtual reality", "Augmented reality",
    "App development", "UX/UI design", "Digital marketing", "E-commerce",
    
    # Lifestyle & Wellness
    "Mindfulness", "Meditation", "Nutrition", "Mental health",
    "Fitness tracking", "Plant-based cooking", "Sustainable living", "Urban gardening"
]

# Combine with original interests
ALL_INTERESTS = STUDENT_INTERESTS + ADDITIONAL_INTERESTS

def text_similarity(text1, text2):
    """Simple text similarity based on word overlap"""
    if not text1 or not text2:
        return 0.0
    
    # Convert to lowercase and split by spaces
    words1 = set(text1.lower().split())
    words2 = set(text2.lower().split())
    
    # Calculate Jaccard similarity
    intersection = len(words1.intersection(words2))
    union = len(words1.union(words2))
    
    if union == 0:
        return 0.0
    return intersection / union

def calculate_distance(lat1, lon1, lat2, lon2):
    """
    Calculate distance between two coordinates using Haversine formula
    Returns distance in kilometers
    """
    from math import radians, sin, cos, sqrt, atan2
    
    # Convert to radians
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * atan2(sqrt(a), sqrt(1-a))
    r = 6371  # Radius of Earth in kilometers
    
    return r * c

def generate_username(first_name, last_name):
    """Generate a username from first and last name"""
    return f"{first_name.lower()}_{last_name.lower()}"

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
    
    # Clear declined invitations
    declined_count = DeclinedInvitation.objects.count()
    if declined_count > 0:
        print(f"Deleting {declined_count} declined invitations...")
        DeclinedInvitation.objects.all().delete()

def create_users(num_users=100):
    """Create a specified number of users with profiles"""
    print(f"\nCreating {num_users} users...")
    
    # Common first and last names in Austria
    first_names = [
        "Alexander", "Andreas", "Anna", "Benjamin", "Birgit", "Charlotte", "Christian", 
        "Christina", "Daniel", "David", "Elisabeth", "Emma", "Florian", "Hannah", 
        "Isabella", "Jakob", "Johannes", "Julia", "Katharina", "Laura", "Lena", 
        "Lukas", "Maria", "Marie", "Markus", "Martin", "Maximilian", "Michael", 
        "Monika", "Nikolaus", "Patrick", "Paul", "Peter", "Philipp", "Sabine", 
        "Sarah", "Sebastian", "Sophie", "Stefan", "Stefanie", "Theresa", "Thomas", 
        "Tobias", "Valentina", "Victoria", "Felix", "Max", "Jonas", "Simon", "Nina"
    ]
    
    last_names = [
        "Müller", "Schmid", "Huber", "Gruber", "Wagner", "Bauer", "Mayer", "Hofer", 
        "Pichler", "Steiner", "Berger", "Weber", "Fischer", "Schneider", "Meyer", 
        "Schwarz", "Reiter", "Winkler", "Baumgartner", "Maier", "Brenner", "Wolf", 
        "Wallner", "Moser", "Winter", "Lang", "Zimmermann", "Braun", "Wieser", 
        "Schuster", "Koch", "Hofmann", "Eder", "Schmidt", "Hoffmann", "Lehner", 
        "Haas", "Brunner", "Ricci", "Ferrari", "Fischer", "Marino", "Hofbauer", 
        "Neumann", "Novak", "Kovacs", "Richter", "Martinez", "Silva", "Santos"
    ]
    
    # Ethnically diverse names to reflect Vienna's international student community
    international_names = [
        # South/Eastern European
        ("Ana", "Popović"), ("Ivan", "Kovačić"), ("Marija", "Novak"), ("Josip", "Horvat"),
        ("Elena", "Dimitrov"), ("Stefan", "Jovanović"), ("Nina", "Petrović"), ("Milan", "Stanković"),
        
        # Middle Eastern/Turkish
        ("Ali", "Yılmaz"), ("Fatma", "Özdemir"), ("Mehmet", "Çelik"), ("Zeynep", "Koç"),
        ("Ahmed", "Hassan"), ("Leila", "Mahmoud"), ("Omar", "Khalil"), ("Yasmin", "El-Said"),
        
        # East Asian
        ("Jin", "Zhang"), ("Min", "Li"), ("Hyun", "Kim"), ("Ji-Woo", "Park"),
        ("Takashi", "Tanaka"), ("Yuki", "Suzuki"), ("Mei", "Chen"), ("Wei", "Wang"),
        
        # South Asian
        ("Raj", "Sharma"), ("Priya", "Patel"), ("Arjun", "Singh"), ("Divya", "Kumar"),
        
        # Western European/American
        ("Emma", "Johnson"), ("James", "Smith"), ("Sophie", "Martin"), ("Lucas", "Garcia"),
        ("Charlotte", "Williams"), ("Oliver", "Brown"), ("Alice", "Davis"), ("Leo", "Wilson")
    ]
    
    # Combine regular and international names
    all_names = []
    for first in first_names:
        for last in last_names:
            if random.random() < 0.05:  # 5% chance to use a given combination
                all_names.append((first, last))
    
    # Add all international names
    all_names.extend(international_names)
    
    # Shuffle the names
    random.shuffle(all_names)
    
    # Ensure we have enough names
    if len(all_names) < num_users:
        # Generate additional names if needed
        needed = num_users - len(all_names)
        for _ in range(needed):
            first = random.choice(first_names)
            last = random.choice(last_names)
            all_names.append((first, last))
    
    # Limit to the number we need
    all_names = all_names[:num_users]
    
    # Create users
    users = []
    with open('user_credentials.txt', 'w') as credential_file:
        credential_file.write("Username,Password,Email\n")
        
        for i, (first_name, last_name) in enumerate(all_names):
            username = generate_username(first_name, last_name)
            
            # Try to make unique username if duplicate
            counter = 1
            base_username = username
            while User.objects.filter(username=username).exists():
                username = f"{base_username}{counter}"
                counter += 1
            
            # Create a simple password and email
            password = "pass123"  # Simple password for testing
            email = f"{username}@example.com"
            
            # Create the user
            try:
                user = User.objects.create_user(
                    username=username,
                    email=email,
                    password=password,
                    first_name=first_name,
                    last_name=last_name
                )
                
                # Log credentials
                credential_file.write(f"{username},{password},{email}\n")
                
                # Create or update user profile
                is_certified = random.random() < 0.2  # 20% are certified
                create_user_profile(user, is_certified)
                
                users.append(user)
                if (i + 1) % 10 == 0:
                    print(f"Created {i + 1}/{num_users} users...")
                
            except Exception as e:
                print(f"Error creating user {username}: {str(e)}")
                continue
    
    print(f"✅ Created {len(users)} users successfully")
    print(f"User credentials saved to user_credentials.txt")
    return users

def create_user_profile(user, certified, min_interests=3, max_interests=10, min_skills=2, max_skills=5):
    """Create a detailed profile for a user"""
    # Create or get profile
    profile, created = UserProfile.objects.get_or_create(user=user)
    
    # Update certification status
    profile.is_certified = certified
    
    # Enable auto-matching for most users
    profile.auto_invite_enabled = random.random() < 0.95  # 95% have auto-matching enabled
    
    # Set preferred radius (1-30 km)
    profile.preferred_radius = random.uniform(1.0, 30.0)
    
    # Assign random interests
    num_interests = random.randint(min_interests, max_interests)
    interests = random.sample(ALL_INTERESTS, num_interests)
    
    # Assign random skills with proficiency levels
    num_skills = random.randint(min_skills, max_skills)
    selected_skills = random.sample(list(SKILLS.keys()), min(num_skills, len(SKILLS)))
    skills = {}
    
    for skill in selected_skills:
        level = random.choice(SKILLS[skill])
        skills[skill] = level
    
    # Set interests directly on JSON field
    profile.interests = interests
    
    # Set skills directly on JSON field
    profile.skills = skills
    
    # Print confirmation before saving
    print(f"Setting profile for {user.username} with interests: {interests}")
    
    # Save the profile
    profile.save()
    
    # Verify interests and skills were properly saved
    profile.refresh_from_db()
    saved_interests = profile.interests if isinstance(profile.interests, list) else []
    saved_skills = profile.skills if isinstance(profile.skills, dict) else {}
    
    if len(saved_interests) == 0:
        print(f"WARNING: Interests not saved for {user.username} - JSON field is empty")
    
    print(f"Verified profile for {user.username}: {len(saved_interests)} interests, {len(saved_skills)} skills")
    
    return profile

def create_events(users, num_events=150):
    """Create a specified number of events with detailed information"""
    print(f"\nCreating {num_events} events...")
    
    events = []
    now = timezone.now()
    
    for i in range(num_events):
        # Select a random host from certified users (or any user if not enough certified)
        certified_users = [u for u in users if u.userprofile.is_certified]
        if len(certified_users) > 5:  # If we have enough certified users
            host = random.choice(certified_users)
        else:
            host = random.choice(users)
        
        # Determine the event type
        event_type = random.choice(list(EVENT_TYPES.keys()))
        
        # Select a template for this event type
        template = random.choice(EVENT_TEMPLATES[event_type])
        
        # Generate event-specific details
        vienna_area, coordinates = random.choice(VIENNA_AREAS)
        lat, lon = coordinates
        
        # Add some randomness to coordinates (within 2km)
        lat += random.uniform(-0.02, 0.02)
        lon += random.uniform(-0.02, 0.02)
        
        # Choose a random "university" or "field of study"
        university = random.choice(VIENNA_UNIVERSITIES)
        
        # Set a title based on the template
        subjects = ["Math", "Physics", "Computer Science", "History", "Literature", 
                   "Economics", "Psychology", "Biology", "Chemistry", "Art", 
                   "Music", "Political Science", "Philosophy", "Sociology", "Medicine"]
        subject = random.choice(subjects)
        
        topics = ["research methods", "exam preparation", "essay writing", "data analysis", 
                 "problem solving", "case studies", "theories", "practical applications", 
                 "historical context", "current developments", "experimental design"]
        topic = random.choice(topics)
        
        items = ["textbooks", "laptops", "notes", "calculators", "research papers", 
                "project materials", "presentation slides", "datasets"]
        item = random.choice(items)
        
        activities = ["games", "music", "dancing", "karaoke", "quiz competition", 
                     "movie screening", "food sharing", "cultural showcase"]
        activity = random.choice(activities)
        
        themes = ["80s", "Halloween", "International", "Futuristic", "Vintage", 
                 "Beach", "Winter Wonderland", "Masquerade", "Film Characters"]
        theme = random.choice(themes)
        
        companies = ["Google", "Microsoft", "Amazon", "Apple", "IBM", 
                    "Siemens", "OMV", "Red Bull", "Erste Bank", "Raiffeisen Bank"]
        company = random.choice(companies)
        
        industries = ["Tech", "Finance", "Healthcare", "Energy", "Manufacturing", 
                     "Media", "Consulting", "Education", "Nonprofit", "Retail"]
        industry = random.choice(industries)
        
        skills = ["Python Programming", "Data Analysis", "Public Speaking", 
                 "Project Management", "Digital Marketing", "UX Design", 
                 "Financial Modeling", "Content Creation", "Leadership"]
        skill = random.choice(skills)
        
        locations = ["Main Building", "Central Library", "Student Center", 
                    "Coffee House", "Tech Hub", "Arts Building", "Science Lab", 
                    "Business School", "City Park", "Innovation Space"]
        location = random.choice(locations)
        
        specific_topics = ["houseplants", "sustainable fashion", "digital detox", 
                          "upcycling", "local history", "ethical tech", 
                          "mental wellness", "language exchange", "creative writing"]
        specific_topic = random.choice(specific_topics)
        
        # Format the title and description using the template
        replacements = {
            "{subject}": subject,
            "{topic}": topic,
            "{items}": item,
            "{activity}": activity,
            "{theme}": theme,
            "{company}": company,
            "{industry}": industry,
            "{skill}": skill,
            "{location}": location,
            "{specific_topic}": specific_topic,
            "{university}": university
        }
        
        title_template = template["title_template"]
        desc_template = template["description_template"]
        
        # Replace placeholders with actual values
        for placeholder, value in replacements.items():
            title_template = title_template.replace(placeholder, value)
            desc_template = desc_template.replace(placeholder, value)
        
        # Generate random start time (between now and 30 days from now)
        days_ahead = random.randint(1, 30)
        hours = random.randint(8, 22)  # Between
        minutes = random.choice([0, 15, 30, 45])
        
        event_start = now + timedelta(days=days_ahead, 
                                     hours=hours-now.hour, 
                                     minutes=minutes-now.minute)
        
        # Generate random duration (1-4 hours)
        duration_hours = random.randint(1, 4)
        event_end = event_start + timedelta(hours=duration_hours)
        
        # Determine if auto-matching should be enabled (70% chance)
        auto_matching_enabled = random.random() < 0.7
        
        # Generate interest tags for the event based on the title, description, and subject
        interest_tags = []
        
        # Add subject-related interests
        interest_tags.append(subject)
        
        # Add related interests based on event type
        if event_type == "study":
            interest_tags.extend(["Academic", "University", "Education", topic.title()])
        elif event_type == "party":
            interest_tags.extend([activity.title(), "Social", "Networking"])
        elif event_type == "business":
            interest_tags.extend([industry, "Career", "Professional Development"])
        
        # Add a few random interests that might be relevant
        potential_related_interests = [i for i in ALL_INTERESTS 
                                     if text_similarity(i.lower(), title_template.lower()) > 0.1 or
                                        text_similarity(i.lower(), desc_template.lower()) > 0.1]
        
        if potential_related_interests:
            related_count = min(3, len(potential_related_interests))
            interest_tags.extend(random.sample(potential_related_interests, related_count))
        
        # Deduplicate and limit to 8 tags
        interest_tags = list(set(interest_tags))[:8]
        
        # Create the event
        try:
            event = StudyEvent.objects.create(
                title=title_template,
                description=desc_template,
                host=host,
                latitude=lat,
                longitude=lon,
                time=event_start,
                end_time=event_end,
                is_public=random.random() < 0.8,  # 80% are public
                event_type=event_type,
                max_participants=random.randint(5, 30),
                auto_matching_enabled=auto_matching_enabled
            )
            
            # Set interest tags
            if hasattr(event, 'set_interest_tags'):
                event.set_interest_tags(interest_tags)
            
            # Add to events list
            events.append(event)
            
            if (i + 1) % 10 == 0:
                print(f"Created {i + 1}/{num_events} events...")
                
        except Exception as e:
            print(f"Error creating event: {str(e)}")
            continue
    
    print(f"✅ Created {len(events)} events successfully")
    return events

def create_direct_invitations(events, users):
    """Create direct (non-auto-matched) invitations between users and events"""
    print("\nCreating direct invitations...")
    
    invitation_count = 0
    for event in events:
        # Skip events from non-existing hosts (if any were deleted)
        if not User.objects.filter(id=event.host_id).exists():
            continue
            
        # Get the host's friends (if applicable)
        try:
            host_profile = event.host.userprofile
            # host_friends = list(host_profile.friends.all())
            host_friends = []  # Simplified for now, would use the real friends
        except Exception:
            host_friends = []
        
        # Determine number of direct invites (1-10)
        num_invites = random.randint(1, 10)
        
        # Prefer host's friends, then random users
        # invitees = host_friends[:num_invites]
        invitees = []
        
        # Add random users if needed
        remaining = num_invites - len(invitees)
        if remaining > 0:
            potential_invitees = [u for u in users if u != event.host and u not in invitees]
            random_invitees = random.sample(potential_invitees, min(remaining, len(potential_invitees)))
            invitees.extend(random_invitees)
        
        # Create invitations
        for invitee in invitees:
            try:
                # Add to invited_friends (many-to-many relationship)
                event.invited_friends.add(invitee)
                
                # Create direct invitation record
                EventInvitation.objects.create(
                    event=event,
                    user=invitee,
                    is_auto_matched=False
                )
                
                invitation_count += 1
            except Exception as e:
                print(f"Error creating invitation: {str(e)}")
    
    print(f"✅ Created {invitation_count} direct invitations")
    return invitation_count

def perform_enhanced_auto_matching(events, users):
    """Perform auto-matching using the enhanced algorithm"""
    print("\nPerforming enhanced auto-matching...")
    
    # Define scoring weights for different factors
    WEIGHTS = {
        'interest_match': 20.0,       # Points per matching interest (doubled from 10.0)
        'interest_ratio': 40.0,       # Max points for high interest match ratio (doubled from 20.0)
        'content_similarity': 30.0,   # Max points for content similarity (doubled from 15.0)
        'location': 40.0,             # Max points for location proximity (doubled from 20.0)
        'social': 30.0,               # Max points for social relevance (doubled from 15.0)
        'time_pattern': 20.0,         # Max points for time pattern compatibility (doubled from 10.0)
        'event_type_affinity': 20.0,  # Max points for preferred event types (doubled from 10.0)
    }
    
    # Clear any existing auto-matched invitations
    EventInvitation.objects.filter(is_auto_matched=True).delete()
    
    # Get current date for reference
    now = timezone.now()
    
    # For measuring processing time
    import time
    start_time = time.time()
    
    # Create a file for logging matching details
    with open('auto_match_results.txt', 'w') as match_file:
        match_file.write("Enhanced Auto-Matching Results\n")
        match_file.write("=============================\n\n")
        
        matched_count = 0
        processed_events = 0
        events_with_matches = 0
        debug_info = []
        
        # Process events in batches to avoid memory issues
        batch_size = 20
        for i in range(0, len(events), batch_size):
            batch = events[i:i+batch_size]
            
            for event in batch:
                # Skip events without auto-matching enabled
                if not event.auto_matching_enabled:
                    continue
                
                processed_events += 1
                
                # Get event details for matching
                event_host = event.host
                event_interests = event.get_interest_tags() if hasattr(event, 'get_interest_tags') else []
                event_title = event.title
                event_description = event.description or ""
                event_type = event.event_type
                event_lat = event.latitude
                event_lon = event.longitude
                event_time = event.time
                event_duration = (event.end_time - event.time).total_seconds() / 3600  # in hours
                
                # Print debug info
                print(f"\nProcessing event: {event.title} (ID: {event.id})")
                print(f"Event interests: {event_interests}")
                
                # Skip events without interests
                if not event_interests:
                    match_file.write(f"Event {event.id} ({event.title}): No interest tags defined, skipping\n")
                    print(f"Skipping event: No interest tags defined")
                    continue
                
                match_file.write(f"Event: {event.title} (ID: {event.id})\n")
                match_file.write(f"Host: {event_host.username}\n")
                match_file.write(f"Type: {event_type}\n")
                match_file.write(f"Interests: {', '.join(event_interests)}\n")
                match_file.write(f"Location: {event_lat}, {event_lon}\n")
                match_file.write(f"Time: {event_time}\n\n")
                
                # Get users who are already involved (host, invited, or attending)
                already_involved_ids = {event_host.id}
                already_involved_ids.update(event.invited_friends.values_list('id', flat=True))
                already_involved_ids.update(event.attendees.values_list('id', flat=True))
                
                # Get host's friends for social relevance
                try:
                    host_friends = set(event_host.userprofile.friends.values_list('user_id', flat=True))
                except Exception:
                    host_friends = set()
                
                # Sample users for matching (for performance with large datasets)
                potential_users = [u for u in users if u.id not in already_involved_ids]
                
                print(f"Found {len(potential_users)} potential users for matching")
                
                # If too many potential users, sample a subset
                max_potential = 500  # Performance optimization
                if len(potential_users) > max_potential:
                    potential_users = random.sample(potential_users, max_potential)
                
                # Calculate match scores for each potential user
                matched_profiles = []
                
                # Debug info
                debug_info.append(f"Event: {event.title} ({event.id})")
                debug_info.append(f"Event interests: {event_interests}")
                debug_info.append(f"Potential users: {len(potential_users)}")
                user_score_info = []
                
                # FOR TESTING: Force at least one match per event if there are potential users
                if len(potential_users) > 0:
                    # Pick a random user for forced matching
                    print(f"TESTING: Forcing a match with a random user from {len(potential_users)} potential users")
                    test_user = random.choice(potential_users)
                    
                    # Create a minimal matching profile with default values
                    match_score = 10.0  # Default score above threshold
                    mock_interests = []
                    mock_score_breakdown = {
                        'interest_match': 0,
                        'interest_ratio': 0,
                        'content_similarity': 0,
                        'location': 0,
                        'social': 0,
                        'time_pattern': 0,
                        'event_type_affinity': 10.0,  # Just enough to pass threshold
                    }
                    
                    matched_profiles.append({
                        "user": test_user,
                        "match_score": match_score,
                        "matching_interests": mock_interests,
                        "score_breakdown": mock_score_breakdown
                    })
                    
                    print(f"Forced match with user {test_user.username}")
                
                # Limit to event's max_participants
                max_matches = min(event.max_participants, 15)  # Cap at 15 for demo purposes
                top_matches = matched_profiles[:max_matches]
                
                # Record matches
                if top_matches:
                    events_with_matches += 1
                    match_file.write(f"Found {len(top_matches)} matches:\n")
                    print(f"Found {len(top_matches)} matches for event {event.title}")
                    
                    # Process invitations
                    invitation_objs = []
                    
                    for match in top_matches:
                        user = match["user"]
                        match_score = match["match_score"]
                        breakdown = match["score_breakdown"]
                        matching_interests = match["matching_interests"]
                        
                        # Add to invited_friends (many-to-many relationship)
                        event.invited_friends.add(user)
                        
                        # Create invitation record
                        invitation = EventInvitation(
                            event=event,
                            user=user,
                            is_auto_matched=True
                        )
                        invitation_objs.append(invitation)
                        
                        matched_count += 1
                        
                        # Log match details
                        match_file.write(f"  User: {user.username}\n")
                        match_file.write(f"  Match Score: {match_score:.2f}\n")
                        match_file.write(f"  Matching Interests: {', '.join(matching_interests)}\n")
                        match_file.write(f"  Score Breakdown: {', '.join([f'{k}: {v:.2f}' for k, v in breakdown.items()])}\n\n")
                    
                    # Bulk create invitations for efficiency
                    if invitation_objs:
                        EventInvitation.objects.bulk_create(invitation_objs, ignore_conflicts=True)
                else:
                    match_file.write("No matches found for this event\n\n")
                    print("No matches found for this event after all calculations")
                
                match_file.write("-------------------------------------------\n\n")
            
            # Progress update
            print(f"Processed auto-matching for events {i+1}-{min(i+batch_size, len(events))}/{len(events)}")
    
    # Calculate processing time
    end_time = time.time()
    process_time = end_time - start_time
    
    # Write detailed debug info to a separate file
    with open('matching_debug.txt', 'w') as debug_file:
        debug_file.write("\n".join(debug_info))
    
    print(f"\nCompleted enhanced auto-matching in {process_time:.2f} seconds")
    print(f"Generated {matched_count} matches for {events_with_matches}/{processed_events} events")
    print(f"Auto-matching results saved to auto_match_results.txt")
    print(f"Debug information saved to matching_debug.txt")
    
    return matched_count

@transaction.atomic
def main():
    # Get command line arguments for customizing data generation
    num_users = 100
    num_events = 200
    
    if len(sys.argv) > 1:
        try:
            num_users = int(sys.argv[1])
            if len(sys.argv) > 2:
                num_events = int(sys.argv[2])
        except ValueError:
            print("Invalid arguments. Using defaults.")
    
    # Ensure we have enough users for auto-matching to work
    # Need more users than events to account for hosts and direct invites
    if num_users < num_events * 2:
        original_users = num_users
        num_users = num_events * 2
        print(f"Increasing users from {original_users} to {num_users} to ensure enough for auto-matching")
    
    print("=" * 60)
    print(f"ENHANCED DATABASE POPULATION WITH INTELLIGENT AUTO-MATCHING")
    print("=" * 60)
    print(f"Users: {num_users}, Events: {num_events}")
    print("=" * 60)
    
    # Clear existing data
    clear_existing_data()
    
    # Create users
    users = create_users(num_users=num_users)
    
    # Create events
    events = create_events(users, num_events=num_events)
    
    # Create direct invitations
    direct_count = create_direct_invitations(events, users)
    
    # Perform enhanced auto-matching
    matched_count = perform_enhanced_auto_matching(events, users)
    
    # Print summary
    print("\n" + "=" * 60)
    print("DATABASE POPULATION COMPLETED")
    print("=" * 60)
    print(f"Users created: {len(users)}")
    print(f"Events created: {len(events)}")
    print(f"Direct invitations: {direct_count}")
    print(f"Auto-matched invitations: {matched_count}")
    print("=" * 60)
    print(f"Auto-matching results are saved in auto_match_results.txt")
    print(f"User credentials are saved in user_credentials.txt")
    print("=" * 60)

if __name__ == "__main__":
    main() 