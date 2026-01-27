#!/usr/bin/env python
"""Clear both SQLite and MySQL databases."""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from rag.config import settings
from rag.db_mysql import connect_mysql

def clear_mysql():
    """Clear all data from MySQL tables."""
    try:
        conn = connect_mysql(
            host=settings.mysql_host,
            user=settings.mysql_user,
            password=settings.mysql_password,
            database=settings.mysql_database,
            port=settings.mysql_port,
        )
        
        with conn.cursor() as cur:
            # Disable foreign key checks temporarily
            cur.execute("SET FOREIGN_KEY_CHECKS = 0")
            
            # Truncate tables (faster than DELETE)
            cur.execute("TRUNCATE TABLE embeddings")
            cur.execute("TRUNCATE TABLE chunks")
            cur.execute("TRUNCATE TABLE documents")
            
            # Re-enable foreign key checks
            cur.execute("SET FOREIGN_KEY_CHECKS = 1")
        
        conn.close()
        print("✅ MySQL database cleared successfully")
        return True
        
    except Exception as e:
        print(f"❌ Failed to clear MySQL: {e}")
        return False


def clear_sqlite():
    """Delete SQLite database file."""
    try:
        db_path = Path("data/rag.db")
        if db_path.exists():
            db_path.unlink()
            print("✅ SQLite database deleted successfully")
            return True
        else:
            print("⚠️  SQLite database doesn't exist")
            return True
    except Exception as e:
        print(f"❌ Failed to delete SQLite: {e}")
        return False


if __name__ == "__main__":
    print("🗑️  Clearing both databases...")
    print()
    
    sqlite_ok = clear_sqlite()
    mysql_ok = clear_mysql()
    
    print()
    if sqlite_ok and mysql_ok:
        print("✅ Both databases cleared successfully!")
        print("You can now restart the server and upload fresh documents.")
    else:
        print("⚠️  Some operations failed. Check errors above.")
