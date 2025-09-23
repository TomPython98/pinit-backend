from django.core.management.base import BaseCommand
from django.contrib.auth.models import User

class Command(BaseCommand):
    help = 'Lists all usernames in the database'

    def handle(self, *args, **options):
        users = User.objects.all().order_by('username')
        self.stdout.write(f"Total users: {users.count()}")
        for user in users:
            self.stdout.write(f"Username: {user.username} | Name: {user.first_name} {user.last_name}")