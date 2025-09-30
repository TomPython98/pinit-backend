from django.core.management.base import BaseCommand
import random
import datetime
from django.utils import timezone
from django.db import transaction
from django.contrib.auth.models import User
from myapp.models import (
    UserProfile, StudyEvent, EventInvitation, 
    UserInterest, UserSkill, FriendRequest, 
    EventComment, EventLike, EventShare,
    DeclinedInvitation
)


class Command(BaseCommand):
    help = 'Populates the database with realistic Vienna-based users and events'

    def add_arguments(self, parser):
        parser.add_argument('--users', type=int, default=50, help='Number of users to create')
        parser.add_argument('--events', type=int, default=30, help='Number of events to create')
        parser.add_argument('--no-clear', action='store_true', help='Do not clear existing data')

    def handle(self, *args, **options):
        num_users = options['users']
        num_events = options['events']
        clear_data = not options['no_clear']

        self.stdout.write(self.style.SUCCESS('Starting Vienna app data population...'))

        if clear_data:
            self.clear_existing_data()

        # Create users
        users = self.create_vienna_users(num_users)
        
        # Create friendships between users
        self.create_friendships(users, connection_density=0.2)
        
        # Create events
        events = self.create_vienna_events(users, num_events)
        
        # Create event interactions
        self.create_event_interactions(users, events)
        
        self.stdout.write(self.style.SUCCESS('Vienna app data population completed successfully!'))

    def clear_existing_data(self):
        self.stdout.write("Clearing existing data...")
        EventShare.objects.all().delete()
        EventLike.objects.all().delete()
        EventComment.objects.all().delete()
        EventInvitation.objects.all().delete()
        DeclinedInvitation.objects.all().delete()
        FriendRequest.objects.all().delete()
        StudyEvent.objects.all().delete()
        UserSkill.objects.all().delete()
        UserInterest.objects.all().delete()
        
        # Keep UserProfile deletion last as it depends on User
        # Don't delete profiles directly, as they are linked to users
        User.objects.filter(is_superuser=False, is_staff=False).delete()
        
        self.stdout.write(self.style.SUCCESS("All existing data cleared."))

    # Define Vienna-specific data
    VIENNA_DISTRICTS = [
        "Innere Stadt", "Leopoldstadt", "Landstraße", "Wieden", "Margareten",
        "Mariahilf", "Neubau", "Josefstadt", "Alsergrund", "Favoriten",
        "Simmering", "Meidling", "Hietzing", "Penzing", "Rudolfsheim-Fünfhaus",
        "Ottakring", "Hernals", "Währing", "Döbling", "Brigittenau", "Floridsdorf",
        "Donaustadt", "Liesing"
    ]

    VIENNA_UNIVERSITIES = [
        "University of Vienna", "Vienna University of Technology", 
        "Medical University of Vienna", "Vienna University of Economics and Business",
        "University of Natural Resources and Life Sciences", 
        "University of Applied Arts Vienna", "University of Music and Performing Arts Vienna"
    ]

    VIENNA_CAFES = [
        "Café Central", "Café Sacher", "Café Hawelka", "Café Sperl", 
        "Café Landtmann", "Café Mozart", "Café Demel", "Café Prückel", 
        "Café Schwarzenberg", "Kleines Café"
    ]

    VIENNA_LANDMARKS = [
        "Schönbrunn Palace", "Belvedere Palace", "Hofburg Palace", 
        "St. Stephen's Cathedral", "Vienna State Opera", "Kunsthistorisches Museum",
        "Albertina Museum", "Prater", "Hundertwasserhaus", "Museumsquartier",
        "Karlskirche", "Naschmarkt", "Vienna City Hall"
    ]

    VIENNA_INTERESTS = [
        "Classical Music", "Opera", "Art History", "Coffee Culture", "Architecture",
        "German Language", "Austrian Literature", "Viennese Cuisine", "Waltz Dancing",
        "European Politics", "History", "Philosophy", "Theater", "Film Studies",
        "Psychology", "Economics", "Computer Science", "Mathematics", "Physics",
        "Chemistry", "Biology", "Medicine", "Law", "Environmental Studies",
        "Sustainability", "Hiking", "Cycling", "Swimming", "Running", "Yoga",
        "Chess", "Reading", "Writing", "Photography", "Design", "Fashion",
        "Cooking", "Baking", "Wine Tasting", "Beer Brewing", "Gardening"
    ]

    ACADEMIC_INTERESTS = [
        "Literature", "Linguistics", "History", "Philosophy", "Anthropology",
        "Sociology", "Psychology", "Political Science", "Economics", "Business",
        "Marketing", "Finance", "Accounting", "Statistics", "Mathematics",
        "Physics", "Chemistry", "Biology", "Medicine", "Pharmacy", "Engineering",
        "Computer Science", "Information Technology", "Cybersecurity", "AI/ML",
        "Data Science", "Architecture", "Urban Planning", "Environmental Studies",
        "Climate Science", "Agriculture", "Forestry", "Veterinary Medicine",
        "Law", "International Relations", "Education", "Art History", "Music Theory",
        "Theater Studies", "Film Studies", "Media Studies", "Communication"
    ]

    EVENT_TYPES = ["study", "party", "business", "other"]

    # Austrian/German names for realistic Vienna population
    FIRST_NAMES = [
        "Andreas", "Anna", "Anton", "Barbara", "Bernd", "Birgit", "Christian", "Christine",
        "Daniel", "Elisabeth", "Eva", "Felix", "Florian", "Friedrich", "Georg", "Gerhard",
        "Hannah", "Helmut", "Isabella", "Jakob", "Johannes", "Julia", "Katharina", "Klaus",
        "Laura", "Lukas", "Magdalena", "Maria", "Markus", "Martin", "Matthias", "Maximilian",
        "Michael", "Monika", "Nico", "Nina", "Oliver", "Paul", "Peter", "Richard", "Robert",
        "Sandra", "Sarah", "Stefan", "Susanne", "Teresa", "Thomas", "Valentina", "Victoria",
        "Wolfgang"
    ]

    LAST_NAMES = [
        "Bauer", "Berger", "Ebner", "Fischer", "Fuchs", "Gruber", "Hofer", "Huber", "Keller",
        "Klein", "Koch", "Lang", "Leitner", "Mayer", "Moser", "Müller", "Pichler", "Reiter",
        "Schmid", "Schmidt", "Schneider", "Schuster", "Schwarz", "Steiner", "Wagner", "Weber",
        "Winkler", "Wolf", "Ziegler", "Becker", "Hoffmann", "Schulz", "Maier", "Lehmann",
        "Schröder", "Neumann", "Braun", "Zimmermann", "Hofmann", "Hartmann", "Richter", "Walter",
        "Werner", "Schmitz", "Krause", "Meier", "Lange", "Schäfer", "Schubert", "Kraus"
    ]

    # Define Vienna coordinates (approximately)
    VIENNA_CENTER = (48.2082, 16.3738)  # Latitude, Longitude
    VIENNA_RADIUS = 0.08  # Roughly covers the city

    def random_vienna_location(self):
        """Generate a random location within Vienna city limits"""
        # Add some randomness to the center coordinates
        lat = self.VIENNA_CENTER[0] + (random.random() - 0.5) * 2 * self.VIENNA_RADIUS
        lon = self.VIENNA_CENTER[1] + (random.random() - 0.5) * 2 * self.VIENNA_RADIUS
        return (lat, lon)

    def random_datetime(self, start_days=-30, end_days=60):
        """Generate a random datetime between start_days and end_days from now"""
        now = timezone.now()
        start_date = now + datetime.timedelta(days=start_days)
        end_date = now + datetime.timedelta(days=end_days)
        time_between_dates = end_date - start_date
        seconds_between_dates = time_between_dates.total_seconds()
        random_seconds = random.randrange(0, int(seconds_between_dates))
        return start_date + datetime.timedelta(seconds=random_seconds)

    def create_vienna_users(self, num_users=50):
        """Create users with Austrian/German names and Vienna-specific interests"""
        users = []
        self.stdout.write(f"Creating {num_users} users...")
        
        # Use transaction for efficiency
        with transaction.atomic():
            for i in range(num_users):
                first_name = random.choice(self.FIRST_NAMES)
                last_name = random.choice(self.LAST_NAMES)
                
                # Create username (first initial + last name + random number if needed)
                base_username = f"{first_name[0].lower()}{last_name.lower()}"
                username = base_username
                
                # Check if username exists, add number if it does
                counter = 1
                while User.objects.filter(username=username).exists():
                    username = f"{base_username}{counter}"
                    counter += 1
                
                # Create user with simple password (same for all)
                user = User.objects.create_user(
                    username=username,
                    password="vienna123",  # Simple password for all users
                    first_name=first_name,
                    last_name=last_name
                )
                
                # Get user profile (created automatically via signal)
                profile = user.userprofile
                
                # Set random certification (10% chance)
                profile.is_certified = random.random() < 0.1
                
                # Set auto invite preference (80% enabled)
                profile.auto_invite_enabled = random.random() < 0.8
                
                # Set preferred radius (between 2km and 20km)
                profile.preferred_radius = round(random.uniform(2.0, 20.0), 1)
                
                # Set interests (3-8 random interests)
                num_interests = random.randint(3, 8)
                interests = random.sample(self.VIENNA_INTERESTS + self.ACADEMIC_INTERESTS, num_interests)
                profile.set_interests(interests)
                
                # Set skills (2-5 random skills)
                num_skills = random.randint(2, 5)
                skills = {}
                for _ in range(num_skills):
                    skill = random.choice(self.ACADEMIC_INTERESTS)
                    level = random.choice(["BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT"])
                    skills[skill] = level
                profile.set_skills(skills)
                
                profile.save()
                users.append(user)
                
                # Progress indicator
                if (i + 1) % 10 == 0 or i + 1 == num_users:
                    self.stdout.write(f"Created {i + 1} users...")
        
        self.stdout.write(self.style.SUCCESS(f"Created {len(users)} users successfully."))
        return users

    def create_friendships(self, users, connection_density=0.2):
        """Create friendships between users with some randomness"""
        self.stdout.write("Creating friendships...")
        
        # Initialize counters
        friendship_count = 0
        friend_request_count = 0
        
        with transaction.atomic():
            for i, user1 in enumerate(users):
                # Determine how many other users this user will be friends with
                num_connections = int(len(users) * connection_density)
                potential_friends = users.copy()
                potential_friends.remove(user1)  # Can't be friends with yourself
                
                # Shuffle to get random connections
                random.shuffle(potential_friends)
                
                # Create friendships
                for j in range(min(num_connections, len(potential_friends))):
                    user2 = potential_friends[j]
                    
                    # Skip if already friends
                    if user2.userprofile in user1.userprofile.friends.all():
                        continue
                    
                    # 80% chance of established friendship, 20% chance of pending request
                    if random.random() < 0.8:
                        # Create mutual friendship
                        user1.userprofile.friends.add(user2.userprofile)
                        user2.userprofile.friends.add(user1.userprofile)
                        friendship_count += 1
                    else:
                        # Create a friend request (if none exists)
                        if not FriendRequest.objects.filter(from_user=user1, to_user=user2).exists() and \
                        not FriendRequest.objects.filter(from_user=user2, to_user=user1).exists():
                            FriendRequest.objects.create(from_user=user1, to_user=user2)
                            friend_request_count += 1
        
        self.stdout.write(self.style.SUCCESS(f"Created {friendship_count} friendships and {friend_request_count} pending friend requests."))

    def create_vienna_events(self, users, num_events=30):
        """Create study events in Vienna with realistic details"""
        self.stdout.write(f"Creating {num_events} events...")
        
        events = []
        with transaction.atomic():
            for i in range(num_events):
                # Choose a random host (weighted toward certified users)
                certified_users = [u for u in users if u.userprofile.is_certified]
                regular_users = [u for u in users if not u.userprofile.is_certified]
                
                # 70% chance to pick a certified user if available
                if certified_users and random.random() < 0.7:
                    host = random.choice(certified_users)
                else:
                    host = random.choice(users)
                
                # Get host friends - FIXED: get User objects, not just IDs
                host_friends_profiles = host.userprofile.friends.all()
                host_friends = []
                for profile in host_friends_profiles:
                    host_friends.append(profile.user)
                
                # Generate event data
                event_type = random.choice(self.EVENT_TYPES)
                
                # Create realistic Vienna-based titles
                if event_type == "study":
                    title_templates = [
                        f"Study Session: {{}} at {random.choice(self.VIENNA_UNIVERSITIES)}",
                        f"{{}} Group at {random.choice(self.VIENNA_CAFES)}",
                        f"Exam Prep: {{}} at {random.choice(self.VIENNA_DISTRICTS)}",
                        f"Research Discussion: {{}}",
                        f"{{}} Workshop near {random.choice(self.VIENNA_LANDMARKS)}"
                    ]
                    subject = random.choice(self.ACADEMIC_INTERESTS)
                    title = random.choice(title_templates).format(subject)
                elif event_type == "party":
                    title_templates = [
                        f"Student Party at {random.choice(self.VIENNA_DISTRICTS)}",
                        f"Birthday Celebration at {random.choice(self.VIENNA_CAFES)}",
                        f"Weekend Gathering near {random.choice(self.VIENNA_LANDMARKS)}",
                        f"Semester End Party in {random.choice(self.VIENNA_DISTRICTS)}",
                        f"Casual Meet-up at {random.choice(self.VIENNA_CAFES)}"
                    ]
                    title = random.choice(title_templates)
                elif event_type == "business":
                    title_templates = [
                        f"Networking Event at {random.choice(self.VIENNA_CAFES)}",
                        f"Startup Meetup in {random.choice(self.VIENNA_DISTRICTS)}",
                        f"Career Workshop at {random.choice(self.VIENNA_UNIVERSITIES)}",
                        f"Industry Panel near {random.choice(self.VIENNA_LANDMARKS)}",
                        f"Business Idea Exchange"
                    ]
                    title = random.choice(title_templates)
                else:  # other
                    title_templates = [
                        f"Coffee & Chat at {random.choice(self.VIENNA_CAFES)}",
                        f"Walking Tour of {random.choice(self.VIENNA_LANDMARKS)}",
                        f"Cultural Exchange in {random.choice(self.VIENNA_DISTRICTS)}",
                        f"Book Club Meeting at {random.choice(self.VIENNA_CAFES)}",
                        f"Weekend Hike near Vienna"
                    ]
                    title = random.choice(title_templates)
                
                # Create descriptions
                descriptions = [
                    f"Join us for a productive session in this beautiful part of Vienna. Everyone is welcome!",
                    f"Let's meet for an exciting discussion. Great opportunity to make new connections in Vienna.",
                    f"Looking forward to seeing you in one of Vienna's nicest locations. Don't forget your materials!",
                    f"A perfect chance to enjoy Vienna while being productive. Refreshments will be provided.",
                    f"Join fellow students and professionals in this vibrant area of Vienna."
                ]
                description = random.choice(descriptions)
                
                # Generate event time details
                start_time = self.random_datetime()
                duration_hours = random.randint(1, 4)
                end_time = start_time + datetime.timedelta(hours=duration_hours)
                
                # Generate Vienna location
                lat, lon = self.random_vienna_location()
                
                # Create event
                event = StudyEvent.objects.create(
                    title=title,
                    description=description,
                    host=host,
                    latitude=lat,
                    longitude=lon,
                    time=start_time,
                    end_time=end_time,
                    is_public=random.random() < 0.7,  # 70% public
                    event_type=event_type,
                    max_participants=random.randint(5, 20),
                    auto_matching_enabled=random.random() < 0.5  # 50% auto-matching
                )
                
                # Add interest tags (3-6 random interests)
                num_tags = random.randint(3, 6)
                if hasattr(event, 'set_interest_tags'):
                    host_interests = host.userprofile.get_interests()
                    if host_interests:
                        # Mix host interests with random interests
                        available_tags = list(set(self.VIENNA_INTERESTS + self.ACADEMIC_INTERESTS + host_interests))
                        tags = random.sample(available_tags, min(num_tags, len(available_tags)))
                        event.set_interest_tags(tags)
                        event.save()
                        
                # Invite friends (25-50% of host's friends)
                if host_friends:
                    num_invites = max(1, int(len(host_friends) * random.uniform(0.25, 0.5)))
                    invitees = random.sample(host_friends, min(num_invites, len(host_friends)))
                    
                    for invitee in invitees:
                        # FIXED: invitee is now a User object, not an ID
                        invitation = EventInvitation.objects.create(
                            event=event,
                            user=invitee,
                            is_auto_matched=False
                        )
                
                # Add attendees (1-5 random users, including possibly the host)
                num_attendees = random.randint(1, 5)
                potential_attendees = random.sample(users, min(num_attendees, len(users)))
                
                for attendee in potential_attendees:
                    event.attendees.add(attendee)
                
                events.append(event)
                
                # Progress indicator
                if (i + 1) % 5 == 0 or i + 1 == num_events:
                    self.stdout.write(f"Created {i + 1} events...")
        
        self.stdout.write(self.style.SUCCESS(f"Created {len(events)} events successfully."))
        return events

    def create_event_interactions(self, users, events):
        """Create comments, likes, and shares for events"""
        self.stdout.write("Creating event interactions...")
        
        # Track counters
        comment_count = 0
        reply_count = 0
        like_count = 0
        share_count = 0
        
        with transaction.atomic():
            for event in events:
                # Determine how many comments this event will have (0-8)
                num_comments = random.randint(0, 8)
                
                # Create comments
                comments = []
                for _ in range(num_comments):
                    # Choose a random user
                    commenter = random.choice(users)
                    
                    # Create comment
                    comment_texts = [
                        "Looking forward to this event!",
                        "This sounds really interesting. Can't wait!",
                        "Is there anything specific we should prepare?",
                        "Thanks for organizing this!",
                        "I've been to that location before, it's great!",
                        "Will there be refreshments available?",
                        "Can I bring a friend along?",
                        "What time should we arrive?",
                        "Do we need to bring our own materials?",
                        "Is there parking nearby?",
                        "Is this suitable for beginners?",
                        "How long will this event last?",
                        "Are there any prerequisites for this event?",
                        "This is exactly what I've been looking for!"
                    ]
                    
                    comment = EventComment.objects.create(
                        event=event,
                        user=commenter,
                        text=random.choice(comment_texts)
                    )
                    comments.append(comment)
                    comment_count += 1
                    
                    # 30% chance of replies to comments
                    if random.random() < 0.3:
                        reply_texts = [
                            "Yes, great question!",
                            "I was wondering the same thing.",
                            "Looking forward to meeting you there!",
                            "I'll be there too!",
                            "Thanks for asking, I was curious about that as well.",
                            "See you at the event!",
                            "I'm excited too!",
                            "Has anyone been to this place before?",
                            "Good point!"
                        ]
                        
                        # Choose a random user for the reply (possibly the host)
                        replier = random.choice([event.host] + random.sample(users, 2))
                        
                        reply = EventComment.objects.create(
                            event=event,
                            user=replier,
                            text=random.choice(reply_texts),
                            parent=comment
                        )
                        reply_count += 1
                
                # Create likes (for both the event and comments)
                # Event likes
                num_event_likes = random.randint(0, 15)
                likers = random.sample(users, min(num_event_likes, len(users)))
                
                for liker in likers:
                    EventLike.objects.create(
                        event=event,
                        user=liker
                    )
                    like_count += 1
                
                # Comment likes
                for comment in comments:
                    # 50% chance for each comment to get likes
                    if random.random() < 0.5:
                        num_comment_likes = random.randint(1, 5)
                        comment_likers = random.sample(users, min(num_comment_likes, len(users)))
                        
                        for liker in comment_likers:
                            EventLike.objects.create(
                                event=event,
                                user=liker,
                                comment=comment
                            )
                            like_count += 1
                
                # Create shares (20% chance for each event)
                if random.random() < 0.2:
                    num_shares = random.randint(1, 3)
                    sharers = random.sample(users, min(num_shares, len(users)))
                    
                    for sharer in sharers:
                        platforms = ['whatsapp', 'facebook', 'twitter', 'instagram', 'other']
                        platform = random.choice(platforms)
                        
                        EventShare.objects.create(
                            event=event,
                            user=sharer,
                            shared_platform=platform
                        )
                        share_count += 1
        
        self.stdout.write(self.style.SUCCESS(f"Created {comment_count} comments, {reply_count} replies, {like_count} likes, and {share_count} shares."))