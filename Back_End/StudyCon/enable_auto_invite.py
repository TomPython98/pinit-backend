import os
import sys
import django

# Set up Django environment
sys.path.append('/Users/tombesinger/Desktop/Full_App/Back_End/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import UserProfile

def enable_auto_invite_for_all():
    """Enable auto-invite for all users"""
    print("🔧 Enabling auto-invite for all users...")
    
    # Get all user profiles
    profiles = UserProfile.objects.all()
    enabled_count = 0
    
    for profile in profiles:
        if not profile.auto_invite_enabled:
            profile.auto_invite_enabled = True
            profile.save()
            enabled_count += 1
            print(f"✓ Enabled auto-invite for {profile.user.username}")
    
    print(f"✅ Enabled auto-invite for {enabled_count} users")
    
    # Verify
    total_profiles = UserProfile.objects.count()
    enabled_profiles = UserProfile.objects.filter(auto_invite_enabled=True).count()
    print(f"Total profiles: {total_profiles}")
    print(f"Profiles with auto-invite enabled: {enabled_profiles}")

if __name__ == "__main__":
    enable_auto_invite_for_all() 