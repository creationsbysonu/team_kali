"""
Authentication Seed File
Populates database with sample users for authentication system
"""
import os
import random
import uuid
from django.utils import timezone
from django.core.management.base import BaseCommand
from django.db import transaction, IntegrityError
from faker import Faker

from authentication.models import CustomUser

fake = Faker()

class Command(BaseCommand):
    help = 'Generate seed data for authentication users'

    def add_arguments(self, parser):
        parser.add_argument('--users', type=int, default=50, help='Number of users to create')
        parser.add_argument('--clear', action='store_true', help='Clear existing data before seeding')

    def handle(self, *args, **options):
        if options['clear']:
            self.clear_data()
            self.stdout.write(self.style.SUCCESS('Existing user data cleared'))
        
        try:
            with transaction.atomic():
                self.stdout.write('Creating users...')
                users = self.create_users(options['users'])
            
            self.stdout.write(self.style.SUCCESS('Authentication seed data generation completed!'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error during seeding: {str(e)}'))
    
    def clear_data(self):
        """Clear existing user data - use with caution"""
        # Don't delete all users by default, we'll only delete non-superusers
        CustomUser.objects.filter(is_superuser=False).delete()
        self.stdout.write('Deleted non-superuser accounts')
    
    def create_users(self, count):
        """Create sample users with Faker, handling potential duplicates"""
        users = []
        created_count = 0
        attempts = 0
        max_attempts = count * 3  # Allow multiple attempts to create unique users

        while created_count < count and attempts < max_attempts:
            try:
                first_name = fake.first_name()
                last_name = fake.last_name()
                
                # Generate a more robust unique username
                base_username = f"{first_name.lower()}{last_name.lower()}"
                username = base_username + str(random.randint(1, 9999))
                email = f"{username}@{fake.domain_name()}"
                
                user = CustomUser.objects.create_user(
                    email=email,
                    username=username,
                    password="password123",  # Simple password for all test users
                    first_name=first_name,
                    last_name=last_name,
                    phone_number=fake.phone_number()[:15],
                    is_verified=random.choice([True, False]),
                    profile_picture=self._get_random_avatar_url()
                )
                
                # Randomly assign Firebase UID to some users
                if random.random() > 0.5:
                    user.firebase_uid = f"firebase_{uuid.uuid4()}"
                    user.save()
                
                users.append(user)
                created_count += 1
                
                # Create admin user only once and only if not already exists
                if created_count == count:
                    self.create_admin_user()
                
            except IntegrityError:
                # Skip this iteration if unique constraint is violated
                attempts += 1
                self.stdout.write(self.style.WARNING(f'Duplicate user, retrying... (Attempt {attempts})'))
                continue
        
        if created_count < count:
            self.stdout.write(self.style.WARNING(f'Could only create {created_count} unique users'))
        
        return users
    
    def create_admin_user(self):
        """Safely create admin user, skipping if already exists"""
        try:
            # Check if admin already exists
            CustomUser.objects.get(username='admin')
            self.stdout.write(self.style.WARNING('Admin user already exists, skipping creation'))
        except CustomUser.DoesNotExist:
            # Create admin user only if it doesn't exist
            CustomUser.objects.create_superuser(
                email="admin@gentech.com",
                username="admin",
                password="admin123",
                first_name="Admin",
                last_name="User",
                is_verified=True
            )
            self.stdout.write(self.style.SUCCESS('Admin user created'))
    
    def _get_random_avatar_url(self):
        """Return a random avatar URL for user profiles"""
        gender = random.choice(['men', 'women'])
        return f"https://randomuser.me/api/portraits/{gender}/{random.randint(1, 99)}.jpg"


if __name__ == "__main__":
    # This allows the script to be run directly
    from django.core.management import execute_from_command_line
    execute_from_command_line(['manage.py', 'seed_authentication'])