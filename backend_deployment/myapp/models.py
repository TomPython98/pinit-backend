import uuid
import os
from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from django.db.models.signals import post_save
from django.dispatch import receiver
import json
from django.core.validators import MinValueValidator, MaxValueValidator
from django.core.files.storage import default_storage
from PIL import Image
from io import BytesIO

# Skill level choices for user skills
SKILL_LEVEL_CHOICES = [
    ('BEGINNER', 'Beginner'),
    ('INTERMEDIATE', 'Intermediate'),
    ('ADVANCED', 'Advanced'),
    ('EXPERT', 'Expert'),
]

def user_image_upload_path(instance, filename):
    """Generate upload path for user images"""
    return f'users/{instance.user.username}/images/{filename}'

class UserImage(models.Model):
    """Professional model for storing user profile images"""
    IMAGE_TYPES = [
        ('profile', 'Profile Picture'),
        ('gallery', 'Gallery Image'),
        ('cover', 'Cover Photo'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to=user_image_upload_path, max_length=500)
    image_type = models.CharField(max_length=20, choices=IMAGE_TYPES, default='gallery')
    is_primary = models.BooleanField(default=False, help_text="Primary profile picture")
    caption = models.CharField(max_length=255, blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-is_primary', '-uploaded_at']
        # Removed broken unique_together constraint - now handled by migration constraint
    
    def save(self, *args, **kwargs):
        # Ensure only one primary image per user
        if self.is_primary:
            UserImage.objects.filter(user=self.user, is_primary=True).update(is_primary=False)
        
        super().save(*args, **kwargs)
        
        # Optimize image after saving
        self.optimize_image()
    
    def optimize_image(self):
        """Optimize image size and quality"""
        try:
            if self.image:
                # Open the image
                img = Image.open(self.image.path)
                
                # Convert to RGB if necessary
                if img.mode in ('RGBA', 'LA', 'P'):
                    img = img.convert('RGB')
                
                # Resize if too large (max 1920x1920)
                max_size = (1920, 1920)
                if img.size[0] > max_size[0] or img.size[1] > max_size[1]:
                    img.thumbnail(max_size, Image.Resampling.LANCZOS)
                
                # Save optimized version
                img.save(self.image.path, 'JPEG', quality=85, optimize=True)
        except Exception as e:
            print(f"Error optimizing image {self.id}: {e}")
    
    def delete(self, *args, **kwargs):
        # Delete the file from storage
        if self.image:
            try:
                if default_storage.exists(self.image.name):
                    default_storage.delete(self.image.name)
            except Exception as e:
                print(f"Error deleting image file {self.image.name}: {e}")
        
        super().delete(*args, **kwargs)
    
    def get_image_url(self):
        """Get the full URL for the image"""
        if self.image:
            return self.image.url
        return None
    
    def __str__(self):
        return f"{self.user.username} - {self.get_image_type_display()}"

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    is_certified = models.BooleanField(default=False, help_text="True if this user can create public events.")
    friends = models.ManyToManyField("self", blank=True, symmetrical=True)
    
    # Basic profile information for profile completion
    full_name = models.CharField(max_length=255, blank=True, help_text="User's full name")
    university = models.CharField(max_length=255, blank=True, help_text="User's university")
    degree = models.CharField(max_length=255, blank=True, help_text="User's degree program")
    year = models.CharField(max_length=50, blank=True, help_text="User's academic year")
    bio = models.TextField(blank=True, help_text="User's bio/description")
    
    # Legacy field - will be deprecated
    profile_picture = models.TextField(blank=True, help_text="Base64 encoded profile picture (deprecated)")
    
    # New fields for smart matching
    interests = models.JSONField(default=list, blank=True, help_text="JSON array of user interests")
    skills = models.JSONField(default=dict, blank=True, help_text="JSON object mapping skill names to skill levels")
    auto_invite_enabled = models.BooleanField(default=True, help_text="Whether user wants to receive automatic invites")
    preferred_radius = models.FloatField(default=10.0, help_text="Preferred radius in km for event matching")
    
    def get_interests(self):
        """Get the list of interests"""
        if isinstance(self.interests, list):
            return self.interests
        return []
    
    def set_interests(self, interests_list):
        """Set the list of interests"""
        self.interests = interests_list
    
    def get_skills(self):
        """Get the skills dictionary"""
        if isinstance(self.skills, dict):
            return self.skills
        return {}
    
    def set_skills(self, skills_dict):
        """Set the skills dictionary"""
        self.skills = skills_dict
    
    def get_primary_image(self):
        """Get the user's primary profile image"""
        try:
            return self.user.images.filter(is_primary=True).first()
        except:
            return None
    
    def get_profile_images(self):
        """Get all profile images for the user"""
        try:
            return self.user.images.filter(image_type='profile').order_by('-is_primary', '-uploaded_at')
        except:
            return UserImage.objects.none()
    
    def get_gallery_images(self):
        """Get all gallery images for the user"""
        try:
            return self.user.images.filter(image_type='gallery').order_by('-uploaded_at')
        except:
            return UserImage.objects.none()
    
    def get_all_images(self):
        """Get all images for the user"""
        try:
            return self.user.images.all().order_by('-is_primary', '-uploaded_at')
        except:
            return UserImage.objects.none()
    
    def get_profile_picture_url(self):
        """Get the URL of the primary profile picture"""
        primary_image = self.get_primary_image()
        if primary_image:
            return primary_image.get_image_url()
        
        # Fallback to legacy base64 field
        if self.profile_picture:
            return f"data:image/jpeg;base64,{self.profile_picture}"
        
        return None
    
    def get_matching_score(self, event):
        """
        Calculate a matching score between this user and an event
        based on interests and location
        """
        score = 0
        
        # Interest matching
        user_interests = self.get_interests()
        event_interests = event.interest_tags if hasattr(event, 'interest_tags') else []
        
        # Calculate interest overlap
        if user_interests and event_interests:
            matching_interests = set(user_interests).intersection(set(event_interests))
            score += len(matching_interests) * 10  # 10 points per matching interest
        
        # Return the final score
        return score
    
    def __str__(self):
        return self.user.username

# Auto-create a UserProfile when a new User is created
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.userprofile.save()


# Add this new model for UserInterest for more structured storage
class UserInterest(models.Model):
    user_profile = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='interest_items')
    interest = models.CharField(max_length=100)
    
    class Meta:
        unique_together = ('user_profile', 'interest')
    
    def __str__(self):
        return f"{self.user_profile.user.username} - {self.interest}"


# Add this new model for UserSkill for more structured storage
class UserSkill(models.Model):
    user_profile = models.ForeignKey(UserProfile, on_delete=models.CASCADE, related_name='skill_items')
    skill = models.CharField(max_length=100)
    level = models.CharField(max_length=20, choices=SKILL_LEVEL_CHOICES, default='BEGINNER')
    
    class Meta:
        unique_together = ('user_profile', 'skill')
    
    def __str__(self):
        return f"{self.user_profile.user.username} - {self.skill} ({self.level})"

# Friend Request Model
class FriendRequest(models.Model):
    from_user = models.ForeignKey(User, related_name="sent_requests", on_delete=models.CASCADE)
    to_user = models.ForeignKey(User, related_name="received_requests", on_delete=models.CASCADE)
    timestamp = models.DateTimeField(auto_now_add=True)

    def accept(self):
        """Accepts the friend request and establishes mutual friendship."""
        self.to_user.userprofile.friends.add(self.from_user.userprofile)
        self.from_user.userprofile.friends.add(self.to_user.userprofile)
        self.delete()  # Delete the friend request after acceptance

    def __str__(self):
        return f"{self.from_user.username} → {self.to_user.username}"


# Chat Message Model
class ChatMessage(models.Model):
    sender = models.ForeignKey(User, related_name="sent_messages", on_delete=models.CASCADE)
    receiver = models.ForeignKey(User, related_name="received_messages", on_delete=models.CASCADE)
    message = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.sender} → {self.receiver}: {self.message}"


# New model for tracking auto-matched invitations
class EventInvitation(models.Model):
    event = models.ForeignKey('StudyEvent', on_delete=models.CASCADE, related_name='invitation_records')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_invitations')
    is_auto_matched = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('event', 'user')
        
    def __str__(self):
        return f"{self.user.username} invited to {self.event.title} (auto-matched: {self.is_auto_matched})"


# Study Event Model - KEEP ONLY THIS ONE VERSION
class StudyEvent(models.Model):
    EVENT_TYPE_CHOICES = [
        ('study', 'Study'),
        ('party', 'Party'),
        ('business', 'Business'),
        ('other', 'Other'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255, db_index=True)
    description = models.TextField(blank=True, null=True)
    host = models.ForeignKey(User, on_delete=models.CASCADE, db_index=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    time = models.DateTimeField(db_index=True)
    end_time = models.DateTimeField(default=timezone.now, db_index=True)
    is_public = models.BooleanField(default=True, db_index=True)
    
    # Keep the original field as is (without through parameter)
    invited_friends = models.ManyToManyField(User, related_name='invited_study_events', blank=True)
    
    attendees = models.ManyToManyField(User, related_name='attending_study_events', blank=True)
    event_type = models.CharField(max_length=20, choices=EVENT_TYPE_CHOICES, default='other', db_index=True)

    # New fields for auto-matching
    max_participants = models.IntegerField(default=10)
    auto_matching_enabled = models.BooleanField(default=False, db_index=True)
    interest_tags = models.JSONField(default=list, blank=True, help_text="JSON array of interest tags for matching")

    @property
    def coordinate_lat(self):
        return self.latitude

    @property
    def coordinate_lon(self):
        return self.longitude

    def get_interest_tags(self):
        """Get the list of interest tags"""
        if isinstance(self.interest_tags, list):
            return self.interest_tags
        return []
    
    def set_interest_tags(self, tags_list):
        """Set the list of interest tags"""
        self.interest_tags = tags_list
    
    def get_all_invitees(self):
        """Get all invited users including direct and auto-matched"""
        direct_invites = set(self.invited_friends.all())
        auto_matched = set(inv.user for inv in self.invitation_records.all())
        return direct_invites.union(auto_matched)
    
    def get_auto_matched_invitees(self):
        """Get only auto-matched users"""
        return [inv.user for inv in self.invitation_records.filter(is_auto_matched=True)]
    
    def get_direct_invitees(self):
        """Get only directly invited users (not auto-matched)"""
        auto_matched_ids = set(inv.user.id for inv in self.invitation_records.filter(is_auto_matched=True))
        return self.invited_friends.exclude(id__in=auto_matched_ids)
    
    def invite_user(self, user, is_auto_matched=False):
        """Invite a user to the event"""
        # Add to direct invites list
        self.invited_friends.add(user)
        
        # Create or update invitation record
        EventInvitation.objects.update_or_create(
            event=self,
            user=user,
            defaults={'is_auto_matched': is_auto_matched}
        )

    def __str__(self):
        return f"StudyEvent: {self.title} from {self.time} to {self.end_time} (ID: {self.id})"

    class Meta:
        # Add composite indexes for common query patterns
        indexes = [
            models.Index(fields=['is_public', 'end_time']),
            models.Index(fields=['host', 'is_public']),
            models.Index(fields=['auto_matching_enabled', 'is_public']),
            models.Index(fields=['event_type', 'is_public']),
        ]


# Event interaction models
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
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE, related_name='declined_by')
    declined_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'event')
        verbose_name = 'Declined Invitation'
        verbose_name_plural = 'Declined Invitations'
    
    def __str__(self):
        return f"{self.user.username} declined {self.event.title}"

class Device(models.Model):
    """Model to store device tokens for push notifications"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='devices')
    token = models.CharField(max_length=255, unique=True)
    device_type = models.CharField(max_length=10, choices=[('ios', 'iOS'), ('android', 'Android')])
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    
    class Meta:
        unique_together = ('user', 'token')
        
    def __str__(self):
        return f"{self.user.username} - {self.device_type} device"

# User reputation models for implementing Bandura's social learning theory
class UserRating(models.Model):
    """
    Model to store user ratings and references based on Bandura's social learning theory.
    This enables users to learn from observing others and reinforces positive behavior.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_given')
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_received')
    
    # Optional link to the event for which this rating was given
    event = models.ForeignKey(
        StudyEvent, 
        on_delete=models.SET_NULL, 
        related_name='event_ratings',
        null=True,
        blank=True
    )
    
    # Rating score (1-5)
    rating = models.IntegerField(
        validators=[
            MinValueValidator(1, message="Rating must be at least 1"),
            MaxValueValidator(5, message="Rating cannot exceed 5")
        ]
    )
    
    # Optional reference/comment
    reference = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        # Ensure a user can only rate another user once for a specific event
        unique_together = ('from_user', 'to_user', 'event')
        ordering = ['-created_at']
    
    def save(self, *args, **kwargs):
        # Ensure rating is between 1-5
        if self.rating < 1:
            self.rating = 1
        elif self.rating > 5:
            self.rating = 5
        
        # Save the rating
        super().save(*args, **kwargs)
        
        # Update user's reputation stats
        self.update_user_stats()
        
        # Send notification to rated user
        self.send_rating_notification()
    
    def update_user_stats(self):
        """Update the reputation stats for the rated user"""
        try:
            # Get all ratings for this user
            ratings = UserRating.objects.filter(to_user=self.to_user)
            
            # Calculate stats
            count = ratings.count()
            avg_rating = ratings.aggregate(models.Avg('rating'))['rating__avg'] or 0
            
            # Update or create reputation stats
            stats, created = UserReputationStats.objects.update_or_create(
                user=self.to_user,
                defaults={
                    'total_ratings': count,
                    'average_rating': avg_rating,
                }
            )
            
            # Check if trust level has increased
            stats.update_trust_level()
        except Exception as e:
            print(f"Error updating user stats: {e}")
    
    def send_rating_notification(self):
        """Send a notification to the user about the new rating"""
        try:
            from myapp.views import send_push_notification
            
            # Send push notification
            send_push_notification(
                user_id=self.to_user.id,
                notification_type="new_rating",
                from_user=self.from_user.username,
                rating=self.rating
            )
        except Exception as e:
            print(f"Error sending rating notification: {e}")
    
    def __str__(self):
        event_info = f" for {self.event.title}" if self.event else ""
        return f"{self.from_user.username} rated {self.to_user.username}{event_info}: {self.rating}/5"

class UserTrustLevel(models.Model):
    """
    Model to define trust levels based on Bandura's social learning theory.
    Each level represents increasing social recognition and reinforcement.
    """
    level = models.IntegerField(unique=True)
    title = models.CharField(max_length=50)
    required_ratings = models.IntegerField(help_text="Minimum number of ratings needed")
    min_average_rating = models.FloatField(help_text="Minimum average rating needed")
    
    class Meta:
        ordering = ['level']
    
    def __str__(self):
        return f"{self.level} - {self.title}"

class UserReputationStats(models.Model):
    """
    Model to store reputation statistics for users.
    This implements the reinforcement component of Bandura's theory.
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='reputation_stats')
    total_ratings = models.IntegerField(default=0)
    average_rating = models.FloatField(default=0.0)
    trust_level = models.ForeignKey(
        UserTrustLevel, 
        on_delete=models.SET_NULL, 
        null=True,
        related_name='users_at_level'
    )
    events_hosted = models.IntegerField(default=0)
    events_attended = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)
    
    def update_trust_level(self):
        """Update the user's trust level based on their stats"""
        try:
            # Find the highest level the user qualifies for
            new_level = UserTrustLevel.objects.filter(
                required_ratings__lte=self.total_ratings,
                min_average_rating__lte=self.average_rating
            ).order_by('-level').first()
            
            if new_level and (not self.trust_level or self.trust_level.level < new_level.level):
                # User has reached a new trust level!
                old_level = self.trust_level
                self.trust_level = new_level
                self.save()
                
                # Send notification about the new level
                self.send_level_up_notification(old_level, new_level)
        except Exception as e:
            print(f"Error updating trust level: {e}")
    
    def update_event_counts(self):
        """Update the counts of events hosted and attended"""
        try:
            # Count hosted events
            self.events_hosted = StudyEvent.objects.filter(host=self.user).count()
            
            # Count attended events
            self.events_attended = self.user.attending_study_events.count()
            
            self.save()
        except Exception as e:
            print(f"Error updating event counts: {e}")
    
    def send_level_up_notification(self, old_level, new_level):
        """Send a notification about reaching a new trust level"""
        try:
            from myapp.views import send_push_notification
            
            # Send push notification
            send_push_notification(
                user_id=self.user.id,
                notification_type="trust_level_change",
                trust_level=new_level.level,
                level_title=new_level.title
            )
        except Exception as e:
            print(f"Error sending level up notification: {e}")
    
    def __str__(self):
        level_info = f" - {self.trust_level.title}" if self.trust_level else ""
        return f"{self.user.username}{level_info} ({self.average_rating:.1f}/5.0 from {self.total_ratings} ratings)"

# Initialize default trust levels
from django.db.models.signals import post_migrate
from django.dispatch import receiver

@receiver(post_migrate)
def create_default_trust_levels(sender, **kwargs):
    if sender.name == 'myapp':
        # Only create if no levels exist yet
        if UserTrustLevel.objects.count() == 0:
            print("Creating default user trust levels...")
            levels = [
                {"level": 1, "title": "Newcomer", "required_ratings": 0, "min_average_rating": 0.0},
                {"level": 2, "title": "Participant", "required_ratings": 3, "min_average_rating": 3.0},
                {"level": 3, "title": "Trusted Member", "required_ratings": 10, "min_average_rating": 3.5},
                {"level": 4, "title": "Event Expert", "required_ratings": 20, "min_average_rating": 4.0},
                {"level": 5, "title": "Community Leader", "required_ratings": 50, "min_average_rating": 4.5}
            ]
            
            for level_data in levels:
                UserTrustLevel.objects.create(**level_data)
            
            print("Default trust levels created.")