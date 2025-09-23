import random
import os
import django
import uuid
from datetime import datetime, timedelta
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone
from django.db import transaction
from django.core.management import call_command
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import StudyEvent, EventComment, EventLike, EventShare, EventImage, UserProfile, EventInvitation
from django.contrib.auth.models import User

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

# Vienna-specific student interests
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
    "Python": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "Java": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "C++": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "JavaScript": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "Data Analysis": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "Machine Learning": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "Web Development": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "Database Management": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "UI/UX Design": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "Mobile Development": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "Project Management": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "Digital Marketing": ["Beginner", "Intermediate", "Advanced", "Expert"],
    "German": ["A1", "A2", "B1", "B2", "C1", "C2", "Native"],
    "English": ["A1", "A2", "B1", "B2", "C1", "C2", "Native"],
    "Spanish": ["A1", "A2", "B1", "B2", "C1", "C2", "Native"],
    "French": ["A1", "A2", "B1", "B2", "C1", "C2", "Native"],
    "Italian": ["A1", "A2", "B1", "B2", "C1", "C2", "Native"],
    "Musical Instrument": ["Beginner", "Intermediate", "Advanced", "Professional"],
    "Drawing": ["Beginner", "Intermediate", "Advanced", "Professional"],
    "Photography": ["Beginner", "Intermediate", "Advanced", "Professional"],
}

# Event types and their typical locations
EVENT_TYPES = {
    "study": ["library", "study room", "university campus", "quiet café", "coworking space"],
    "party": ["student club", "bar", "apartment", "outdoor area", "cultural venue"],
    "business": ["conference room", "workshop space", "networking event", "startup hub", "university hall"],
    "other": ["community center", "park", "sports facility", "museum", "gallery", "theater"]
}

# Rich event templates based on event types
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

# Comment templates organized by event type
COMMENT_TEMPLATES = {
    "study": [
        "Looking forward to studying {subject} together!",
        "Does anyone have notes from the previous {subject} lecture?",
        "I'm bringing extra materials on {topic}.",
        "Could we focus on {topic} specifically? I found it challenging.",
        "Great initiative! {subject} is always better studied in groups."
    ],
    "party": [
        "This sounds like so much fun! Can't wait!",
        "Who else is coming to this?",
        "Looking forward to meeting new people!",
        "Is there a dress code for this?",
        "Thanks for organizing! Needed this after exam season."
    ],
    "business": [
        "Really interested in learning more about {industry}.",
        "Will there be opportunities for one-on-one networking?",
        "Looking forward to improving my {skill} skills.",
        "Does anyone know if {company} offers internships?",
        "Great opportunity for career development!"
    ],
    "other": [
        "This sounds like a unique experience!",
        "I've been wanting to try {activity} for ages.",
        "Will beginners be welcome?",
        "Looking forward to meeting people with similar interests!",
        "Such a creative idea for an event!"
    ]
}

# Subjects for study events
SUBJECTS = [
    "Mathematics", "Physics", "Chemistry", "Biology", "Computer Science", 
    "Economics", "Business", "Law", "Medicine", "Psychology", "Sociology",
    "Political Science", "History", "Literature", "Philosophy", "Art History",
    "Engineering", "Architecture", "Environmental Science", "Languages"
]

# Topics within subjects
TOPICS = {
    "Mathematics": ["Calculus", "Linear Algebra", "Statistics", "Probability", "Number Theory"],
    "Physics": ["Mechanics", "Electromagnetism", "Thermodynamics", "Quantum Mechanics", "Optics"],
    "Computer Science": ["Algorithms", "Data Structures", "Machine Learning", "Web Development", "Databases"],
    "Languages": ["Grammar", "Conversation", "Literature", "Writing", "Vocabulary"],
    "Economics": ["Microeconomics", "Macroeconomics", "International Trade", "Econometrics", "Finance"],
    "Law": ["Constitutional Law", "Criminal Law", "International Law", "EU Law", "Human Rights Law"]
}

# Default topics for subjects not specifically listed
DEFAULT_TOPICS = ["Fundamentals", "Advanced Concepts", "Practical Applications", "Theory", "Problem Solving"]

# Additional data for template filling
TEMPLATE_DATA = {
    "items": ["textbooks", "notes", "laptop", "calculator", "study materials", "research papers", "assignments"],
    "activity": ["games", "music", "dancing", "food", "drinks", "karaoke", "quiz competition", "movie screening"],
    "theme": ["80s", "Halloween", "International", "Costume", "Beach", "Winter Wonderland", "Neon"],
    "industry": ["Tech", "Finance", "Healthcare", "Education", "Engineering", "Marketing", "Design", "Media"],
    "skill": ["Public Speaking", "Networking", "Resume Writing", "Interview Skills", "Leadership", "Time Management"],
    "company": ["Google", "Microsoft", "Amazon", "Local Startup", "Vienna Tech", "Austrian Innovation Hub"],
    "specific_topic": ["container gardening techniques", "urban agriculture", "sustainable living", "community building"],
    "location": ["Museumquartier", "Naschmarkt", "Stadtpark", "Danube Island", "Vienna University Campus", "Prater", "Karlsplatz"]
}

# Generate a script that creates detailed test data for the PinIt app
class Command:
    def __init__(self):
        self.users = []
        self.events = []
        self.user_profiles = []
    
    def print(self, message):
        """Print a message to console"""
        print(message)
    
    @transaction.atomic
    def handle(self):
        """Main method to generate all test data"""
        self.print("Starting Vienna PinIt data generation...")
        
        # Clear existing data
        self.clear_database()
        
        # Create users with profiles
        self.create_users()
        
        # Create events
        self.create_events()
        
        # Create invitations (direct and auto-matched)
        self.create_invitations()
        
        # Create social interactions
        self.create_interactions()
        
        self.print("\nData generation complete!")
        self.print_statistics()
    
    def clear_database(self):
        """Clear all existing data from relevant tables"""
        self.print("Clearing existing database data...")
        
        # Delete all interaction data
        EventComment.objects.all().delete()
        EventLike.objects.all().delete()
        EventShare.objects.all().delete()
        EventImage.objects.all().delete()
        
        # Delete invitations and events
        EventInvitation.objects.all().delete()
        StudyEvent.objects.all().delete()
        
        # Delete user profiles and users (except superuser)
        UserProfile.objects.all().delete()
        User.objects.filter(is_superuser=False).delete()
        
        self.print("Database cleared.")
    
    def create_users(self):
        """Create a diverse set of users with profiles"""
        self.print("Creating users with profiles...")
        
        # Common user types in Vienna
        user_types = [
            # Local students
            {"prefix": "Student", "count": 15, "certified": False, 
             "interests_count": (3, 7), "skills_count": (2, 5)},
            
            # Exchange students
            {"prefix": "Exchange", "count": 10, "certified": False,
             "interests_count": (3, 6), "skills_count": (2, 4)},
             
            # PhD students and researchers
            {"prefix": "Researcher", "count": 5, "certified": True,
             "interests_count": (2, 5), "skills_count": (3, 6)},
             
            # Professors and lecturers
            {"prefix": "Prof", "count": 5, "certified": True,
             "interests_count": (2, 4), "skills_count": (4, 7)},
             
            # Regular users
            {"prefix": "User", "count": 10, "certified": False,
             "interests_count": (2, 5), "skills_count": (1, 4)},
        ]
        
        # Named users with specific roles
        named_users = [
            {"username": "NormalGuy", "certified": False},
            {"username": "Lill", "certified": False},
            {"username": "JanDoe", "certified": True},
            {"username": "MariaKlein", "certified": False},
            {"username": "ThomasWeber", "certified": False},
            {"username": "FranzMueller", "certified": False},
            {"username": "SophiaWagner", "certified": False},
            {"username": "MaxHuber", "certified": False},
            {"username": "EmmaSchmidt", "certified": False},
            {"username": "LukasGruber", "certified": False},
            {"username": "LeaFischer", "certified": False},
            {"username": "MohammedPhD", "certified": True},
            {"username": "AkikoExchange", "certified": False},
            {"username": "ZoeVisiting", "certified": False},
            {"username": "ProfMeier", "certified": True},
            {"username": "DrSchmidt", "certified": True},
            {"username": "TutorLisa", "certified": True},
            {"username": "HostPhilipp", "certified": False},
            {"username": "OrganizerAlex", "certified": False},
            {"username": "AnaHoffmann", "certified": False},
            {"username": "Admin", "certified": True},
        ]
        
        # Create each named user
        for user_info in named_users:
            username = user_info["username"]
            certified = user_info["certified"]
            
            # Create user
            user = User.objects.create_user(
                username=username,
                email=f"{username.lower()}@example.com",
                password="Schamixd1",
                first_name=username,
                last_name="User"
            )
            
            # Create profile
            self.create_user_profile(user, certified)
            self.users.append(user)
        
        # Create generic users by type
        for user_type in user_types:
            prefix = user_type["prefix"]
            count = user_type["count"]
            certified = user_type["certified"]
            interests_range = user_type["interests_count"]
            skills_range = user_type["skills_count"]
            
            for i in range(1, count + 1):
                username = f"{prefix}{i}"
                
                # Create user
                user = User.objects.create_user(
                    username=username,
                    email=f"{username.lower()}@example.com",
                    password="Schamixd1",
                    first_name=random.choice(["Alex", "Sam", "Jordan", "Taylor", "Morgan", "Chris", "Pat"]),
                    last_name=random.choice(["Smith", "Müller", "Huber", "Wagner", "Novak", "Popescu", "Garcia"])
                )
                
                # Create profile with type-specific parameters
                self.create_user_profile(
                    user, 
                    certified, 
                    min_interests=interests_range[0],
                    max_interests=interests_range[1],
                    min_skills=skills_range[0],
                    max_skills=skills_range[1]
                )
                self.users.append(user)
        
        self.print(f"Created {len(self.users)} users with profiles.")
    
    def create_user_profile(self, user, certified, min_interests=2, max_interests=5, min_skills=1, max_skills=4):
        """Create a user profile with interests and skills"""
        # Select random interests
        interests_count = random.randint(min_interests, max_interests)
        interests = random.sample(STUDENT_INTERESTS, interests_count)
        
        # Select random skills with proficiency levels
        skills_count = random.randint(min_skills, max_skills)
        skill_keys = random.sample(list(SKILLS.keys()), skills_count)
        skills = {}
        for skill in skill_keys:
            proficiency = random.choice(SKILLS[skill])
            skills[skill] = proficiency
        
        # Creating user profile
        profile = UserProfile.objects.create(
            user=user,
            is_certified=certified,
            interests=interests,
            skills=skills,
            auto_invite_enabled=random.choice([True, True, True, False]),  # 75% with auto-invite enabled
            preferred_radius=random.choice([2.0, 5.0, 10.0, 20.0])
        )
        
        self.user_profiles.append(profile)
        return profile
    
    def create_events(self):
        """Create a variety of events in Vienna"""
        self.print("Creating events...")
        
        # Number of events to create
        event_count = 50
        
        # Time range for events (from now to 2 years in the future)
        now = timezone.now()
        
        for i in range(event_count):
            # Select a random user to host the event
            host = random.choice(self.users)
            
            # Determine if this is a public event
            is_public = random.random() < 0.7  # 70% of events are public
            
            # Select event type
            event_type = random.choice(list(EVENT_TYPES.keys()))
            
            # Select random Vienna location
            area_name, coordinates = random.choice(VIENNA_AREAS)
            
            # Add some randomness to coordinates
            lat = coordinates[0] + random.uniform(-0.01, 0.01)
            lon = coordinates[1] + random.uniform(-0.01, 0.01)
            
            # Select event template based on type
            template = random.choice(EVENT_TEMPLATES[event_type])
            
            # Event time: random time in the future
            days_offset = random.randint(1, 365)
            hours_offset = random.randint(0, 23)
            minutes_offset = random.choice([0, 15, 30, 45])
            
            event_time = now + timedelta(days=days_offset, hours=hours_offset, minutes=minutes_offset)
            event_end_time = event_time + timedelta(hours=random.randint(1, 5))
            
            # Fill template placeholders
            title_data = {}
            desc_data = {}
            
            if event_type == "study":
                subject = random.choice(SUBJECTS)
                title_data["subject"] = subject
                desc_data["subject"] = subject
                
                # Get topic for this subject
                if subject in TOPICS:
                    topic = random.choice(TOPICS[subject])
                else:
                    topic = random.choice(DEFAULT_TOPICS)
                
                desc_data["topic"] = topic
                
            for key in template["title_template"].replace("{", "").replace("}", "").split():
                if key in TEMPLATE_DATA and key not in title_data:
                    title_data[key] = random.choice(TEMPLATE_DATA[key])
            
            for key in template["description_template"].replace("{", "").replace("}", "").split():
                if key in TEMPLATE_DATA and key not in desc_data:
                    desc_data[key] = random.choice(TEMPLATE_DATA[key])
            
            # Format title and description
            try:
                title = template["title_template"].format(**title_data)
                description = template["description_template"].format(**desc_data)
            except KeyError:
                # Fallback for any missing template variables
                title = f"{event_type.capitalize()} Event in {area_name}"
                description = f"Join us for this {event_type} event in {area_name}."
            
            # Create the event
            event = StudyEvent.objects.create(
                id=uuid.uuid4(),
                title=title,
                description=description,
                latitude=lat,
                longitude=lon,
                time=event_time,
                end_time=event_end_time,
                host=host,  # Django User object
                is_public=is_public,
                event_type=event_type
            )
            
            self.events.append(event)
        
        self.print(f"Created {len(self.events)} events.")
    
    def create_invitations(self):
        """Create direct and auto-matched invitations"""
        self.print("Creating invitations...")
        direct_count = 0
        auto_matched_count = 0
        
        for event in self.events:
            # Skip events that are not public or have passed
            if not event.is_public or event.time < timezone.now():
                continue
            
            # Get all users except the host
            potential_invitees = [user for user in self.users if user != event.host]
            
            # Direct invitations (2-8 per event)
            direct_invitees_count = random.randint(2, min(8, len(potential_invitees)))
            direct_invitees = random.sample(potential_invitees, direct_invitees_count)
            
            for invitee in direct_invitees:
                EventInvitation.objects.create(
                    event=event,
                    user=invitee,
                    is_auto_matched=False
                )
                direct_count += 1
            
            # Auto-matched invitations
            # Find users with auto_invite_enabled and matching interests
            event_subject = event.title.split()[0]  # Simple extraction of subject from title
            auto_match_candidates = []
            
            for user in potential_invitees:
                if user not in direct_invitees:  # Don't auto-match users who received direct invites
                    try:
                        profile = UserProfile.objects.get(user=user)
                        # Check if auto-invite is enabled
                        if profile.auto_invite_enabled:
                            # Simple interest matching (in a real system, this would be more sophisticated)
                            user_interests = profile.interests if hasattr(profile, 'interests') else []
                            
                            # Match based on event type or subject
                            if (event.event_type.lower() in [interest.lower() for interest in user_interests] or
                                event_subject.lower() in [interest.lower() for interest in user_interests] or
                                any(interest.lower() in event.description.lower() for interest in user_interests)):
                                auto_match_candidates.append(user)
                    except UserProfile.DoesNotExist:
                        continue
            
            # Select a subset of matching users
            auto_match_count = min(len(auto_match_candidates), random.randint(0, 5))
            auto_match_users = random.sample(auto_match_candidates, auto_match_count) if auto_match_candidates else []
            
            for user in auto_match_users:
                EventInvitation.objects.create(
                    event=event,
                    user=user,
                    is_auto_matched=True
                )
                auto_matched_count += 1
        
        # Special case: Make sure Lill has auto-matched invitations
        lill_user = User.objects.filter(username="Lill").first()
        if lill_user:
            # Find events that can be auto-matched for Lill
            suitable_events = [
                event for event in self.events 
                if event.is_public and event.time > timezone.now() and event.host != lill_user
            ]
            
            # Select 3-5 events for auto-matching with Lill
            auto_match_count_for_lill = min(len(suitable_events), random.randint(3, 5))
            lill_auto_match_events = random.sample(suitable_events, auto_match_count_for_lill)
            
            for event in lill_auto_match_events:
                # Check if invitation already exists
                if not EventInvitation.objects.filter(event=event, user=lill_user).exists():
                    EventInvitation.objects.create(
                        event=event,
                        user=lill_user,
                        is_auto_matched=True
                    )
                    auto_matched_count += 1
        
        self.print(f"Created {direct_count} direct invitations and {auto_matched_count} auto-matched invitations.")
    
    def create_interactions(self):
        """Create social interactions for events"""
        self.print("Creating social interactions for events...")
        
        # Comment templates and topics
        for event in self.events:
            # Skip events with no attendees or that haven't happened yet
            if event.time > timezone.now():
                continue
            
            # Select users for interactions (exclude host)
            interaction_users = [user for user in self.users if user != event.host]
            if not interaction_users:
                continue
            
            # Comments
            num_comments = random.randint(0, min(10, len(interaction_users)))
            comment_users = random.sample(interaction_users, k=num_comments) if num_comments > 0 else []
            
            for user in comment_users:
                # Select template based on event type
                templates = COMMENT_TEMPLATES.get(event.event_type, COMMENT_TEMPLATES["other"])
                comment_template = random.choice(templates)
                
                # Fill template with relevant data
                comment_data = {}
                if "{subject}" in comment_template:
                    subject = event.title.split()[0]
                    comment_data["subject"] = subject
                
                if "{topic}" in comment_template:
                    if "subject" in comment_data and comment_data["subject"] in TOPICS:
                        topic = random.choice(TOPICS[comment_data["subject"]])
                    else:
                        topic = random.choice(DEFAULT_TOPICS)
                    comment_data["topic"] = topic
                
                for key in ["industry", "skill", "company", "activity"]:
                    if "{" + key + "}" in comment_template:
                        comment_data[key] = random.choice(TEMPLATE_DATA[key])
                
                try:
                    comment_text = comment_template.format(**comment_data)
                except KeyError:
                    # Fallback for any template issues
                    comment_text = "Great event! Looking forward to it."
                
                # Create comment
                comment = EventComment.objects.create(
                    event=event,
                    user=user,
                    text=comment_text
                )
                
                # Sometimes add replies
                if random.random() < 0.3 and len(interaction_users) > 1:
                    reply_users = [u for u in interaction_users if u != user]
                    if reply_users:
                        reply_user = random.choice(reply_users)
                        reply_text = "Thanks for the comment! Looking forward to seeing you there."
                        EventComment.objects.create(
                            event=event,
                            user=reply_user,
                            text=reply_text,
                            parent=comment
                        )
            
            # Likes
            if interaction_users:
                num_likes = random.randint(0, min(len(interaction_users), 15))
                like_users = random.sample(interaction_users, k=num_likes) if num_likes > 0 else []
                
                for user in like_users:
                    EventLike.objects.create(
                        event=event,
                        user=user
                    )
            
            # Shares
            if interaction_users:
                share_platforms = ['whatsapp', 'facebook', 'twitter', 'instagram', 'email', 'other']
                num_shares = random.randint(0, min(5, len(interaction_users)))
                share_users = random.sample(interaction_users, k=num_shares) if num_shares > 0 else []
                
                for user in share_users:
                    EventShare.objects.create(
                        event=event,
                        user=user,
                        platform=random.choice(share_platforms)
                    )
    
    def print_statistics(self):
        """Print statistics about the generated data"""
        self.print("\n=== PinIt Data Statistics ===")
        self.print(f"Users created: {User.objects.count()}")
        self.print(f"User profiles: {UserProfile.objects.count()}")
        self.print(f"Study events: {StudyEvent.objects.count()}")
        self.print(f"Direct invitations: {EventInvitation.objects.filter(is_auto_matched=False).count()}")
        self.print(f"Auto-matched invitations: {EventInvitation.objects.filter(is_auto_matched=True).count()}")
        self.print(f"Comments: {EventComment.objects.count()}")
        self.print(f"Likes: {EventLike.objects.count()}")
        self.print(f"Shares: {EventShare.objects.count()}")
        
        lill_user = User.objects.filter(username="Lill").first()
        if lill_user:
            self.print(f"\nLill's Statistics:")
            lill_direct = EventInvitation.objects.filter(user=lill_user, is_auto_matched=False).count()
            lill_auto = EventInvitation.objects.filter(user=lill_user, is_auto_matched=True).count()
            self.print(f"Direct invitations: {lill_direct}")
            self.print(f"Auto-matched invitations: {lill_auto}")


# Run the command when executing the script directly
if __name__ == "__main__":
    command = Command()
    command.handle() 