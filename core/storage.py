"""
Custom Cloudinary Storage Backends

Provides organized storage for different media types:
- Logos: /logos folder for ministry/tenant logos
- Documents: /documents folder for user documents  
- Avatars: /avatars folder for user profile pictures
"""
import os
import uuid
from django.utils.text import slugify
from cloudinary_storage.storage import MediaCloudinaryStorage


class LogoCloudinaryStorage(MediaCloudinaryStorage):
    """
    Custom storage for ministry logos.
    
    Uploads all logos to the 'logos' folder in Cloudinary.
    Renames files with UUID to avoid conflicts.
    
    Usage in models:
        from core.storage import LogoCloudinaryStorage
        
        logo = models.ImageField(
            upload_to=LogoCloudinaryStorage.get_upload_path,
            storage=LogoCloudinaryStorage(),
            null=True, blank=True
        )
    """
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
    
    @staticmethod
    def get_upload_path(instance, filename):
        """
        Generate upload path for logos.
        
        Path format: logos/{slug}_{uuid}.{ext}
        Example: logos/ministry-of-health_abc123.png
        """
        # Get file extension
        ext = filename.split('.')[-1].lower()
        
        # Generate unique filename
        if hasattr(instance, 'slug') and instance.slug:
            base_name = slugify(instance.slug)
        elif hasattr(instance, 'name') and instance.name:
            base_name = slugify(instance.name)
        else:
            base_name = 'logo'
        
        # Add UUID for uniqueness
        unique_id = uuid.uuid4().hex[:8]
        new_filename = f"{base_name}_{unique_id}.{ext}"
        
        # Return path within logos folder
        return f"logos/{new_filename}"
    
    def _get_resource_type(self, name):
        """Force image resource type for logos"""
        return 'image'


class DocumentCloudinaryStorage(MediaCloudinaryStorage):
    """
    Custom storage for user documents.
    
    Uploads documents to the 'documents' folder in Cloudinary.
    Supports PDFs, images, and other document types.
    """
    
    @staticmethod
    def get_upload_path(instance, filename):
        """
        Generate upload path for documents.
        
        Path format: documents/{user_id}/{filename}
        """
        ext = filename.split('.')[-1].lower()
        unique_id = uuid.uuid4().hex[:8]
        
        # Try to get user ID for organization
        user_id = 'unknown'
        if hasattr(instance, 'user_id'):
            user_id = str(instance.user_id)[:8]
        elif hasattr(instance, 'user') and instance.user:
            user_id = str(instance.user.id)[:8]
        
        new_filename = f"{unique_id}.{ext}"
        return f"documents/{user_id}/{new_filename}"


class AvatarCloudinaryStorage(MediaCloudinaryStorage):
    """
    Custom storage for user profile avatars.
    
    Uploads avatars to the 'avatars' folder in Cloudinary.
    """
    
    @staticmethod
    def get_upload_path(instance, filename):
        """
        Generate upload path for avatars.
        
        Path format: avatars/{user_id}.{ext}
        """
        ext = filename.split('.')[-1].lower()
        
        # Get user ID
        user_id = uuid.uuid4().hex[:8]
        if hasattr(instance, 'id') and instance.id:
            user_id = str(instance.id)[:8]
        
        return f"avatars/{user_id}.{ext}"
