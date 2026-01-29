# Generated migration for manual progress tracking refactor

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('queue_management', '0001_initial'),
    ]

    operations = [
        # Add completed_by field to TokenProgress for audit trail
        migrations.AddField(
            model_name='tokenprogress',
            name='completed_by',
            field=models.ForeignKey(
                blank=True,
                help_text='Staff member who manually marked this step as complete',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='completed_progress_steps',
                to=settings.AUTH_USER_MODEL
            ),
        ),
        
        # Add index for completed_by for faster queries
        migrations.AddIndex(
            model_name='tokenprogress',
            index=models.Index(fields=['completed_by'], name='queue_manag_completed_by_idx'),
        ),
        
        # Update TokenProgress help text for completed_at
        migrations.AlterField(
            model_name='tokenprogress',
            name='completed_at',
            field=models.DateTimeField(
                blank=True,
                help_text='When this step was completed (UTC)',
                null=True
            ),
        ),
    ]
