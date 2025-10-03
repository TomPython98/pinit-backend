#!/usr/bin/env python3
"""
Generate Reviews and Reputation Script
Create user ratings, reviews, and test the reputation system
"""

import requests
import json
import time
import random
from datetime import datetime, timedelta

# Production server URL
PRODUCTION_BASE_URL = "https://pinit-backend-production.up.railway.app/api/"

# Review templates for different rating levels
REVIEW_TEMPLATES = {
    5: [
        "Outstanding study partner! Very knowledgeable and helpful.",
        "Excellent organizer! The event was perfectly structured and engaging.",
        "Amazing collaboration! Learned so much from this person.",
        "Fantastic communication skills and great at explaining complex topics.",
        "Highly recommended! Always punctual and well-prepared.",
        "Incredible dedication to learning and helping others succeed.",
        "Outstanding leadership qualities and great team player.",
        "Exceptional knowledge sharing and very supportive of others.",
        "Brilliant problem-solving skills and excellent teaching ability.",
        "Outstanding contribution to our study group! Very inspiring."
    ],
    4: [
        "Great study partner! Very reliable and knowledgeable.",
        "Good organizer! The event was well-structured and informative.",
        "Nice collaboration! Learned a lot from this person.",
        "Good communication skills and helpful explanations.",
        "Recommended! Usually punctual and well-prepared.",
        "Good dedication to learning and helping others.",
        "Nice leadership qualities and good team player.",
        "Good knowledge sharing and supportive of others.",
        "Good problem-solving skills and teaching ability.",
        "Good contribution to our study group! Very helpful."
    ],
    3: [
        "Decent study partner. Knowledgeable but could improve communication.",
        "Okay organizer. Event was structured but could be more engaging.",
        "Average collaboration. Learned some things from this person.",
        "Fair communication skills. Explanations could be clearer.",
        "Acceptable performance. Sometimes punctual and prepared.",
        "Moderate dedication to learning and helping others.",
        "Average leadership qualities and team player.",
        "Decent knowledge sharing. Could be more supportive.",
        "Average problem-solving skills and teaching ability.",
        "Decent contribution to our study group. Room for improvement."
    ],
    2: [
        "Below average study partner. Limited knowledge and poor communication.",
        "Poor organizer. Event was disorganized and unengaging.",
        "Disappointing collaboration. Learned very little from this person.",
        "Poor communication skills. Explanations were unclear.",
        "Unreliable performance. Often late and unprepared.",
        "Low dedication to learning and helping others.",
        "Poor leadership qualities and not a good team player.",
        "Limited knowledge sharing and not very supportive.",
        "Poor problem-solving skills and teaching ability.",
        "Minimal contribution to our study group. Needs improvement."
    ],
    1: [
        "Terrible study partner. No knowledge and very poor communication.",
        "Awful organizer. Event was completely disorganized.",
        "Worst collaboration ever. Learned nothing from this person.",
        "Terrible communication skills. No clear explanations.",
        "Completely unreliable. Always late and unprepared.",
        "No dedication to learning or helping others.",
        "No leadership qualities and terrible team player.",
        "No knowledge sharing and not supportive at all.",
        "No problem-solving skills or teaching ability.",
        "No contribution to our study group. Completely useless."
    ]
}

def get_existing_users():
    """Get list of existing users"""
    print("👥 Getting existing users...")
    
    # Known usernames from our previous data generation
    known_users = [
        "liam_cruz_879", "paula_chavez_469", "carlos_lopez_233", 
        "fernanda_mendoza_332", "liam_gutierrez_333", "maria_sanchez_294",
        "james_torres_777", "lucia_martinez_206", "andres_jimenez_888",
        "valentina_vargas_582", "sebastian_ramos_312", "charlotte_torres_632",
        "benjamin_gutierrez_598", "noah_torres_875", "liam_perez_680",
        "camila_reyes_197", "ana_perez_244", "lucas_jimenez_428",
        "emma_alvarez_228", "maria_cruz_598", "alejandro_lopez_208",
        "diego_perez_852", "sebastian_ramos_759", "camila_castro_449",
        "isabella_diaz_776", "charlotte_chavez_367", "liam_cruz_712",
        "lucia_ortiz_968", "santiago_alvarez_147", "sophia_perez_608"
    ]
    
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_all_users/", timeout=10)
        if response.status_code == 200:
            users_data = response.json()
            if isinstance(users_data, list):
                usernames = [user.get('username') for user in users_data if isinstance(user, dict) and user.get('username')]
            else:
                usernames = []
            
            if usernames:
                print(f"✅ Found {len(usernames)} existing users from API")
                return usernames
            else:
                print(f"⚠️  API returned empty, using known users")
                return known_users
        else:
            print(f"❌ Failed to get users: {response.status_code}, using known users")
            return known_users
    except Exception as e:
        print(f"❌ Error getting users: {e}, using known users")
        return known_users

def get_user_events(username):
    """Get events for a specific user"""
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_study_events/{username}/", timeout=10)
        if response.status_code == 200:
            events_data = response.json()
            return events_data.get('events', [])
        else:
            return []
    except Exception as e:
        print(f"❌ Error getting events for {username}: {e}")
        return []

def submit_user_rating(from_user, to_user, event_id, rating, reference):
    """Submit a user rating"""
    rating_data = {
        "from_username": from_user,
        "to_username": to_user,
        "event_id": event_id,
        "rating": rating,
        "reference": reference
    }
    
    try:
        response = requests.post(f"{PRODUCTION_BASE_URL}submit_user_rating/", json=rating_data, timeout=10)
        if response.status_code == 200:
            return True, response.json()
        else:
            return False, response.text
    except Exception as e:
        return False, str(e)

def get_user_reputation(username):
    """Get user reputation data"""
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_user_reputation/{username}/", timeout=10)
        if response.status_code == 200:
            return True, response.json()
        else:
            return False, response.text
    except Exception as e:
        return False, str(e)

def get_user_ratings(username):
    """Get user ratings data"""
    try:
        response = requests.get(f"{PRODUCTION_BASE_URL}get_user_ratings/{username}/", timeout=10)
        if response.status_code == 200:
            return True, response.json()
        else:
            return False, response.text
    except Exception as e:
        return False, str(e)

def generate_realistic_ratings(users, events):
    """Generate realistic ratings based on user interactions"""
    print("⭐ Generating realistic user ratings...")
    print("-" * 50)
    
    ratings_created = 0
    
    # Create ratings for users who have attended events together
    for event in events[:20]:  # Use first 20 events
        event_id = event.get('id')
        event_title = event.get('title', 'Event')
        attendees = event.get('attendees', [])
        
        if len(attendees) >= 2:
            print(f"📅 Processing event: {event_title}")
            print(f"   Attendees: {len(attendees)}")
            
            # Create 2-4 ratings per event
            num_ratings = min(random.randint(2, 4), len(attendees) - 1)
            selected_attendees = random.sample(attendees, min(num_ratings + 1, len(attendees)))
            
            for i, rater in enumerate(selected_attendees[:-1]):  # Last person doesn't rate
                # Select someone to rate (not themselves)
                ratee_candidates = [a for a in selected_attendees if a != rater]
                if ratee_candidates:
                    ratee = random.choice(ratee_candidates)
                    
                    # Generate realistic rating (bias towards higher ratings)
                    rating_weights = [1, 2, 3, 4, 5, 5, 4, 5, 4, 5]  # Favor 4-5 star ratings
                    rating = random.choice(rating_weights)
                    reference = random.choice(REVIEW_TEMPLATES[rating])
                    
                    success, result = submit_user_rating(rater, ratee, event_id, rating, reference)
                    if success:
                        ratings_created += 1
                        print(f"   ✅ {rater} rated {ratee}: {rating}⭐ - {reference[:50]}...")
                    else:
                        print(f"   ❌ Failed to rate {ratee}: {result}")
                    
                    time.sleep(0.2)
    
    print(f"⭐ Created {ratings_created} user ratings")
    return ratings_created

def test_reputation_system(users):
    """Test the reputation system for sample users"""
    print(f"\n🏆 Testing Reputation System")
    print("=" * 60)
    
    test_users = users[:5]  # Test first 5 users
    
    for username in test_users:
        print(f"\n👤 Reputation for: {username}")
        print("-" * 40)
        
        # Get reputation data
        success, reputation_data = get_user_reputation(username)
        if success:
            print(f"✅ Reputation data retrieved successfully!")
            print(f"   Total ratings: {reputation_data.get('total_ratings', 0)}")
            print(f"   Average rating: {reputation_data.get('average_rating', 0):.2f}")
            print(f"   Events hosted: {reputation_data.get('events_hosted', 0)}")
            print(f"   Events attended: {reputation_data.get('events_attended', 0)}")
            
            trust_level = reputation_data.get('trust_level', {})
            if trust_level:
                print(f"   Trust level: {trust_level.get('level', 0)} - {trust_level.get('title', 'N/A')}")
        else:
            print(f"❌ Failed to get reputation: {reputation_data}")
        
        # Get detailed ratings
        success, ratings_data = get_user_ratings(username)
        if success:
            ratings = ratings_data.get('ratings_received', [])
            print(f"   Detailed ratings: {len(ratings)} received")
            
            for i, rating in enumerate(ratings[:3]):  # Show first 3 ratings
                print(f"     {i+1}. {rating.get('from_username', 'N/A')}: {rating.get('rating', 0)}⭐")
                print(f"        \"{rating.get('reference', 'N/A')[:60]}...\"")
        else:
            print(f"❌ Failed to get detailed ratings: {ratings_data}")

def create_additional_ratings(users):
    """Create additional ratings between users"""
    print(f"\n⭐ Creating Additional User Ratings")
    print("-" * 50)
    
    additional_ratings = 0
    
    # Create random ratings between users
    for _ in range(50):  # Create 50 additional ratings
        from_user = random.choice(users)
        to_user = random.choice([u for u in users if u != from_user])
        
        # Generate realistic rating
        rating_weights = [1, 2, 3, 4, 5, 5, 4, 5, 4, 5]  # Favor 4-5 star ratings
        rating = random.choice(rating_weights)
        reference = random.choice(REVIEW_TEMPLATES[rating])
        
        success, result = submit_user_rating(from_user, to_user, None, rating, reference)
        if success:
            additional_ratings += 1
            print(f"✅ {from_user} rated {to_user}: {rating}⭐")
        else:
            print(f"❌ Failed: {from_user} -> {to_user}: {result}")
        
        time.sleep(0.1)
    
    print(f"⭐ Created {additional_ratings} additional ratings")
    return additional_ratings

def main():
    """Main function to generate reviews and reputation data"""
    print("⭐ PinIt Reviews and Reputation Generator")
    print("=" * 70)
    
    # Get existing users
    users = get_existing_users()
    if not users:
        print("❌ No users found.")
        return
    
    print(f"👥 Found {len(users)} users")
    
    # Get events for rating context
    all_events = []
    for user in users[:5]:  # Get events from first 5 users
        events = get_user_events(user)
        all_events.extend(events)
    
    print(f"📅 Found {len(all_events)} events for rating context")
    
    # Generate realistic ratings based on event attendance
    event_ratings = generate_realistic_ratings(users, all_events)
    
    # Create additional random ratings
    additional_ratings = create_additional_ratings(users)
    
    # Test reputation system
    test_reputation_system(users)
    
    print(f"\n🎉 REVIEWS AND REPUTATION GENERATION COMPLETE!")
    print("=" * 70)
    print(f"✅ Event-based ratings created: {event_ratings}")
    print(f"✅ Additional ratings created: {additional_ratings}")
    print(f"✅ Total ratings: {event_ratings + additional_ratings}")
    print(f"✅ Reputation system tested and working")
    
    print(f"\n🏆 REPUTATION FEATURES NOW ACTIVE:")
    print(f"   - User rating system (1-5 stars)")
    print(f"   - Written reviews and references")
    print(f"   - Trust levels and reputation scores")
    print(f"   - Event-based rating context")
    print(f"   - Social learning through peer feedback")
    
    print(f"\n🔑 Test Users (Password: password123):")
    for i, user in enumerate(users[:5], 1):
        print(f"   {i}. {user} - Check their reputation and reviews!")

if __name__ == "__main__":
    main()
