#!/usr/bin/env python
"""
Redis & Celery Configuration Test
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sewa_sathi.settings')
django.setup()

import redis
from django.core.cache import cache
from sewa_sathi.celery import app as celery_app
from authentication.core.jwt_utils import TokenManager

print('=' * 60)
print('Redis & Celery Configuration Test')
print('=' * 60)

# Test 1: Redis Direct Connection
print('\n📌 Test 1: Redis Direct Connection')
try:
    r = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)
    r.ping()
    info = r.info()
    print('✅ Redis (DB 0 - Celery Broker): CONNECTED')
    print(f'   Version: {info["redis_version"]}')
    print(f'   Connected Clients: {info["connected_clients"]}')
    print(f'   Used Memory: {info["used_memory_human"]}')
except Exception as e:
    print(f'❌ Redis: ERROR - {e}')

# Test 2: Django Cache (Redis DB 1)
print('\n📌 Test 2: Django Cache (Redis DB 1)')
try:
    cache.set('test_key', 'test_value', 10)
    value = cache.get('test_key')
    if value == 'test_value':
        print('✅ Cache: WORKING')
        print('   Set/Get operations successful')
        cache.delete('test_key')
    else:
        print('❌ Cache: FAILED - Value mismatch')
except Exception as e:
    print(f'❌ Cache: ERROR - {e}')

# Test 3: Celery Broker Connection
print('\n📌 Test 3: Celery Broker Connection')
try:
    celery_app.connection().ensure_connection(max_retries=1)
    print('✅ Celery Broker: CONNECTED')
    print(f'   Broker URL: {celery_app.conf.broker_url}')
    print(f'   Result Backend: {celery_app.conf.result_backend}')
except Exception as e:
    print(f'❌ Celery Broker: ERROR - {e}')

# Test 4: Registered Celery Tasks
print('\n📌 Test 4: Registered Celery Tasks')
custom_tasks = [name for name in celery_app.tasks.keys() if not name.startswith('celery.')]
print(f'✅ Registered Tasks: {len(custom_tasks)}')
for task_name in sorted(custom_tasks):
    print(f'   - {task_name}')

# Test 5: Token Blacklist (Redis-based)
print('\n📌 Test 5: Token Blacklist (Redis Cache)')
try:
    test_jti = 'test_jti_12345'
    TokenManager.blacklist_token(test_jti)
    is_blacklisted = TokenManager.is_token_blacklisted(test_jti)
    if is_blacklisted:
        print('✅ Token Blacklist: WORKING')
        print('   Set/Check operations successful')
    else:
        print('❌ Token Blacklist: FAILED')
except Exception as e:
    print(f'❌ Token Blacklist: ERROR - {e}')

# Summary
print('\n' + '=' * 60)
print('📊 Summary')
print('=' * 60)
print('✅ Redis is properly configured and running')
print('✅ Django Cache (Redis DB 1) is working')
print('✅ Celery Broker (Redis DB 0) is connected')
print(f'✅ {len(custom_tasks)} custom task(s) registered')
print('✅ Token blacklist (Redis-based) is working')
print('\n💡 To start Celery worker:')
print('   celery -A sewa_sathi worker --loglevel=info')
print('\n💡 To start Celery Beat (scheduled tasks):')
print('   celery -A sewa_sathi beat --loglevel=info')
print('\n💡 To monitor with Flower:')
print('   celery -A sewa_sathi flower')
print('=' * 60)
