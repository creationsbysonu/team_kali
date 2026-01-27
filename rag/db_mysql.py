import json
from typing import Dict, List, Tuple, Optional
import numpy as np
import pymysql

SCHEMA_STATEMENTS = [
    """
    CREATE TABLE IF NOT EXISTS documents (
      id INT AUTO_INCREMENT PRIMARY KEY,
      ministry VARCHAR(255),
      title VARCHAR(255),
      upload_date VARCHAR(64),
      path TEXT
    ) ENGINE=InnoDB;
    """,
    """
        CREATE TABLE IF NOT EXISTS chunks (
      id INT AUTO_INCREMENT PRIMARY KEY,
      document_id INT,
      chunk_order INT,
            text MEDIUMTEXT,
            token_count INT,
      FOREIGN KEY(document_id) REFERENCES documents(id) ON DELETE CASCADE
    ) ENGINE=InnoDB;
    """,
    """
        CREATE TABLE IF NOT EXISTS embeddings (
      chunk_id INT PRIMARY KEY,
            vector JSON,
            dim INT,
            model_name VARCHAR(255),
      FOREIGN KEY(chunk_id) REFERENCES chunks(id) ON DELETE CASCADE
    ) ENGINE=InnoDB;
    """,
]


def connect_mysql(host: str, user: str, password: str, database: str, port: int = 3306):
    return pymysql.connect(
        host=host,
        user=user,
        password=password,
        database=database,
        port=port,
        charset="utf8mb4",
        autocommit=True,
        cursorclass=pymysql.cursors.Cursor,
    )


def init_db_mysql(conn):
    with conn.cursor() as cur:
        for stmt in SCHEMA_STATEMENTS:
            cur.execute(stmt)
        # Migrations for existing DBs - check if columns exist first
        try:
            cur.execute("SHOW COLUMNS FROM chunks LIKE 'token_count'")
            if cur.fetchone() is None:
                cur.execute("ALTER TABLE chunks ADD COLUMN token_count INT")
        except Exception:
            pass
        try:
            cur.execute("SHOW COLUMNS FROM embeddings LIKE 'model_name'")
            if cur.fetchone() is None:
                cur.execute("ALTER TABLE embeddings ADD COLUMN model_name VARCHAR(255)")
        except Exception:
            pass


def upsert_document_mysql(conn, meta: Dict[str, str]) -> int:
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO documents(ministry, title, upload_date, path) VALUES(%s,%s,%s,%s)",
            (meta.get("ministry"), meta.get("title"), meta.get("upload_date"), meta.get("path")),
        )
        return cur.lastrowid


def insert_chunk_mysql(conn, document_id: int, order: int, text: str, token_count: int = None) -> int:
    with conn.cursor() as cur:
        if token_count is None:
            cur.execute(
                "INSERT INTO chunks(document_id, chunk_order, text) VALUES(%s,%s,%s)",
                (document_id, order, text),
            )
        else:
            cur.execute(
                "INSERT INTO chunks(document_id, chunk_order, text, token_count) VALUES(%s,%s,%s,%s)",
                (document_id, order, text, token_count),
            )
        return cur.lastrowid


def save_embedding_mysql(conn, chunk_id: int, vec: np.ndarray, model_name: str = None):
    vec_list = vec.astype(float).tolist()
    with conn.cursor() as cur:
        if model_name is None:
            cur.execute(
                "INSERT INTO embeddings(chunk_id, vector, dim) VALUES(%s,%s,%s) ON DUPLICATE KEY UPDATE vector=VALUES(vector), dim=VALUES(dim)",
                (chunk_id, json.dumps(vec_list), int(vec.shape[-1])),
            )
        else:
            cur.execute(
                "INSERT INTO embeddings(chunk_id, vector, dim, model_name) VALUES(%s,%s,%s,%s) ON DUPLICATE KEY UPDATE vector=VALUES(vector), dim=VALUES(dim), model_name=VALUES(model_name)",
                (chunk_id, json.dumps(vec_list), int(vec.shape[-1]), model_name),
            )


def load_all_for_index_mysql(conn) -> Tuple[List[str], List[Dict[str, str]], np.ndarray]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT c.text, d.ministry, d.title, d.upload_date, d.path, e.vector
            FROM chunks c
            JOIN documents d ON d.id = c.document_id
            JOIN embeddings e ON e.chunk_id = c.id
            ORDER BY d.id, c.chunk_order
            """
        )
        rows = cur.fetchall()
    texts: List[str] = []
    metas: List[Dict[str, str]] = []
    vecs: List[List[float]] = []
    for text, ministry, title, upload_date, path, vec_json in rows:
        texts.append(text)
        metas.append({
            "ministry": ministry,
            "title": title,
            "upload_date": upload_date,
            "path": path,
        })
        if isinstance(vec_json, (bytes, bytearray)):
            vec_json = vec_json.decode("utf-8")
        vecs.append(json.loads(vec_json))
    embeddings = np.array(vecs, dtype=float) if vecs else np.zeros((0, 1), dtype=float)
    return texts, metas, embeddings
