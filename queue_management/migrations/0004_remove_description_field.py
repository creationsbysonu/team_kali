# Generated migration to remove description field from ServiceProgressStep

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('queue_management', '0003_tokenprogress_completed_by_and_model_updates'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='serviceprogressstep',
            name='description',
        ),
    ]
