"""
Seed Ministry Management Command

Creates sample ministries for development.
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from ministry.models import Ministry, MinistryMember

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed sample ministries for development'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing ministries before seeding',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write('Clearing existing ministries...')
            MinistryMember.objects.all().delete()
            Ministry.objects.all().delete()

        # Sample ministries for Nepal government portal
        ministries = [
            {
                'name': 'Ministry of Home Affairs',
                'slug': 'moha',
                'description': 'Government ministry responsible for internal security, law enforcement, and administrative affairs.',
                'settings': {
                    'theme_color': '#1a365d',
                    'allow_citizen_registration': True,
                }
            },
            {
                'name': 'Ministry of Finance',
                'slug': 'mof',
                'description': 'Government ministry responsible for national budget, taxation, and economic policy.',
                'settings': {
                    'theme_color': '#2c5282',
                    'allow_citizen_registration': True,
                }
            },
            {
                'name': 'Ministry of Health',
                'slug': 'moh',
                'description': 'Government ministry responsible for public health services and healthcare policies.',
                'settings': {
                    'theme_color': '#276749',
                    'allow_citizen_registration': True,
                }
            },
            {
                'name': 'Ministry of Education',
                'slug': 'moe',
                'description': 'Government ministry responsible for education policies and academic affairs.',
                'settings': {
                    'theme_color': '#744210',
                    'allow_citizen_registration': True,
                }
            },
            {
                'name': 'Ministry of Foreign Affairs',
                'slug': 'mofa',
                'description': 'Government ministry responsible for foreign relations and diplomatic affairs.',
                'settings': {
                    'theme_color': '#702459',
                    'allow_citizen_registration': False,
                }
            },
        ]

        created_count = 0
        for ministry_data in ministries:
            ministry, created = Ministry.objects.get_or_create(
                slug=ministry_data['slug'],
                defaults={
                    'name': ministry_data['name'],
                    'description': ministry_data['description'],
                    'settings': ministry_data['settings'],
                    'status': Ministry.Status.ACTIVE,
                }
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'  ✓ Created: {ministry.name}')
                )
            else:
                self.stdout.write(f'  - Exists: {ministry.name}')

        # Create admin users for ministries if super admin exists
        super_admins = User.objects.filter(user_type='super_admin', is_superuser=True)
        if super_admins.exists():
            super_admin = super_admins.first()
            # Add super admin to all ministries as staff
            for ministry in Ministry.objects.all():
                MinistryMember.objects.get_or_create(
                    ministry=ministry,
                    user=super_admin,
                    defaults={'is_active': True}
                )
            self.stdout.write(
                self.style.SUCCESS(f'\n  ✓ Super admin added to all ministries')
            )

        self.stdout.write(
            self.style.SUCCESS(
                f'\n✅ Seeding complete! Created {created_count} new ministries.'
            )
        )
