#!/usr/bin/env python
"""Quick Redis & Celery Health Check"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sewa_sathi.settings')
django.setup()

from django.core.cache import cache
from sewa_sathi.celery import app as celery_app
# Import tasks to ensure they're registered
from authentication.tasks import send_otp_email  # noqa

print('Redis & Celery Health Check')
print('-' * 50)

# Test Redis
try:
    cache.set('test', 'ok', 10)
    print('✅ Redis: WORKING')
except:
    print('❌ Redis: FAILED')

# Test Celery
try:
    celery_app.connection().ensure_connection(max_retries=1)
    print('✅ Celery Broker: CONNECTED')
except:
    print('❌ Celery Broker: DISCONNECTED')

# List tasks
tasks = [t for t in celery_app.tasks.keys() if not t.startswith('celery.')]
print(f'✅ Registered Tasks: {len(tasks)}')
for t in tasks:
    print(f'   - {t}')

print('-' * 50)
print('Start Celery Worker: celery -A sewa_sathi worker -l info')
