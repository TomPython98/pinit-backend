# Generated manually for EventReviewReminder model

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('myapp', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='EventReviewReminder',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('sent_at', models.DateTimeField(auto_now_add=True)),
                ('event', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='review_reminders', to='myapp.studyevent')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='received_review_reminders', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-sent_at'],
            },
        ),
        migrations.AddConstraint(
            model_name='eventreviewreminder',
            constraint=models.UniqueConstraint(fields=('event', 'user'), name='unique_event_user_reminder'),
        ),
    ]
