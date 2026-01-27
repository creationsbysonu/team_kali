from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from pathlib import Path
from typing import List, Optional
import shutil
import os

from rag.config import settings
from rag.models import E5Embedding, OllamaGenerator
from rag.ingest import ingest_to_db, ingest_to_mysql
from rag.pipeline import RAGPipeline
from rag.db import connect, init_db

# Global pipeline instance
pipeline: Optional[RAGPipeline] = None
embedder: Optional[E5Embedding] = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Lifespan context manager for startup/shutdown."""
    global pipeline, embedder
    
    # Startup
    embedder = E5Embedding()
    generator = OllamaGenerator(model_name="llama3:latest")
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
            print(f"Loaded {len(pipeline.index.texts)} chunks from MySQL (primary)")
        except Exception as e:
            print(f"MySQL load failed, trying SQLite: {e}")
            conn = connect(settings.db_path)
            try:
                pipeline.index.build_from_db(conn)
                print(f"Loaded {len(pipeline.index.texts)} chunks from SQLite (fallback)")
            finally:
                conn.close()
    else:
        conn = connect(settings.db_path)
        try:
            pipeline.index.build_from_db(conn)
            print(f"Loaded {len(pipeline.index.texts)} chunks from SQLite")
        except Exception as e:
            print(f"No existing embeddings found: {e}")
        finally:
            conn.close()
    
    yield
    
    # Shutdown (cleanup if needed)
    pass

app = FastAPI(
    title="नेपाल सरकारी RAG API",
    description="E-Governance Document Q&A System",
    lifespan=lifespan
)


@app.get("/", response_class=HTMLResponse)
async def root():
    """Serve the main HTML interface."""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>नेपाल सरकारी RAG प्रणाली</title>
        <meta charset="UTF-8">
        <style>
            body { 
                font-family: 'Segoe UI', Arial, sans-serif; 
                max-width: 900px; 
                margin: 50px auto; 
                padding: 20px; 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
            }
            h1 { 
                color: #333; 
                text-align: center;
                text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
            }
            .container { 
                background: white; 
                padding: 30px; 
                border-radius: 15px; 
                box-shadow: 0 10px 40px rgba(0,0,0,0.2); 
            }
            .section { 
                margin: 30px 0; 
                padding: 20px; 
                background: #f8f9fa;
                border-radius: 10px; 
            }
            input[type="file"] { 
                margin: 10px 0;
                padding: 12px;
                border: 2px dashed #667eea;
                border-radius: 8px;
                width: 100%;
                cursor: pointer;
                transition: all 0.3s;
            }
            input[type="file"]:hover {
                border-color: #764ba2;
                background: #f0f0ff;
            }
            button { 
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white; 
                border: none; 
                padding: 12px 24px; 
                border-radius: 8px; 
                cursor: pointer; 
                font-size: 16px;
                font-weight: 600;
                width: 100%;
                transition: transform 0.2s, box-shadow 0.2s;
            }
            button:hover { 
                transform: translateY(-2px);
                box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
            }
            button:active {
                transform: translateY(0);
            }
            textarea { 
                width: 100%; 
                padding: 12px; 
                border: 2px solid #ddd; 
                border-radius: 8px; 
                font-size: 16px;
                transition: border-color 0.3s;
            }
            textarea:focus {
                outline: none;
                border-color: #667eea;
            }
            .response { 
                margin-top: 20px; 
                padding: 20px; 
                background: white;
                border: 2px solid #667eea;
                border-radius: 8px; 
                white-space: pre-wrap;
                line-height: 1.8;
            }
            .status { 
                margin: 10px 0; 
                padding: 15px; 
                background: #e3f2fd;
                border-left: 4px solid #1976d2;
                border-radius: 8px;
                color: #1976d2;
            }
            .status.success {
                background: #e8f5e9;
                border-left-color: #2e7d32;
                color: #2e7d32;
            }
            .error { 
                background: #ffebee;
                border-left-color: #c62828;
                color: #c62828;
            }
            
            /* Loading Spinner */
            .loader {
                display: inline-block;
                width: 18px;
                height: 18px;
                border: 3px solid #f3f3f3;
                border-top: 3px solid #667eea;
                border-radius: 50%;
                animation: spin 1s linear infinite;
                margin-right: 8px;
                vertical-align: middle;
            }
            
            @keyframes spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            
            /* Progress Steps */
            .progress-container {
                margin: 15px 0;
                padding: 15px;
                background: white;
                border-radius: 8px;
            }
            
            .progress-step {
                display: flex;
                align-items: center;
                margin: 10px 0;
                padding: 10px;
                background: #f5f5f5;
                border-radius: 6px;
                font-size: 14px;
                transition: all 0.3s;
            }
            
            .progress-step.active {
                background: #e3f2fd;
                border-left: 4px solid #1976d2;
                font-weight: 600;
                color: #1976d2;
            }
            
            .progress-step.completed {
                background: #e8f5e9;
                border-left: 4px solid #2e7d32;
                color: #2e7d32;
            }
            
            .progress-step .icon {
                margin-right: 10px;
                font-size: 18px;
                min-width: 24px;
            }
            
            .dots {
                display: inline-block;
                width: 20px;
            }
            
            .dots:after {
                content: '.';
                animation: dots 1.5s steps(4, end) infinite;
            }
            
            @keyframes dots {
                0%, 20% { content: '.'; }
                40% { content: '..'; }
                60% { content: '...'; }
                80%, 100% { content: ''; }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🇳🇵 नेपाल सरकारी RAG प्रणाली</h1>
            
            <div class="section">
                <h2>📤 कागजात अपलोड गर्नुहोस्</h2>
                <input type="file" id="fileInput" multiple accept=".pdf,.md,.txt,.jpg,.jpeg,.png,.tiff,.bmp">
                <button onclick="uploadFiles()">अपलोड र प्रोसेस गर्नुहोस्</button>
                <div id="uploadStatus"></div>
            </div>
            
            <div class="section">
                <h2>❓ प्रश्न सोध्नुहोस्</h2>
                <textarea id="question" rows="3" placeholder="तपाईंको प्रश्न यहाँ लेख्नुहोस्..."></textarea>
                <button onclick="askQuestion()">उत्तर प्राप्त गर्नुहोस्</button>
                <div id="answer"></div>
            </div>
        </div>
        
        <script>
            async function uploadFiles() {
                const fileInput = document.getElementById('fileInput');
                const statusDiv = document.getElementById('uploadStatus');
                
                if (!fileInput.files.length) {
                    statusDiv.innerHTML = '<div class="status error">कृपया फाइल छान्नुहोस्</div>';
                    return;
                }
                
                // Show progressive loading steps
                statusDiv.innerHTML = `
                    <div class="progress-container">
                        <div class="progress-step active">
                            <span class="icon"><span class="loader"></span></span>
                            <span>📤 फाइल अपलोड गर्दै<span class="dots"></span></span>
                        </div>
                        <div class="progress-step">
                            <span class="icon">⏳</span>
                            <span>पाठ निकाल्दै (OCR यदि आवश्यक भए)</span>
                        </div>
                        <div class="progress-step">
                            <span class="icon">✂️</span>
                            <span>टुक्रामा विभाजन गर्दै</span>
                        </div>
                        <div class="progress-step">
                            <span class="icon">🧠</span>
                            <span>Embeddings बनाउँदै</span>
                        </div>
                        <div class="progress-step">
                            <span class="icon">💾</span>
                            <span>डाटाबेसमा सुरक्षित गर्दै</span>
                        </div>
                    </div>
                `;
                
                const formData = new FormData();
                for (let file of fileInput.files) {
                    formData.append('files', file);
                }
                
                // Simulate step progression
                const steps = statusDiv.querySelectorAll('.progress-step');
                let currentStep = 0;
                const stepInterval = setInterval(() => {
                    if (currentStep > 0) {
                        steps[currentStep - 1].classList.remove('active');
                        steps[currentStep - 1].classList.add('completed');
                        steps[currentStep - 1].querySelector('.icon').innerHTML = '✅';
                    }
                    if (currentStep < steps.length) {
                        steps[currentStep].classList.add('active');
                        if (currentStep > 0) {
                            steps[currentStep].querySelector('.icon').innerHTML = '<span class="loader"></span>';
                        }
                        currentStep++;
                    }
                }, 800);
                
                try {
                    const response = await fetch('/upload', {
                        method: 'POST',
                        body: formData
                    });
                    const result = await response.json();
                    
                    clearInterval(stepInterval);
                    
                    if (response.ok) {
                        // Mark all steps as completed
                        steps.forEach(step => {
                            step.classList.remove('active');
                            step.classList.add('completed');
                            step.querySelector('.icon').innerHTML = '✅';
                        });
                        
                        setTimeout(() => {
                            statusDiv.innerHTML = '<div class="status success">✅ ' + result.message + '<br>📊 कुल Chunks: ' + result.total_chunks + '</div>';
                        }, 500);
                        fileInput.value = '';
                    } else {
                        statusDiv.innerHTML = '<div class="status error">❌ ' + result.detail + '</div>';
                    }
                } catch (error) {
                    clearInterval(stepInterval);
                    statusDiv.innerHTML = '<div class="status error">❌ त्रुटि: ' + error.message + '</div>';
                }
            }
            
            async function askQuestion() {
                const question = document.getElementById('question').value.trim();
                const answerDiv = document.getElementById('answer');
                
                if (!question) {
                    answerDiv.innerHTML = '<div class="status error">कृपया प्रश्न लेख्नुहोस्</div>';
                    return;
                }
                
                // Show progressive answer generation steps
                answerDiv.innerHTML = `
                    <div class="progress-container">
                        <div class="progress-step active">
                            <span class="icon"><span class="loader"></span></span>
                            <span>🔍 प्रश्न विश्लेषण गर्दै<span class="dots"></span></span>
                        </div>
                        <div class="progress-step">
                            <span class="icon">⏳</span>
                            <span>📚 सम्बन्धित कागजातहरू खोज्दै</span>
                        </div>
                        <div class="progress-step">
                            <span class="icon">⏳</span>
                            <span>🤖 उत्तर उत्पन्न गर्दै (Llama3)</span>
                        </div>
                        <div class="progress-step">
                            <span class="icon">⏳</span>
                            <span>📝 उत्तर फर्म्याट गर्दै</span>
                        </div>
                    </div>
                `;
                
                const formData = new FormData();
                formData.append('question', question);
                
                // Simulate step progression
                const steps = answerDiv.querySelectorAll('.progress-step');
                let currentStep = 0;
                const stepInterval = setInterval(() => {
                    if (currentStep > 0) {
                        steps[currentStep - 1].classList.remove('active');
                        steps[currentStep - 1].classList.add('completed');
                        steps[currentStep - 1].querySelector('.icon').innerHTML = '✅';
                    }
                    if (currentStep < steps.length) {
                        steps[currentStep].classList.add('active');
                        if (currentStep > 0) {
                            steps[currentStep].querySelector('.icon').innerHTML = '<span class="loader"></span>';
                        }
                        currentStep++;
                    }
                }, 700);
                
                try {
                    const response = await fetch('/query', {
                        method: 'POST',
                        body: formData
                    });
                    const result = await response.json();
                    
                    clearInterval(stepInterval);
                    
                    if (response.ok) {
                        // Mark all steps as completed
                        steps.forEach(step => {
                            step.classList.remove('active');
                            step.classList.add('completed');
                            step.querySelector('.icon').innerHTML = '✅';
                        });
                        
                        // Show answer after brief delay
                        setTimeout(() => {
                            const formattedAnswer = result.answer.replace(/\\n/g, '<br>');
                            answerDiv.innerHTML = '<div class="response">📄 <strong>उत्तर:</strong><br><br>' + formattedAnswer + '</div>';
                        }, 400);
                    } else {
                        answerDiv.innerHTML = '<div class="status error">❌ ' + result.detail + '</div>';
                    }
                } catch (error) {
                    clearInterval(stepInterval);
                    answerDiv.innerHTML = '<div class="status error">❌ त्रुटि: ' + error.message + '</div>';
                }
            }
        </script>
    </body>
    </html>
    """


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
        safe_filename = "".join(c for c in file.filename if c.isalnum() or c in "._- ")
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


@app.post("/query")
async def query(question: str = Form(...)):
    """
    Query the RAG system with a question.
    Supports both Nepali and romanized Nepali input.
    """
    global pipeline
    
    if not question or len(question.strip()) == 0:
        raise HTTPException(status_code=400, detail="प्रश्न खाली छ")
    
    if len(question) > 1000:
        raise HTTPException(status_code=400, detail="प्रश्न धेरै लामो छ (अधिकतम १००० अक्षर)")
    
    try:
        answer = pipeline.answer(question)
        return JSONResponse(content={"answer": answer, "question": question})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"त्रुटि: {str(e)}")


# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
