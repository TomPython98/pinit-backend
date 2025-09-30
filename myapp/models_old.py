import uuid
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.db.models.signals import post_save
from django.dispatch import receiver


# ✅ User Profile Model
class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    is_certified = models.BooleanField(default=False, help_text="True if this user can create public events.")
    friends = models.ManyToManyField("self", blank=True, symmetrical=True)  # ✅ Ensure mutual friendship

    def __str__(self):
        return self.user.username


# ✅ Auto-create a UserProfile when a new User is created
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.userprofile.save()


# ✅ Friend Request Model
class FriendRequest(models.Model):
    from_user = models.ForeignKey(User, related_name="sent_requests", on_delete=models.CASCADE)
    to_user = models.ForeignKey(User, related_name="received_requests", on_delete=models.CASCADE)
    timestamp = models.DateTimeField(auto_now_add=True)

    def accept(self):
        """Accepts the friend request and establishes mutual friendship."""
        self.to_user.userprofile.friends.add(self.from_user.userprofile)
        self.from_user.userprofile.friends.add(self.to_user.userprofile)
        self.delete()  # ✅ Delete the friend request after acceptance

    def __str__(self):
        return f"{self.from_user.username} → {self.to_user.username}"


# ✅ Chat Message Model
class ChatMessage(models.Model):
    sender = models.ForeignKey(User, related_name="sent_messages", on_delete=models.CASCADE)
    receiver = models.ForeignKey(User, related_name="received_messages", on_delete=models.CASCADE)
    message = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.sender} → {self.receiver}: {self.message}"


# ✅ Study Event Model
class StudyEvent(models.Model):
    EVENT_TYPE_CHOICES = [
        ('study', 'Study'),
        ('party', 'Party'),
        ('business', 'Business'),
        ('other', 'Other'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)  # ✅ Added Description Field
    host = models.ForeignKey(User, on_delete=models.CASCADE)
    latitude = models.FloatField()
    longitude = models.FloatField()
    time = models.DateTimeField()  # Start time of the event
    end_time = models.DateTimeField(default=timezone.now)  # End time of the event
    is_public = models.BooleanField(default=True)
    invited_friends = models.ManyToManyField(User, related_name='invited_study_events', blank=True)
    attendees = models.ManyToManyField(User, related_name='attending_study_events', blank=True)
    event_type = models.CharField(max_length=20, choices=EVENT_TYPE_CHOICES, default='other')

    @property
    def coordinate_lat(self):
        return self.latitude

    @property
    def coordinate_lon(self):
        return self.longitude

    def __str__(self):
        return f"StudyEvent: {self.title} from {self.time} to {self.end_time} (ID: {self.id})"


from django.db import models
from django.contrib.auth.models import User
from .models import StudyEvent  # Assuming this is in the same app

# Add these models to your models.py file

class EventComment(models.Model):
    """
    Model to store comments/posts on study events
    """
    event = models.ForeignKey(
        StudyEvent, 
        on_delete=models.CASCADE, 
        related_name='comments'
    )
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='event_comments'
    )
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    parent = models.ForeignKey(
        'self', 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True, 
        related_name='replies'
    )

    def __str__(self):
        return f"Comment by {self.user.username} on {self.event.title}"

class EventLike(models.Model):
    """
    Model to track likes on study events and comments
    """
    event = models.ForeignKey(
        StudyEvent, 
        on_delete=models.CASCADE, 
        related_name='likes'
    )
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='event_likes'
    )
    # Optional link to a comment - if null, the like is for the event itself
    comment = models.ForeignKey(
        EventComment,
        on_delete=models.CASCADE,
        related_name='likes',
        null=True,
        blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Prevent multiple likes from same user on same object
        unique_together = ('event', 'user', 'comment')

    def __str__(self):
        if self.comment:
            return f"Like by {self.user.username} on comment in {self.event.title}"
        return f"Like by {self.user.username} on {self.event.title}"

class EventShare(models.Model):
    """
    Model to track event shares
    """
    event = models.ForeignKey(
        StudyEvent, 
        on_delete=models.CASCADE, 
        related_name='shares'
    )
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='event_shares'
    )
    shared_platform = models.CharField(
        max_length=50, 
        choices=[
            ('whatsapp', 'WhatsApp'),
            ('facebook', 'Facebook'),
            ('twitter', 'Twitter'),
            ('instagram', 'Instagram'),
            ('other', 'Other Platform')
        ],
        default='other'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Share by {self.user.username} on {self.shared_platform}"

class EventImage(models.Model):
    """
    Model to store images associated with comments/posts
    """
    comment = models.ForeignKey(
        EventComment,
        on_delete=models.CASCADE,
        related_name='images'
    )
    image_url = models.URLField()
    upload_date = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Image for comment {self.comment.id} in {self.comment.event.title}"

# Add this new model to track declined invitations
class DeclinedInvitation(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='declined_invitations')
    event = models.ForeignKey('StudyEvent', on_delete=models.CASCADE, related_name='declined_by')
    declined_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'event')
        verbose_name = 'Declined Invitation'
        verbose_name_plural = 'Declined Invitations'
    
    def __str__(self):
        return f"{self.user.username} declined {self.event.title}"