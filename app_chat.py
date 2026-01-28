"""
Modern FastAPI backend with streaming responses and chat history
"""
from dotenv import load_dotenv
load_dotenv()  # Load .env file before anything else

from fastapi import FastAPI, File, UploadFile, HTTPException, Form, Request
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

# Global pipeline instance
pipeline: Optional[RAGPipeline] = None
embedder: Optional[E5Embedding] = None

# Chat history storage (in production, use a database)
chat_history = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup/shutdown."""
    global pipeline, embedder
    
    # Startup
    embedder = E5Embedding()
    generator = GeminiGenerator()  # Uses GOOGLE_GEMINI_API_KEY from .env
    pipeline = RAGPipeline(embedder, generator)
    
    # Ensure DB and uploads directory exist
    settings.uploads_dir.mkdir(parents=True, exist_ok=True)
    conn = connect(settings.db_path)
    try:
        init_db(conn)
    finally:
        conn.close()
    
    # Load existing embeddings from primary database
    if settings.use_mysql_primary:
        try:
            import pymysql
            mysql_conn = pymysql.connect(
                host=settings.mysql_host,
                port=settings.mysql_port,
                user=settings.mysql_user,
                password=settings.mysql_password,
                database=settings.mysql_database,
            )
            pipeline.index.build_from_mysql(mysql_conn)
            mysql_conn.close()
            print(f"✅ Loaded {len(pipeline.index.texts)} chunks from MySQL (primary)")
        except Exception as e:
            print(f"⚠️ MySQL load failed, trying SQLite: {e}")
            conn = connect(settings.db_path)
            try:
                pipeline.index.build_from_db(conn)
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
    return {
        "status": "online",
        "message": "RAG System is running! ✅",
        "server": "192.168.1.118:8001",
        "chunks_loaded": len(pipeline.index.texts) if pipeline else 0,
        "endpoints": {
            "upload": "POST /ingest - Upload PDF via Cloudinary URL",
            "chat": "POST /chat/simple - Ask questions"
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
        raise HTTPException(status_code=400, detail="कुनै फाइल प्रदान गरिएन")
    
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
        
        # Sanitize filename
        safe_filename = "".join(c for c in file.filename if c.isalnum() or c in "._-एआइईउऊऋऌएऐओऔकखगघङचछजझञटठडढणतथदधनपफबभमयरलवशषसहक्षत्रज्ञ")
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
    """Request model for URL-based file ingestion"""
    file_url: str
    notice_id: str
    title: Optional[str] = None
    ministry: Optional[str] = None
    upload_date: Optional[str] = None


class Source(BaseModel):
    """Source reference for chat responses"""
    notice_id: str
    title: Optional[str] = None
    excerpt: Optional[str] = None
    score: Optional[float] = None


class ChatRequestSimple(BaseModel):
    """Simple chat request model"""
    question: str
    session_id: Optional[str] = "default"


class ChatResponseSimple(BaseModel):
    """Chat response with sources"""
    answer: str
    sources: List[Source] = []


@app.post("/ingest")
async def ingest_from_url(req: IngestRequest):
    """
    Django sends file URL + notice_id from Cloudinary.
    We download, process, and store with notice_id.
    """
    global pipeline, embedder
    
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
        
        # Add notice_id to metadata by creating a marker file
        metadata_file = temp_path.with_suffix('.meta.json')
        metadata = {
            "notice_id": req.notice_id,
            "title": req.title or "Unknown",
            "ministry": req.ministry or "Unknown",
            "upload_date": req.upload_date or datetime.now().strftime("%Y-%m-%d")
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
        
        return {
            "success": True,
            "notice_id": req.notice_id,
            "title": req.title or "Unknown",
            "chunks_processed": len(pipeline.index.texts)
        }
    
    except httpx.HTTPError as e:
        raise HTTPException(status_code=400, detail=f"फाइल डाउनलोड त्रुटि: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"प्रशोधन त्रुटि: {str(e)}")


@app.post("/chat/simple", response_model=ChatResponseSimple)
async def chat_simple(req: ChatRequestSimple):
    """
    Simple chat endpoint for Django integration.
    Returns answer with sources containing notice_id.
    """
    global pipeline
    
    try:
        # Get conversation history
        history = chat_history.get(req.session_id, [])
        
        # Get answer from pipeline
        answer = pipeline.answer(req.question, conversation_history=history)
        
        # Perform the same retrieval to get sources
        from rag.transliterate import normalize_query
        normalized_question = normalize_query(req.question)
        retrieved = pipeline.index.search(normalized_question, top_k=settings.top_k)
        
        # Extract unique sources from retrieved chunks
        sources_dict = {}
        for r in retrieved:
            meta = r.get('meta', {})
            notice_id = meta.get('notice_id')
            
            # Only include sources with notice_id (from Cloudinary uploads)
            if notice_id and notice_id not in sources_dict:
                # Extract short excerpt (clean page markers)
                excerpt = r['text'][:150]
                excerpt = re.sub(r'\[पृष्ठ \d+\]', '', excerpt).strip()
                
                sources_dict[notice_id] = Source(
                    notice_id=notice_id,
                    title=meta.get('title', 'Unknown'),
                    excerpt=excerpt,
                    score=r.get('score', 0.0)
                )
        
        sources = list(sources_dict.values())
        
        # Store in chat history
        if req.session_id not in chat_history:
            chat_history[req.session_id] = []
        
        chat_history[req.session_id].append({
            "role": "user",
            "content": req.question,
            "timestamp": datetime.now().isoformat()
        })
        chat_history[req.session_id].append({
            "role": "assistant",
            "content": answer,
            "timestamp": datetime.now().isoformat()
        })
        
        return ChatResponseSimple(answer=answer, sources=sources)
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"त्रुटि: {str(e)}")


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
            
            # Get answer from pipeline with conversation context
            answer = pipeline.answer(question, conversation_history=history)
            
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
