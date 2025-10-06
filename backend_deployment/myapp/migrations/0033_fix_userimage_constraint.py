# Generated migration to fix UserImage unique constraint

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0032_add_userimage_model'),
    ]

    operations = [
        # Remove the broken constraint
        migrations.RemoveConstraint(
            model_name='userimage',
            name='unique_primary_per_user',
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
