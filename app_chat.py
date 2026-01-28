"""
Modern FastAPI backend with streaming responses and chat history
"""
from dotenv import load_dotenv
load_dotenv()  # Load .env file before anything else

from fastapi import FastAPI, File, UploadFile, HTTPException, Form, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse, JSONResponse, StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from pathlib import Path
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
import shutil
import os
import json
import asyncio
import httpx
import re
from datetime import datetime

from rag.config import settings
from rag.models import E5Embedding, GeminiGenerator
from rag.ingest import ingest_to_db, ingest_to_mysql
from rag.pipeline import RAGPipeline
from rag.db import connect, init_db
from rag.features import AdvancedFeatures
from rag.connection_pool import init_pool, get_pool, PooledConnection
from rag.logger import log_info, log_error, log_warning, log_debug, logger
from rag.cache import query_cache, embedding_cache
from rag.validation import validate_notice_id, validate_file_url, validate_query, sanitize_filename

# Global pipeline instance
pipeline: Optional[RAGPipeline] = None
embedder: Optional[E5Embedding] = None
last_top_source: Dict[str, Dict[str, Any]] = {}

def is_vague_query(text: str) -> bool:
    """Check if query is too vague to answer meaningfully."""
    t = text.strip().lower()
    # Very short queries are vague
    if len(t) < 6:
        return True
    
    # Check if query has specific context/entities
    # If it mentions specific topics, ministries, or actions, it's NOT vague
    specific_indicators = [
        'abhimukhi', 'अभिमुखि', 'taalim', 'तालिम', 'training',
        'suchana', 'सूचना', 'notice', 'ghataana', 'घटना', 'event',
        'mahanagar', 'महानगर', 'mantralaya', 'मन्त्रालय', 'ministry',
        'barema', 'बारेमा', 'about', 'sambandhi', 'सम्बन्धी',
        'haleko', 'हालेको', 'posted', 'gareko', 'गरेको', 'done'
    ]
    
    # If query has any specific indicator, it's not vague
    if any(ind in t for ind in specific_indicators):
        return False
    
    # Only flag as vague if it's JUST generic words without context
    vague_only = ["केही", "kehi", "kahi", "some", "anything", "something"]
    words = t.split()
    # If query is very short AND has vague markers, then it's vague
    return len(words) <= 3 and any(m in t for m in vague_only)

def extract_page_hint(text: str) -> Optional[str]:
    import re
    m = re.search(r"\[पृष्ठ\s+(\d+)\]", text)
    if m:
        return f"पृष्ठ {m.group(1)}"
    return None
advanced_features: Optional[AdvancedFeatures] = None

# Chat history storage (in production, use a database)
chat_history = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup/shutdown."""
    global pipeline, embedder, advanced_features
    
    # Startup
    embedder = E5Embedding()
    generator = GeminiGenerator()  # Uses GOOGLE_GEMINI_API_KEY from .env
    pipeline = RAGPipeline(embedder, generator)
    advanced_features = AdvancedFeatures(pipeline)
    
    # Ensure necessary directories exist
    settings.uploads_dir.mkdir(parents=True, exist_ok=True)
    settings.log_dir.mkdir(parents=True, exist_ok=True)
    conn = connect(settings.db_path)
    try:
        init_db(conn)
    finally:
        conn.close()
    
    # Initialize MySQL connection pool
    if settings.use_mysql_primary:
        try:
            log_info("Initializing MySQL connection pool", pool_size=settings.mysql_pool_size)
            pool = init_pool(
                host=settings.mysql_host,
                port=settings.mysql_port,
                user=settings.mysql_user,
                password=settings.mysql_password,
                database=settings.mysql_database,
                pool_size=settings.mysql_pool_size
            )
            
            # Initialize schema using pooled connection
            from rag.db_mysql import init_db_mysql
            with PooledConnection(pool) as conn:
                init_db_mysql(conn)
                pipeline.index.build_from_mysql(conn)
            
            log_info(f"Loaded chunks from MySQL", count=len(pipeline.index.texts))
            print(f"✅ Loaded {len(pipeline.index.texts)} chunks from MySQL (primary)")
        except Exception as e:
            log_error("MySQL load failed, falling back to SQLite", error=e)
            print(f"⚠️ MySQL load failed, trying SQLite: {e}")
            conn = connect(settings.db_path)
            try:
                pipeline.index.build_from_db(conn)
                log_info(f"Loaded chunks from SQLite fallback", count=len(pipeline.index.texts))
                print(f"✅ Loaded {len(pipeline.index.texts)} chunks from SQLite (fallback)")
            finally:
                conn.close()
    else:
        conn = connect(settings.db_path)
        try:
            pipeline.index.build_from_db(conn)
            print(f"✅ Loaded {len(pipeline.index.texts)} chunks from SQLite")
        except Exception as e:
            print(f"ℹ️ No existing embeddings found: {e}")
        finally:
            conn.close()
    
    yield
    
    # Shutdown (cleanup if needed)
    pass

app = FastAPI(
    title="नेपाल सरकारी RAG API",
    description="E-Governance Document Q&A System with Chat Interface",
    lifespan=lifespan
)


@app.get("/", response_class=HTMLResponse)
async def root():
    """Serve the modern chatbot interface."""
    try:
        with open("static/index.html", "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return """
        <h1>Static files not found</h1>
        <p>Please ensure the 'static' directory exists with index.html and app.js</p>
        <p>Current directory: """ + str(Path.cwd()) + """</p>
        """


@app.get("/health")
async def health_check():
    """Health check endpoint - test if server is running."""
    pool = get_pool()
    
    return {
        "status": "online",
        "message": "RAG System is running! ✅ Django-compatible",
        "server": "192.168.1.118:8001",
        "chunks_loaded": len(pipeline.index.texts) if pipeline else 0,
        "database": {
            "primary": "MySQL" if settings.use_mysql_primary else "SQLite",
            "pool_enabled": pool is not None
        },
        "cache": query_cache.stats() if settings.enable_cache else {"enabled": False},
        "endpoints": {
            "websocket": "WS /ws/chat - PRIMARY: Real-time chat (Django spec)",
            "http_chat": "POST /chat - HTTP fallback (Django spec)",
            "ingest": "POST /ingest - Upload PDF via Cloudinary URL (Django spec)",
            "stream": "POST /chat/stream - For UI streaming"
        }
    }


@app.post("/upload")
async def upload_files(files: List[UploadFile] = File(...)):
    """
    Upload and process documents into the RAG system.
    Supports: PDF, Markdown, Text, and Images (with OCR)
    """
    global pipeline, embedder
    
    if not files:
        log_warning("Upload attempt with no files")
        raise HTTPException(status_code=400, detail="कुनै फाइल प्रदान गरिएन")
    
    log_info(f"Upload request received", file_count=len(files))
    allowed_extensions = {".pdf", ".md", ".txt", ".jpg", ".jpeg", ".png", ".tiff", ".bmp"}
    processed_files = []
    
    for file in files:
        # Check file size (max 50MB as configured)
        file_content = await file.read()
        file_size_mb = len(file_content) / (1024 * 1024)
        if file_size_mb > settings.max_file_size_mb:
            raise HTTPException(
                status_code=413, 
                detail=f"फाइल धेरै ठूलो छ: {file.filename} ({file_size_mb:.1f}MB). अधिकतम: {settings.max_file_size_mb}MB"
            )
        
        # Check file extension
        file_ext = Path(file.filename).suffix.lower()
        if file_ext not in allowed_extensions:
            raise HTTPException(
                status_code=400, 
                detail=f"अवैध फाइल प्रकार: {file_ext}. अनुमति: {', '.join(allowed_extensions)}"
            )
        
        # Sanitize filename (use validation utility)
        safe_filename = sanitize_filename(file.filename)
        file_path = settings.uploads_dir / safe_filename
        
        # Save file
        with open(file_path, "wb") as buffer:
            buffer.write(file_content)
        
        processed_files.append(str(file_path))
    
    # Ingest to primary database
    if settings.use_mysql_primary:
        try:
            mysql_cfg = {
                "host": settings.mysql_host,
                "port": str(settings.mysql_port),
                "user": settings.mysql_user,
                "password": settings.mysql_password,
                "database": settings.mysql_database,
            }
            ingest_to_mysql(embedder, mysql_cfg, settings.uploads_dir)
            
            # Sync to SQLite if enabled
            if settings.sync_to_sqlite:
                from rag.ingest import sync_mysql_to_sqlite
                sync_mysql_to_sqlite(mysql_cfg)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"डाटाबेस त्रुटि: {str(e)}")
    else:
        # SQLite primary
        ingest_to_db(embedder, settings.uploads_dir, settings.db_path)
    
    # Rebuild index from primary database
    if settings.use_mysql_primary:
        import pymysql
        mysql_conn = pymysql.connect(
            host=settings.mysql_host,
            port=settings.mysql_port,
            user=settings.mysql_user,
            password=settings.mysql_password,
            database=settings.mysql_database,
        )
        try:
            pipeline.index.build_from_mysql(mysql_conn)
        finally:
            mysql_conn.close()
    else:
        conn = connect(settings.db_path)
        try:
            pipeline.index.build_from_db(conn)
        finally:
            conn.close()
    
    return JSONResponse(content={
        "message": f"{len(processed_files)} फाइल(हरू) सफलतापूर्वक प्रशोधन गरियो",
        "files": [Path(f).name for f in processed_files],
        "total_chunks": len(pipeline.index.texts)
    })


# ============================================
# DJANGO/CLOUDINARY INTEGRATION ENDPOINTS
# ============================================

class IngestRequest(BaseModel):
    """Request model for URL-based file ingestion - Django spec"""
    file_url: str
    notice_id: str
    title: Optional[str] = None
    ministry_name: Optional[str] = None
    service_name: Optional[str] = None


class Source(BaseModel):
    """Source reference for chat responses - Django spec"""
    notice_id: str  # CRITICAL for deep linking
    title: Optional[str] = None
    ministry_name: Optional[str] = None
    service_name: Optional[str] = None
    page_hint: Optional[str] = None
    excerpt: Optional[str] = None


class ChatRequest(BaseModel):
    """Chat request model - Django spec"""
    query: str  # Django sends 'query' not 'question'
    session_id: Optional[str] = None


class ChatResponse(BaseModel):
    """Chat response with sources - Django spec"""
    response: str  # Django expects 'response' not 'answer'
    sources: List[Source] = []


@app.post("/ingest")
async def ingest_from_url(req: IngestRequest):
    """
    Django sends file URL + notice_id from Cloudinary - Django spec.
    We download, process, and store with notice_id + ministry_name + service_name.
    """
    global pipeline, embedder
    
    # Validate notice_id
    valid, error = validate_notice_id(req.notice_id)
    if not valid:
        log_warning(f"Invalid notice_id: {error}")
        raise HTTPException(status_code=400, detail=f"अवैध सूचना नं: {error}")
    
    # Validate file URL
    valid, error = validate_file_url(req.file_url)
    if not valid:
        log_warning(f"Invalid file URL: {error}")
        raise HTTPException(status_code=400, detail=f"अवैध फाइल URL: {error}")
    
    log_info("Ingest request received", notice_id=req.notice_id, url=req.file_url[:50])
    
    try:
        # Download file from URL
        async with httpx.AsyncClient(timeout=120.0) as client:
            print(f"📥 Downloading from: {req.file_url}")
            response = await client.get(req.file_url)
            response.raise_for_status()
            file_bytes = response.content
        
        # Save temporarily with notice_id as filename
        file_ext = Path(req.file_url).suffix or ".pdf"
        temp_path = settings.uploads_dir / f"{req.notice_id}{file_ext}"
        
        with open(temp_path, "wb") as f:
            f.write(file_bytes)
        
        print(f"💾 Saved to: {temp_path}")
        
        # Add notice_id + title + ministry_name + service_name + upload_date to metadata - Django spec
        from datetime import datetime
        metadata_file = temp_path.with_suffix('.meta.json')
        metadata = {
            "notice_id": req.notice_id,
            "title": req.title or "Unknown",
            "ministry_name": req.ministry_name or "Unknown",
            "service_name": req.service_name or "Unknown",
            "upload_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        with open(metadata_file, "w", encoding="utf-8") as f:
            json.dump(metadata, f, ensure_ascii=False)
        
        # Process the file (use existing ingestion logic)
        if settings.use_mysql_primary:
            try:
                mysql_cfg = {
                    "host": settings.mysql_host,
                    "port": str(settings.mysql_port),
                    "user": settings.mysql_user,
                    "password": settings.mysql_password,
                    "database": settings.mysql_database,
                }
                
                # Ingest to MySQL
                ingest_to_mysql(embedder, mysql_cfg, settings.uploads_dir)
                
                # Rebuild index
                import pymysql
                mysql_conn = pymysql.connect(
                    host=settings.mysql_host,
                    port=settings.mysql_port,
                    user=settings.mysql_user,
                    password=settings.mysql_password,
                    database=settings.mysql_database,
                )
                try:
                    pipeline.index.build_from_mysql(mysql_conn)
                finally:
                    mysql_conn.close()
                
            except Exception as e:
                raise HTTPException(status_code=500, detail=f"डाटाबेस त्रुटि: {str(e)}")
        else:
            ingest_to_db(embedder, settings.uploads_dir, settings.db_path)
            conn = connect(settings.db_path)
            try:
                pipeline.index.build_from_db(conn)
            finally:
                conn.close()
        
        # Count chunks for this specific notice_id
        chunks_created = 0
        if settings.use_mysql_primary:
            import pymysql
            conn = pymysql.connect(
                host=settings.mysql_host,
                port=settings.mysql_port,
                user=settings.mysql_user,
                password=settings.mysql_password,
                database=settings.mysql_database,
            )
            try:
                cursor = conn.cursor()
                cursor.execute(
                    "SELECT COUNT(*) FROM chunks c JOIN documents d ON c.document_id = d.id WHERE d.notice_id = %s",
                    (req.notice_id,)
                )
                chunks_created = cursor.fetchone()[0]
            finally:
                conn.close()
        
        return {
            "status": "ok",
            "success": True,
            "message": "Document ingested successfully",
            "notice_id": req.notice_id,
            "chunks_created": chunks_created
        }
    
    except httpx.HTTPError as e:
        raise HTTPException(status_code=400, detail=f"फाइल डाउनलोड त्रुटि: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"प्रशोधन त्रुटि: {str(e)}")


def detect_follow_up_query(query: str, conversation_history: list) -> tuple:
    """
    Detect if query is asking about previous response.
    Returns: (is_follow_up, modified_query)
    """
    follow_up_keywords = [
        'mathiko', 'माथिको', 'माथि', 'यसलाई', 'यसको', 'above', 'this',
        'chhotkarima', 'छोटकरिमा', 'छोटकरीमा', 'संक्षेप', 'summary', 'summarize',
        'vannus', 'भन्नुस्', 'बताउनुस्', 'explain', 'व्याख्या',
        'तपाईंले', 'तपाइले', 'you said', 'यसमा', 'यो',
        'kun dastabej', 'कुन दस्तावेज', 'which document', 'कुन फाइल',
        'पहिले सोध', 'earlier', 'asked earlier', 'अघि सोध'
    ]
    
    query_lower = query.lower()
    is_follow_up = any(keyword in query_lower for keyword in follow_up_keywords)
    
    if is_follow_up and conversation_history:
        # Get last assistant response
        last_response = ""
        for msg in reversed(conversation_history):
            if msg.get('role') == 'assistant':
                last_response = msg.get('content', '')
                break
        
        if last_response:
            # Check if asking about which document
            if any(word in query_lower for word in ['kun dastabej', 'कुन दस्तावेज', 'which document', 'कुन फाइल']):
                modified_query = f"यो जवाफमा उल्लेख गरिएको जानकारी कुन दस्तावेजबाट आएको हो भनी पत्ता लगाउनुहोस्। जवाफमा केवल दस्तावेजको नाम मात्र उल्लेख गर्नुहोस्:\n\n{last_response}"
            # Check if asking for summary
            elif any(word in query_lower for word in ['chhotkarima', 'छोटकरिमा', 'छोटकरीमा', 'संक्षेप', 'summary']):
                modified_query = f"यो जवाफलाई संक्षिप्त रूपमा प्रस्तुत गर्नुहोस् (३-४ बुँदामा):\n\n{last_response}"
            else:
                modified_query = f"अघिल्लो जवाफको सन्दर्भमा:\n{last_response[:500]}...\n\nनयाँ प्रश्न: {query}"
            
            return True, modified_query
    
    return False, query


async def direct_llm_query(query: str) -> str:
    """
    Direct LLM query without vector search.
    Used for summarization/follow-up queries.
    """
    try:
        # Use existing generator from pipeline
        response = pipeline.generator.generate(query)
        return response
    except Exception as e:
        return f"त्रुटि: {str(e)}"


@app.post("/chat", response_model=ChatResponse)
async def chat(req: ChatRequest):
    """
    HTTP fallback chat endpoint for Django integration - Django spec.
    Returns response with sources containing notice_id, ministry_name, service_name, excerpt.
    """
    global pipeline
    
    # Validate query
    valid, error = validate_query(req.query, max_length=settings.max_query_length)
    if not valid:
        log_warning(f"Invalid query: {error}")
        raise HTTPException(status_code=400, detail=f"अवैध प्रश्न: {error}")
    
    try:
        # Get conversation history
        session_id = req.session_id or "default"
        history = chat_history.get(session_id, [])
        
        # Check if this is a follow-up query
        is_follow_up, processed_query = detect_follow_up_query(req.query, history)
        
        # Process based on query type
        if is_follow_up:
            # Special-case: "which document" follow-up → return last top source title without re-search
            doc_keywords = ['kun dastabej', 'कुन दस्तावेज', 'which document', 'कुन फाइल']
            ql = req.query.lower()
            if any(k in ql for k in doc_keywords):
                top = last_top_source.get(session_id)
                if top:
                    name = top.get('title') or top.get('notice_id') or 'Unknown'
                    response_text = f"मुख्य स्रोत: {name}"
                    sources = [Source(notice_id=top.get('notice_id', ''), title=top.get('title'))]
                else:
                    # Fallback to LLM extraction if no memory
                    response_text = await direct_llm_query(processed_query)
                    sources = []
            else:
                # Other follow-ups: use direct LLM (no vector search needed)
                response_text = await direct_llm_query(processed_query)
                sources = []  # No new sources for summaries
        else:
            # Regular RAG pipeline
            response_text = pipeline.answer(processed_query, conversation_history=history)
            
            # Perform retrieval to get sources
            from rag.transliterate import normalize_query
            normalized_query = normalize_query(processed_query)
            retrieved = pipeline.index.search(normalized_query, top_k=settings.top_k)
            
            # Vague query handling: ask for clarification early
            if is_vague_query(processed_query):
                response_text = "कुन विषयमा? (तालिम/सूचना/घटना) कृपया स्पष्ट पार्नुहोस्।"
                sources = []
            else:
                # Count chunks per document and show only the top contributor
                doc_count = {}
                sources_dict = {}
                for r in retrieved:
                    meta = r.get('meta', {})
                    notice_id = meta.get('notice_id')
                    
                    if notice_id:
                        # Count chunks from this document
                        doc_count[notice_id] = doc_count.get(notice_id, 0) + 1
                        
                        # Store source info if not already stored
                        if notice_id not in sources_dict:
                            excerpt = r['text'][:200]
                            page_hint = extract_page_hint(r['text'])
                            excerpt = re.sub(r'\[पृष्ठ \d+\]', '', excerpt).strip()
                            
                            sources_dict[notice_id] = Source(
                                notice_id=notice_id,
                                title=meta.get('title'),
                                ministry_name=meta.get('ministry_name', 'Unknown'),
                                service_name=meta.get('service_name'),
                                page_hint=page_hint,
                                excerpt=excerpt
                            )
                
                # Return only the top document (most chunks)
                if doc_count:
                    top_notice_id = max(doc_count, key=doc_count.get)
                    sources = [sources_dict[top_notice_id]]
                    # Save for session
                    session_id = req.session_id or "default"
                    last_top_source[session_id] = {
                        "notice_id": top_notice_id,
                        "title": sources_dict[top_notice_id].title
                    }
                else:
                    sources = []
        
        # Store in chat history
        session_id = req.session_id or "default"
        if session_id not in chat_history:
            chat_history[session_id] = []
        
        chat_history[session_id].append({
            "role": "user",
            "content": req.query,
            "timestamp": datetime.now().isoformat()
        })
        chat_history[session_id].append({
            "role": "assistant",
            "content": response_text,
            "timestamp": datetime.now().isoformat()
        })
        
        return ChatResponse(response=response_text, sources=sources)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"त्रुटि: {str(e)}")


@app.websocket("/ws/chat")
async def websocket_chat(websocket: WebSocket):
    """
    PRIMARY WebSocket endpoint for Django integration - Django spec.
    Persistent connection for real-time chat.
    
    Expected message format:
    {
        "query": "your question here",
        "session_id": "optional-session-id"
    }
    
    Response format:
    {
        "response": "answer text",
        "sources": [
            {
                "notice_id": "123",
                "ministry_name": "Ministry Name",
                "service_name": "Service Name",
                "excerpt": "text excerpt..."
            }
        ]
    }
    """
    global pipeline
    
    await websocket.accept()
    print(f"🔌 WebSocket connection established")
    
    try:
        while True:
            # Receive message from Django
            data = await websocket.receive_json()
            query = data.get("query", "").strip()
            session_id = data.get("session_id", "default")
            
            # Validate query
            valid, error = validate_query(query, max_length=settings.max_query_length)
            if not valid:
                await websocket.send_json({
                    "error": f"अवैध प्रश्न: {error}",
                    "response": "",
                    "sources": []
                })
                continue
            
            print(f"📩 Received query: {query[:50]}...")
            
            try:
                # Get conversation history
                history = chat_history.get(session_id, [])
                
                # Check if this is a follow-up query
                is_follow_up, processed_query = detect_follow_up_query(query, history)
                
                # Process based on query type
                if is_follow_up:
                    # Special-case: "which document" follow-up → return last top source without re-search
                    doc_keywords = ['kun dastabej', 'कुन दस्तावेज', 'which document', 'कुन फाइल']
                    ql = query.lower()
                    if any(k in ql for k in doc_keywords):
                        top = last_top_source.get(session_id)
                        if top:
                            name = top.get('title') or top.get('notice_id') or 'Unknown'
                            response_text = f"मुख्य स्रोत: {name}"
                            sources = [{
                                "notice_id": top.get('notice_id', ''),
                                "title": top.get('title')
                            }]
                        else:
                            response_text = await direct_llm_query(processed_query)
                            sources = []
                    else:
                        # Other follow-ups: use direct LLM
                        response_text = await direct_llm_query(processed_query)
                        sources = []
                else:
                    # Regular RAG pipeline
                    response_text = pipeline.answer(processed_query, conversation_history=history)
                    
                    # Perform retrieval to get sources
                    from rag.transliterate import normalize_query
                    normalized_query = normalize_query(processed_query)
                    retrieved = pipeline.index.search(normalized_query, top_k=settings.top_k)
                    
                    # Vague query handling
                    if is_vague_query(processed_query):
                        response_text = "कुन विषयमा? (तालिम/सूचना/घटना) कृपया स्पष्ट पार्नुहोस्।"
                        sources = []
                    else:
                        # Count chunks per document and show only the top contributor
                        doc_count = {}
                        sources_dict = {}
                        for r in retrieved:
                            meta = r.get('meta', {})
                            notice_id = meta.get('notice_id')
                            
                            if notice_id:
                                # Count chunks from this document
                                doc_count[notice_id] = doc_count.get(notice_id, 0) + 1
                                
                                # Store source info if not already stored
                                if notice_id not in sources_dict:
                                    excerpt = r['text'][:200]
                                    page_hint = extract_page_hint(r['text'])
                                    excerpt = re.sub(r'\[पृष्ठ \d+\]', '', excerpt).strip()
                                    
                                    sources_dict[notice_id] = {
                                        "notice_id": notice_id,
                                        "title": meta.get('title'),
                                        "ministry_name": meta.get('ministry_name', 'Unknown'),
                                        "service_name": meta.get('service_name'),
                                        "page_hint": page_hint,
                                        "excerpt": excerpt
                                    }
                        
                        # Return only the top document (most chunks)
                        if doc_count:
                            top_notice_id = max(doc_count, key=doc_count.get)
                            sources = [sources_dict[top_notice_id]]
                            # Save last top source for the session
                            last_top_source[session_id] = {
                                "notice_id": top_notice_id,
                                "title": sources[0].get("title")
                            }
                        else:
                            sources = []
                
                # Store in chat history
                if session_id not in chat_history:
                    chat_history[session_id] = []
                
                chat_history[session_id].append({
                    "role": "user",
                    "content": query,
                    "timestamp": datetime.now().isoformat()
                })
                chat_history[session_id].append({
                    "role": "assistant",
                    "content": response_text,
                    "timestamp": datetime.now().isoformat()
                })
                
                # Send response back to Django
                await websocket.send_json({
                    "response": response_text,
                    "sources": sources
                })
                
                print(f"✅ Sent response with {len(sources)} sources")
                
            except Exception as e:
                print(f"❌ Error processing query: {str(e)}")
                await websocket.send_json({
                    "error": f"Processing error: {str(e)}",
                    "response": "",
                    "sources": []
                })
    
    except WebSocketDisconnect:
        print(f"🔌 WebSocket connection closed")
    except Exception as e:
        print(f"❌ WebSocket error: {str(e)}")
        try:
            await websocket.close()
        except Exception:
            # Connection already closed
            pass


@app.post("/chat/stream")
async def chat_stream(request: Request):
    """
    Stream chat responses with typewriter effect.
    """
    global pipeline
    
    body = await request.json()
    question = body.get("question", "").strip()
    session_id = body.get("session_id", "default")
    
    if not question:
        raise HTTPException(status_code=400, detail="प्रश्न खाली छ")
    
    if len(question) > 1000:
        raise HTTPException(status_code=400, detail="प्रश्न धेरै लामो छ (अधिकतम १००० अक्षर)")
    
    async def generate():
        try:
            # Get conversation history for context
            history = chat_history.get(session_id, [])
            
            # Detect follow-up
            is_follow_up, processed_query = detect_follow_up_query(question, history)
            
            # Handle vague queries early
            if not is_follow_up and is_vague_query(question):
                clarifier = "कुन विषयमा? (तालिम/सूचना/घटना) कृपया स्पष्ट पार्नुहोस्।"
                for ch in clarifier:
                    yield json.dumps({"type": "content", "data": ch}) + "\n"
                    await asyncio.sleep(0.02)
                yield json.dumps({"type": "done", "data": clarifier}) + "\n"
                return
            
            # Special-case: which document follow-up
            if is_follow_up:
                doc_keywords = ['kun dastabej', 'कुन दस्तावेज', 'which document', 'कुन फाइल']
                ql = question.lower()
                if any(k in ql for k in doc_keywords):
                    top = last_top_source.get(session_id)
                    if top:
                        name = top.get('title') or top.get('notice_id') or 'Unknown'
                        msg = f"मुख्य स्रोत: {name}"
                        for ch in msg:
                            yield json.dumps({"type": "content", "data": ch}) + "\n"
                            await asyncio.sleep(0.02)
                        yield json.dumps({"type": "done", "data": msg}) + "\n"
                        # Store history
                        if session_id not in chat_history:
                            chat_history[session_id] = []
                        chat_history[session_id].append({
                            "role": "user",
                            "content": question,
                            "timestamp": datetime.now().isoformat()
                        })
                        chat_history[session_id].append({
                            "role": "assistant",
                            "content": msg,
                            "timestamp": datetime.now().isoformat()
                        })
                        return
                    else:
                        # Fallback: direct LLM
                        answer = await direct_llm_query(processed_query)
                else:
                    # Other follow-ups: direct LLM
                    answer = await direct_llm_query(processed_query)
            else:
                # Non-follow-up: run RAG answer
                answer = pipeline.answer(question, conversation_history=history)
                # Compute top source and store for session
                from rag.transliterate import normalize_query
                normalized_query = normalize_query(question)
                retrieved = pipeline.index.search(normalized_query, top_k=settings.top_k)
                doc_count = {}
                sources_dict = {}
                for r in retrieved:
                    meta = r.get('meta', {})
                    notice_id = meta.get('notice_id')
                    if notice_id:
                        doc_count[notice_id] = doc_count.get(notice_id, 0) + 1
                        if notice_id not in sources_dict:
                            sources_dict[notice_id] = {
                                "title": meta.get('title'),
                                "notice_id": notice_id
                            }
                if doc_count:
                    top_notice_id = max(doc_count, key=doc_count.get)
                    last_top_source[session_id] = {
                        "notice_id": top_notice_id,
                        "title": sources_dict[top_notice_id].get("title")
                    }
            
            # Stream answer character by character (typewriter effect)
            for char in answer:
                yield json.dumps({"type": "content", "data": char}) + "\n"
                await asyncio.sleep(0.02)  # Adjust speed here
            
            # Send completion signal
            yield json.dumps({"type": "done", "data": answer}) + "\n"
            
            # Store in chat history
            if session_id not in chat_history:
                chat_history[session_id] = []
            
            chat_history[session_id].append({
                "role": "user",
                "content": question,
                "timestamp": datetime.now().isoformat()
            })
            chat_history[session_id].append({
                "role": "assistant",
                "content": answer,
                "timestamp": datetime.now().isoformat()
            })
            
        except Exception as e:
            yield json.dumps({"type": "error", "data": str(e)}) + "\n"
    
    return StreamingResponse(generate(), media_type="text/event-stream")


@app.post("/chat")
async def chat(question: str = Form(...), session_id: str = Form("default")):
    """
    Non-streaming chat endpoint (fallback).
    """
    global pipeline
    
    if not question or len(question.strip()) == 0:
        raise HTTPException(status_code=400, detail="प्रश्न खाली छ")
    
    if len(question) > 1000:
        raise HTTPException(status_code=400, detail="प्रश्न धेरै लामो छ (अधिकतम १००० अक्षर)")
    
    try:
        # Get conversation history for context
        history = chat_history.get(session_id, [])
        
        # Get answer from pipeline with conversation context
        answer = pipeline.answer(question, conversation_history=history)
        
        # Store in chat history
        if session_id not in chat_history:
            chat_history[session_id] = []
        
        chat_history[session_id].append({
            "role": "user",
            "content": question,
            "timestamp": datetime.now().isoformat()
        })
        chat_history[session_id].append({
            "role": "assistant",
            "content": answer,
            "timestamp": datetime.now().isoformat()
        })
        
        return JSONResponse(content={"answer": answer, "question": question})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"त्रुटि: {str(e)}")


@app.get("/chat/history/{session_id}")
async def get_chat_history(session_id: str):
    """Get chat history for a session."""
    return JSONResponse(content={
        "session_id": session_id,
        "messages": chat_history.get(session_id, [])
    })


@app.delete("/chat/history/{session_id}")
async def clear_chat_history(session_id: str):
    """Clear chat history for a session."""
    if session_id in chat_history:
        del chat_history[session_id]
    return JSONResponse(content={"message": "इतिहास मेटाइयो"})


@app.get("/chat/sessions")
async def get_sessions():
    """Get all chat sessions."""
    sessions = []
    for session_id, messages in chat_history.items():
        if messages:
            sessions.append({
                "session_id": session_id,
                "message_count": len(messages),
                "last_message": messages[-1]["timestamp"] if messages else None,
                "preview": messages[0]["content"][:50] + "..." if messages else ""
            })
    return JSONResponse(content={"sessions": sessions})


# ============================================
# ADVANCED FEATURES ENDPOINTS
# ============================================

@app.get("/stats")
async def get_statistics():
    """Get comprehensive document statistics."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    stats = advanced_features.get_document_statistics()
    return JSONResponse(content=stats)


@app.post("/extract")
async def extract_key_info(request: dict):
    """Extract key information from documents based on query."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    question = request.get("question") or request.get("query")
    if not question:
        raise HTTPException(status_code=400, detail="प्रश्न आवश्यक छ")
    
    top_k = request.get("top_k", 3)
    result = advanced_features.extract_key_information(question, top_k)
    return JSONResponse(content=result)


@app.get("/related/{document_title}")
async def get_related_docs(document_title: str, top_k: int = 5):
    """Find documents related to the given document."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    related = advanced_features.find_related_documents(document_title, top_k)
    return JSONResponse(content={"document": document_title, "related": related})


@app.post("/compare")
async def compare_documents(request: dict):
    """Compare two documents."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    doc1 = request.get("document1")
    doc2 = request.get("document2")
    
    if not doc1 or not doc2:
        raise HTTPException(status_code=400, detail="दुई दस्तावेज आवश्यक छ")
    
    comparison = advanced_features.compare_documents(doc1, doc2)
    return JSONResponse(content=comparison)


@app.post("/search/filter")
async def search_with_filter(request: dict):
    """Search with ministry/service filters."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    query = request.get("query") or request.get("question")
    if not query:
        raise HTTPException(status_code=400, detail="प्रश्न आवश्यक छ")
    
    ministry = request.get("ministry")
    service = request.get("service")
    top_k = request.get("top_k", 6)
    
    results = advanced_features.search_by_filter(query, ministry, service, top_k)
    return JSONResponse(content={
        "query": query,
        "filters": {"ministry": ministry, "service": service},
        "results": results,
        "count": len(results)
    })


@app.post("/batch")
async def batch_query(request: dict):
    """Process multiple questions in batch."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    questions = request.get("questions", [])
    if not questions or not isinstance(questions, list):
        raise HTTPException(status_code=400, detail="प्रश्नहरूको सूची आवश्यक छ")
    
    results = advanced_features.batch_query(questions)
    return JSONResponse(content={
        "total_questions": len(questions),
        "results": results,
        "success_count": sum(1 for r in results if r["status"] == "success"),
        "failed_count": sum(1 for r in results if r["status"] == "failed")
    })


@app.get("/ministry/{ministry_name}/documents")
async def get_ministry_docs(ministry_name: str):
    """Get all documents from a specific ministry."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    docs = advanced_features.get_ministry_documents(ministry_name)
    return JSONResponse(content={
        "ministry": ministry_name,
        "document_count": len(docs),
        "documents": docs
    })


@app.get("/service/{service_name}/documents")
async def get_service_docs(service_name: str):
    """Get all documents from a specific service."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    docs = advanced_features.get_service_documents(service_name)
    return JSONResponse(content={
        "service": service_name,
        "document_count": len(docs),
        "documents": docs
    })


@app.get("/ministries")
async def list_ministries():
    """List all available ministries."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    stats = advanced_features.get_document_statistics()
    ministries = stats.get("ministries", {})
    
    return JSONResponse(content={
        "ministries": [
            {"name": name, "document_count": count}
            for name, count in ministries.items()
        ],
        "total": len(ministries)
    })


@app.get("/services")
async def list_services():
    """List all available services."""
    if not advanced_features:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    stats = advanced_features.get_document_statistics()
    services = stats.get("services", {})
    
    return JSONResponse(content={
        "services": [
            {"name": name, "document_count": count}
            for name, count in services.items()
        ],
        "total": len(services)
    })


@app.post("/admin/clear-cache")
async def clear_cache():
    """Clear all caches (admin endpoint)."""
    if not settings.enable_cache:
        return JSONResponse(content={"message": "Cache not enabled"})
    
    query_cache.clear()
    embedding_cache.clear()
    log_info("Cache cleared by admin")
    
    return JSONResponse(content={
        "message": "Cache cleared successfully",
        "query_cache_cleared": True,
        "embedding_cache_cleared": True
    })


@app.get("/admin/stats")
async def admin_stats():
    """Get detailed system statistics (admin endpoint)."""
    pool = get_pool()
    
    return JSONResponse(content={
        "system": {
            "chunks_loaded": len(pipeline.index.texts) if pipeline else 0,
            "documents_indexed": len(set(m.get('title') for m in pipeline.index.metadata)) if pipeline else 0
        },
        "database": {
            "type": "MySQL" if settings.use_mysql_primary else "SQLite",
            "pool_enabled": pool is not None,
            "pool_size": settings.mysql_pool_size
        },
        "cache": {
            "enabled": settings.enable_cache,
            "query_cache": query_cache.stats(),
            "embedding_cache": embedding_cache.stats()
        },
        "config": {
            "max_query_length": settings.max_query_length,
            "relevance_threshold": settings.relevance_threshold,
            "recency_boost_days": settings.recency_boost_days_high,
            "chunk_size": settings.chunk_size_words
        }
    })


@app.post("/export")
async def export_answer(request: dict):
    """Export answer in different formats (text/JSON)."""
    question = request.get("question") or request.get("query")
    format_type = request.get("format", "json").lower()
    
    if not question:
        raise HTTPException(status_code=400, detail="प्रश्न आवश्यक छ")
    
    if not pipeline:
        raise HTTPException(status_code=503, detail="सेवा तयार छैन")
    
    # Generate answer
    answer = pipeline.answer(question)
    
    timestamp = datetime.now().isoformat()
    
    if format_type == "text":
        # Plain text format
        text_content = f"""नेपाल सरकारी RAG System
{'='*60}
मिति: {timestamp}

प्रश्न: {question}

उत्तर:
{answer}

{'='*60}
"""
        return StreamingResponse(
            iter([text_content]),
            media_type="text/plain",
            headers={
                "Content-Disposition": f"attachment; filename=answer_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
            }
        )
    else:
        # JSON format (default)
        json_content = {
            "timestamp": timestamp,
            "question": question,
            "answer": answer,
            "system": "नेपाल सरकारी RAG System"
        }
        return JSONResponse(content=json_content)


# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve static files
from pathlib import Path as PathlibPath
static_dir = PathlibPath(__file__).parent / "static"
if static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")
else:
    print(f"⚠️ Warning: Static directory not found at {static_dir}")


if __name__ == "__main__":
    import uvicorn
    print("\n" + "="*80)
    print("🚀 नेपाल सरकारी RAG System with Chat Interface")
    print("="*80)
    print(f"📱 Web Interface: http://localhost:8001")
    print(f"📚 API Docs: http://localhost:8001/docs")
    print(f"💾 Database: {'MySQL (Primary)' if settings.use_mysql_primary else 'SQLite'}")
    print("="*80 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=8001)
