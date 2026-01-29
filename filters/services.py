"""
Filters App - Notice Filter Service

This app handles all filtering logic for notices, keeping it
isolated from the notices app for clean separation of concerns.

MVP Filters:
- ministry: Filter by ministry ID
- service: Filter by service ID

Future expansion can add more filters without modifying notices app.
"""

import logging
from typing import Any

logger = logging.getLogger(__name__)


class NoticeFilterService:
    """
    Service class for applying filters to notice queryset.
    
    Designed to be called from notices app views without
    the notices app needing to know filter implementation details.
    
    Usage:
        from filters.services import NoticeFilterService
        queryset = NoticeFilterService.apply(queryset, request.query_params)
    """
    
    # Mapping of filter parameter names to filter methods
    FILTER_MAPPING = {
        'ministry': '_filter_by_ministry',
        'service': '_filter_by_service',
        'search': '_filter_by_search',
        'file_type': '_filter_by_file_type',
        'date_from': '_filter_by_date_from',
        'date_to': '_filter_by_date_to',
    }
    
    @classmethod
    def apply(cls, queryset, params: dict) -> Any:
        """
        Apply all applicable filters to the queryset.
        
        Args:
            queryset: Django QuerySet of Notice objects
            params: Dictionary of filter parameters (e.g., request.query_params)
            
        Returns:
            Filtered QuerySet
        """
        if not params:
            return queryset
        
        for param_name, method_name in cls.FILTER_MAPPING.items():
            value = params.get(param_name)
            if value:
                filter_method = getattr(cls, method_name, None)
                if filter_method:
                    queryset = filter_method(queryset, value)
                    logger.debug(f"Applied filter {param_name}={value}")
        
        return queryset
    
    @staticmethod
    def _filter_by_ministry(queryset, ministry_id: str):
        """
        Filter notices by ministry ID.
        
        Args:
            queryset: Notice QuerySet
            ministry_id: UUID of the ministry
            
        Returns:
            Filtered QuerySet
        """
        try:
            return queryset.filter(ministry_id=ministry_id)
        except Exception as e:
            logger.warning(f"Invalid ministry filter value: {ministry_id} - {e}")
            return queryset
    
    @staticmethod
    def _filter_by_service(queryset, service_id: str):
        """
        Filter notices by service ID.
        
        Args:
            queryset: Notice QuerySet
            service_id: UUID of the service
            
        Returns:
            Filtered QuerySet
        """
        try:
            return queryset.filter(service_id=service_id)
        except Exception as e:
            logger.warning(f"Invalid service filter value: {service_id} - {e}")
            return queryset
    
    @staticmethod
    def _filter_by_search(queryset, search_term: str):
        """
        Search notices by title.
        
        Args:
            queryset: Notice QuerySet
            search_term: Text to search for in title
            
        Returns:
            Filtered QuerySet
        """
        if search_term and len(search_term) >= 2:
            return queryset.filter(title__icontains=search_term)
        return queryset
    
    @staticmethod
    def _filter_by_file_type(queryset, file_type: str):
        """
        Filter notices by file type (pdf, png, jpg, jpeg).
        
        Args:
            queryset: Notice QuerySet
            file_type: File extension
            
        Returns:
            Filtered QuerySet
        """
        file_type = file_type.lower()
        if file_type in ['pdf', 'png', 'jpg', 'jpeg']:
            return queryset.filter(file_type=file_type)
        return queryset
    
    @staticmethod
    def _filter_by_date_from(queryset, date_from: str):
        """
        Filter notices created on or after a date.
        
        Args:
            queryset: Notice QuerySet
            date_from: ISO date string (YYYY-MM-DD)
            
        Returns:
            Filtered QuerySet
        """
        try:
            return queryset.filter(created_at__date__gte=date_from)
        except Exception as e:
            logger.warning(f"Invalid date_from filter value: {date_from} - {e}")
            return queryset
    
    @staticmethod
    def _filter_by_date_to(queryset, date_to: str):
        """
        Filter notices created on or before a date.
        
        Args:
            queryset: Notice QuerySet
            date_to: ISO date string (YYYY-MM-DD)
            
        Returns:
            Filtered QuerySet
        """
        try:
            return queryset.filter(created_at__date__lte=date_to)
        except Exception as e:
            logger.warning(f"Invalid date_to filter value: {date_to} - {e}")
            return queryset
    
    @classmethod
    def get_available_filters(cls) -> list:
        """
        Return list of available filter parameters.
        Useful for API documentation.
        """
        return list(cls.FILTER_MAPPING.keys())
