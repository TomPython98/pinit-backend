# Generated manually for UserImage model

from django.db import migrations, models
from django.db.models import deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0030_userprofile_bio_userprofile_degree_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='UserImage',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('image', models.ImageField(max_length=500, upload_to='users/username/images/')),
                ('image_type', models.CharField(choices=[('profile', 'Profile Picture'), ('gallery', 'Gallery Image'), ('cover', 'Cover Photo')], default='gallery', max_length=20)),
                ('is_primary', models.BooleanField(default=False, help_text='Primary profile picture')),
                ('caption', models.CharField(blank=True, max_length=255)),
                ('uploaded_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(on_delete=deletion.CASCADE, related_name='images', to='auth.user')),
            ],
            options={
                'ordering': ['-is_primary', '-uploaded_at'],
            },
        ),
    ]