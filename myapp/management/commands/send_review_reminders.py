"""
Management command to send review reminders for ended events.
Run this periodically (e.g., every hour via cron job or Railway scheduled task).
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from myapp.models import StudyEvent, EventReviewReminder, User
from myapp.views import send_push_notification


class Command(BaseCommand):
    help = 'Send review reminders for events that recently ended'

    def handle(self, *args, **options):
        now = timezone.now()
        
        # Get events that ended in the last hour (but not more than 2 hours ago)
        # This gives us a 1-hour window to catch ended events
        time_window_start = now - timedelta(hours=2)
        time_window_end = now - timedelta(minutes=5)  # Wait 5 minutes after event ends
        
        ended_events = StudyEvent.objects.filter(
            end_time__gte=time_window_start,
            end_time__lte=time_window_end
        ).prefetch_related('attendees')
        
        self.stdout.write(f"Found {ended_events.count()} recently ended events")
        
        reminders_sent = 0
        
        for event in ended_events:
            # Get all attendees (excluding the host)
            attendees = event.attendees.exclude(id=event.host.id)
            
            for attendee in attendees:
                # Check if we've already sent a reminder for this event-user combination
                reminder_exists = EventReviewReminder.objects.filter(
                    event=event,
                    user=attendee
                ).exists()
                
                if not reminder_exists:
                    # Create reminder record
                    EventReviewReminder.objects.create(
                        event=event,
                        user=attendee
                    )
                    
                    # Get other attendees to review (excluding self and host)
                    reviewable_users = event.attendees.exclude(
                        id__in=[attendee.id]
                    ).values_list('username', flat=True)
                    
                    reviewable_count = len(reviewable_users)
                    
                    if reviewable_count > 0:
                        # Send push notification
                        try:
                            send_push_notification(
                                user_id=attendee.id,
                                notification_type='review_reminder',
                                event_id=str(event.id),
                                event_title=event.title,
                                reviewable_count=reviewable_count
                            )
                            reminders_sent += 1
                            self.stdout.write(
                                self.style.SUCCESS(
                                    f"✅ Sent review reminder to {attendee.username} for event '{event.title}'"
                                )
                            )
                        except Exception as e:
                            self.stdout.write(
                                self.style.ERROR(
                                    f"❌ Failed to send reminder to {attendee.username}: {str(e)}"
                                )
                            )
        
        self.stdout.write(
            self.style.SUCCESS(
                f"\n🎉 Completed! Sent {reminders_sent} review reminders"
            )
        )

