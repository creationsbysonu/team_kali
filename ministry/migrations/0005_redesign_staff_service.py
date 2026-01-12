# Generated migration for StaffService redesign

from django.db import migrations, models
import django.db.models.deletion
import uuid
import core.storage


class Migration(migrations.Migration):

    dependencies = [
        ('ministry', '0004_staffservice'),
    ]

    operations = [
        # Drop the old StaffService table
        migrations.DeleteModel(
            name='StaffService',
        ),
        
        # Recreate with new schema
        migrations.CreateModel(
            name='StaffService',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('service_name', models.CharField(help_text='Name of the service (e.g., IT Support, Birth Certificate)', max_length=255)),
                ('service_logo', models.ImageField(blank=True, help_text='Service logo (uploaded to Cloudinary /logos folder)', null=True, storage=core.storage.LogoCloudinaryStorage(), upload_to=core.storage.LogoCloudinaryStorage.get_upload_path)),
                ('staff_name', models.CharField(help_text='Full name of the staff member handling this service', max_length=255)),
                ('staff_image', models.ImageField(blank=True, help_text='Staff profile photo (uploaded to Cloudinary /logos folder)', null=True, storage=core.storage.LogoCloudinaryStorage(), upload_to=core.storage.LogoCloudinaryStorage.get_upload_path)),
                ('email', models.EmailField(help_text='Staff login email', max_length=254, unique=True)),
                ('password', models.CharField(help_text='Hashed password for staff login', max_length=128)),
                ('status', models.CharField(choices=[('active', 'Active'), ('paused', 'Paused')], default='active', help_text='Service availability status - Ministry can pause when staff is absent', max_length=20)),
                ('is_active', models.BooleanField(default=True, help_text='System-level enable/disable for this staff service account')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('ministry', models.ForeignKey(help_text='Ministry this staff service belongs to', on_delete=django.db.models.deletion.CASCADE, related_name='staff_services', to='ministry.ministry')),
            ],
            options={
                'verbose_name': 'Staff Service',
                'verbose_name_plural': 'Staff Services',
                'ordering': ['-created_at'],
            },
        ),
        
        # Add indexes
        migrations.AddIndex(
            model_name='staffservice',
            index=models.Index(fields=['ministry', 'status', 'is_active'], name='ministry_st_ministr_f8e4d0_idx'),
        ),
        migrations.AddIndex(
            model_name='staffservice',
            index=models.Index(fields=['email'], name='ministry_st_email_e2b6d5_idx'),
        ),
        migrations.AddIndex(
            model_name='staffservice',
            index=models.Index(fields=['status'], name='ministry_st_status_5c7a8f_idx'),
        ),
        migrations.AddIndex(
            model_name='staffservice',
            index=models.Index(fields=['is_active'], name='ministry_st_is_acti_3f9c2a_idx'),
        ),
    ]
