from dataclasses import dataclass
from pathlib import Path
import os

@dataclass
class Settings:
    data_dir: Path = Path("data/docs")
    uploads_dir: Path = Path("uploads")
    chunk_size_words: int = 150  # Reduced to stay under 512 token limit (Nepali: ~2.5 tokens/word)
    chunk_overlap_words: int = 30  # Proportionally reduced overlap
    top_k: int = 6
    db_path: Path = Path("data/rag.db")
    max_file_size_mb: int = 50  # Maximum file upload size
    
    # Database settings
    use_mysql_primary: bool = True  # True = MySQL primary, False = SQLite primary
    sync_to_sqlite: bool = True  # Sync MySQL → SQLite for local cache
    
    # MySQL settings (primary database)
    mysql_host: str = "localhost"
    mysql_port: int = 3306
    mysql_user: str = "root"
    mysql_password: str = os.getenv("MYSQL_PASSWORD", "guptasonu")  # Use env var, fallback to default
    mysql_database: str = "rag"
    mysql_pool_size: int = 5  # Connection pool size
    
    # Search & Ranking settings
    relevance_threshold: float = 0.65  # Minimum similarity score for results
    recency_boost_days_high: int = 30  # Days for 10% boost
    recency_boost_days_medium: int = 90  # Days for 5% boost
    recency_boost_high: float = 1.10  # 10% boost for very recent docs
    recency_boost_medium: float = 1.05  # 5% boost for recent docs
    
    # Query settings
    max_query_length: int = 1000  # Maximum query characters
    comprehensive_query_multiplier: int = 3  # Retrieve 3x chunks for comprehensive queries
    
    # Cache settings
    enable_cache: bool = True
    query_cache_size: int = 100
    query_cache_ttl_seconds: int = 1800  # 30 minutes
    embedding_cache_size: int = 500
    embedding_cache_ttl_seconds: int = 3600  # 1 hour
    
    # Logging settings
    log_dir: Path = Path("logs")
    log_level: str = "INFO"  # DEBUG, INFO, WARNING, ERROR, CRITICAL

settings = Settings()
