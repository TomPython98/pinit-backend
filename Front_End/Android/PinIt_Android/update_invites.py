import os
import sys
import django

print("Script starting...")
sys.stdout.flush()  # Force output to be shown

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

print("Django setup complete")
sys.stdout.flush()

from django.contrib.auth.models import User
from myapp.models import EventInvitation

# Get current count
auto_matched_before = EventInvitation.objects.filter(is_auto_matched=True).count()
total_before = EventInvitation.objects.count()
print(f"Before: {auto_matched_before} auto-matched out of {total_before} total invitations")
sys.stdout.flush()

# Update all invitations to be auto-matched
updated = EventInvitation.objects.all().update(is_auto_matched=True)
print(f"Updated {updated} invitations")
sys.stdout.flush()

# Verify after the update
auto_matched_after = EventInvitation.objects.filter(is_auto_matched=True).count()
print(f"After: {auto_matched_after} auto-matched invitations")
sys.stdout.flush()

print("Script complete!")
sys.stdout.flush() 