"""
Celery Tasks for Authentication App

This module imports all tasks from submodules so Celery's autodiscover_tasks()
can find them. Celery looks for tasks.py in the root of each Django app.
"""
from authentication.otp.tasks import send_otp_email  # noqa: F401

__all__ = ['send_otp_email']
