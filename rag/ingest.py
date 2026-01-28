from pathlib import Path
from typing import Dict, List, Tuple
import json
import frontmatter
import sqlite3
import numpy as np
from pypdf import PdfReader
import pymysql
try:
    import pytesseract
    from pdf2image import convert_from_path
    from PIL import Image
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False

from .config import settings
from .db import connect, init_db, upsert_document, insert_chunk, save_embedding
from .models import EmbeddingModel

# Import enhanced OCR functions
try:
    from .ocr_enhanced import (
        extract_text_from_pdf_enhanced,
        extract_text_from_image_enhanced,
        OCR_AVAILABLE as ENHANCED_OCR_AVAILABLE
    )
    USE_ENHANCED_OCR = ENHANCED_OCR_AVAILABLE
except ImportError:
    USE_ENHANCED_OCR = False
    print("[WARNING] Enhanced OCR not available, falling back to basic OCR")

class DocChunk:
    def __init__(self, text: str, source: Dict[str, str]):
        self.text = text
        self.source = source  # {ministry, title, upload_date, path}


def _extract_text_from_pdf_ocr(pdf_path: Path) -> Tuple[str, Dict[str, str]]:
    """Extract text from scanned PDF using enhanced multi-pass OCR.
    
    Returns:
        Tuple of (text, metadata_dict with detected ministry)
    """
    if not OCR_AVAILABLE:
        return "", {}
    
    # Use enhanced OCR if available
    if USE_ENHANCED_OCR:
        return extract_text_from_pdf_enhanced(pdf_path)
    
    # Fallback to basic OCR
    try:
        images = convert_from_path(str(pdf_path), dpi=300)
        text_parts = []
        for i, image in enumerate(images):
            text = pytesseract.image_to_string(image, lang='nep+eng')
            text_parts.append(text)
            print(f"  OCR page {i+1}/{len(images)}")
            image.close()
        return "\n".join(text_parts), {}
    except Exception as e:
        print(f"OCR failed for {pdf_path}: {e}")
        return "", {}


def _extract_text_from_image(image_path: Path) -> Tuple[str, Dict[str, str]]:
    """Extract text from image file using enhanced multi-pass OCR.
    
    Returns:
        Tuple of (text, metadata_dict with detected ministry)
    """
    if not OCR_AVAILABLE:
        return "", {}
    
    # Use enhanced OCR if available
    if USE_ENHANCED_OCR:
        return extract_text_from_image_enhanced(image_path)
    
    # Fallback to basic OCR
    image = None
    try:
        image = Image.open(image_path)
        text = pytesseract.image_to_string(image, lang='nep+eng')
        return text, {}
    except Exception as e:
        print(f"OCR failed for {image_path}: {e}")
        return "", {}
    finally:
        if image:
            image.close()


def _read_doc(path: Path) -> Tuple[Dict[str, str], str, List[Tuple[str, int]]]:
    """Read a document and return (metadata, full_text, page_texts).
    
    Returns:
        Tuple of (meta_dict, full_text_string, list of (page_text, page_num) tuples)
    """
    # Check for metadata file (for Cloudinary/Django integration)
    metadata_file = path.with_suffix('.meta.json')
    external_metadata = {}
    if metadata_file.exists():
        try:
            with open(metadata_file, 'r', encoding='utf-8') as f:
                external_metadata = json.load(f)
            print(f"📋 Loaded metadata from {metadata_file.name}")
        except Exception as e:
            print(f"⚠️ Failed to load metadata: {e}")
    
    if path.suffix.lower() == ".md":
        with open(path, encoding="utf-8") as f:
            post = frontmatter.load(f)
            meta = post.metadata
            meta["path"] = str(path)
            if "title" not in meta:
                meta["title"] = path.stem
            # Merge external metadata (from Cloudinary/Django)
            if external_metadata:
                meta.update(external_metadata)
            return meta, post.content, [(post.content, 1)]
    
    elif path.suffix.lower() == ".txt":
        with open(path, encoding="utf-8") as f:
            text = f.read()
        from datetime import datetime
        meta = {"ministry": "Unknown", "title": path.stem, "upload_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "path": str(path)}
        # Merge external metadata
        if external_metadata:
            meta.update(external_metadata)
        return meta, text, [(text, 1)]
    
    elif path.suffix.lower() == ".pdf":
        reader = PdfReader(str(path))
        page_texts = []  # List of (text, page_num)
        
        # Try to extract text normally from each page
        has_text = False
        for page_num, page in enumerate(reader.pages, start=1):
            page_text = page.extract_text()
            if page_text and page_text.strip():
                has_text = True
                page_texts.append((page_text, page_num))
            else:
                page_texts.append(("", page_num))
        
        # If no text extracted, use OCR
        if not has_text:
            print(f"  Using OCR for {path.name}")
            ocr_text, ocr_metadata = _extract_text_from_pdf_ocr(path)
            # OCR returns full text, assign to page 1 for simplicity
            page_texts = [(ocr_text, 1)]
            from datetime import datetime
            meta = {
                "ministry": "Unknown",
                "title": path.stem,
                "upload_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "path": str(path)
            }
            if ocr_metadata:
                meta.update(ocr_metadata)
            # Merge external metadata (takes precedence)
            if external_metadata:
                meta.update(external_metadata)
            full_text = ocr_text
        else:
            # Concatenate all page texts
            full_text = "\n".join([pt[0] for pt in page_texts if pt[0]])
            from datetime import datetime
            meta = {
                "ministry": "Unknown",
                "title": path.stem,
                "upload_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "path": str(path)
            }
            # Merge external metadata (takes precedence)
            if external_metadata:
                meta.update(external_metadata)
        
        return meta, full_text, page_texts
    
    elif path.suffix.lower() in {".jpg", ".jpeg", ".png", ".tiff", ".bmp"}:
        text, ocr_metadata = _extract_text_from_image(path)
        from datetime import datetime
        meta = {
            "ministry": "Unknown",
            "title": path.stem,
            "upload_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "path": str(path)
        }
        if ocr_metadata:
            meta.update(ocr_metadata)
        # Merge external metadata (takes precedence)
        if external_metadata:
            meta.update(external_metadata)
        
        return meta, text, [(text, 1)]
    else:
        from datetime import datetime
        meta = {"ministry": "Unknown", "title": path.stem, "upload_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "path": str(path)}
        # Merge external metadata
        if external_metadata:
            meta.update(external_metadata)
        return meta, "", []


def _chunk_text(text: str, size: int, overlap: int) -> List[str]:
    words = text.split()
    chunks = []
    start = 0
    while start < len(words):
        end = min(start + size, len(words))
        chunk = " ".join(words[start:end])
        if chunk.strip():
            chunks.append(chunk)
        start += size - overlap
        if start <= 0:
            break
    return chunks


def _chunk_text_with_metadata(text: str, meta: Dict[str, str], size: int, overlap: int) -> List[str]:
    """Chunk text with metadata prepended."""
    prefix_parts = []
    if meta.get('ministry') and meta['ministry'] != 'Unknown':
        prefix_parts.append(f"[{meta['ministry']}]")
    if meta.get('title'):
        prefix_parts.append(f"[{meta['title']}]")
    
    prefix = " ".join(prefix_parts)
    
    words = text.split()
    chunks = []
    start = 0
    while start < len(words):
        end = min(start + size, len(words))
        chunk_text = " ".join(words[start:end])
        if chunk_text.strip():
            if prefix:
                chunk_with_meta = f"{prefix}\n{chunk_text}"
            else:
                chunk_with_meta = chunk_text
            chunks.append(chunk_with_meta)
        start += size - overlap
        if start <= 0:
            break
    
    return chunks


def _chunk_pages_with_metadata(page_texts: List[Tuple[str, int]], meta: Dict[str, str], size: int, overlap: int) -> List[Tuple[str, int]]:
    """Chunk page-aware text and track which page each chunk came from.
    
    Returns:
        List of (chunk_text_with_metadata, page_number) tuples
    """
    prefix_parts = []
    if meta.get('ministry') and meta['ministry'] != 'Unknown':
        prefix_parts.append(f"[{meta['ministry']}]")
    if meta.get('title'):
        prefix_parts.append(f"[{meta['title']}]")
    
    prefix = " ".join(prefix_parts)
    
    chunks_with_pages = []
    
    for page_text, page_num in page_texts:
        if not page_text or not page_text.strip():
            continue
            
        words = page_text.split()
        start = 0
        
        while start < len(words):
            end = min(start + size, len(words))
            chunk_text = " ".join(words[start:end])
            
            if chunk_text.strip():
                if prefix:
                    chunk_with_meta = f"{prefix}\n{chunk_text}"
                else:
                    chunk_with_meta = chunk_text
                chunks_with_pages.append((chunk_with_meta, page_num))
            
            start += size - overlap
            if start <= 0:
                break
    
    return chunks_with_pages


def load_and_chunk_docs(data_dir: Path = settings.data_dir) -> List[DocChunk]:
    chunks: List[DocChunk] = []
    for path in sorted(data_dir.glob("**/*")):
        if path.suffix.lower() not in {".md", ".txt", ".pdf", ".jpg", ".jpeg", ".png", ".tiff", ".bmp"}:
            continue
        meta, body, page_texts = _read_doc(path)
        # Use page-aware chunking for PDFs with page tracking
        for ch_text, page_num in _chunk_pages_with_metadata(page_texts, meta, settings.chunk_size_words, settings.chunk_overlap_words):
            # Add page number to metadata
            meta_with_page = meta.copy()
            meta_with_page['page'] = str(page_num)
            chunks.append(DocChunk(f"{ch_text} [पृष्ठ {page_num}]", meta_with_page))
    return chunks


def ingest_to_db(embedder: EmbeddingModel, data_dir: Path = settings.uploads_dir, db_path: Path = settings.db_path, model_name: str | None = None):
    conn = connect(db_path)
    init_db(conn)
    for path in sorted(data_dir.glob("**/*")):
        if path.suffix.lower() not in {".md", ".txt", ".pdf", ".jpg", ".jpeg", ".png", ".tiff", ".bmp"}:
            continue
        meta, body, page_texts = _read_doc(path)
        if not body or not body.strip():
            print(f"Skipping empty document: {path.name}")
            continue
        doc_id = upsert_document(conn, meta)
        
        # Use page-aware chunking with page number tracking
        chunks_with_pages = _chunk_pages_with_metadata(page_texts, meta, settings.chunk_size_words, settings.chunk_overlap_words)
        if not chunks_with_pages:
            continue
        
        # Add page numbers to chunk texts
        chunks = [f"{ch_text} [पृष्ठ {page_num}]" for ch_text, page_num in chunks_with_pages]
        
        # Compute tokens and embeddings in batch
        tokens = None
        if hasattr(embedder, "count_tokens"):
            try:
                tokens = embedder.count_tokens(chunks)  # type: ignore[attr-defined]
            except Exception:
                tokens = None
        vectors = embedder.embed(chunks)
        if model_name is None and hasattr(embedder, "model_name"):
            try:
                model_name = getattr(embedder, "model_name")  # type: ignore
            except Exception:
                model_name = None
        for i, ch in enumerate(chunks):
            tok = tokens[i] if tokens is not None else None
            chunk_id = insert_chunk(conn, doc_id, i, ch, tok)
            vec = vectors[i]
            save_embedding(conn, chunk_id, np.array(vec), model_name)
    conn.close()


def ingest_to_mysql(embedder: EmbeddingModel, mysql_cfg: Dict[str, str], data_dir: Path = settings.uploads_dir, model_name: str | None = None):
    from .db_mysql import connect_mysql, init_db_mysql, upsert_document_mysql, insert_chunk_mysql, save_embedding_mysql
    conn = connect_mysql(
        host=mysql_cfg.get("host", "localhost"),
        user=mysql_cfg.get("user", "root"),
        password=mysql_cfg.get("password", ""),
        database=mysql_cfg.get("database", "rag"),
        port=int(mysql_cfg.get("port", 3306)),
    )
    init_db_mysql(conn)
    for path in sorted(data_dir.glob("**/*")):
        if path.suffix.lower() not in {".md", ".txt", ".pdf", ".jpg", ".jpeg", ".png", ".tiff", ".bmp"}:
            continue
        meta, body, page_texts = _read_doc(path)
        if not body.strip():
            continue
        doc_id = upsert_document_mysql(conn, meta)
        
        # Use page-aware chunking with page number tracking
        chunks_with_pages = _chunk_pages_with_metadata(page_texts, meta, settings.chunk_size_words, settings.chunk_overlap_words)
        if not chunks_with_pages:
            continue
        
        # Add page numbers to chunk texts
        chunks = [f"{ch_text} [पृष्ठ {page_num}]" for ch_text, page_num in chunks_with_pages]
        
        tokens = None
        if hasattr(embedder, "count_tokens"):
            try:
                tokens = embedder.count_tokens(chunks)  # type: ignore[attr-defined]
            except Exception:
                tokens = None
        vectors = embedder.embed(chunks)
        if model_name is None and hasattr(embedder, "model_name"):
            try:
                model_name = getattr(embedder, "model_name")  # type: ignore
            except Exception:
                model_name = None
        for i, ch in enumerate(chunks):
            tok = tokens[i] if tokens is not None else None
            chunk_id = insert_chunk_mysql(conn, doc_id, i, ch, tok)
            vec = vectors[i]
            save_embedding_mysql(conn, chunk_id, np.array(vec), model_name)
    conn.close()


def sync_mysql_to_sqlite(mysql_cfg: dict, db_path: Path = settings.db_path):
    """Sync all data from MySQL to SQLite."""
    import pymysql
    
    print("Syncing MySQL → SQLite...")
    
    # Connect to MySQL
    mysql_conn = pymysql.connect(
        host=mysql_cfg.get("host", "localhost"),
        user=mysql_cfg.get("user", "root"),
        password=mysql_cfg.get("password", ""),
        database=mysql_cfg.get("database", "rag"),
        port=int(mysql_cfg.get("port", 3306)),
    )
    
    # Connect to SQLite
    sqlite_conn = connect(db_path)
    init_db(sqlite_conn)
    
    try:
        # Load all from MySQL
        mysql_cur = mysql_conn.cursor(pymysql.cursors.DictCursor)
        
        # Sync documents
        mysql_cur.execute("SELECT id, ministry, title, upload_date, path FROM documents")
        docs = mysql_cur.fetchall()
        for doc in docs:
            sqlite_conn.execute(
                "INSERT OR REPLACE INTO documents (id, ministry, title, upload_date, path) VALUES (?, ?, ?, ?, ?)",
                (doc['id'], doc['ministry'], doc['title'], doc['upload_date'], doc['path'])
            )
        
        # Sync chunks
        mysql_cur.execute("SELECT id, document_id, chunk_order, text, token_count FROM chunks")
        chunks = mysql_cur.fetchall()
        for chunk in chunks:
            sqlite_conn.execute(
                "INSERT OR REPLACE INTO chunks (id, document_id, chunk_order, text, token_count) VALUES (?, ?, ?, ?, ?)",
                (chunk['id'], chunk['document_id'], chunk['chunk_order'], chunk['text'], chunk['token_count'])
            )
        
        # Sync embeddings
        mysql_cur.execute("SELECT chunk_id, vector, dim, model_name FROM embeddings")
        embeddings = mysql_cur.fetchall()
        for emb in embeddings:
            sqlite_conn.execute(
                "INSERT OR REPLACE INTO embeddings (chunk_id, vector, dim, model_name) VALUES (?, ?, ?, ?)",
                (emb['chunk_id'], emb['vector'], emb['dim'], emb['model_name'])
            )
        
        sqlite_conn.commit()
        print(f"Synced {len(docs)} documents, {len(chunks)} chunks, {len(embeddings)} embeddings to SQLite")
    
    finally:
        mysql_conn.close()
        sqlite_conn.close()

