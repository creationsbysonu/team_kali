import os
from celery import Celery
from celery.schedules import crontab

# Set the default Django settings module for the 'celery' program.
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sewa_sathi.settings')

app = Celery('sewa_sathi')

# Using a string here means the worker doesn't have to serialize
# the configuration object to child processes.
# - namespace='CELERY' means all celery-related configuration keys
#   should have a `CELERY_` prefix.
app.config_from_object('django.conf:settings', namespace='CELERY')

# Load task modules from all registered Django apps.
app.autodiscover_tasks()


# Celery Beat Schedule for periodic tasks
app.conf.beat_schedule = {
    # End-of-day token auto-cancellation (runs at 6:00 PM Nepal Time daily)
    'auto-cancel-tokens-end-of-day': {
        'task': 'queue_management.end_of_day_auto_cancel',
        'schedule': crontab(hour=18, minute=0),  # 6:00 PM Nepal Time
        'options': {
            'description': 'Auto-cancel all active tokens at end of day'
        }
    },
    
    # Create daily queues for tomorrow (runs at 11:30 PM Nepal Time daily)
    'create-daily-queues-tomorrow': {
        'task': 'queue_management.create_daily_queues',
        'schedule': crontab(hour=23, minute=30),  # 11:30 PM Nepal Time
        'options': {
            'description': 'Create daily queues for tomorrow'
        }
    },
    
    # Optional: Cleanup old tokens (runs weekly on Sunday at 2:00 AM)
    'cleanup-old-tokens': {
        'task': 'queue_management.cleanup_old_tokens',
        'schedule': crontab(hour=2, minute=0, day_of_week=0),  # Sunday 2:00 AM
        'options': {
            'description': 'Cleanup tokens older than 90 days'
        }
    },
}


@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')