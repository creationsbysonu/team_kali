"""
Seed Places Management Command

Creates sample places (locations) for development.
"""
from django.core.management.base import BaseCommand
from places.models import Place


class Command(BaseCommand):
    help = 'Seed sample places (locations) for development'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing places before seeding',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write('Clearing existing places...')
            Place.all_objects.all().delete()
            self.stdout.write(self.style.SUCCESS('  ✓ Cleared all places'))

        # Sample places for Nepal
        places_data = [
            {'name': 'Kathmandu', 'slug': 'kathmandu'},
            {'name': 'Biratnagar', 'slug': 'biratnagar'},
            {'name': 'Pokhara', 'slug': 'pokhara'},
            {'name': 'Lalitpur', 'slug': 'lalitpur'},
            {'name': 'Bharatpur', 'slug': 'bharatpur'},
            {'name': 'Birgunj', 'slug': 'birgunj'},
            {'name': 'Dharan', 'slug': 'dharan'},
            {'name': 'Butwal', 'slug': 'butwal'},
        ]

        created_count = 0
        for place_data in places_data:
            place, created = Place.objects.get_or_create(
                slug=place_data['slug'],
                defaults={
                    'name': place_data['name'],
                    'is_active': True,
                }
            )
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'  ✓ Created: {place.name}')
                )
            else:
                self.stdout.write(f'  - Exists: {place.name}')

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS(f'Done! Created {created_count} places'))
