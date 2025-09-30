#!/usr/bin/env python
import os, sys, django
sys.path.insert(0, '/Users/tombesinger/Desktop/App/StudyCon/StudyCon')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()
from django.contrib.auth.models import User
from myapp.models import UserProfile, StudyEvent, EventInvitation, EventComment, EventLike, EventShare, EventImage
from django.db import transaction
print("Fixing database...")
with transaction.atomic():
    print("Deleting comments, likes, and shares...")
    EventComment.objects.all().delete()
    EventLike.objects.all().delete()
    EventShare.objects.all().delete()
    EventImage.objects.all().delete()

    print("Deleting invitations and events...")
    EventInvitation.objects.all().delete()
    StudyEvent.objects.all().delete()

    print("Deleting user profiles...")
    UserProfile.objects.all().delete()

    print("Deleting users (except superusers)...")
    User.objects.filter(is_superuser=False).delete()

print("Database fixed! Now you can run the data generator.")
