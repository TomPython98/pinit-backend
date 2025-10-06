#!/usr/bin/env python3
"""
Script to update existing image URLs to use R2
"""
import os
import sys
import django

# Add the project directory to Python path
sys.path.append('/Users/tombesinger/Desktop/PinItApp')

# Set up Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

from myapp.models import UserImage
from django.conf import settings

def update_existing_images():
    """Update existing images to use R2 URLs"""
    print("Updating existing images to use R2 URLs...")
    
    # Get all images
    images = UserImage.objects.all()
    print(f"Found {images.count()} images")
    
    for img in images:
        if img.image:
            # Update the public_url field
            img.public_url = img.image.url
            img.storage_key = img.image.name
            img.save(update_fields=['public_url', 'storage_key'])
            print(f"Updated image {img.id}: {img.public_url}")
    
    print("Done!")

if __name__ == "__main__":
    update_existing_images()
