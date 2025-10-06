# Generated manually for UserImage model

from django.db import migrations, models
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0031_auto_20241001_1236'),  # Update this to match your latest migration
    ]

    operations = [
        migrations.CreateModel(
            name='UserImage',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('image', models.ImageField(max_length=500, upload_to='users/{instance.user.username}/images/{filename}')),
                ('image_type', models.CharField(choices=[('profile', 'Profile Picture'), ('gallery', 'Gallery Image'), ('cover', 'Cover Photo')], default='gallery', max_length=20)),
                ('is_primary', models.BooleanField(default=False, help_text='Primary profile picture')),
                ('caption', models.CharField(blank=True, max_length=255)),
                ('uploaded_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(on_delete=models.deletion.CASCADE, related_name='images', to='auth.user')),
            ],
            options={
                'ordering': ['-is_primary', '-uploaded_at'],
            },
        ),
        migrations.AddField(
            model_name='userprofile',
            name='profile_picture',
            field=models.TextField(blank=True, help_text='Base64 encoded profile picture (deprecated)'),
        ),
        migrations.AddConstraint(
            model_name='userimage',
            constraint=models.UniqueConstraint(fields=('user', 'is_primary'), name='unique_primary_per_user'),
        ),
    ]
