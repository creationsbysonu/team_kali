# Nova2 - नेपाली RAG Chat System

A modern Retrieval-Augmented Generation (RAG) chat system for Nepali government documents with advanced streaming, OCR, and a beautiful dark-mode UI.

## 🌟 Key Features

### Core Capabilities
- **Semantic Search**: E5 multilingual embeddings with MySQL vector storage (279 chunks loaded)
- **Streaming Responses**: Real-time answer generation with typewriter effect
- **Enhanced OCR**: Multi-pass Tesseract with PSM modes (3, 6, 11, 4) for better accuracy
- **Transliteration**: Romanization support for English document chunks
- **Dual Database**: MySQL primary + SQLite secondary sync

### Modern Chat Interface
- **Stop Generation**: Abort ongoing responses mid-stream using AbortController
- **Edit Messages**: Click edit button on any user message to modify and regenerate response
- **Chat History**: Automatic session management and persistence
- **File Upload**: Support for PDF, images, and text documents with progress tracking

### Beautiful UI/UX
- **🌙 Dark Mode**: Complete theme system with localStorage persistence
- **📱 Mobile Responsive**: Hamburger menu, slide-in sidebar, overlay for mobile devices
- **🎨 Modern Design**: Gradient buttons, smooth 0.3s transitions, box shadows
- **⚡ Loading States**: Visual feedback during processing with pulse animations
- **❌ Smart Errors**: Friendly error messages with retry suggestions

## 🚀 Quick Start

### Prerequisites
- Python 3.10+
- MySQL 8.0+ database
- Conda environment: `rag-st`
- Tesseract OCR installed

### Installation & Running

```bash
# Activate conda environment
conda activate rag-st

# Run the application
python app_chat.py

# Server starts at http://localhost:8001
```

### Access the Chat Interface
Open your browser: **http://localhost:8001**

## 📁 Project Structure

```
nova2/
├── app_chat.py              # FastAPI backend with streaming (345 lines)
├── static/
│   ├── index.html           # Chat UI with dark mode (918 lines)
│   └── app.js               # Frontend logic (560 lines)
├── ocr_enhanced.py          # Enhanced OCR with multi-pass
├── requirements.txt         # Python dependencies
├── .env                     # Environment configuration (not in git)
└── .gitignore               # Version control exclusions
```

## 🎨 UI Features Walkthrough

### Stop Button During Generation
1. Type a question and click Send (📤)
2. Red "रोक्नुहोस्" button appears during generation
3. Click to abort streaming instantly
4. Partial response is preserved

### Edit Previous Messages
1. Hover over any user message
2. Click the edit button (✏️) that appears
3. Message loads back into input field
4. Edit and resend - subsequent messages are removed

### Dark Mode Toggle
1. Click theme toggle button (🌙) in sidebar header
2. Smooth transition to dark theme
3. Preference saved in localStorage
4. Auto-loads on next visit

### Mobile Experience
1. Resize browser to <768px width
2. Hamburger menu (☰) appears in top-left
3. Click to slide-in sidebar from left
4. Dark overlay closes sidebar on tap
5. All features work perfectly on mobile

## 🔧 Technical Implementation

### Backend (app_chat.py)
- **Framework**: FastAPI with async/await and lifespan context
- **Streaming**: Server-Sent Events with JSON chunks
- **Embeddings**: sentence-transformers E5 model
- **LLM**: Ollama integration (llama3.2 or qwen2.5)
- **Storage**: In-memory chat_history dict + MySQL persistence
- **Endpoints**:
  - `POST /chat/stream` - Streaming chat responses
  - `GET /chat/history` - List all chat sessions
  - `GET /chat/history/{session_id}` - Load specific session
  - `DELETE /chat/history/{session_id}` - Clear session
  - `POST /upload` - File upload with OCR processing

### Frontend (app.js - 560 lines)
- **Pure JavaScript**: No frameworks, vanilla JS with modern APIs
- **AbortController**: For canceling fetch requests mid-stream
- **Fetch API**: Streaming responses with ReadableStream
- **LocalStorage**: Theme and session persistence
- **Event Delegation**: Efficient DOM event handling
- **State Management**:
  - `currentAbortController` - Track ongoing requests
  - `editingMessageId` - Manage edit mode
  - `isProcessing` - Prevent duplicate sends

### UI Architecture (index.html - 918 lines)
- **CSS Variables**: 14+ theme variables for light/dark modes
- **Responsive Design**: Media queries at 768px, 480px breakpoints
- **Animations**: Smooth 0.3s transitions, typewriter effect, pulse loading
- **Components**:
  - Sidebar with chat history
  - Main chat area with message bubbles
  - Input area with send/stop buttons
  - Upload modal with progress bars
  - Mobile menu and overlay

## 🛠️ Configuration

### Environment Variables (.env)
```env
# MySQL Primary Database
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=your_user
MYSQL_PASSWORD=your_password
MYSQL_DATABASE=rag_db

# Ollama LLM
OLLAMA_MODEL=llama3.2  # or qwen2.5
OLLAMA_BASE_URL=http://localhost:11434
```

### Customize Theme Colors
Edit CSS variables in [static/index.html](static/index.html#L14-L47):
```css
:root {
    --primary: #6366f1;      /* Primary color */
    --secondary: #8b5cf6;    /* Secondary color */
    --success: #10b981;      /* Success states */
    --error: #ef4444;        /* Error states */
    /* ... 10+ more variables */
}
```

## 🎯 Keyboard Shortcuts
- **Ctrl/Cmd + Enter**: Send message (also works from textarea)
- **Escape**: Close upload modal

## 🐛 Troubleshooting

### Server Won't Start
```bash
# Check if port 8001 is in use
lsof -i :8001
kill -9 <PID>  # Kill existing process

# Verify conda environment
conda activate rag-st
which python  # Should show rag-st path
```

### Dark Mode Not Persisting
- Check browser console (F12) for localStorage errors
- Clear browser cache: Cmd+Shift+R (Mac) or Ctrl+F5 (Windows)
- Verify theme toggle button has click event

### Stop Button Not Appearing
- Requires modern browser with AbortController support
- Check Network tab (F12) for streaming request
- Verify `currentAbortController` is not null during generation

### Edit Message Not Working
- Hover over user messages (not assistant messages)
- Edit button should fade in with 0.3s transition
- Check console for JavaScript errors

### Mobile Menu Not Sliding
- Verify screen width < 768px (use responsive mode in DevTools)
- Check `translateX(-100%)` CSS animation
- Mobile overlay should appear with dark background

## 📦 Key Dependencies

### Python Packages (see requirements.txt)
- `fastapi` - Modern web framework
- `uvicorn` - ASGI server
- `mysql-connector-python` - MySQL driver
- `sentence-transformers` - E5 embeddings
- `pytesseract` - OCR wrapper
- `pdf2image` - PDF to image conversion
- `opencv-python` - Image preprocessing
- `numpy` - Vector operations

### System Requirements
- **Tesseract OCR**: `brew install tesseract` (Mac)
- **Poppler**: For pdf2image - `brew install poppler`
- **MySQL 8.0+**: Vector storage

## 🎉 Recent Updates (Current Session)

### Phase 15 - Final Polish ✅
- Fixed CSS syntax error (orphaned rules in index.html)
- Added loading states with `.loading` class
- Improved error messages with retry suggestions
- Added timestamps to chat history sessions
- Keyboard shortcut hint in input placeholder
- Null checks for all DOM element access
- Better connection retry logic
- .gitignore entries for backup files

### Phase 14 - UI Enhancement ✅
- Complete dark mode with 14+ CSS variables
- Mobile responsive design (768px, 480px breakpoints)
- Hamburger menu with slide-in sidebar
- Theme toggle with localStorage persistence
- Enhanced gradients and box shadows
- Smooth 0.3s transitions throughout

### Phase 13 - Stop & Edit ✅
- Stop button with AbortController
- Edit message functionality
- Unique message IDs
- Edit button on hover
- Message removal after edit point

### Phase 12 - Transliteration ✅
- Fixed halant issues in romanization
- English word preservation
- sambidhan special mapping
- LLM prompt improvements

## 🔐 Security Considerations
- Environment variables for credentials (never commit .env)
- .gitignore for sensitive files
- Input validation on backend endpoints
- CORS configuration for API
- Secure session management

## 📊 Performance Stats
- **Chunks Loaded**: 279 from MySQL
- **Average Response Time**: ~2-3 seconds for streaming start
- **Typewriter Speed**: ~30ms per character
- **Database**: Vector similarity search via MySQL cosine distance

## 🆘 Support & Common Issues

**"सर्भर संग सम्पर्क हुन सकेन" Error**
1. Check if server is running: `curl http://localhost:8001`
2. Verify MySQL connection in terminal logs
3. Check .env file has correct credentials

**Stop Button Stuck Visible**
- Refresh page (F5)
- Check browser console for errors
- Verify `currentAbortController = null` after stream ends

**Chat History Not Loading**
- Check `/chat/history` endpoint in Network tab
- Verify MySQL `chat_sessions` table exists
- Check server logs for database errors

**Mobile Sidebar Won't Close**
- Tap dark overlay area
- Use hamburger menu (☰) to toggle
- Check z-index in DevTools (overlay should be 999)

---

**Version**: 2.0  
**Last Updated**: December 2024  
**Developer**: sonu  
**Environment**: rag-st (conda)  
**Status**: Production Ready ✅  
**Database**: 279 chunks loaded from MySQL
   Document body here...
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run a demo:
   ```bash
   python main.py --build-index
   python main.py --question "अनलाइन सेवाको आवेदन प्रकृया के हो?"
   ```

## MySQL Backend (phpMyAdmin)
- Manage your MySQL database via phpMyAdmin; the app stores chunks and embeddings in tables you can inspect.
- Initialize schema and ingest using CLI flags:
   ```bash
   python main.py --use-mysql --init-db --mysql-host localhost --mysql-port 3306 --mysql-user root --mysql-password YOUR_PASS --mysql-db rag
   python main.py --use-mysql --ingest --mysql-host localhost --mysql-port 3306 --mysql-user root --mysql-password YOUR_PASS --mysql-db rag
   python main.py --use-mysql --build-index-from-db --mysql-host localhost --mysql-port 3306 --mysql-user root --mysql-password YOUR_PASS --mysql-db rag
   python main.py --use-mysql --question "अनलाइन सेवाको आवेदन प्रकृया के हो?" --mysql-host localhost --mysql-port 3306 --mysql-user root --mysql-password YOUR_PASS --mysql-db rag
   ```
- Tables: `documents`, `chunks`, `embeddings`. Vectors are saved as JSON for easy visualization.

## PDF Support
- Place `.pdf` files in `data/docs`; text is extracted via `pypdf` and chunked like `.md/.txt`.
- Front-matter metadata is supported for `.md/.txt`. PDFs default to filename as `title` and unknown `ministry`/`upload_date` unless provided elsewhere.

## Embedding Model: intfloat/multilingual-e5-base

The system uses `intfloat/multilingual-e5-base` for multilingual embeddings via the `E5Embedding` adapter.

**Usage with `--use-st` flag:**
```bash
python main.py --ingest --use-st
python main.py --question "तपाईंको प्रश्न यहाँ" --use-st
```

**Important Notes:**
- The E5 model requires ~2GB download on first run
- ARM macOS users: If you encounter segfaults, run on Linux/Docker or use a server environment
- For production deployment on stable environments (Linux server, Docker, Google Colab), the E5 adapter works reliably

**Troubleshooting ARM macOS:**
If embeddings fail locally, the full pipeline works - deploy to:
- Linux server with Python 3.11+
- Docker container (see Dockerfile below)
- Cloud platforms (AWS, GCP, Azure)

**Quick Docker Setup:**
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "main.py"]
```

## Model Adapters
- Implement `EmbeddingModel.embed(texts: List[str]) -> np.ndarray` to return a 2D array of vectors.
- Implement `GenerativeModel.generate(prompt: str) -> str` to return a string answer.
See `rag/models.py` for base classes and `rag/pipeline.py` for how prompts are constructed.

## Metadata & Citations
- Ingestion captures `ministry`, `title`, and `upload_date` from front-matter.
- Answers include sources in: `स्रोत: {Ministry} – {Document Title} (अपलोड मिति: {Upload Date})`.

## Notes
- This is a minimal reference; integrate your own embedding/LLM providers in `rag/models.py`.
- For PDFs or advanced loaders, extend `rag/ingest.py`.
# nova_hack
