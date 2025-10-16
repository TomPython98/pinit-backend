# Generated manually for performance improvements - comes after existing migrations

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0003_eventjoinrequest'),
    ]

    operations = [
        # Add indexes to ChatMessage model
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_chatmessage_sender_receiver_timestamp ON myapp_chatmessage (sender_id, receiver_id, timestamp);",
            reverse_sql="DROP INDEX IF EXISTS idx_chatmessage_sender_receiver_timestamp;"
        ),
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_chatmessage_receiver_timestamp ON myapp_chatmessage (receiver_id, timestamp);",
            reverse_sql="DROP INDEX IF EXISTS idx_chatmessage_receiver_timestamp;"
        ),
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_chatmessage_timestamp ON myapp_chatmessage (timestamp);",
            reverse_sql="DROP INDEX IF EXISTS idx_chatmessage_timestamp;"
        ),
        
        # Add indexes to EventInvitation model
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_eventinvitation_event_auto_matched ON myapp_eventinvitation (event_id, is_auto_matched);",
            reverse_sql="DROP INDEX IF EXISTS idx_eventinvitation_event_auto_matched;"
        ),
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_eventinvitation_user_created_at ON myapp_eventinvitation (user_id, created_at);",
            reverse_sql="DROP INDEX IF EXISTS idx_eventinvitation_user_created_at;"
        ),
        
        # Add indexes to EventJoinRequest model
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_eventjoinrequest_event_status ON myapp_eventjoinrequest (event_id, status);",
            reverse_sql="DROP INDEX IF EXISTS idx_eventjoinrequest_event_status;"
        ),
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_eventjoinrequest_user_status ON myapp_eventjoinrequest (user_id, status);",
            reverse_sql="DROP INDEX IF EXISTS idx_eventjoinrequest_user_status;"
        ),
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_eventjoinrequest_status_created_at ON myapp_eventjoinrequest (status, created_at);",
            reverse_sql="DROP INDEX IF EXISTS idx_eventjoinrequest_status_created_at;"
        ),
        
        # Add indexes to UserImage model
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_userimage_user_primary ON myapp_userimage (user_id, is_primary);",
            reverse_sql="DROP INDEX IF EXISTS idx_userimage_user_primary;"
        ),
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_userimage_user_type ON myapp_userimage (user_id, image_type);",
            reverse_sql="DROP INDEX IF EXISTS idx_userimage_user_type;"
        ),
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_userimage_primary_uploaded ON myapp_userimage (is_primary, uploaded_at);",
            reverse_sql="DROP INDEX IF EXISTS idx_userimage_primary_uploaded;"
        ),
        migrations.RunSQL(
            "CREATE INDEX IF NOT EXISTS idx_userimage_uploaded_at ON myapp_userimage (uploaded_at);",
            reverse_sql="DROP INDEX IF EXISTS idx_userimage_uploaded_at;"
        ),
    ]
