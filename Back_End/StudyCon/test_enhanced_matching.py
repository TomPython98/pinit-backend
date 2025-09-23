import os
import sys
import django
import json
import requests

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/Full_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import StudyEvent, User, UserProfile, EventInvitation
from django.utils import timezone
from datetime import timedelta

def test_enhanced_automatching():
    """Test the enhanced automatching algorithm"""
    print("🧪 Testing Enhanced Auto-Matching Algorithm")
    print("=" * 50)
    
    # Get all events
    events = StudyEvent.objects.all()
    print(f"Found {events.count()} events in database")
    
    # Get all users
    users = User.objects.all()
    print(f"Found {users.count()} users in database")
    
    # Test with a specific event
    test_event = events.first()
    if not test_event:
        print("❌ No events found in database")
        return
    
    print(f"\n🎯 Testing with event: {test_event.title}")
    print(f"   Event ID: {test_event.id}")
    print(f"   Host: {test_event.host.username}")
    print(f"   Type: {test_event.event_type}")
    print(f"   Interests: {test_event.get_interest_tags()}")
    
    # Test the enhanced matching via API
    url = "http://127.0.0.1:8000/api/advanced_auto_match/"
    
    payload = {
        "event_id": str(test_event.id),
        "max_invites": 10,
        "min_score": 30.0,
        "potentials_only": True
    }
    
    try:
        print(f"\n📡 Testing API endpoint: {url}")
        response = requests.post(url, json=payload, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print("✅ API call successful!")
            
            if data.get("success"):
                matches = data.get("potential_matches", [])
                print(f"\n🎉 Found {len(matches)} potential matches:")
                
                for i, match in enumerate(matches[:5], 1):  # Show first 5 matches
                    username = match.get("username", "Unknown")
                    score = match.get("match_score", 0)
                    interests = match.get("matching_interests", [])
                    ratio = match.get("interest_ratio", 0)
                    breakdown = match.get("score_breakdown", {})
                    
                    print(f"\n{i}. {username} (Score: {score})")
                    print(f"   Interest Match: {int(ratio * 100)}%")
                    print(f"   Common Interests: {', '.join(interests)}")
                    
                    if breakdown:
                        print("   Score Breakdown:")
                        for factor, factor_score in breakdown.items():
                            if factor_score and factor_score > 0:
                                print(f"     • {factor}: {factor_score}")
                
                # Show matching factors explanation
                print(f"\n🎯 Enhanced matching considers these factors:")
                print("   • Interest Match (25 points per match)")
                print("   • Interest Ratio (30 points max)")
                print("   • Content Similarity (20 points max)")
                print("   • Location Proximity (15 points max)")
                print("   • Social Connections (20 points max)")
                print("   • Academic Similarity (25 points max)")
                print("   • Skill Relevance (20 points max)")
                print("   • Bio Similarity (15 points max)")
                print("   • Reputation Boost (15 points max)")
                print("   • Event Type Preference (10 points max)")
                print("   • Time Compatibility (10 points max)")
                print("   • Activity Level (10 points max)")
                print(f"   • Total possible score: 225 points")
                print(f"   • Minimum threshold: 30 points")
                
            else:
                print(f"❌ API returned success=false: {data.get('message', 'Unknown error')}")
        else:
            print(f"❌ API call failed with status {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Error testing API: {str(e)}")
    
    # Test user profile data availability
    print(f"\n📊 User Profile Data Analysis:")
    print("=" * 30)
    
    users_with_data = 0
    users_with_interests = 0
    users_with_skills = 0
    users_with_bio = 0
    users_with_academic = 0
    
    for user in users:
        try:
            profile = user.userprofile
            
            if profile.get_interests():
                users_with_interests += 1
            
            if profile.get_skills():
                users_with_skills += 1
            
            if profile.bio:
                users_with_bio += 1
            
            if profile.university or profile.degree or profile.year:
                users_with_academic += 1
            
            users_with_data += 1
            
        except Exception as e:
            print(f"Error processing user {user.username}: {str(e)}")
    
    print(f"Users with profile data: {users_with_data}/{users.count()}")
    print(f"Users with interests: {users_with_interests}/{users.count()}")
    print(f"Users with skills: {users_with_skills}/{users.count()}")
    print(f"Users with bio: {users_with_bio}/{users.count()}")
    print(f"Users with academic info: {users_with_academic}/{users.count()}")
    
    # Test reputation data
    print(f"\n🏆 Reputation Data Analysis:")
    print("=" * 30)
    
    users_with_reputation = 0
    users_with_trust_level = 0
    
    for user in users:
        try:
            if hasattr(user, 'reputation_stats') and user.reputation_stats:
                users_with_reputation += 1
                if user.reputation_stats.trust_level:
                    users_with_trust_level += 1
        except:
            pass
    
    print(f"Users with reputation stats: {users_with_reputation}/{users.count()}")
    print(f"Users with trust levels: {users_with_trust_level}/{users.count()}")
    
    print(f"\n✅ Enhanced automatching test completed!")

if __name__ == "__main__":
    test_enhanced_automatching() 