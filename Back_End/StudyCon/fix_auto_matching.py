import os
import sys
import django

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/Full_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import User, EventInvitation, StudyEvent

def fix_auto_matching():
    """Fix auto-matching by adding users to invited_friends field"""
    print("🔧 Fixing auto-matching by adding users to invited_friends field...")
    
    # Get all auto-matched invitations
    auto_invitations = EventInvitation.objects.filter(is_auto_matched=True)
    print(f"Found {auto_invitations.count()} auto-matched invitations")
    
    fixed_count = 0
    for invitation in auto_invitations:
        event = invitation.event
        user = invitation.user
        
        # Check if user is already in invited_friends
        if not event.invited_friends.filter(username=user.username).exists():
            # Add user to invited_friends
            event.invited_friends.add(user)
            fixed_count += 1
            print(f"✓ Added {user.username} to invited_friends for event '{event.title}'")
    
    print(f"✅ Fixed {fixed_count} auto-matched invitations")
    
    # Verify the fix
    print("\n🔍 Verifying the fix...")
    test_user = User.objects.get(username="Anna_Hoffmann_501")
    auto_invitations = EventInvitation.objects.filter(user=test_user, is_auto_matched=True)
    
    for inv in auto_invitations[:3]:
        event = inv.event
        is_in_invited_friends = event.invited_friends.filter(username=test_user.username).exists()
        print(f"Event: {event.title} - User in invited_friends: {'✓' if is_in_invited_friends else '✗'}")

if __name__ == "__main__":
    fix_auto_matching() 