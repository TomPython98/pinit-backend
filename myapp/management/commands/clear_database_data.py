"""
Django management command to clear all data from the database
while preserving the database structure and models.

This command will:
1. Clear all user data (users, profiles, images, etc.)
2. Clear all event data (events, comments, likes, shares, etc.)
3. Clear all social data (friends, messages, ratings, etc.)
4. Preserve database structure and migrations
5. Reset auto-increment counters

Usage:
    python manage.py clear_database_data
    python manage.py clear_database_data --confirm  # Skip confirmation prompt
"""

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.contrib.auth.models import User
from django.conf import settings
import os

from myapp.models import (
    UserProfile, UserImage, UserInterest, UserSkill, FriendRequest, ChatMessage,
    StudyEvent, EventInvitation, EventJoinRequest, EventComment, EventLike,
    EventShare, EventImage, DeclinedInvitation, Device, UserRating,
    UserTrustLevel, UserReputationStats, EventReviewReminder
)


class Command(BaseCommand):
    help = 'Clear all data from the database while preserving structure'

    def add_arguments(self, parser):
        parser.add_argument(
            '--confirm',
            action='store_true',
            help='Skip confirmation prompt',
        )
        parser.add_argument(
            '--keep-trust-levels',
            action='store_true',
            help='Keep UserTrustLevel data (recommended)',
        )

    def handle(self, *args, **options):
        # Safety check - prevent running in production without explicit confirmation
        if not options['confirm']:
            if os.environ.get('DATABASE_URL'):
                self.stdout.write(
                    self.style.WARNING(
                        '⚠️  WARNING: This will clear ALL DATA from your PRODUCTION PostgreSQL database!\n'
                        'This action cannot be undone.\n'
                        'If you are sure, run with --confirm flag.'
                    )
                )
                return

        # Confirmation prompt for local development
        if not options['confirm']:
            confirm = input(
                'Are you sure you want to clear ALL data from the database? '
                'This action cannot be undone. Type "yes" to continue: '
            )
            if confirm.lower() != 'yes':
                self.stdout.write(self.style.SUCCESS('Operation cancelled.'))
                return

        try:
            with transaction.atomic():
                self.clear_database_data(options)
                self.stdout.write(
                    self.style.SUCCESS('✅ Successfully cleared all database data!')
                )
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'❌ Error clearing database: {str(e)}')
            )
            raise CommandError(f'Failed to clear database: {str(e)}')

    def clear_database_data(self, options):
        """Clear all data from the database in the correct order"""
        
        self.stdout.write('🗑️  Starting database cleanup...')
        
        # 1. Clear social interaction data first (to avoid foreign key constraints)
        self.stdout.write('   Clearing social interactions...')
        EventLike.objects.all().delete()
        EventShare.objects.all().delete()
        EventComment.objects.all().delete()
        EventImage.objects.all().delete()
        
        # 2. Clear event-related data
        self.stdout.write('   Clearing event data...')
        EventJoinRequest.objects.all().delete()
        EventInvitation.objects.all().delete()
        DeclinedInvitation.objects.all().delete()
        EventReviewReminder.objects.all().delete()
        StudyEvent.objects.all().delete()
        
        # 3. Clear user interaction data
        self.stdout.write('   Clearing user interactions...')
        ChatMessage.objects.all().delete()
        FriendRequest.objects.all().delete()
        UserRating.objects.all().delete()
        UserReputationStats.objects.all().delete()
        
        # 4. Clear user profile data
        self.stdout.write('   Clearing user profiles...')
        UserInterest.objects.all().delete()
        UserSkill.objects.all().delete()
        UserImage.objects.all().delete()
        UserProfile.objects.all().delete()
        
        # 5. Clear device tokens
        self.stdout.write('   Clearing device tokens...')
        Device.objects.all().delete()
        
        # 6. Clear users (this will cascade to related data)
        self.stdout.write('   Clearing users...')
        User.objects.all().delete()
        
        # 7. Optionally keep trust levels (recommended)
        if not options.get('keep_trust_levels', True):
            self.stdout.write('   Clearing trust levels...')
            UserTrustLevel.objects.all().delete()
        else:
            self.stdout.write('   Keeping trust levels (recommended)')
        
        # 8. Reset auto-increment counters for PostgreSQL
        if os.environ.get('DATABASE_URL'):
            self.stdout.write('   Resetting auto-increment counters...')
            self.reset_sequences()
        
        self.stdout.write('✅ Database cleanup completed!')

    def reset_sequences(self):
        """Reset PostgreSQL sequences to start from 1"""
        from django.db import connection
        
        with connection.cursor() as cursor:
            # Get all tables and reset their sequences
            cursor.execute("""
                SELECT tablename FROM pg_tables 
                WHERE schemaname = 'public' 
                AND tablename NOT LIKE 'django_%'
                AND tablename NOT LIKE 'auth_%'
            """)
            
            tables = cursor.fetchall()
            
            for (table_name,) in tables:
                try:
                    # Reset sequence for each table
                    cursor.execute(f"""
                        SELECT setval(pg_get_serial_sequence('{table_name}', 'id'), 1, false)
                        WHERE pg_get_serial_sequence('{table_name}', 'id') IS NOT NULL
                    """)
                except Exception as e:
                    # Some tables might not have an 'id' column, that's okay
                    pass

    def get_model_counts(self):
        """Get count of records in each model for reporting"""
        models_to_check = [
            ('Users', User),
            ('UserProfiles', UserProfile),
            ('UserImages', UserImage),
            ('StudyEvents', StudyEvent),
            ('EventComments', EventComment),
            ('EventLikes', EventLike),
            ('EventShares', EventShare),
            ('FriendRequests', FriendRequest),
            ('ChatMessages', ChatMessage),
            ('UserRatings', UserRating),
            ('Devices', Device),
        ]
        
        counts = {}
        for name, model in models_to_check:
            try:
                counts[name] = model.objects.count()
            except Exception:
                counts[name] = 0
        
        return counts
