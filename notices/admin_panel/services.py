"""
Notice Admin Panel Services

Business logic for notice management by ministry admins and staff admins.
"""

import logging
from typing import Tuple, Dict, Any, Optional, TYPE_CHECKING
from django.db import transaction
from django.utils import timezone

from notices.models import Notice
from ministry.models import Ministry
from services.models import Service

if TYPE_CHECKING:
    from django.http import HttpRequest
    from authentication.models import CustomUser

logger = logging.getLogger(__name__)


class NoticeAdminService:
    """
    Service for notice management operations.
    Used by ministry admins and staff admins.
    """
    
    @staticmethod
    def get_notices_for_ministry(ministry_id: str, filters: Optional[Dict[str, Any]] = None, request=None) -> Tuple[bool, Dict[str, Any], int]:
        """
        Get notices for a specific ministry.
        
        Args:
            ministry_id: UUID of the ministry
            filters: Optional filters (service, status, search, etc.)
            request: HTTP request for building URLs
            
        Returns:
            Tuple of (success, response_data, status_code)
        """
        try:
            from notices.serializers import NoticeListSerializer
            
            queryset = Notice.objects.filter(
                ministry_id=ministry_id
            ).select_related('ministry', 'service', 'created_by').order_by('-created_at')
            
            # Apply filters
            if filters:
                if filters.get('service'):
                    queryset = queryset.filter(service_id=filters['service'])
                if filters.get('is_active') is not None:
                    queryset = queryset.filter(is_active=filters['is_active'])
                if filters.get('ingestion_status'):
                    queryset = queryset.filter(ingestion_status=filters['ingestion_status'])
                if filters.get('search'):
                    queryset = queryset.filter(title__icontains=filters['search'])
            
            serializer = NoticeListSerializer(
                queryset, 
                many=True, 
                context={'request': request}
            )
            
            return True, {
                'success': True,
                'data': serializer.data,
                'count': queryset.count()
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching notices for ministry {ministry_id}: {e}")
            return False, {
                'success': False,
                'error': 'Failed to fetch notices'
            }, 500
    
    @staticmethod
    def upload_notice(
        ministry_id: str,
        data: dict,
        uploaded_by,
        request=None
    ) -> Tuple[bool, dict, int]:
        """
        Upload a new notice for a ministry.
        
        Args:
            ministry_id: UUID of the ministry
            data: Notice data (title, service, file)
            uploaded_by: User uploading the notice
            request: HTTP request for building URLs
            
        Returns:
            Tuple of (success, response_data, status_code)
        """
        try:
            from notices.serializers import NoticeDetailSerializer
            
            # Validate ministry exists
            try:
                ministry = Ministry.objects.get(id=ministry_id, status=Ministry.Status.ACTIVE)
            except Ministry.DoesNotExist:
                return False, {
                    'success': False,
                    'error': 'Ministry not found or inactive'
                }, 404
            
            # Validate required fields
            title = data.get('title')
            file = data.get('file')
            
            if not title:
                return False, {
                    'success': False,
                    'error': 'Title is required'
                }, 400
            
            if not file:
                return False, {
                    'success': False,
                    'error': 'File is required'
                }, 400
            
            # Validate service if provided
            service_id = data.get('service')
            service = None
            if service_id:
                try:
                    service = Service.objects.get(
                        id=service_id, 
                        ministry_id=ministry_id,
                        is_active=True
                    )
                except Service.DoesNotExist:
                    return False, {
                        'success': False,
                        'error': 'Service not found or does not belong to this ministry'
                    }, 400
            
            # Create notice
            with transaction.atomic():
                notice = Notice.objects.create(
                    title=title,
                    ministry=ministry,
                    service=service,
                    file=file,
                    created_by=uploaded_by,
                    is_active=True
                )
                
                logger.info(f"Notice uploaded: {notice.id} by {uploaded_by.email} for ministry {ministry.name}")
            
            # Trigger RAG ingestion
            from rag_bridge.tasks import ingest_document
            ingest_document.delay(str(notice.id))  # type: ignore[attr-defined]
            
            serializer = NoticeDetailSerializer(notice, context={'request': request})
            
            return True, {
                'success': True,
                'message': 'Notice uploaded successfully. Document ingestion queued.',
                'data': serializer.data
            }, 201
            
        except Exception as e:
            logger.error(f"Error uploading notice: {e}")
            return False, {
                'success': False,
                'error': 'Failed to upload notice'
            }, 500
    
    @staticmethod
    def update_notice(
        notice_id: str,
        ministry_id: str,
        data: dict,
        updated_by,
        request=None
    ) -> Tuple[bool, dict, int]:
        """
        Update an existing notice.
        
        Args:
            notice_id: UUID of the notice
            ministry_id: UUID of the ministry (for verification)
            data: Updated data
            updated_by: User making the update
            request: HTTP request for building URLs
            
        Returns:
            Tuple of (success, response_data, status_code)
        """
        try:
            from notices.serializers import NoticeDetailSerializer
            
            # Get notice
            try:
                notice = Notice.objects.get(id=notice_id, ministry_id=ministry_id)
            except Notice.DoesNotExist:
                return False, {
                    'success': False,
                    'error': 'Notice not found'
                }, 404
            
            # Update fields
            if 'title' in data:
                notice.title = data['title']
            if 'is_active' in data:
                notice.is_active = data['is_active']
            if 'service' in data:
                if data['service']:
                    try:
                        service = Service.objects.get(
                            id=data['service'],
                            ministry_id=ministry_id,
                            is_active=True
                        )
                        notice.service = service  # type: ignore[assignment]
                    except Service.DoesNotExist:
                        return False, {
                            'success': False,
                            'error': 'Service not found'
                        }, 400
                else:
                    notice.service = None
            
            notice.save()
            logger.info(f"Notice updated: {notice.id} by {updated_by.email}")
            
            serializer = NoticeDetailSerializer(notice, context={'request': request})
            
            return True, {
                'success': True,
                'message': 'Notice updated successfully',
                'data': serializer.data
            }, 200
            
        except Exception as e:
            logger.error(f"Error updating notice: {e}")
            return False, {
                'success': False,
                'error': 'Failed to update notice'
            }, 500
    
    @staticmethod
    def delete_notice(
        notice_id: str,
        ministry_id: str,
        deleted_by
    ) -> Tuple[bool, dict, int]:
        """
        Soft delete a notice.
        
        Args:
            notice_id: UUID of the notice
            ministry_id: UUID of the ministry (for verification)
            deleted_by: User deleting the notice
            
        Returns:
            Tuple of (success, response_data, status_code)
        """
        try:
            # Get notice
            try:
                notice = Notice.objects.get(id=notice_id, ministry_id=ministry_id)
            except Notice.DoesNotExist:
                return False, {
                    'success': False,
                    'error': 'Notice not found'
                }, 404
            
            # Soft delete
            notice.is_active = False
            notice.save(update_fields=['is_active', 'updated_at'])
            
            logger.info(f"Notice deactivated: {notice.id} by {deleted_by.email}")
            
            return True, {
                'success': True,
                'message': 'Notice deleted successfully'
            }, 200
            
        except Exception as e:
            logger.error(f"Error deleting notice: {e}")
            return False, {
                'success': False,
                'error': 'Failed to delete notice'
            }, 500
    
    @staticmethod
    def get_notice_stats(ministry_id: str) -> Tuple[bool, dict, int]:
        """
        Get notice statistics for a ministry.
        
        Args:
            ministry_id: UUID of the ministry
            
        Returns:
            Tuple of (success, response_data, status_code)
        """
        try:
            from django.db.models import Count
            
            notices = Notice.objects.filter(ministry_id=ministry_id)
            
            stats = {
                'total': notices.count(),
                'active': notices.filter(is_active=True).count(),
                'inactive': notices.filter(is_active=False).count(),
                'pending_ingestion': notices.filter(
                    ingestion_status=Notice.IngestionStatus.PENDING
                ).count(),
                'processing': notices.filter(
                    ingestion_status=Notice.IngestionStatus.PROCESSING
                ).count(),
                'completed': notices.filter(
                    ingestion_status=Notice.IngestionStatus.COMPLETED
                ).count(),
                'failed': notices.filter(
                    ingestion_status=Notice.IngestionStatus.FAILED
                ).count(),
            }
            
            # Get notices by service
            by_service = notices.filter(is_active=True).values(
                'service__id', 'service__name'
            ).annotate(count=Count('id')).order_by('-count')[:10]
            
            result_stats: Dict[str, Any] = {
                **stats,
                'by_service': list(by_service)
            }
            
            return True, {
                'success': True,
                'data': result_stats
            }, 200
            
        except Exception as e:
            logger.error(f"Error getting notice stats: {e}")
            return False, {
                'success': False,
                'error': 'Failed to get statistics'
            }, 500
    
    @staticmethod
    def retry_ingestion(notice_id: str, ministry_id: str) -> Tuple[bool, dict, int]:
        """
        Retry RAG ingestion for a failed notice.
        
        Args:
            notice_id: UUID of the notice
            ministry_id: UUID of the ministry (for verification)
            
        Returns:
            Tuple of (success, response_data, status_code)
        """
        try:
            # Get notice
            try:
                notice = Notice.objects.get(id=notice_id, ministry_id=ministry_id)
            except Notice.DoesNotExist:
                return False, {
                    'success': False,
                    'error': 'Notice not found'
                }, 404
            
            if notice.ingestion_status == Notice.IngestionStatus.COMPLETED:
                return False, {
                    'success': False,
                    'error': 'Notice already ingested successfully'
                }, 400
            
            # Reset status and trigger ingestion
            notice.ingestion_status = Notice.IngestionStatus.PENDING
            notice.ingestion_error = ''
            notice.save(update_fields=['ingestion_status', 'ingestion_error', 'updated_at'])
            
            from rag_bridge.tasks import ingest_document
            ingest_document.delay(str(notice.id))  # type: ignore[attr-defined]
            
            logger.info(f"Retry ingestion queued for notice: {notice.id}")
            
            return True, {
                'success': True,
                'message': 'Ingestion retry queued'
            }, 200
            
        except Exception as e:
            logger.error(f"Error retrying ingestion: {e}")
            return False, {
                'success': False,
                'error': 'Failed to retry ingestion'
            }, 500
    
    @staticmethod
    def upload_notice_as_staff(
        staff,
        data: dict,
        request=None
    ) -> Tuple[bool, dict, int]:
        """
        Upload a notice as a staff admin.
        
        Staff admin uploads notice with:
        - ministry: auto-set from staff's service.ministry or staff service
        - service: auto-set from staff's assigned service
        
        Args:
            staff: Staff object (staff_profile model) OR StaffService object (direct staff login)
            data: Notice data (title, file only - ministry/service auto-set)
            request: HTTP request for building URLs
            
        Returns:
            Tuple of (success, response_data, status_code)
        """
        try:
            from notices.serializers import NoticeDetailSerializer
            from ministry.models import StaffService
            
            # Determine if staff is StaffService (direct login) or Staff (staff_profile)
            is_staff_service = isinstance(staff, StaffService)
            
            if is_staff_service:
                # StaffService: ministry is direct attribute, service lookup by service_name
                ministry = staff.ministry
                # Find the corresponding Service object
                from services.models import Service
                service = Service.objects.filter(
                    ministry=ministry,
                    name=staff.service_name,
                    is_active=True
                ).first()
                if not service:
                    return False, {
                        'success': False,
                        'error': f'Service "{staff.service_name}" not found in ministry'
                    }, 400
                created_by_user = None  # StaffService doesn't have a user field
            else:
                # Staff model: has service and service.ministry
                service = staff.service
                ministry = service.ministry
                created_by_user = staff.user
            
            # Validate required fields
            title = data.get('title')
            file = data.get('file')
            
            if not title:
                return False, {
                    'success': False,
                    'error': 'Title is required'
                }, 400
            
            if not file:
                return False, {
                    'success': False,
                    'error': 'File is required'
                }, 400
            
            # Create notice with staff's ministry and service
            with transaction.atomic():
                notice = Notice.objects.create(
                    title=title,
                    ministry=ministry,
                    service=service,
                    file=file,
                    created_by=created_by_user,  # May be None for StaffService
                    is_active=True
                )
                
                staff_identifier = staff.email if is_staff_service else staff.user.email
                logger.info(
                    f"Notice uploaded by staff: {notice.id} by {staff_identifier} "
                    f"for ministry {ministry.name}, service {service.name}"
                )
            
            # Trigger RAG ingestion
            from rag_bridge.tasks import ingest_document
            ingest_document.delay(str(notice.id))  # type: ignore[attr-defined]
            
            serializer = NoticeDetailSerializer(notice, context={'request': request})
            
            return True, {
                'success': True,
                'message': 'Notice uploaded successfully. Document ingestion queued.',
                'data': serializer.data
            }, 201
            
        except Exception as e:
            logger.error(f"Error uploading notice as staff: {e}")
            return False, {
                'success': False,
                'error': 'Failed to upload notice'
            }, 500
    
    @staticmethod
    def get_notices_for_staff(staff, filters: Optional[Dict[str, Any]] = None, request=None) -> Tuple[bool, Dict[str, Any], int]:
        """
        Get notices for a staff admin (only notices for their service).
        
        Args:
            staff: Staff object
            filters: Optional filters (is_active, ingestion_status, search)
            request: HTTP request for building URLs
            
        Returns:
            Tuple of (success, response_data, status_code)
        """
        try:
            from notices.serializers import NoticeListSerializer
            
            service = staff.service
            ministry = service.ministry
            
            # Staff can see notices for their service only
            queryset = Notice.objects.filter(
                ministry=ministry,
                service=service
            ).select_related('ministry', 'service', 'created_by').order_by('-created_at')
            
            # Apply filters
            if filters:
                if filters.get('is_active') is not None:
                    queryset = queryset.filter(is_active=filters['is_active'])
                if filters.get('ingestion_status'):
                    queryset = queryset.filter(ingestion_status=filters['ingestion_status'])
                if filters.get('search'):
                    queryset = queryset.filter(title__icontains=filters['search'])
            
            serializer = NoticeListSerializer(
                queryset, 
                many=True, 
                context={'request': request}
            )
            
            return True, {
                'success': True,
                'data': serializer.data,
                'count': queryset.count(),
                'service': {
                    'id': str(service.id),
                    'name': service.name
                },
                'ministry': {
                    'id': str(ministry.id),
                    'name': ministry.name
                }
            }, 200
            
        except Exception as e:
            logger.error(f"Error fetching notices for staff: {e}")
            return False, {
                'success': False,
                'error': 'Failed to fetch notices'
            }, 500
