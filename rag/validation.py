"""
Input validation utilities
"""
import re
from typing import Optional


def validate_notice_id(notice_id: str) -> tuple[bool, Optional[str]]:
    """Validate notice_id format."""
    if not notice_id or not notice_id.strip():
        return False, "Notice ID cannot be empty"
    
    # Check length
    if len(notice_id) > 100:
        return False, "Notice ID too long (max 100 characters)"
    
    # Check for invalid characters (allow alphanumeric, dash, underscore)
    if not re.match(r'^[a-zA-Z0-9_-]+$', notice_id):
        return False, "Notice ID contains invalid characters"
    
    return True, None


def validate_file_url(url: str) -> tuple[bool, Optional[str]]:
    """Validate file URL format."""
    if not url or not url.strip():
        return False, "URL cannot be empty"
    
    # Check if it looks like a URL
    if not url.startswith(('http://', 'https://')):
        return False, "URL must start with http:// or https://"
    
    # Check length
    if len(url) > 2000:
        return False, "URL too long"
    
    # Check for valid file extensions
    valid_extensions = ['.pdf', '.jpg', '.jpeg', '.png', '.txt', '.md']
    if not any(url.lower().endswith(ext) for ext in valid_extensions):
        return False, f"Invalid file type. Allowed: {', '.join(valid_extensions)}"
    
    return True, None


def sanitize_filename(filename: str) -> str:
    """Sanitize filename to prevent path traversal."""
    # Remove path components
    filename = filename.split('/')[-1].split('\\')[-1]
    
    # Remove potentially dangerous characters
    filename = re.sub(r'[^\w\s.-]', '', filename)
    
    # Limit length
    if len(filename) > 255:
        name, ext = filename.rsplit('.', 1) if '.' in filename else (filename, '')
        filename = name[:250] + ('.' + ext if ext else '')
    
    return filename


def validate_query(query: str, max_length: int = 1000) -> tuple[bool, Optional[str]]:
    """Validate search query."""
    if not query or not query.strip():
        return False, "Query cannot be empty"
    
    if len(query) > max_length:
        return False, f"Query too long (max {max_length} characters)"
    
    # Check for suspiciously repetitive queries (possible DoS)
    unique_chars = len(set(query))
    if len(query) > 50 and unique_chars < 5:
        return False, "Invalid query pattern"
    
    return True, None
