# 🚀 Nepal Government RAG System - Complete Features Guide

## 📚 Table of Contents
1. [Core Features](#core-features)
2. [Advanced Analytics](#advanced-analytics)
3. [Document Management](#document-management)
4. [Search & Retrieval](#search--retrieval)
5. [Batch Processing](#batch-processing)
6. [API Endpoints Reference](#api-endpoints-reference)

---

## Core Features

### 1. **Document Q&A with Streaming**
- Real-time streaming responses
- Conversation history support
- Automatic romanization and spell correction
- Multi-strategy search (exact, fuzzy, phonetic)

**Endpoint:** `POST /chat/stream`
```json
{
  "question": "nyaayalaya ko adhikaar ke ke hun?",
  "session_id": "session_123"
}
```

### 2. **Document Summarization**
- Automatic summary generation
- Context-aware summarization
- Works on previous answers

**Usage:** Ask "छोट्करीमा भन्नुहोस्" after any question

### 3. **Universal Spell Correction**
- 500+ word dictionary
- Phonetic similarity matching
- Edit distance correction
- Pattern-based fixes

**Automatically applied to all queries**

### 4. **Document Ingestion**
- Local file upload
- URL-based ingestion (Cloudinary integration)
- Automatic OCR for scanned PDFs
- Metadata extraction (ministry, service, title)

**Endpoints:**
- `POST /upload` - Upload local files
- `POST /ingest` - Ingest from URL (Django integration)

---

## Advanced Analytics

### 5. **Document Statistics** ✨ NEW
Get comprehensive insights about your document collection.

**Endpoint:** `GET /stats`

**Response:**
```json
{
  "total_documents": 45,
  "total_chunks": 892,
  "ministries": {
    "गृह मन्त्रालय": 150,
    "शिक्षा मन्त्रालय": 200
  },
  "services": {
    "नागरिकता सेवा": 120,
    "परीक्षा सेवा": 180
  },
  "average_chunk_length": 145.3,
  "total_words": 129847,
  "ministry_count": 8,
  "service_count": 15
}
```

### 6. **Key Information Extraction** ✨ NEW
Extract key facts and information from documents.

**Endpoint:** `POST /extract`

**Request:**
```json
{
  "question": "नागरिकता बारे",
  "top_k": 3
}
```

**Response:**
```json
{
  "query": "नागरिकता बारे",
  "key_facts": [
    {
      "fact": "नागरिकता प्राप्त गर्न जन्म प्रमाणपत्र आवश्यक छ",
      "confidence": 0.8756,
      "source": "नागरिकता नियमावली"
    }
  ],
  "sources": ["नागरिकता नियमावली"],
  "confidence": 0.8234,
  "total_facts_found": 15
}
```

---

## Document Management

### 7. **Related Documents Finder** ✨ NEW
Find documents similar to a given document.

**Endpoint:** `GET /related/{document_title}?top_k=5`

**Example:** `GET /related/नागरिकता नियमावली?top_k=5`

**Response:**
```json
{
  "document": "नागरिकता नियमावली",
  "related": [
    {
      "title": "जन्म दर्ता नियम",
      "ministry": "गृह मन्त्रालय",
      "service": "जन्म दर्ता सेवा",
      "relevance_score": 0.7845,
      "notice_id": "2081-002"
    }
  ]
}
```

### 8. **Document Comparison** ✨ NEW
Compare two documents side-by-side.

**Endpoint:** `POST /compare`

**Request:**
```json
{
  "document1": "नागरिकता ऐन 2063",
  "document2": "नागरिकता नियमावली 2064"
}
```

**Response:**
```json
{
  "document1": "नागरिकता ऐन 2063",
  "document2": "नागरिकता नियमावली 2064",
  "similarity_score": 0.6523,
  "common_topics": 245,
  "unique_to_doc1": 89,
  "unique_to_doc2": 112,
  "comparison_summary": "नागरिकता ऐन 2063 र नागरिकता नियमावली 2064 केही मिल्दोजुल्दो छन् (समानता: 65.2%)"
}
```

### 9. **Ministry/Service Document Listing** ✨ NEW
Get all documents from specific ministry or service.

**Endpoints:**
- `GET /ministry/{ministry_name}/documents`
- `GET /service/{service_name}/documents`
- `GET /ministries` - List all ministries
- `GET /services` - List all services

**Example:** `GET /ministry/गृह मन्त्रालय/documents`

**Response:**
```json
{
  "ministry": "गृह मन्त्रालय",
  "document_count": 12,
  "documents": [
    {
      "title": "नागरिकता नियमावली",
      "ministry": "गृह मन्त्रालय",
      "service": "नागरिकता सेवा",
      "notice_id": "2081-001",
      "chunk_count": 45
    }
  ]
}
```

---

## Search & Retrieval

### 10. **Filtered Search** ✨ NEW
Search with ministry and/or service filters.

**Endpoint:** `POST /search/filter`

**Request:**
```json
{
  "query": "आवेदन प्रक्रिया",
  "ministry": "गृह मन्त्रालय",
  "service": "नागरिकता सेवा",
  "top_k": 6
}
```

**Response:**
```json
{
  "query": "आवेदन प्रक्रिया",
  "filters": {
    "ministry": "गृह मन्त्रालय",
    "service": "नागरिकता सेवा"
  },
  "results": [
    {
      "text": "आवेदन फारम भर्नुपर्छ र आवश्यक कागजात संलग्न गर्नुपर्छ...",
      "score": 0.8234,
      "ministry": "गृह मन्त्रालय",
      "service": "नागरिकता सेवा",
      "title": "नागरिकता नियमावली",
      "notice_id": "2081-001"
    }
  ],
  "count": 6
}
```

### 11. **Answer Export** ✨ NEW
Export answers in different formats (JSON/Text).

**Endpoint:** `POST /export`

**Request:**
```json
{
  "question": "राष्ट्रपतिको अधिकार",
  "format": "text"  // or "json"
}
```

**Response:** Downloads file with answer

---

## Batch Processing

### 12. **Batch Query Processing** ✨ NEW
Process multiple questions at once.

**Endpoint:** `POST /batch`

**Request:**
```json
{
  "questions": [
    "नागरिकता कसरी लिने?",
    "राहदानी बनाउन के चाहिन्छ?",
    "जन्म दर्ता कहाँ गर्ने?"
  ]
}
```

**Response:**
```json
{
  "total_questions": 3,
  "results": [
    {
      "question_number": 1,
      "question": "नागरिकता कसरी लिने?",
      "answer": "नागरिकता प्राप्त गर्न...",
      "status": "success"
    }
  ],
  "success_count": 3,
  "failed_count": 0
}
```

---

## Chat Features

### 13. **Chat History Management**
- Session-based chat history
- Message persistence
- History retrieval

**Endpoints:**
- `GET /chat/history/{session_id}` - Get chat history
- `DELETE /chat/history/{session_id}` - Clear history
- `GET /chat/sessions` - List all sessions

---

## API Endpoints Reference

### Core Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Web interface |
| GET | `/health` | Health check |
| POST | `/upload` | Upload local files |
| POST | `/ingest` | Ingest from URL |
| POST | `/chat` | Chat (non-streaming) |
| POST | `/chat/stream` | Chat with streaming |

### Advanced Features ✨ NEW
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/stats` | Document statistics |
| POST | `/extract` | Key information extraction |
| GET | `/related/{title}` | Find related documents |
| POST | `/compare` | Compare two documents |
| POST | `/search/filter` | Filtered search |
| POST | `/batch` | Batch query processing |
| POST | `/export` | Export answers |

### Document Management ✨ NEW
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/ministry/{name}/documents` | Ministry documents |
| GET | `/service/{name}/documents` | Service documents |
| GET | `/ministries` | List all ministries |
| GET | `/services` | List all services |

### Chat Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/chat/history/{session_id}` | Get chat history |
| DELETE | `/chat/history/{session_id}` | Clear chat history |
| GET | `/chat/sessions` | List all sessions |

---

## Usage Examples

### Example 1: Getting Document Statistics
```bash
curl http://localhost:8001/stats
```

### Example 2: Finding Related Documents
```bash
curl http://localhost:8001/related/नागरिकता%20नियमावली?top_k=3
```

### Example 3: Filtered Search
```bash
curl -X POST http://localhost:8001/search/filter \
  -H "Content-Type: application/json" \
  -d '{
    "query": "आवेदन प्रक्रिया",
    "ministry": "गृह मन्त्रालय",
    "top_k": 5
  }'
```

### Example 4: Batch Processing
```bash
curl -X POST http://localhost:8001/batch \
  -H "Content-Type: application/json" \
  -d '{
    "questions": [
      "नागरिकता कसरी लिने?",
      "राहदानी बनाउन के चाहिन्छ?"
    ]
  }'
```

### Example 5: Comparing Documents
```bash
curl -X POST http://localhost:8001/compare \
  -H "Content-Type: application/json" \
  -d '{
    "document1": "नागरिकता ऐन 2063",
    "document2": "नागरिकता नियमावली 2064"
  }'
```

---

## Feature Highlights

✅ **13 Major Features** implemented
✅ **20+ API Endpoints** available
✅ **Real-time Streaming** responses
✅ **Universal Spell Correction** (500+ words)
✅ **Multi-strategy Search** (exact, fuzzy, phonetic)
✅ **Automatic OCR** for scanned documents
✅ **Rich Metadata** (ministry, service, title, notice_id)
✅ **Document Analytics** and statistics
✅ **Batch Processing** for multiple queries
✅ **Export Functionality** (JSON/Text)
✅ **Filtered Search** by ministry/service
✅ **Document Comparison** and similarity
✅ **Related Documents** finder
✅ **Django Integration** ready

---

## Technology Stack

- **Backend:** FastAPI 0.104+
- **Database:** MySQL (primary) + SQLite (fallback)
- **Embeddings:** E5 Multilingual Base
- **LLM:** Google Gemini 2.5 Flash
- **OCR:** Tesseract with multi-pass enhancement
- **Language:** Python 3.11+

---

## Quick Start

```bash
# Start the server
python app_chat.py

# Access web interface
open http://localhost:8001

# View API documentation
open http://localhost:8001/docs
```

---

## Support

For issues or feature requests, please check the documentation or contact the development team.

**System Version:** 2.0 (Advanced Features Edition)
**Last Updated:** January 2026
