import sqlite3
import json
from pathlib import Path
from typing import Dict, List, Tuple
import numpy as np

from .config import settings

SCHEMA = """
CREATE TABLE IF NOT EXISTS documents (
  id INTEGER PRIMARY KEY,
  ministry TEXT,
  title TEXT,
  upload_date TEXT,
  path TEXT,
  notice_id TEXT
);

CREATE TABLE IF NOT EXISTS chunks (
  id INTEGER PRIMARY KEY,
  document_id INTEGER,
  chunk_order INTEGER,
    text TEXT,
    token_count INTEGER,
  FOREIGN KEY(document_id) REFERENCES documents(id)
);

CREATE TABLE IF NOT EXISTS embeddings (
  chunk_id INTEGER PRIMARY KEY,
  vector TEXT,
    dim INTEGER,
    model_name TEXT,
  FOREIGN KEY(chunk_id) REFERENCES chunks(id)
);
"""


def connect(db_path: Path | None = None) -> sqlite3.Connection:
    path = str(db_path or settings.db_path)
    conn = sqlite3.connect(path)
    return conn


def init_db(conn: sqlite3.Connection):
    conn.executescript(SCHEMA)
    # Basic migrations to add missing columns for existing DBs
    cur = conn.cursor()
    try:
        # Check and add notice_id column
        cur.execute("PRAGMA table_info(documents)")
        doc_cols = {row[1] for row in cur.fetchall()}
        if "notice_id" not in doc_cols:
            print("🔧 Adding notice_id column to documents table")
            cur.execute("ALTER TABLE documents ADD COLUMN notice_id TEXT")
            conn.commit()
        
        # Check and add token_count column
        cur.execute("PRAGMA table_info(chunks)")
        chunk_cols = {row[1] for row in cur.fetchall()}
        if "token_count" not in chunk_cols:
            cur.execute("ALTER TABLE chunks ADD COLUMN token_count INTEGER")
    except Exception:
        pass
    try:
        cur.execute("PRAGMA table_info(embeddings)")
        emb_cols = {row[1] for row in cur.fetchall()}
        if "model_name" not in emb_cols:
            cur.execute("ALTER TABLE embeddings ADD COLUMN model_name TEXT")
    except Exception:
        pass
    conn.commit()


def upsert_document(conn: sqlite3.Connection, meta: Dict[str, str]) -> int:
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO documents(ministry, title, upload_date, path, notice_id) VALUES(?,?,?,?,?)",
        (meta.get("ministry"), meta.get("title"), meta.get("upload_date"), meta.get("path"), meta.get("notice_id")),
    )
    conn.commit()
    return cur.lastrowid


def insert_chunk(conn: sqlite3.Connection, document_id: int, order: int, text: str, token_count: int = None) -> int:
    cur = conn.cursor()
    if token_count is None:
        cur.execute(
            "INSERT INTO chunks(document_id, chunk_order, text) VALUES(?,?,?)",
            (document_id, order, text),
        )
    else:
        cur.execute(
            "INSERT INTO chunks(document_id, chunk_order, text, token_count) VALUES(?,?,?,?)",
            (document_id, order, text, token_count),
        )
    conn.commit()
    return cur.lastrowid


def save_embedding(conn: sqlite3.Connection, chunk_id: int, vec: np.ndarray, model_name: str = None):
    vec_list = vec.astype(float).tolist()
    cur = conn.cursor()
    if model_name is None:
        cur.execute(
            "INSERT OR REPLACE INTO embeddings(chunk_id, vector, dim) VALUES(?,?,?)",
            (chunk_id, json.dumps(vec_list), int(vec.shape[-1])),
        )
    else:
        cur.execute(
            "INSERT OR REPLACE INTO embeddings(chunk_id, vector, dim, model_name) VALUES(?,?,?,?)",
            (chunk_id, json.dumps(vec_list), int(vec.shape[-1]), model_name),
        )
    conn.commit()


def load_all_for_index(conn: sqlite3.Connection) -> Tuple[List[str], List[Dict[str, str]], np.ndarray]:
    cur = conn.cursor()
    cur.execute(
        """
        SELECT c.text, d.ministry, d.title, d.upload_date, d.path, d.notice_id, e.vector
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
    for text, ministry, title, upload_date, path, notice_id, vec_json in rows:
        texts.append(text)
        metas.append({
            "ministry": ministry,
            "title": title,
            "upload_date": upload_date,
            "path": path,
            "notice_id": notice_id
        })
        vecs.append(json.loads(vec_json))
    if vecs:
        embeddings = np.array(vecs, dtype=float)
    else:
        embeddings = np.zeros((0, 1), dtype=float)
    return texts, metas, embeddings
