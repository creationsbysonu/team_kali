"""
MySQL connection pooling for better performance
"""
import pymysql
from pymysql.cursors import Cursor
from queue import Queue, Empty
from threading import Lock
from typing import Optional
import time


class MySQLConnectionPool:
    """Thread-safe MySQL connection pool."""
    
    def __init__(self, host: str, port: int, user: str, password: str, 
                 database: str, pool_size: int = 5):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.database = database
        self.pool_size = pool_size
        
        self._pool = Queue(maxsize=pool_size)
        self._lock = Lock()
        self._created_connections = 0
        
        # Pre-create connections
        for _ in range(pool_size):
            conn = self._create_connection()
            if conn:
                self._pool.put(conn)
    
    def _create_connection(self):
        """Create a new MySQL connection."""
        try:
            conn = pymysql.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=self.database,
                charset="utf8mb4",
                autocommit=True,
                cursorclass=Cursor,
            )
            with self._lock:
                self._created_connections += 1
            return conn
        except Exception as e:
            print(f"❌ Failed to create MySQL connection: {e}")
            return None
    
    def get_connection(self, timeout: float = 5.0):
        """Get a connection from the pool."""
        try:
            conn = self._pool.get(timeout=timeout)
            
            # Test if connection is alive
            try:
                conn.ping(reconnect=True)
                return conn
            except:
                # Connection dead, create new one
                conn = self._create_connection()
                if conn:
                    return conn
                else:
                    raise Exception("Failed to create new connection")
                    
        except Empty:
            # Pool exhausted, try creating new connection if under limit
            with self._lock:
                if self._created_connections < self.pool_size:
                    conn = self._create_connection()
                    if conn:
                        return conn
            raise Exception("Connection pool exhausted")
    
    def return_connection(self, conn):
        """Return a connection to the pool."""
        if conn:
            try:
                self._pool.put_nowait(conn)
            except:
                # Pool full, close connection
                try:
                    conn.close()
                except:
                    pass
    
    def close_all(self):
        """Close all connections in the pool."""
        while not self._pool.empty():
            try:
                conn = self._pool.get_nowait()
                conn.close()
            except:
                pass


# Global pool instance
_pool: Optional[MySQLConnectionPool] = None


def init_pool(host: str, port: int, user: str, password: str, 
              database: str, pool_size: int = 5):
    """Initialize the global connection pool."""
    global _pool
    _pool = MySQLConnectionPool(host, port, user, password, database, pool_size)
    return _pool


def get_pool() -> Optional[MySQLConnectionPool]:
    """Get the global connection pool."""
    return _pool


class PooledConnection:
    """Context manager for pooled connections."""
    
    def __init__(self, pool: MySQLConnectionPool):
        self.pool = pool
        self.conn = None
    
    def __enter__(self):
        self.conn = self.pool.get_connection()
        return self.conn
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.pool.return_connection(self.conn)
