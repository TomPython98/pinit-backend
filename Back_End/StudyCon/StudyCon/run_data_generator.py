#!/usr/bin/env python
"""
Run this script from the Django project root to generate test data
"""
import os
import sys
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
django.setup()

# Import the data generator
from generate_vienna_data import Command

if __name__ == "__main__":
    print("PinIt Vienna Test Data Generator")
    print("--------------------------------")
    print("This script will DELETE all existing data and create new test data including:")
    print("- User accounts (with password 'Schamixd1')")
    print("- User profiles with Vienna-specific interests")
    print("- Study events throughout Vienna")
    print("- Direct invitations and auto-matched invitations")
    print("- Social interactions (comments, likes, shares)")
    print("\nAre you sure you want to continue? This will DELETE existing data.")
    confirmation = input("Type 'yes' to continue: ")
    
    if confirmation.lower() == 'yes':
        command = Command()
        command.handle()
        print("\nData generation complete! You can now log in with any of the created users.")
        print("All accounts use the password: Schamixd1")
    else:
        print("Operation cancelled.") 