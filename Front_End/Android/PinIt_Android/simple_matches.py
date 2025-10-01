import os
import django
import random
import sys
import traceback

# Open log file at the beginning
with open('debug_output.log', 'w') as log_file:
    log_file.write("Starting script...\n")

    try:
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'StudyCon.settings')
        django.setup()
        log_file.write("Django setup complete\n")

        from django.contrib.auth.models import User
        from myapp.models import StudyEvent, EventInvitation
        log_file.write("Imports complete\n")

        # Get current counts
        events = StudyEvent.objects.filter(auto_matching_enabled=True)
        log_file.write(f"Found {events.count()} events with auto-matching enabled\n")
        log_file.write(f"Total users: {User.objects.count()}\n")

        # Update all events to have auto-matching enabled
        StudyEvent.objects.all().update(auto_matching_enabled=True)
        log_file.write("Updated all events to have auto-matching enabled\n")

        # Reset auto-matched invitations
        auto_match_count = EventInvitation.objects.filter(is_auto_matched=True).count()
        log_file.write(f"Found {auto_match_count} existing auto-matched invitations\n")
        EventInvitation.objects.filter(is_auto_matched=True).delete()
        log_file.write("Deleted existing auto-matched invitations\n")

        # Create new auto-matched invitations
        users = User.objects.all()
        log_file.write(f"Found {len(users)} users to potentially invite\n")
        match_count = 0

        # Process all events and create more invitations per event
        event_count = StudyEvent.objects.count()
        log_file.write(f"Processing all {event_count} events\n")

        for i, event in enumerate(StudyEvent.objects.all()):
            log_file.write(f"Processing event {i+1}/{event_count} - ID {event.id}: {event.title}\n")
            
            try:
                host = event.host
                log_file.write(f"  Host: {host.username}\n")
                potential_users = [u for u in users if u != host]
                log_file.write(f"  Found {len(potential_users)} potential users to invite\n")
                
                if potential_users:
                    invite_count = min(10, len(potential_users))
                    invite_users = random.sample(potential_users, invite_count)
                    log_file.write(f"  Inviting {len(invite_users)} users\n")
                    
                    for user in invite_users:
                        log_file.write(f"    Creating invitation for {user.username}\n")
                        EventInvitation.objects.create(
                            event=event,
                            user=user,
                            is_auto_matched=True
                        )
                        match_count += 1
            except Exception as e:
                log_file.write(f"ERROR processing event {event.id}: {str(e)}\n")
                traceback.print_exc(file=log_file)
                continue

        log_file.write(f"Created {match_count} new auto-matched invitations\n")
        final_count = EventInvitation.objects.filter(is_auto_matched=True).count()
        log_file.write(f"Final auto-matched invitation count: {final_count}\n")
        log_file.write("Script complete!\n")

    except Exception as e:
        log_file.write(f"ERROR: {str(e)}\n")
        traceback.print_exc(file=log_file)
        log_file.write("Script failed!\n") 