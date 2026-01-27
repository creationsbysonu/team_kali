from dataclasses import dataclass
from pathlib import Path
import os

@dataclass
class Settings:
    data_dir: Path = Path("data/docs")
    uploads_dir: Path = Path("uploads")
    chunk_size_words: int = 250
    chunk_overlap_words: int = 50
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

settings = Settings()
