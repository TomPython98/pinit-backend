import os
import sys
import django
import random
from datetime import datetime, timedelta
from django.utils import timezone

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/Full_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from django.contrib.auth.models import User
from myapp.models import StudyEvent, UserProfile, EventInvitation, UserTrustLevel, UserReputationStats
from django.db import transaction

# Vienna universities and locations
VIENNA_UNIVERSITIES = [
    "University of Vienna",
    "Vienna University of Technology (TU Wien)",
    "Medical University of Vienna",
    "University of Natural Resources and Life Sciences (BOKU)",
    "Vienna University of Economics and Business (WU)",
    "Academy of Fine Arts Vienna",
    "University of Applied Arts Vienna",
    "Vienna University of Music and Performing Arts",
    "Webster University Vienna",
    "Central European University (CEU)"
]

# Vienna districts and coordinates (approximate)
VIENNA_LOCATIONS = [
    {"name": "Innere Stadt", "lat": 48.2082, "lon": 16.3738},
    {"name": "Leopoldstadt", "lat": 48.2148, "lon": 16.3785},
    {"name": "Landstraße", "lat": 48.1987, "lon": 16.3833},
    {"name": "Wieden", "lat": 48.1925, "lon": 16.3667},
    {"name": "Margareten", "lat": 48.1867, "lon": 16.3583},
    {"name": "Mariahilf", "lat": 48.1983, "lon": 16.3583},
    {"name": "Neubau", "lat": 48.2050, "lon": 16.3583},
    {"name": "Josefstadt", "lat": 48.2117, "lon": 16.3583},
    {"name": "Alsergrund", "lat": 48.2183, "lon": 16.3583},
    {"name": "Favoriten", "lat": 48.1750, "lon": 16.3833},
    {"name": "Simmering", "lat": 48.1667, "lon": 16.4000},
    {"name": "Meidling", "lat": 48.1750, "lon": 16.3333},
    {"name": "Hietzing", "lat": 48.1833, "lon": 16.3000},
    {"name": "Penzing", "lat": 48.1917, "lon": 16.3000},
    {"name": "Rudolfsheim-Fünfhaus", "lat": 48.2000, "lon": 16.3250},
    {"name": "Ottakring", "lat": 48.2083, "lon": 16.3250},
    {"name": "Hernals", "lat": 48.2167, "lon": 16.3250},
    {"name": "Währing", "lat": 48.2250, "lon": 16.3250},
    {"name": "Döbling", "lat": 48.2333, "lon": 16.3250},
    {"name": "Brigittenau", "lat": 48.2250, "lon": 16.3750},
    {"name": "Floridsdorf", "lat": 48.2333, "lon": 16.4000},
    {"name": "Donaustadt", "lat": 48.2250, "lon": 16.4500},
    {"name": "Liesing", "lat": 48.1333, "lon": 16.2833}
]

# Popular interests in Vienna
VIENNA_INTERESTS = [
    # Academic/Study
    "Computer Science", "Mathematics", "Physics", "Chemistry", "Biology", "Medicine", "Psychology", "Economics", "Business", "Law",
    "History", "Philosophy", "Literature", "Languages", "Art History", "Architecture", "Engineering", "Data Science", "AI/ML",
    
    # Cultural
    "Classical Music", "Opera", "Jazz", "Contemporary Art", "Museums", "Theater", "Film", "Photography", "Dance", "Ballet",
    "Vienna Coffee Culture", "Austrian Cuisine", "Wine Tasting", "Café Culture", "Historical Sites", "Palaces", "Cathedrals",
    
    # Social/Activities
    "Hiking", "Cycling", "Soccer", "Tennis", "Swimming", "Yoga", "Meditation", "Cooking", "Baking", "Gardening",
    "Travel", "Photography", "Writing", "Reading", "Gaming", "Board Games", "Chess", "Poker", "Dancing", "Singing",
    
    # Professional
    "Networking", "Startups", "Entrepreneurship", "Marketing", "Finance", "Consulting", "Research", "Teaching", "Mentoring",
    "Public Speaking", "Leadership", "Project Management", "Design", "UX/UI", "Programming", "Web Development", "Mobile Apps",
    
    # Language/Cultural Exchange
    "German", "English", "French", "Italian", "Spanish", "Russian", "Chinese", "Japanese", "Arabic", "Turkish",
    "Language Exchange", "Cultural Exchange", "International Students", "Study Abroad", "Erasmus",
    
    # Environmental/Social
    "Sustainability", "Climate Change", "Renewable Energy", "Social Justice", "Human Rights", "Volunteering", "Community Service",
    "Animal Rights", "Veganism", "Organic Food", "Zero Waste", "Urban Gardening", "Public Transport", "Cycling Advocacy"
]

# Skills with levels
SKILLS = {
    "Programming": ["Python", "Java", "JavaScript", "C++", "Swift", "Kotlin", "Rust", "Go", "PHP", "Ruby"],
    "Design": ["Graphic Design", "UI/UX Design", "Web Design", "Interior Design", "Fashion Design", "Product Design"],
    "Languages": ["German", "English", "French", "Italian", "Spanish", "Russian", "Chinese", "Japanese"],
    "Music": ["Piano", "Violin", "Guitar", "Singing", "Composition", "Music Production"],
    "Sports": ["Soccer", "Tennis", "Swimming", "Cycling", "Running", "Yoga", "Martial Arts"],
    "Cooking": ["Austrian Cuisine", "Italian Cuisine", "Asian Cuisine", "Baking", "Pastry", "Vegan Cooking"],
    "Academic": ["Research", "Data Analysis", "Statistics", "Machine Learning", "Academic Writing", "Teaching"]
}

# Event types and their typical interests
EVENT_TYPES = {
    "study": ["Computer Science", "Mathematics", "Physics", "Chemistry", "Biology", "Medicine", "Psychology", "Economics", "Business", "Law", "History", "Philosophy", "Literature", "Languages", "Data Science", "AI/ML", "Research", "Academic Writing"],
    "party": ["Classical Music", "Jazz", "Dancing", "Singing", "Gaming", "Board Games", "Socializing", "Networking", "Cultural Exchange"],
    "business": ["Networking", "Startups", "Entrepreneurship", "Marketing", "Finance", "Consulting", "Leadership", "Project Management", "Public Speaking"],
    "other": ["Hiking", "Cycling", "Cooking", "Baking", "Photography", "Travel", "Museums", "Theater", "Film", "Sustainability", "Volunteering"]
}

def create_trust_levels():
    """Create default trust levels if they don't exist"""
    levels = [
        {"level": 1, "title": "Newcomer", "required_ratings": 0, "min_average_rating": 0.0},
        {"level": 2, "title": "Active Member", "required_ratings": 3, "min_average_rating": 3.5},
        {"level": 3, "title": "Trusted Member", "required_ratings": 10, "min_average_rating": 4.0},
        {"level": 4, "title": "Community Leader", "required_ratings": 25, "min_average_rating": 4.2},
        {"level": 5, "title": "Vienna Expert", "required_ratings": 50, "min_average_rating": 4.5}
    ]
    
    for level_data in levels:
        UserTrustLevel.objects.get_or_create(
            level=level_data["level"],
            defaults=level_data
        )

def generate_realistic_name():
    """Generate realistic Austrian/German names"""
    first_names = [
        "Alexander", "Andreas", "Anna", "Barbara", "Bernhard", "Christina", "Daniel", "Elisabeth", "Florian", "Gabriele",
        "Georg", "Hannah", "Ingrid", "Jakob", "Julia", "Katharina", "Lukas", "Maria", "Markus", "Michaela",
        "Nikolaus", "Petra", "Philipp", "Sabine", "Stefan", "Susanne", "Thomas", "Ursula", "Veronika", "Wolfgang",
        "Adrian", "Bettina", "Christian", "Diana", "Erik", "Franziska", "Gerhard", "Helena", "Ivan", "Josef",
        "Klara", "Lena", "Manuel", "Nina", "Oliver", "Patricia", "Rainer", "Sandra", "Tobias", "Valentina"
    ]
    
    last_names = [
        "Bauer", "Berger", "Fischer", "Gruber", "Huber", "Klein", "Koch", "Mayer", "Müller", "Pichler",
        "Steiner", "Wagner", "Weber", "Winkler", "Wolf", "Zimmermann", "Schmidt", "Schneider", "Hofmann", "Schäfer",
        "Koch", "Meyer", "Becker", "Schulz", "Hoffmann", "Schmitt", "Schneider", "Fischer", "Weber", "Meyer",
        "Wagner", "Becker", "Schulz", "Hoffmann", "Schäfer", "Koch", "Bauer", "Richter", "Klein", "Wolf",
        "Schröder", "Neumann", "Schwarz", "Zimmermann", "Braun", "Krüger", "Hofmann", "Hartmann", "Lange", "Schmitt"
    ]
    
    return f"{random.choice(first_names)}_{random.choice(last_names)}"

def generate_user_interests():
    """Generate realistic user interests"""
    num_interests = random.randint(3, 8)
    return random.sample(VIENNA_INTERESTS, num_interests)

def generate_user_skills():
    """Generate realistic user skills"""
    skills = {}
    num_skills = random.randint(1, 4)
    skill_categories = random.sample(list(SKILLS.keys()), num_skills)
    
    for category in skill_categories:
        skill_name = random.choice(SKILLS[category])
        skill_level = random.choice(["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"])
        skills[skill_name] = skill_level
    
    return skills

def generate_bio(interests, university, degree):
    """Generate a realistic bio based on interests and academic background"""
    bio_templates = [
        f"Student at {university} studying {degree}. Passionate about {', '.join(interests[:3])}. Always looking to connect with like-minded people in Vienna!",
        f"Currently pursuing {degree} at {university}. Love exploring Vienna's {random.choice(['coffee culture', 'museums', 'parks', 'cultural scene'])} and meeting new people.",
        f"Vienna-based {degree} student at {university}. Interested in {', '.join(interests[:2])} and discovering the city's hidden gems.",
        f"From {university}, studying {degree}. Enjoy {', '.join(interests[:2])} and building meaningful connections in this beautiful city.",
        f"Passionate {degree} student at {university}. Love {', '.join(interests[:2])} and the vibrant atmosphere of Vienna."
    ]
    
    return random.choice(bio_templates)

def create_vienna_users(num_users=200):
    """Create realistic Vienna users"""
    print(f"Creating {num_users} Vienna users...")
    
    # Create trust levels first
    create_trust_levels()
    
    users_created = []
    
    for i in range(num_users):
        try:
            # Generate user data
            username = generate_realistic_name()
            email = f"{username.lower()}@example.com"
            password = "vienna123"  # Simple password for testing
            
            # Create user
            user = User.objects.create_user(
                username=username,
                email=email,
                password=password,
                first_name=username.split('_')[0],
                last_name=username.split('_')[1]
            )
            
            # Generate profile data
            university = random.choice(VIENNA_UNIVERSITIES)
            degrees = ["Computer Science", "Mathematics", "Physics", "Medicine", "Economics", "Law", "Psychology", "History", "Philosophy", "Engineering", "Business Administration", "International Relations", "Art History", "Architecture", "Biology", "Chemistry"]
            degree = random.choice(degrees)
            years = ["1st Year", "2nd Year", "3rd Year", "4th Year", "5th Year", "Master's", "PhD"]
            year = random.choice(years)
            
            interests = generate_user_interests()
            skills = generate_user_skills()
            bio = generate_bio(interests, university, degree)
            
            # Create user profile
            profile = UserProfile.objects.get(user=user)
            profile.full_name = f"{user.first_name} {user.last_name}"
            profile.university = university
            profile.degree = degree
            profile.year = year
            profile.bio = bio
            profile.interests = interests
            profile.skills = skills
            profile.auto_invite_enabled = random.choice([True, True, True, False])  # 75% enable auto-matching
            profile.preferred_radius = random.uniform(5.0, 20.0)
            profile.save()
            
            # Create reputation stats
            trust_level = UserTrustLevel.objects.get(level=random.choices([1, 2, 3, 4, 5], weights=[0.4, 0.3, 0.2, 0.08, 0.02])[0])
            
            reputation_stats = UserReputationStats.objects.create(
                user=user,
                total_ratings=random.randint(0, 20),
                average_rating=random.uniform(3.0, 5.0),
                trust_level=trust_level,
                events_hosted=random.randint(0, 5),
                events_attended=random.randint(0, 15)
            )
            
            users_created.append({
                "username": username,
                "password": password,
                "email": email,
                "university": university,
                "degree": degree,
                "interests": interests
            })
            
            if (i + 1) % 50 == 0:
                print(f"Created {i + 1} users...")
                
        except Exception as e:
            print(f"Error creating user {i}: {str(e)}")
            continue
    
    print(f"✅ Created {len(users_created)} Vienna users successfully!")
    return users_created

def create_vienna_events(num_events=100):
    """Create realistic Vienna events with auto-matching enabled"""
    print(f"Creating {num_events} Vienna events...")
    
    users = list(User.objects.all())
    if not users:
        print("❌ No users found. Please create users first.")
        return []
    
    events_created = []
    
    for i in range(num_events):
        try:
            # Select random host
            host = random.choice(users)
            
            # Generate event data
            event_templates = {
                "study": [
                    "Study Group: {subject}",
                    "{subject} Review Session",
                    "Group Project: {subject}",
                    "{subject} Discussion Group",
                    "Exam Prep: {subject}",
                    "Research Meeting: {subject}",
                    "Thesis Writing: {subject}",
                    "Lab Session: {subject}"
                ],
                "party": [
                    "Vienna Night Out",
                    "International Student Meetup",
                    "Cultural Exchange Party",
                    "Music & Dance Night",
                    "Game Night",
                    "Karaoke Evening",
                    "Wine Tasting Party",
                    "Summer Garden Party"
                ],
                "business": [
                    "Networking Event",
                    "Startup Meetup",
                    "Career Development Workshop",
                    "Business Pitch Night",
                    "Professional Networking",
                    "Industry Discussion",
                    "Mentorship Session",
                    "Entrepreneur Meetup"
                ],
                "other": [
                    "Vienna Walking Tour",
                    "Cooking Class: {cuisine}",
                    "Language Exchange",
                    "Photography Workshop",
                    "Hiking Trip",
                    "Museum Visit",
                    "Concert Night",
                    "Volunteer Activity"
                ]
            }
            
            event_type = random.choice(list(event_templates.keys()))
            template = random.choice(event_templates[event_type])
            
            # Generate interests for the event
            event_interests = random.sample(EVENT_TYPES[event_type], random.randint(2, 5))
            
            # Generate title
            if "{subject}" in template:
                subject = random.choice(event_interests)
                title = template.format(subject=subject)
            elif "{cuisine}" in template:
                cuisines = ["Austrian", "Italian", "Asian", "Mediterranean", "Vegan"]
                title = template.format(cuisine=random.choice(cuisines))
            else:
                title = template
            
            # Generate description
            descriptions = [
                f"Join us for an amazing {event_type} event in Vienna! Perfect for meeting new people and having a great time.",
                f"Looking for people interested in {', '.join(event_interests)}. Let's explore Vienna together!",
                f"Connect with fellow students and professionals in Vienna. Focus on {', '.join(event_interests)}.",
                f"Vienna's best {event_type} event! Come join us for an unforgettable experience.",
                f"International meetup in the heart of Vienna. Great opportunity to practice languages and make friends."
            ]
            description = random.choice(descriptions)
            
            # Generate location and time
            location = random.choice(VIENNA_LOCATIONS)
            base_time = timezone.now() + timedelta(days=random.randint(1, 30))
            event_time = base_time.replace(
                hour=random.randint(9, 21),
                minute=random.choice([0, 15, 30, 45])
            )
            end_time = event_time + timedelta(hours=random.randint(1, 4))
            
            # Create event
            event = StudyEvent.objects.create(
                title=title,
                description=description,
                host=host,
                latitude=location["lat"] + random.uniform(-0.01, 0.01),  # Add some variation
                longitude=location["lon"] + random.uniform(-0.01, 0.01),
                time=event_time,
                end_time=end_time,
                is_public=True,
                event_type=event_type,
                max_participants=random.randint(5, 20),
                auto_matching_enabled=random.choice([True, True, True, False]),  # 75% enable auto-matching
                interest_tags=event_interests
            )
            
            events_created.append({
                "id": str(event.id),
                "title": title,
                "host": host.username,
                "type": event_type,
                "interests": event_interests,
                "location": location["name"],
                "time": event_time.strftime("%Y-%m-%d %H:%M"),
                "auto_matching": event.auto_matching_enabled
            })
            
            if (i + 1) % 20 == 0:
                print(f"Created {i + 1} events...")
                
        except Exception as e:
            print(f"Error creating event {i}: {str(e)}")
            continue
    
    print(f"✅ Created {len(events_created)} Vienna events successfully!")
    return events_created

def create_friendships():
    """Create some realistic friendships between users"""
    print("Creating friendships...")
    
    users = list(User.objects.all())
    friendships_created = 0
    
    for user in users:
        # Each user has 0-5 friends
        num_friends = random.randint(0, 5)
        potential_friends = [u for u in users if u != user and u not in user.userprofile.friends.all()]
        
        if potential_friends:
            friends_to_add = random.sample(potential_friends, min(num_friends, len(potential_friends)))
            user.userprofile.friends.add(*[f.userprofile for f in friends_to_add])
            friendships_created += len(friends_to_add)
    
    print(f"✅ Created {friendships_created} friendships!")

def save_credentials(users, events):
    """Save credentials to a file for easy access"""
    with open("vienna_simulation_credentials.txt", "w") as f:
        f.write("VIENNA SIMULATION CREDENTIALS\n")
        f.write("=" * 50 + "\n\n")
        
        f.write("USER ACCOUNTS (Username: Password)\n")
        f.write("-" * 30 + "\n")
        for user in users[:20]:  # Show first 20 users
            f.write(f"{user['username']}: {user['password']}\n")
        
        f.write(f"\n... and {len(users) - 20} more users\n\n")
        
        f.write("SAMPLE EVENTS WITH AUTO-MATCHING\n")
        f.write("-" * 35 + "\n")
        auto_matched_events = [e for e in events if e['auto_matching']]
        for event in auto_matched_events[:10]:  # Show first 10 auto-matched events
            f.write(f"ID: {event['id']}\n")
            f.write(f"Title: {event['title']}\n")
            f.write(f"Host: {event['host']}\n")
            f.write(f"Type: {event['type']}\n")
            f.write(f"Interests: {', '.join(event['interests'])}\n")
            f.write(f"Location: {event['location']}\n")
            f.write(f"Time: {event['time']}\n")
            f.write("-" * 20 + "\n")
        
        f.write(f"\nTotal users: {len(users)}\n")
        f.write(f"Total events: {len(events)}\n")
        f.write(f"Auto-matched events: {len(auto_matched_events)}\n")
        
        f.write("\nTESTING INSTRUCTIONS:\n")
        f.write("-" * 20 + "\n")
        f.write("1. Use any username:password combination above to log in\n")
        f.write("2. Create events with interest tags to test auto-matching\n")
        f.write("3. Check the auto-matched events filter in the app\n")
        f.write("4. Use the event IDs above to test the enhanced matching API\n")
    
    print("✅ Credentials saved to 'vienna_simulation_credentials.txt'")

def main():
    """Main function to create the Vienna simulation"""
    print("🏛️ Creating Vienna Simulation Database")
    print("=" * 50)
    
    # Clear existing data (optional - comment out if you want to keep existing data)
    # print("Clearing existing data...")
    # User.objects.all().delete()
    # StudyEvent.objects.all().delete()
    
    # Create users
    users = create_vienna_users(200)
    
    # Create events
    events = create_vienna_events(100)
    
    # Create friendships
    create_friendships()
    
    # Save credentials
    save_credentials(users, events)
    
    print("\n🎉 Vienna Simulation Complete!")
    print("=" * 30)
    print(f"✅ Created {len(users)} users")
    print(f"✅ Created {len(events)} events")
    print(f"✅ {len([e for e in events if e['auto_matching']])} events have auto-matching enabled")
    print("✅ Credentials saved to 'vienna_simulation_credentials.txt'")
    print("\n🔍 Test the enhanced automatching system:")
    print("1. Log in with any user from the credentials file")
    print("2. Create events with interest tags")
    print("3. Check auto-matched events in the app")
    print("4. Use the API to test matching algorithms")

if __name__ == "__main__":
    main() 