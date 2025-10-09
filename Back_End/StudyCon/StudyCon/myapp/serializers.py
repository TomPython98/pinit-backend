from rest_framework import serializers
from django.contrib.auth.models import User
from .models import StudyEvent, UserProfile, FriendRequest
import bleach
import re

class UserRegistrationSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150, min_length=3)
    password = serializers.CharField(min_length=8, write_only=True)
    
    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Username already exists")
        # Add validation: alphanumeric only
        if not value.isalnum():
            raise serializers.ValidationError("Username must be alphanumeric")
        return value
    
    def validate_password(self, value):
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters long")
        return value

class StudyEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = StudyEvent
        fields = '__all__'
    
    def validate_title(self, value):
        # Sanitize title
        value = bleach.clean(value, tags=[], strip=True)
        if len(value) < 3 or len(value) > 200:
            raise serializers.ValidationError("Title must be between 3 and 200 characters")
        return value
    
    def validate_description(self, value):
        # Sanitize description
        value = bleach.clean(value, tags=[], strip=True)
        if len(value) > 5000:
            raise serializers.ValidationError("Description too long (max 5000 characters)")
        return value
    
    def validate_max_participants(self, value):
        if value < 2 or value > 100:
            raise serializers.ValidationError("Max participants must be between 2 and 100")
        return value
    
    def validate_latitude(self, value):
        if value < -90 or value > 90:
            raise serializers.ValidationError("Invalid latitude")
        return value
    
    def validate_longitude(self, value):
        if value < -180 or value > 180:
            raise serializers.ValidationError("Invalid longitude")
        return value
    
    def validate(self, data):
        # Ensure end_time is after start_time
        if 'end_time' in data and 'time' in data:
            if data['end_time'] <= data['time']:
                raise serializers.ValidationError("End time must be after start time")
        return data

class FriendRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = FriendRequest
        fields = ['to_user']
    
    def validate_to_user(self, value):
        if not value:
            raise serializers.ValidationError("Target user is required")
        return value

def sanitize_text_input(text):
    """Sanitize text input to prevent XSS"""
    if not text:
        return text
    # Remove all HTML tags and dangerous characters
    return bleach.clean(text, tags=[], strip=True)

def validate_event_data(data):
    """Validate event creation data"""
    errors = []
    
    # Sanitize text inputs
    if 'title' in data:
        data['title'] = sanitize_text_input(data['title'])
        if len(data['title']) < 3 or len(data['title']) > 200:
            errors.append("Title must be between 3 and 200 characters")
    
    if 'description' in data:
        data['description'] = sanitize_text_input(data['description'])
        if len(data['description']) > 5000:
            errors.append("Description too long")
    
    # Validate coordinates
    if 'latitude' in data:
        try:
            lat = float(data['latitude'])
            if lat < -90 or lat > 90:
                errors.append("Invalid latitude")
        except (ValueError, TypeError):
            errors.append("Invalid latitude format")
    
    if 'longitude' in data:
        try:
            lng = float(data['longitude'])
            if lng < -180 or lng > 180:
                errors.append("Invalid longitude")
        except (ValueError, TypeError):
            errors.append("Invalid longitude format")
    
    return data, errors
