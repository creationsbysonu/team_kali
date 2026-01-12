"""
Django management command to create a ministry admin user.

Usage:
    python manage.py create_ministry_admin \
        --email admin@ministry.gov.np \
        --password SecurePassword123! \
        --place dharan \
        --ministry local-level

This creates a user with user_type='admin' and links them to the specified ministry.
"""
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from authentication.models import CustomUser
from ministry.models import Ministry, MinistryMember
from places.models import Place


class Command(BaseCommand):
    help = 'Create a ministry admin user and link to a ministry'

    def add_arguments(self, parser):
        parser.add_argument(
            '--email',
            type=str,
            required=True,
            help='Email address for the admin user'
        )
        parser.add_argument(
            '--password',
            type=str,
            required=True,
            help='Password for the admin user'
        )
        parser.add_argument(
            '--place',
            type=str,
            required=True,
            help='Place slug where the ministry is located'
        )
        parser.add_argument(
            '--ministry',
            type=str,
            required=True,
            help='Ministry slug to assign admin to'
        )
        parser.add_argument(
            '--verified',
            action='store_true',
            help='Mark user as verified (default: True for admins)'
        )

    def handle(self, *args, **options):
        email = options['email']
        password = options['password']
        place_slug = options['place']
        ministry_slug = options['ministry']
        is_verified = options.get('verified', True)  # Default True for admins

        try:
            with transaction.atomic():
                # Check if user already exists
                if CustomUser.objects.filter(email=email).exists():
                    raise CommandError(f'User with email "{email}" already exists')

                # Verify place exists
                try:
                    place = Place.objects.get(slug=place_slug, is_active=True)
                except Place.DoesNotExist:
                    raise CommandError(f'Place with slug "{place_slug}" not found or inactive')

                # Verify ministry exists
                try:
                    ministry = Ministry.objects.get(
                        place=place,
                        slug=ministry_slug,
                        status=Ministry.Status.ACTIVE
                    )
                except Ministry.DoesNotExist:
                    raise CommandError(
                        f'Ministry with slug "{ministry_slug}" not found in place "{place_slug}" or not active'
                    )

                # Check if ministry already has an admin
                existing_admin = MinistryMember.objects.filter(
                    ministry=ministry,
                    is_active=True
                ).first()
                
                if existing_admin:
                    self.stdout.write(
                        self.style.WARNING(
                            f'Warning: Ministry "{ministry.name}" already has an admin: {existing_admin.user.email}'
                        )
                    )
                    
                    confirm = input('Do you want to add another admin? (yes/no): ')
                    if confirm.lower() not in ['yes', 'y']:
                        raise CommandError('Operation cancelled')

                # Create user
                user = CustomUser.objects.create_user(  # type: ignore
                    email=email,
                    password=password,
                    user_type=CustomUser.UserType.ADMIN,
                    is_verified=is_verified,
                    is_active=True
                )

                # Create ministry membership
                membership = MinistryMember.objects.create(
                    ministry=ministry,
                    user=user,
                    is_active=True
                )

                self.stdout.write(self.style.SUCCESS('✓ Ministry admin created successfully!'))
                self.stdout.write('')
                self.stdout.write('Details:')
                self.stdout.write(f'  Email: {user.email}')
                self.stdout.write(f'  User Type: {user.user_type}')
                self.stdout.write(f'  Verified: {user.is_verified}')
                self.stdout.write(f'  Place: {place.name} ({place.slug})')
                self.stdout.write(f'  Ministry: {ministry.name} ({ministry.slug})')
                self.stdout.write('')
                self.stdout.write('Login credentials:')
                self.stdout.write(f'  POST /auth/login/')
                self.stdout.write('  Body: {')
                self.stdout.write(f'    "email": "{email}",')
                self.stdout.write(f'    "password": "***",')
                self.stdout.write(f'    "place_slug": "{place_slug}",')
                self.stdout.write(f'    "ministry_slug": "{ministry_slug}"')
                self.stdout.write('  }')
                self.stdout.write('')

        except Exception as e:
            raise CommandError(f'Error creating ministry admin: {str(e)}')
