# StudyCon Database Schema Documentation

## 🗄️ Database Overview

**Database Engine**: SQLite3 (Development) / PostgreSQL (Production Ready)
**ORM**: Django ORM
**Migrations**: Django Migrations System

## 📊 Entity Relationship Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      User       │    │   UserProfile   │    │   StudyEvent    │
│                 │    │                 │    │                 │
│ • id (PK)       │◄──►│ • user (FK)     │    │ • id (PK)       │
│ • username      │    │ • is_certified  │    │ • title         │
│ • password      │    │ • friends (M2M) │    │ • host (FK)     │
│ • email         │    │ • interests     │    │ • time          │
│ • first_name    │    │ • skills        │    │ • latitude      │
│ • last_name     │    │ • university    │    │ • longitude     │
│ • date_joined   │    │ • degree        │    │ • attendees     │
└─────────────────┘    │ • bio           │    │ • invited_friends│
                       │ • auto_invite   │    │ • matched_users │
                       │ • radius        │    │ • event_type    │
                       └─────────────────┘    └─────────────────┘
                                │                       │
                                │                       │
                       ┌─────────────────┐    ┌─────────────────┐
                       │  FriendRequest  │    │ EventInvitation│
                       │                 │    │                 │
                       │ • id (PK)       │    │ • id (PK)      │
                       │ • from_user (FK)│    │ • event (FK)   │
                       │ • to_user (FK)  │    │ • user (FK)    │
                       │ • created_at    │    │ • is_auto_matched│
                       └─────────────────┘    └─────────────────┘
                                                       │
                                              ┌─────────────────┐
                                              │ EventComment    │
                                              │                 │
                                              │ • id (PK)       │
                                              │ • event (FK)    │
                                              │ • user (FK)     │
                                              │ • content       │
                                              │ • created_at    │
                                              └─────────────────┘
```

## 🏗️ Core Models

### 1. User (Django Built-in)
```python
# Django's built-in User model
class User(models.Model):
    id = models.AutoField(primary_key=True)
    username = models.CharField(max_length=150, unique=True)
    password = models.CharField(max_length=128)
    email = models.EmailField(blank=True)
    first_name = models.CharField(max_length=30, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)
    last_login = models.DateTimeField(null=True, blank=True)
```

### 2. UserProfile
```python
class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, primary_key=True)
    is_certified = models.BooleanField(default=False, help_text="True if this user can create public events.")
    friends = models.ManyToManyField("self", blank=True, symmetrical=True)
    
    # Basic profile information
    full_name = models.CharField(max_length=255, blank=True)
    university = models.CharField(max_length=255, blank=True)
    degree = models.CharField(max_length=255, blank=True)
    year = models.CharField(max_length=50, blank=True)
    bio = models.TextField(blank=True)
    
    # Smart matching features
    interests = models.JSONField(default=list, blank=True)
    skills = models.JSONField(default=dict, blank=True)
    auto_invite_enabled = models.BooleanField(default=True)
    preferred_radius = models.FloatField(default=10.0)
    
    def __str__(self):
        return f"{self.user.username}'s Profile"
```

**Key Relationships:**
- One-to-One with User
- Many-to-Many with self (friends)
- JSON fields for flexible data storage

### 3. StudyEvent
```python
class StudyEvent(models.Model):
    EVENT_TYPE_CHOICES = [
        ('study', 'Study'),
        ('party', 'Party'),
        ('business', 'Business'),
        ('cultural', 'Cultural'),
        ('academic', 'Academic'),
        ('networking', 'Networking'),
        ('social', 'Social'),
        ('language_exchange', 'Language Exchange'),
        ('other', 'Other'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    host = models.ForeignKey(User, on_delete=models.CASCADE)
    time = models.DateTimeField()
    end_time = models.DateTimeField()
    latitude = models.FloatField()
    longitude = models.FloatField()
    is_public = models.BooleanField(default=True)
    event_type = models.CharField(max_length=50, choices=EVENT_TYPE_CHOICES)
    
    # Many-to-Many relationships
    attendees = models.ManyToManyField(User, related_name='attended_events', blank=True)
    invited_friends = models.ManyToManyField(User, related_name='invited_events', blank=True)
    matched_users = models.ManyToManyField(User, related_name='matched_events', blank=True)
    
    # Additional fields
    interest_tags = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return self.title
```

**Key Relationships:**
- Foreign Key to User (host)
- Many-to-Many with User (attendees, invited_friends, matched_users)
- UUID primary key for security

## 👥 Social Models

### 4. FriendRequest
```python
class FriendRequest(models.Model):
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_requests')
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_requests')
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['from_user', 'to_user']
    
    def __str__(self):
        return f"{self.from_user.username} -> {self.to_user.username}"
```

### 5. EventInvitation
```python
class EventInvitation(models.Model):
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    is_auto_matched = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['event', 'user']
    
    def __str__(self):
        return f"{self.user.username} invited to {self.event.title}"
```

### 6. DeclinedInvitation
```python
class DeclinedInvitation(models.Model):
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    declined_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['event', 'user']
```

## 💬 Event Interaction Models

### 7. EventComment
```python
class EventComment(models.Model):
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username}: {self.content[:50]}..."
```

### 8. EventLike
```python
class EventLike(models.Model):
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['event', 'user']
    
    def __str__(self):
        return f"{self.user.username} likes {self.event.title}"
```

### 9. EventShare
```python
class EventShare(models.Model):
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    platform = models.CharField(max_length=50)  # whatsapp, telegram, etc.
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username} shared {self.event.title} on {self.platform}"
```

## ⭐ Rating & Reputation Models

### 10. UserRating
```python
class UserRating(models.Model):
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_given')
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='ratings_received')
    event = models.ForeignKey(StudyEvent, on_delete=models.CASCADE, null=True, blank=True)
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    reference = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['from_user', 'to_user', 'event']
    
    def __str__(self):
        return f"{self.from_user.username} rated {self.to_user.username} {self.rating}/5"
```

### 11. UserReputationStats
```python
class UserReputationStats(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    total_ratings = models.IntegerField(default=0)
    average_rating = models.FloatField(default=0.0)
    events_hosted = models.IntegerField(default=0)
    events_attended = models.IntegerField(default=0)
    trust_level = models.CharField(max_length=50, default='Newcomer')
    last_updated = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.username}'s Reputation"
```

### 12. UserTrustLevel
```python
class UserTrustLevel(models.Model):
    level = models.IntegerField(unique=True)
    title = models.CharField(max_length=50)
    required_ratings = models.IntegerField()
    min_average_rating = models.FloatField()
    
    def __str__(self):
        return f"Level {self.level}: {self.title}"
```

## 🔔 Notification Models

### 13. Device (Push Notifications)
```python
class Device(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    device_token = models.CharField(max_length=255)
    platform = models.CharField(max_length=20)  # ios, android
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username}'s {self.platform} device"
```

## 📊 Database Indexes

### Performance Optimizations
```python
# In models.py, add indexes for frequently queried fields
class StudyEvent(models.Model):
    # ... fields ...
    
    class Meta:
        indexes = [
            models.Index(fields=['host']),
            models.Index(fields=['time']),
            models.Index(fields=['event_type']),
            models.Index(fields=['latitude', 'longitude']),
        ]
```

### Recommended Indexes
1. **StudyEvent**: host, time, event_type, location (lat/lng)
2. **UserRating**: from_user, to_user, created_at
3. **EventComment**: event, created_at
4. **FriendRequest**: from_user, to_user

## 🔄 Database Migrations

### Creating Migrations
```bash
# Create migration for model changes
python manage.py makemigrations

# Apply migrations to database
python manage.py migrate

# Check migration status
python manage.py showmigrations
```

### Migration Files Location
```
myapp/migrations/
├── 0001_initial.py
├── 0002_auto_20250101_1200.py
├── 0003_add_user_rating.py
└── ...
```

## 🗃️ Data Population Scripts

### Sample Data Generation
Located in `/scripts/` directory:
- `generate_buenos_aires_data.py` - Generate international student data
- `create_social_network.py` - Create friend connections
- `run_auto_matching.py` - Generate auto-matched events

### Data Population Commands
```bash
# Generate sample data
python scripts/generate_buenos_aires_data.py

# Create social network
python scripts/create_social_network.py

# Run auto-matching
python scripts/run_auto_matching.py
```

## 🔍 Query Examples

### Common Queries

#### Get User's Events
```python
# Events hosted by user
hosted_events = StudyEvent.objects.filter(host=user)

# Events user is attending
attended_events = StudyEvent.objects.filter(attendees=user)

# Events user is invited to
invited_events = StudyEvent.objects.filter(invited_friends=user)
```

#### Get User's Friends
```python
user_profile = UserProfile.objects.get(user=user)
friends = user_profile.friends.all()
```

#### Get Event Social Feed
```python
event = StudyEvent.objects.get(id=event_id)
comments = EventComment.objects.filter(event=event).order_by('-created_at')
likes = EventLike.objects.filter(event=event)
shares = EventShare.objects.filter(event=event)
```

#### Get User Reputation
```python
ratings_received = UserRating.objects.filter(to_user=user)
total_ratings = ratings_received.count()
average_rating = ratings_received.aggregate(avg=Avg('rating'))['avg']
```

## 🚀 Production Considerations

### Database Migration to PostgreSQL
```python
# settings.py for production
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'studycon_prod',
        'USER': 'your_db_user',
        'PASSWORD': 'your_db_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

### Performance Optimization
1. **Connection Pooling**: Use pgbouncer for PostgreSQL
2. **Read Replicas**: Separate read/write operations
3. **Caching**: Redis for frequently accessed data
4. **Database Monitoring**: Track slow queries

### Backup Strategy
```bash
# SQLite backup
cp db.sqlite3 backup_$(date +%Y%m%d_%H%M%S).sqlite3

# PostgreSQL backup
pg_dump studycon_prod > backup_$(date +%Y%m%d_%H%M%S).sql
```

## 🔧 Database Maintenance

### Regular Maintenance Tasks
1. **Vacuum**: Clean up deleted records
2. **Analyze**: Update query statistics
3. **Reindex**: Rebuild indexes
4. **Backup**: Regular automated backups

### Monitoring Queries
```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('studycon_prod'));

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

**Last Updated**: January 2025
**Schema Version**: 1.0.0
