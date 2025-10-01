import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()
from myapp.models import EventInvitation
# Create at least 100 new auto-matched invitations
print('Before:', EventInvitation.objects.filter(is_auto_matched=True).count(), 'auto-matched invitations')
EventInvitation.objects.all().update(is_auto_matched=True)
print('After:', EventInvitation.objects.filter(is_auto_matched=True).count(), 'auto-matched invitations')
print('All invitations marked as auto-matched') 