"""
Citizen API - Service Layer

Optimized data fetching with:
1. Single query with select_related/prefetch_related
2. Redis caching for static/semi-static data
3. Pre-computed availability status
4. Batch operations for related data

Cache Strategy:
- Ministries list: 5 minutes (changes rarely)
- Services list: 2 minutes (availability changes)
- Service details: 1 minute (queue status changes)
- My tokens: No cache (real-time data)

Query Optimization:
- Use .only() to select specific fields
- Use .defer() to exclude large fields
- Use prefetch_related with Prefetch objects for filtered relations
"""
import logging
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Optional, Tuple, List, Dict, Any
from collections import OrderedDict

from django.db import models
from django.db.models import Count, Q, Prefetch, F, Value, CharField
from django.db.models.functions import Concat
from django.core.cache import cache
from django.conf import settings

from ministry.models import Ministry, StaffService
from officials.models import MinistryOfficial
from queue_management.models import (
    QueueConfiguration,
    DailyQueue,
    QueueToken,
    ServiceProgressStep,
    TokenProgress
)
from attendance.models import AttendanceRecord
from holidays.models import Holiday
from places.models import Place
from core.utils.nepal_time import (
    get_nepal_today,
    get_nepal_now,
    is_saturday,
    nepal_datetime_combine
)

logger = logging.getLogger(__name__)


# =============================================================================
# CACHE KEYS & TTL
# =============================================================================

class CacheKeys:
    """Standardized cache key patterns"""
    MINISTRIES_BY_PLACE = "citizen:ministries:place:{place_id}"
    SERVICES_BY_MINISTRY = "citizen:services:ministry:{ministry_id}"
    SERVICE_DETAILS = "citizen:service:{service_id}"
    TODAY_HOLIDAY = "citizen:holiday:{date}"
    QUEUE_STATS = "citizen:queue_stats:{service_id}:{date}"


class CacheTTL:
    """Cache time-to-live in seconds"""
    MINISTRIES = 300      # 5 minutes
    SERVICES = 120        # 2 minutes  
    SERVICE_DETAILS = 60  # 1 minute
    HOLIDAY = 3600        # 1 hour
    QUEUE_STATS = 30      # 30 seconds


# =============================================================================
# CITIZEN API SERVICE
# =============================================================================

class CitizenAPIService:
    """
    Optimized service layer for citizen Flutter app.
    All methods return: (success: bool, data: dict, status_code: int)
    """
    
    # -------------------------------------------------------------------------
    # PHASE 1: MINISTRIES BY PLACE
    # -------------------------------------------------------------------------
    
    @staticmethod
    def get_ministries_by_place(
        place_identifier: str,
        cursor: Optional[str] = None,
        page_size: int = 20,
        request=None
    ) -> Tuple[bool, Dict, int]:
        """
        Get ministries in a place with pagination.
        
        Optimizations:
        - Single query with annotated services count
        - Redis cache for 5 minutes
        - Cursor pagination for infinite scroll
        
        Args:
            place_identifier: UUID, slug, or numeric ID
            cursor: Pagination cursor
            page_size: Items per page (max 50)
            request: Django request for URL building
            
        Returns:
            (success, response_data, status_code)
        """
        try:
            # Resolve place
            place = CitizenAPIService._resolve_place(place_identifier)
            if not place:
                return False, {"error": "Place not found"}, 404
            
            # Check cache
            cache_key = CacheKeys.MINISTRIES_BY_PLACE.format(place_id=place.id)
            cached_data = cache.get(cache_key)
            
            if cached_data and not cursor:
                # Return cached first page
                return True, {"data": cached_data}, 200
            
            # Query ministries with optimizations
            ministries_qs = Ministry.objects.filter(
                place=place,
                status=Ministry.Status.ACTIVE,
                is_deleted=False
            ).annotate(
                services_count=Count(
                    'staff_services',
                    filter=Q(
                        staff_services__is_active=True,
                        staff_services__status='active'
                    )
                )
            ).only(
                'id', 'name', 'slug', 'logo', 'address', 'phone'
            ).order_by('name')
            
            # Apply cursor pagination
            if cursor:
                ministries_qs = CitizenAPIService._apply_cursor(
                    ministries_qs, cursor, 'name'
                )
            
            # Fetch with limit + 1 for has_more check
            ministries = list(ministries_qs[:page_size + 1])
            has_more = len(ministries) > page_size
            if has_more:
                ministries = ministries[:page_size]
            
            # Build response
            items = []
            for ministry in ministries:
                items.append({
                    "id": str(ministry.id),
                    "name": ministry.name,
                    "slug": ministry.slug,
                    "logo_url": CitizenAPIService._build_url(
                        ministry.logo, request
                    ),
                    "services_count": ministry.services_count,
                    "address": ministry.address,
                    "phone": ministry.phone
                })
            
            response_data = {
                "items": items,
                "pagination": {
                    "next_cursor": CitizenAPIService._encode_cursor(
                        ministries[-1].name
                    ) if has_more else None,
                    "has_more": has_more,
                    "total_estimate": ministries_qs.count()
                },
                "place": {
                    "id": str(place.id),
                    "name": place.name,
                    "slug": place.slug
                }
            }
            
            # Cache first page only
            if not cursor:
                cache.set(cache_key, response_data, CacheTTL.MINISTRIES)
            
            return True, {"data": response_data}, 200
            
        except Exception as e:
            logger.error(f"Error fetching ministries: {str(e)}")
            return False, {"error": "Failed to fetch ministries"}, 500
    
    # -------------------------------------------------------------------------
    # PHASE 2: SERVICES BY MINISTRY
    # -------------------------------------------------------------------------
    
    @staticmethod
    def get_services_by_ministry(
        ministry_identifier: str,
        cursor: Optional[str] = None,
        page_size: int = 20,
        request=None
    ) -> Tuple[bool, Dict, int]:
        """
        Get services in a ministry with availability status.
        
        Optimizations:
        - Single query with prefetched queue_config
        - Pre-computed availability in one pass
        - Redis cache for 2 minutes
        
        Args:
            ministry_identifier: UUID or slug
            cursor: Pagination cursor
            page_size: Items per page (max 50)
            request: Django request for URL building
        """
        try:
            # Resolve ministry
            ministry = CitizenAPIService._resolve_ministry(ministry_identifier)
            if not ministry:
                return False, {"error": "Ministry not found"}, 404
            
            today = get_nepal_today()
            
            # Query services with related data in single query
            services_qs = StaffService.objects.filter(
                ministry=ministry,
                is_active=True,
                status='active'
            ).select_related(
                'queue_config'
            ).prefetch_related(
                Prefetch(
                    'attendance_records',
                    queryset=AttendanceRecord.objects.filter(
                        date=today,
                        person_type=AttendanceRecord.PersonType.STAFF
                    ),
                    to_attr='today_attendance'
                )
            ).order_by('service_name')
            
            # Apply cursor
            if cursor:
                services_qs = CitizenAPIService._apply_cursor(
                    services_qs, cursor, 'service_name'
                )
            
            # Fetch
            services = list(services_qs[:page_size + 1])
            has_more = len(services) > page_size
            if has_more:
                services = services[:page_size]
            
            # Check holiday once for all services
            is_holiday, holiday_name = CitizenAPIService._check_holiday(today)
            is_saturday_today = is_saturday(today)
            
            # Get queue stats in batch
            service_ids = [s.id for s in services]
            queue_stats = CitizenAPIService._get_batch_queue_stats(
                service_ids, today
            )
            
            # Build response
            items = []
            for service in services:
                availability = CitizenAPIService._compute_availability(
                    service, 
                    is_holiday, 
                    holiday_name,
                    is_saturday_today
                )
                
                stats = queue_stats.get(str(service.id), {})
                
                items.append({
                    "id": str(service.id),
                    "service_name": service.service_name,
                    "service_logo_url": CitizenAPIService._build_url(
                        service.service_logo, request
                    ),
                    "staff_name": service.staff_name,
                    "staff_image_url": CitizenAPIService._build_url(
                        service.staff_image, request
                    ),
                    "is_available_today": availability["available"],
                    "availability_reason": availability["reason"],
                    "availability_code": availability["code"],
                    "tokens_available": stats.get("available", 0),
                    "current_queue_position": stats.get("current", None)
                })
            
            response_data = {
                "items": items,
                "pagination": {
                    "next_cursor": CitizenAPIService._encode_cursor(
                        services[-1].service_name
                    ) if has_more else None,
                    "has_more": has_more,
                    "total_estimate": services_qs.count()
                },
                "ministry": {
                    "id": str(ministry.id),
                    "name": ministry.name,
                    "slug": ministry.slug
                }
            }
            
            return True, {"data": response_data}, 200
            
        except Exception as e:
            logger.error(f"Error fetching services: {str(e)}")
            return False, {"error": "Failed to fetch services"}, 500
    
    # -------------------------------------------------------------------------
    # PHASE 3: SERVICE DETAILS
    # -------------------------------------------------------------------------
    
    @staticmethod
    def get_service_details(
        service_id: str,
        request=None
    ) -> Tuple[bool, Dict, int]:
        """
        Get complete service details for booking screen.
        
        Optimizations:
        - Single query with all related data
        - Pre-computed availability and queue stats
        - Redis cache for 1 minute
        """
        try:
            # Check cache
            cache_key = CacheKeys.SERVICE_DETAILS.format(service_id=service_id)
            cached = cache.get(cache_key)
            if cached:
                return True, {"data": cached}, 200
            
            today = get_nepal_today()
            
            # Get service with all related data in single query
            try:
                service = StaffService.objects.select_related(
                    'ministry',
                    'queue_config'
                ).prefetch_related(
                    Prefetch(
                        'queue_config__higher_officials',
                        queryset=MinistryOfficial.objects.filter(
                            is_active=True
                        ).only('id', 'name', 'role'),
                        to_attr='active_officials'
                    ),
                    Prefetch(
                        'queue_config__progress_steps',
                        queryset=ServiceProgressStep.objects.order_by('step_order'),
                        to_attr='ordered_steps'
                    ),
                    Prefetch(
                        'attendance_records',
                        queryset=AttendanceRecord.objects.filter(
                            date=today,
                            person_type=AttendanceRecord.PersonType.STAFF
                        ),
                        to_attr='today_attendance'
                    )
                ).get(id=service_id)
            except StaffService.DoesNotExist:
                return False, {"error": "Service not found"}, 404
            
            # Check queue config
            if not hasattr(service, 'queue_config') or not service.queue_config:
                return False, {
                    "error": "Queue not configured for this service"
                }, 400
            
            qc = service.queue_config
            
            # Get officials attendance
            official_ids = [o.id for o in qc.active_officials]
            officials_attendance = {}
            if official_ids:
                attendance_qs = AttendanceRecord.objects.filter(
                    official_id__in=official_ids,
                    date=today,
                    person_type=AttendanceRecord.PersonType.OFFICIAL
                ).values('official_id', 'status')
                officials_attendance = {
                    str(a['official_id']): a['status'] 
                    for a in attendance_qs
                }
            
            # Compute availability
            is_holiday, holiday_name = CitizenAPIService._check_holiday(today)
            is_saturday_today = is_saturday(today)
            availability = CitizenAPIService._compute_full_availability(
                service, qc, is_holiday, holiday_name, is_saturday_today, today
            )
            
            # Build response
            response_data = {
                "id": str(service.id),
                "service_name": service.service_name,
                "service_logo_url": CitizenAPIService._build_url(
                    service.service_logo, request
                ),
                "staff_name": service.staff_name,
                "staff_image_url": CitizenAPIService._build_url(
                    service.staff_image, request
                ),
                "ministry_name": service.ministry.name,
                "ministry_id": str(service.ministry.id),
                
                # Office hours
                "office_hours": CitizenAPIService._format_time_range(
                    qc.office_start_time, qc.office_end_time
                ),
                "lunch_break": CitizenAPIService._format_time_range(
                    qc.lunch_start_time, qc.lunch_end_time
                ) if qc.lunch_start_time else None,
                
                # Service time
                "avg_service_time": f"{qc.average_service_time_minutes} minutes",
                "daily_capacity": qc.calculate_daily_capacity(),
                
                # Booking options
                "booking_options": {
                    "regular": {"enabled": True},
                    "prebook": {
                        "enabled": qc.prebooking_allowed,
                        "lead_hours": qc.prebooking_lead_hours,
                        "quota": qc.prebooking_quota_per_day
                    } if qc.prebooking_allowed else {"enabled": False},
                    "emergency": {
                        "enabled": qc.emergency_allowed,
                        "fee": str(qc.emergency_fee or 0),
                        "quota": qc.emergency_quota_per_day
                    } if qc.emergency_allowed else {"enabled": False}
                },
                
                # Documents
                "documents": qc.documents_required or [],
                
                # Availability
                "is_available_today": availability["available"],
                "availability": availability,
                
                # Progress
                "progress_enabled": qc.enable_progress_tracking,
                "progress_steps": [
                    {"step_order": s.step_order, "title": s.title}
                    for s in qc.ordered_steps
                ] if qc.enable_progress_tracking else [],
                
                # Officials
                "officials": [
                    {
                        "id": str(o.id),
                        "name": o.name,
                        "role": o.role,
                        "is_present": officials_attendance.get(
                            str(o.id), 'PRESENT'
                        ) == 'PRESENT'
                    }
                    for o in qc.active_officials
                ]
            }
            
            # Cache
            cache.set(cache_key, response_data, CacheTTL.SERVICE_DETAILS)
            
            return True, {"data": response_data}, 200
            
        except Exception as e:
            logger.error(f"Error fetching service details: {str(e)}")
            return False, {"error": "Failed to fetch service details"}, 500
    
    # -------------------------------------------------------------------------
    # PHASE 4: MY TOKENS
    # -------------------------------------------------------------------------
    
    @staticmethod
    def get_my_tokens(
        user,
        status_filter: Optional[str] = None,
        cursor: Optional[str] = None,
        page_size: int = 20,
        request=None
    ) -> Tuple[bool, Dict, int]:
        """
        Get user's tokens with queue position and progress.
        
        No caching - real-time data required.
        
        Args:
            user: Authenticated user
            status_filter: Optional filter (ACTIVE, COMPLETED, CANCELLED)
            cursor: Pagination cursor (by created_at)
            page_size: Items per page
        """
        try:
            today = get_nepal_today()
            
            # Build query
            tokens_qs = QueueToken.objects.filter(
                citizen=user
            ).select_related(
                'daily_queue__queue_config__staff_service__ministry'
            ).prefetch_related(
                Prefetch(
                    'progress_records',
                    queryset=TokenProgress.objects.select_related(
                        'step'
                    ).order_by('step__step_order'),
                    to_attr='progress_list'
                )
            ).order_by('-created_at')
            
            # Apply status filter
            if status_filter:
                if status_filter == 'ACTIVE':
                    tokens_qs = tokens_qs.filter(
                        status__in=['WAITING', 'IN_SERVICE', 'PENDING']
                    )
                elif status_filter == 'COMPLETED':
                    tokens_qs = tokens_qs.filter(status='COMPLETED')
                elif status_filter == 'CANCELLED':
                    tokens_qs = tokens_qs.filter(status='CANCELLED')
            
            # Apply cursor (by created_at descending)
            if cursor:
                from datetime import datetime
                cursor_dt = datetime.fromisoformat(cursor)
                tokens_qs = tokens_qs.filter(created_at__lt=cursor_dt)
            
            # Fetch
            tokens = list(tokens_qs[:page_size + 1])
            has_more = len(tokens) > page_size
            if has_more:
                tokens = tokens[:page_size]
            
            # Get queue positions for waiting tokens
            waiting_token_ids = [
                t.id for t in tokens if t.status == 'WAITING'
            ]
            queue_positions = CitizenAPIService._get_queue_positions(
                waiting_token_ids
            )
            
            # Build response
            items = []
            for token in tokens:
                qc = token.daily_queue.queue_config
                service = qc.staff_service
                
                # Progress
                progress_data = None
                if qc.enable_progress_tracking and hasattr(token, 'progress_list'):
                    completed = sum(1 for p in token.progress_list if p.completed)
                    total = len(token.progress_list)
                    current_step = None
                    for p in token.progress_list:
                        if not p.completed:
                            current_step = p.step.title
                            break
                    
                    progress_data = {
                        "total_steps": total,
                        "completed_steps": completed,
                        "current_step": current_step,
                        "steps": [
                            {"title": p.step.title, "completed": p.completed}
                            for p in token.progress_list
                        ]
                    }
                
                # Queue position
                position = queue_positions.get(str(token.id))
                estimated_wait = None
                estimated_time = None
                if position:
                    wait_minutes = position * qc.average_service_time_minutes
                    estimated_wait = f"{wait_minutes} minutes"
                    from core.utils.nepal_time import get_nepal_now
                    est_time = get_nepal_now() + timedelta(minutes=wait_minutes)
                    estimated_time = est_time.strftime("%I:%M %p")
                
                items.append({
                    "id": str(token.id),
                    "token_number": token.token_number,
                    "booking_type": token.booking_type,
                    "status": token.status,
                    "service_name": service.service_name,
                    "service_logo_url": CitizenAPIService._build_url(
                        service.service_logo, request
                    ),
                    "ministry_name": service.ministry.name,
                    "queue_position": position,
                    "estimated_time": estimated_time,
                    "estimated_wait": estimated_wait,
                    "booking_date": token.daily_queue.date.isoformat(),
                    "created_at": token.created_at.isoformat(),
                    "progress": progress_data
                })
            
            response_data = {
                "items": items,
                "pagination": {
                    "next_cursor": tokens[-1].created_at.isoformat() if has_more else None,
                    "has_more": has_more
                }
            }
            
            return True, {"data": response_data}, 200
            
        except Exception as e:
            logger.error(f"Error fetching user tokens: {str(e)}")
            return False, {"error": "Failed to fetch tokens"}, 500
    
    # -------------------------------------------------------------------------
    # HELPER METHODS
    # -------------------------------------------------------------------------
    
    @staticmethod
    def _resolve_place(identifier: str) -> Optional[Place]:
        """Resolve place by UUID, slug, or numeric ID"""
        try:
            # Try UUID
            import uuid
            try:
                place_uuid = uuid.UUID(identifier)
                return Place.objects.filter(id=place_uuid).first()
            except ValueError:
                pass
            
            # Try slug
            place = Place.objects.filter(slug=identifier).first()
            if place:
                return place
            
            # Try numeric ID (1-indexed order)
            try:
                idx = int(identifier) - 1
                if idx >= 0:
                    places = list(Place.objects.order_by('name')[:idx + 1])
                    if len(places) > idx:
                        return places[idx]
            except ValueError:
                pass
            
            return None
        except Exception:
            return None
    
    @staticmethod
    def _resolve_ministry(identifier: str) -> Optional[Ministry]:
        """Resolve ministry by UUID or slug"""
        try:
            import uuid
            try:
                ministry_uuid = uuid.UUID(identifier)
                return Ministry.objects.filter(
                    id=ministry_uuid,
                    status=Ministry.Status.ACTIVE,
                    is_deleted=False
                ).first()
            except ValueError:
                pass
            
            return Ministry.objects.filter(
                slug=identifier,
                status=Ministry.Status.ACTIVE,
                is_deleted=False
            ).first()
        except Exception:
            return None
    
    @staticmethod
    def _check_holiday(date) -> Tuple[bool, Optional[str]]:
        """Check if date is a holiday (cached)"""
        cache_key = CacheKeys.TODAY_HOLIDAY.format(date=date.isoformat())
        cached = cache.get(cache_key)
        
        if cached is not None:
            return cached
        
        holiday = Holiday.objects.filter(date=date).first()
        result = (True, holiday.name) if holiday else (False, None)
        
        cache.set(cache_key, result, CacheTTL.HOLIDAY)
        return result
    
    @staticmethod
    def _compute_availability(
        service: StaffService,
        is_holiday: bool,
        holiday_name: Optional[str],
        is_saturday_today: bool
    ) -> Dict:
        """Compute availability status for a service"""
        # Check queue config
        if not hasattr(service, 'queue_config') or not service.queue_config:
            return {
                "available": False,
                "reason": "Queue not configured",
                "code": "NO_QUEUE_CONFIG"
            }
        
        if not service.queue_config.active:
            return {
                "available": False,
                "reason": "Queue is inactive",
                "code": "QUEUE_INACTIVE"
            }
        
        # Check Saturday
        if is_saturday_today:
            return {
                "available": False,
                "reason": "Saturday (Weekend)",
                "code": "SATURDAY"
            }
        
        # Check holiday
        if is_holiday:
            return {
                "available": False,
                "reason": f"Holiday: {holiday_name}",
                "code": "HOLIDAY"
            }
        
        # Check staff attendance
        if hasattr(service, 'today_attendance') and service.today_attendance:
            attendance = service.today_attendance[0]
            if attendance.status == AttendanceRecord.Status.ABSENT:
                return {
                    "available": False,
                    "reason": "Staff absent today",
                    "code": "STAFF_ABSENT"
                }
        
        return {
            "available": True,
            "reason": "Service available",
            "code": "AVAILABLE"
        }
    
    @staticmethod
    def _compute_full_availability(
        service: StaffService,
        qc: QueueConfiguration,
        is_holiday: bool,
        holiday_name: Optional[str],
        is_saturday_today: bool,
        today
    ) -> Dict:
        """Compute full availability with queue stats"""
        base = CitizenAPIService._compute_availability(
            service, is_holiday, holiday_name, is_saturday_today
        )
        
        # Add queue stats
        daily_queue = DailyQueue.objects.filter(
            queue_config=qc,
            date=today
        ).first()
        
        tokens_booked = 0
        current_token = None
        
        if daily_queue:
            tokens_booked = QueueToken.objects.filter(
                daily_queue=daily_queue,
                status__in=['WAITING', 'IN_SERVICE', 'PENDING']
            ).count()
            
            current = QueueToken.objects.filter(
                daily_queue=daily_queue,
                status='IN_SERVICE'
            ).first()
            current_token = current.token_number if current else None
        
        capacity = qc.calculate_daily_capacity()
        tokens_available = max(0, capacity - tokens_booked)
        
        # Estimated wait
        estimated_wait = None
        if tokens_booked > 0:
            wait_minutes = tokens_booked * qc.average_service_time_minutes
            if wait_minutes < 60:
                estimated_wait = f"{wait_minutes} minutes"
            else:
                hours = wait_minutes // 60
                mins = wait_minutes % 60
                estimated_wait = f"{hours}h {mins}m"
        
        base.update({
            "tokens_available": tokens_available,
            "tokens_booked": tokens_booked,
            "current_token": current_token,
            "estimated_wait": estimated_wait
        })
        
        return base
    
    @staticmethod
    def _get_batch_queue_stats(
        service_ids: List[str],
        date
    ) -> Dict[str, Dict]:
        """Get queue stats for multiple services in one query"""
        stats = {}
        
        # Get all daily queues
        daily_queues = DailyQueue.objects.filter(
            queue_config__staff_service_id__in=service_ids,
            date=date
        ).select_related('queue_config')
        
        queue_map = {
            str(dq.queue_config.staff_service_id): dq 
            for dq in daily_queues
        }
        
        # Get token counts in batch
        for service_id in service_ids:
            dq = queue_map.get(service_id)
            if dq:
                capacity = dq.queue_config.calculate_daily_capacity()
                booked = QueueToken.objects.filter(
                    daily_queue=dq,
                    status__in=['WAITING', 'IN_SERVICE', 'PENDING']
                ).count()
                
                current = QueueToken.objects.filter(
                    daily_queue=dq,
                    status='IN_SERVICE'
                ).first()
                
                stats[service_id] = {
                    "available": max(0, capacity - booked),
                    "current": current.token_number if current else None
                }
            else:
                # No queue for today
                stats[service_id] = {"available": 0, "current": None}
        
        return stats
    
    @staticmethod
    def _get_queue_positions(token_ids: List) -> Dict[str, int]:
        """Get queue positions for multiple tokens"""
        positions = {}
        
        for token_id in token_ids:
            try:
                token = QueueToken.objects.select_related(
                    'daily_queue'
                ).get(id=token_id)
                
                # Count tokens ahead
                ahead = QueueToken.objects.filter(
                    daily_queue=token.daily_queue,
                    status='WAITING',
                    token_number__lt=token.token_number
                ).count()
                
                positions[str(token_id)] = ahead + 1
            except QueueToken.DoesNotExist:
                pass
        
        return positions
    
    @staticmethod
    def _format_time_range(start_time, end_time) -> str:
        """Format time range for display"""
        if not start_time or not end_time:
            return None
        return f"{start_time.strftime('%I:%M %p')} - {end_time.strftime('%I:%M %p')}"
    
    @staticmethod
    def _build_url(file_field, request) -> Optional[str]:
        """Build absolute URL for file field"""
        if not file_field:
            return None
        try:
            if request:
                return request.build_absolute_uri(file_field.url)
            return file_field.url
        except Exception:
            return None
    
    @staticmethod
    def _encode_cursor(value: str) -> str:
        """Encode cursor value"""
        import base64
        return base64.urlsafe_b64encode(str(value).encode()).decode()
    
    @staticmethod
    def _decode_cursor(cursor: str) -> str:
        """Decode cursor value"""
        import base64
        return base64.urlsafe_b64decode(cursor.encode()).decode()
    
    @staticmethod
    def _apply_cursor(queryset, cursor: str, field: str):
        """Apply cursor filter to queryset"""
        try:
            value = CitizenAPIService._decode_cursor(cursor)
            return queryset.filter(**{f'{field}__gt': value})
        except Exception:
            return queryset
