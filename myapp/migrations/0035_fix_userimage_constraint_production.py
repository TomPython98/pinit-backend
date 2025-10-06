# Generated migration to fix UserImage unique constraint in production

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0034_add_object_storage_fields'),
    ]

    operations = [
        # Remove any existing constraint that might be causing issues
        migrations.RunSQL(
            "ALTER TABLE myapp_userimage DROP CONSTRAINT IF EXISTS unique_primary_per_user;",
            reverse_sql="-- No reverse operation needed"
        ),
        # Add the correct constraint - only one primary per user
        migrations.AddConstraint(
            model_name='userimage',
            constraint=models.UniqueConstraint(
                fields=['user'],
                condition=models.Q(('is_primary', True)),
                name='unique_primary_per_user_fixed'
            ),
        ),
    ]
