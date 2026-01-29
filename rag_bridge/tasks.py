"""
RAG Tasks - Celery tasks for async document ingestion

When a notice is uploaded, this task:
1. Fetches the Notice from DB
2. Extracts file_url, ministry_name, service_name
3. Sends to FastAPI RAG server for processing
"""
import logging
from celery import shared_task
from django.conf import settings

logger = logging.getLogger(__name__)


def get_absolute_file_url(file_field):
    """
    Convert file field URL to absolute URL that external services can access.
    
    Handles:
    - Cloudinary URLs (already absolute, start with http)
    - Local media URLs (need to prepend BASE_URL)
    """
    if not file_field:
        return None
    
    file_url = file_field.url
    
    # If already absolute URL (Cloudinary or other CDN), return as-is
    if file_url.startswith('http://') or file_url.startswith('https://'):
        return file_url
    
    # For local storage, construct absolute URL from BASE_URL setting
    # BASE_URL should be set in .env (e.g., http://192.168.1.118:8000)
    base_url = getattr(settings, 'BASE_URL', 'http://localhost:8000')
    
    # Remove trailing slash from base_url and leading slash from file_url
    base_url = base_url.rstrip('/')
    file_url = file_url if file_url.startswith('/') else '/' + file_url
    
    return f"{base_url}{file_url}"


@shared_task(
    name='rag_bridge.tasks.ingest_document',
    bind=True,
    autoretry_for=(Exception,),
    retry_kwargs={'max_retries': 3},
    retry_backoff=True
)
def ingest_document(self, notice_id: str):
    """
    Fetch notice and send to FastAPI RAG server for ingestion.
    
    Args:
        notice_id: UUID of the notice to ingest
    
    The task:
    1. Fetches Notice from database
    2. Extracts file URL, ministry name, service name
    3. Sends to FastAPI /ingest endpoint
    4. Updates notice ingestion_status
    """
    from notices.models import Notice
    from .services import send_file
    
    try:
        # Fetch notice with related ministry and service
        notice = Notice.objects.select_related('ministry', 'service').get(id=notice_id)
        
        # Update status to processing
        notice.ingestion_status = Notice.IngestionStatus.PROCESSING
        notice.save(update_fields=['ingestion_status', 'updated_at'])
        
        # Build absolute file URL for external access
        file_url = get_absolute_file_url(notice.file)
        if not file_url:
            raise ValueError("Notice has no file attached")
        
        # Extract notice metadata
        title = notice.title
        ministry_name = notice.ministry.name if notice.ministry else None
        service_name = notice.service.name if notice.service else None
        
        logger.info(
            f"Ingesting notice {notice_id}: "
            f"title={title}, ministry={ministry_name}, service={service_name}"
        )
        
        # Send to FastAPI
        # ministry_name: always sent (notice must belong to a ministry)
        # service_name: sent only if notice is linked to a specific service
        #   - Ministry Admin: uploads notice for ministry, optionally links to service
        #   - Staff Admin: uploads notice for their assigned service (under their ministry)
        result = send_file(
            file_url=file_url,
            notice_id=str(notice_id),
            title=title,
            ministry_name=ministry_name,
            service_name=service_name
        )
        
        # Check result and update status
        if result.get('success') or result.get('status') == 'ok':
            notice.ingestion_status = Notice.IngestionStatus.COMPLETED
            notice.ingestion_error = ''
            logger.info(f"Notice {notice_id} ingestion completed successfully")
        else:
            error_msg = result.get('error', result.get('message', 'Unknown error'))
            notice.ingestion_status = Notice.IngestionStatus.FAILED
            notice.ingestion_error = str(error_msg)
            logger.error(f"Notice {notice_id} ingestion failed: {error_msg}")
        
        notice.save(update_fields=['ingestion_status', 'ingestion_error', 'updated_at'])
        
        return result
        
    except Notice.DoesNotExist:
        logger.error(f"Notice {notice_id} not found for ingestion")
        return {"error": "notice_not_found"}
        
    except Exception as e:
        logger.error(f"Ingestion task failed for notice {notice_id}: {str(e)}")
        
        # Update notice status on failure
        try:
            notice = Notice.objects.get(id=notice_id)
            notice.ingestion_status = Notice.IngestionStatus.FAILED
            notice.ingestion_error = str(e)
            notice.save(update_fields=['ingestion_status', 'ingestion_error', 'updated_at'])
        except:
            pass
        
        raise  # Re-raise for Celery retry
