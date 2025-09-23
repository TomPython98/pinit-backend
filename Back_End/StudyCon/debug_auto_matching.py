import os
import sys
import django

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/Full_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import User, EventInvitation, StudyEvent

def debug_user_events(username):
    """Debug why a user is not seeing auto-matched events"""
    try:
        user = User.objects.get(username=username)
        print(f"=== Debug for user: {username} ===")
        
        # Check auto-matched invitations
        auto_invitations = EventInvitation.objects.filter(user=user, is_auto_matched=True)
        print(f"Auto-matched invitations: {auto_invitations.count()}")
        
        # Check if user is in invited_friends for auto-matched events
        for inv in auto_invitations[:3]:
            event = inv.event
            is_in_invited_friends = event.invited_friends.filter(username=username).exists()
            print(f"Event: {event.title}")
            print(f"  - Auto-matched invitation exists: ✓")
            print(f"  - User in invited_friends: {'✓' if is_in_invited_friends else '✗'}")
            print(f"  - Event is_public: {event.is_public}")
            print(f"  - Event auto_matching_enabled: {event.auto_matching_enabled}")
            print(f"  - Event host: {event.host.username}")
            print(f"  - User is host: {event.host.username == username}")
            print()
        
        # Check user's own events
        own_events = StudyEvent.objects.filter(host=user)
        print(f"User's own events: {own_events.count()}")
        
        # Check if user has auto-invite enabled
        print(f"Auto-invite enabled: {user.userprofile.auto_invite_enabled}")
        
        # Check user's interests
        user_interests = user.userprofile.get_interests()
        print(f"User interests: {user_interests}")
        
        # Check total events in system
        total_events = StudyEvent.objects.count()
        auto_matched_events = StudyEvent.objects.filter(auto_matching_enabled=True).count()
        print(f"Total events in system: {total_events}")
        print(f"Auto-matched events in system: {auto_matched_events}")
        
    except User.DoesNotExist:
        print(f"User {username} not found")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    debug_user_events("Anna_Hoffmann_501") 