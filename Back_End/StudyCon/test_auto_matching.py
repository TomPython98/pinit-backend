import os
import sys
import django

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/Full_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import User, EventInvitation, StudyEvent

def test_user_auto_matching(username):
    """Test auto-matching for a specific user"""
    try:
        user = User.objects.get(username=username)
        print(f"User: {user.username}")
        
        # Check auto-matched invitations
        invitations = EventInvitation.objects.filter(user=user, is_auto_matched=True)
        print(f"Auto-matched invitations: {invitations.count()}")
        
        for inv in invitations[:5]:
            print(f"  - Event: {inv.event.title} (ID: {inv.event.id})")
            print(f"    Host: {inv.event.host.username}")
            print(f"    Interests: {inv.event.get_interest_tags()}")
        
        # Check user's interests
        user_interests = user.userprofile.get_interests()
        print(f"User interests: {user_interests}")
        
        # Check if user has auto-invite enabled
        print(f"Auto-invite enabled: {user.userprofile.auto_invite_enabled}")
        
        # Check total events
        total_events = StudyEvent.objects.count()
        auto_matched_events = StudyEvent.objects.filter(auto_matching_enabled=True).count()
        print(f"Total events: {total_events}")
        print(f"Auto-matched events: {auto_matched_events}")
        
    except User.DoesNotExist:
        print(f"User {username} not found")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # Test with a user that has special characters
    test_user_auto_matching("Jan_Schröder_447")
    print("\n" + "="*50 + "\n")
    # Test with a simpler username
    test_user_auto_matching("Anna_Hoffmann_501") 