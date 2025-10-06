# Generated manually for object storage support

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myapp', '0032_add_userimage_model'),
    ]

    operations = [
        migrations.AddField(
            model_name='userimage',
            name='storage_key',
            field=models.CharField(blank=True, max_length=500, null=True),
        ),
        migrations.AddField(
            model_name='userimage',
            name='public_url',
            field=models.URLField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='userimage',
            name='mime_type',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='userimage',
            name='width',
            field=models.PositiveIntegerField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='userimage',
            name='height',
            field=models.PositiveIntegerField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='userimage',
            name='size_bytes',
            field=models.PositiveIntegerField(blank=True, null=True),
        ),
    ]
