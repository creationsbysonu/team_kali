# Django Integration Guide for RAG System

## 📋 Overview
This document specifies what the Django system needs to send to the FastAPI RAG system for document ingestion and Q&A functionality.

---

## 🔗 Base URL
```
http://192.168.1.118:8001
```
*(Make sure both systems are on the same WiFi network)*

---

## 📤 1. DOCUMENT INGESTION ENDPOINT

### **Endpoint:** `POST /ingest`

### **When to Use:**
Call this endpoint **immediately after uploading a PDF to Cloudinary** from Django.

### **Required Data from Django:**

```json
{
  "file_url": "https://res.cloudinary.com/your-cloud/document.pdf",
  "notice_id": "unique-uuid-string",
  "title": "Notice Title in Nepali or English",
  "ministry": "Ministry Name (optional)",
  "upload_date": "2026-01-28 (optional)"
}
```

### **Field Details:**

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `file_url` | string | ✅ **YES** | Full Cloudinary URL of the uploaded PDF | `"https://res.cloudinary.com/demo/raw/upload/v1234567890/notice_abc.pdf"` |
| `notice_id` | string | ✅ **YES** | Unique identifier from Django database (UUID recommended) | `"550e8400-e29b-41d4-a716-446655440000"` |
| `title` | string | ⚠️ Recommended | Human-readable title of the notice | `"राज्य मन्त्रालयको सूचना"` |
| `ministry` | string | ❌ Optional | Ministry or department name | `"गृह मन्त्रालय"` |
| `upload_date` | string | ❌ Optional | Date of upload (YYYY-MM-DD format) | `"2026-01-28"` |

### **Success Response:**
```json
{
  "success": true,
  "notice_id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "राज्य मन्त्रालयको सूचना",
  "chunks_processed": 142
}
```

### **Error Response:**
```json
{
  "detail": "फाइल डाउनलोड त्रुटि: HTTP 404 Not Found"
}
```

### **Django Example Code:**

```python
import requests
import uuid

def upload_notice_to_rag(cloudinary_url, notice_title, ministry_name=None):
    """
    Send uploaded notice to RAG system for processing
    
    Args:
        cloudinary_url: Full URL of PDF stored in Cloudinary
        notice_title: Title of the notice
        ministry_name: Optional ministry name
    
    Returns:
        dict: Response from RAG system
    """
    # Your notice model should have a UUID field
    notice_id = str(uuid.uuid4())  # Or use existing UUID from database
    
    payload = {
        "file_url": cloudinary_url,
        "notice_id": notice_id,
        "title": notice_title,
        "ministry": ministry_name or "Unknown",
        "upload_date": datetime.now().strftime("%Y-%m-%d")
    }
    
    try:
        response = requests.post(
            "http://192.168.1.118:8001/ingest",
            json=payload,
            timeout=300  # 5 minutes (processing can take time)
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"RAG ingestion failed: {e}")
        return None
```

### **Important Notes:**
- ⏱️ **Processing Time:** Can take 30 seconds to 2 minutes depending on PDF size
- 🔄 **Timeout:** Set HTTP timeout to at least 5 minutes
- 📁 **File Format:** Only PDF files are supported
- 🔗 **URL Validity:** Cloudinary URL must be publicly accessible
- 💾 **Storage:** Notice is stored in RAG's database with the provided `notice_id`

---

## 💬 2. CHAT/Q&A ENDPOINT

### **Endpoint:** `POST /chat/simple`

### **When to Use:**
When a user asks a question about government notices through your Flutter app.

### **Required Data from Django:**

```json
{
  "question": "नेपालको राष्ट्रपतिको कार्यकाल कति हो?",
  "session_id": "user-unique-id-or-session-id"
}
```

### **Field Details:**

| Field | Type | Required | Description | Example |
|-------|------|----------|-------------|---------|
| `question` | string | ✅ **YES** | User's question in Nepali or English | `"राष्ट्रपतिको कार्यकाल कति छ?"` |
| `session_id` | string | ⚠️ Recommended | Unique identifier for conversation continuity | `"user_123"` or `"session_abc"` |

### **Success Response:**
```json
{
  "answer": "नेपालको राष्ट्रपतिको कार्यकाल ५ वर्षको हुन्छ। राष्ट्रपति...",
  "sources": [
    {
      "notice_id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "नेपालको संविधान",
      "excerpt": "राष्ट्रपतिको कार्यकाल पाँच वर्षको हुनेछ...",
      "score": 0.92
    },
    {
      "notice_id": "660e8400-e29b-41d4-a716-446655440111",
      "title": "राष्ट्रपति कार्यालयको विधान",
      "excerpt": "कार्यकाल सम्बन्धी व्यवस्था...",
      "score": 0.85
    }
  ]
}
```                     

### **Response Field Details:**

| Field | Type | Description |
|-------|------|-------------|
| `answer` | string | Complete answer to the question in Nepali |
| `sources` | array | List of source documents used to generate the answer |
| `sources[].notice_id` | string | **The UUID you sent during ingestion** - Use this to create deep links! |
| `sources[].title` | string | Title of the source document |
| `sources[].excerpt` | string | Relevant excerpt from the document (150 chars max) |
| `sources[].score` | float | Relevance score (0.0 to 1.0) - higher means more relevant |

### **Django Example Code:**

```python
import requests

def ask_rag_question(user_question, user_id):
    """
    Send question to RAG system and get answer with sources
    
    Args:
        user_question: The question asked by the user
        user_id: User ID or session ID for conversation continuity
    
    Returns:
        dict: Answer and source documents
    """
    payload = {
        "question": user_question,
        "session_id": str(user_id)
    }
    
    try:
        response = requests.post(
            "http://192.168.1.118:8001/chat/simple",
            json=payload,
            timeout=30  # 30 seconds should be enough
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"RAG query failed: {e}")
        return {
            "answer": "माफ गर्नुहोस्, त्रुटि भयो। कृपया पुन: प्रयास गर्नुहोस्।",
            "sources": []
        }
```

### **Important Notes:**
- ⚡ **Response Time:** Typically 3-10 seconds
- 🔄 **Conversation Memory:** Use same `session_id` for follow-up questions
- 🌐 **Language Support:** Questions can be in Nepali or English
- 📚 **Source Linking:** Use `notice_id` in sources to create clickable links back to Django notice detail page

---

## 🎯 3. COMPLETE FLOW EXAMPLE

### **Scenario:** User uploads a notice and then asks a question about it

```python
# Step 1: User uploads PDF in Django admin/frontend
uploaded_file = request.FILES['notice_pdf']

# Step 2: Upload to Cloudinary
cloudinary_response = cloudinary.uploader.upload(
    uploaded_file,
    resource_type='raw',  # Important for PDFs
    folder='government_notices'
)
cloudinary_url = cloudinary_response['secure_url']

# Step 3: Send to RAG system for ingestion
notice_id = str(uuid.uuid4())
rag_response = requests.post(
    "http://192.168.1.118:8001/ingest",
    json={
        "file_url": cloudinary_url,
        "notice_id": notice_id,
        "title": "नयाँ सूचना २०२६",
        "ministry": "गृह मन्त्रालय",
        "upload_date": "2026-01-28"
    },
    timeout=300
)

if rag_response.status_code == 200:
    # Step 4: Save notice in Django database with the notice_id
    Notice.objects.create(
        id=notice_id,  # Use same UUID
        title="नयाँ सूचना २०२६",
        cloudinary_url=cloudinary_url,
        ministry="गृह मन्त्रालय",
        rag_processed=True
    )

# Later: User asks question via Flutter app
# Step 5: Flutter -> Django -> RAG
user_question = "गृह मन्त्रालयको नयाँ नियम के हो?"
chat_response = requests.post(
    "http://192.168.1.118:8001/chat/simple",
    json={
        "question": user_question,
        "session_id": f"user_{request.user.id}"
    },
    timeout=30
)

result = chat_response.json()

# Step 6: Return to Flutter with deep links
response_data = {
    "answer": result["answer"],
    "sources": [
        {
            "notice_id": src["notice_id"],
            "title": src["title"],
            "excerpt": src["excerpt"],
            "url": f"https://your-django-app.com/notice/{src['notice_id']}"  # Deep link!
        }
        for src in result["sources"]
    ]
}
```

---

## ⚠️ 4. ERROR HANDLING

### **Common Errors:**

| Status Code | Error | Reason | Solution |
|-------------|-------|--------|----------|
| 400 | "फाइल डाउनलोड त्रुटि" | Cloudinary URL is invalid or inaccessible | Check URL is publicly accessible |
| 500 | "प्रशोधन त्रुटि" | PDF processing failed | Check PDF is valid and not corrupted |
| 500 | "त्रुटि" | Chat system error | Check question is not empty |
| Connection Error | - | RAG system is down or unreachable | Check WiFi connection and server status |

### **Django Error Handling Example:**

```python
def safe_rag_ingest(cloudinary_url, notice_id, title):
    """Safely ingest with error handling"""
    try:
        response = requests.post(
            "http://192.168.1.118:8001/ingest",
            json={
                "file_url": cloudinary_url,
                "notice_id": notice_id,
                "title": title
            },
            timeout=300
        )
        
        if response.status_code == 200:
            return True, response.json()
        else:
            error_msg = response.json().get('detail', 'Unknown error')
            return False, error_msg
            
    except requests.exceptions.Timeout:
        return False, "RAG system timeout - PDF too large or slow processing"
    except requests.exceptions.ConnectionError:
        return False, "Cannot connect to RAG system - check network"
    except Exception as e:
        return False, f"Unexpected error: {str(e)}"
```

---

## 🔧 5. TESTING CHECKLIST

Before hackathon demo, test these scenarios:

- [ ] **Upload Test:** Upload a sample PDF via Django → Cloudinary → RAG `/ingest`
- [ ] **Check Processing:** Verify you get `{"success": true}` response
- [ ] **Simple Question:** Ask basic question about the uploaded document
- [ ] **Verify Sources:** Check that `notice_id` in response matches what you sent
- [ ] **Deep Link Test:** Create clickable link using `notice_id` from sources
- [ ] **Multiple Uploads:** Upload 2-3 documents and verify all are searchable
- [ ] **Error Handling:** Test with invalid URL to see error response
- [ ] **Conversation Test:** Ask follow-up question with same `session_id`

---

## 📞 6. QUICK REFERENCE

```python
# UPLOAD NOTICE TO RAG
POST http://192.168.1.118:8001/ingest
{
  "file_url": "cloudinary_url",
  "notice_id": "uuid_from_django", 
  "title": "notice_title"
}

# ASK QUESTION
POST http://192.168.1.118:8001/chat/simple
{
  "question": "user_question",
  "session_id": "user_id"
}
```

---

## 🎯 7. FLUTTER INTEGRATION HINTS

Django should return this format to Flutter:

```json
{
  "answer": "जवाफ यहाँ...",
  "sources": [
    {
      "notice_id": "uuid",
      "title": "शीर्षक",
      "excerpt": "अंश...",
      "deep_link": "https://your-app.com/notice/uuid"
    }
  ]
}
```

Flutter can then make sources clickable to navigate back to Django notice detail page!

---

## 📝 8. MANDATORY FIELDS SUMMARY

### For `/ingest`:
- ✅ **MUST HAVE:** `file_url`, `notice_id`
- ⚠️ **SHOULD HAVE:** `title`
- ❌ **OPTIONAL:** `ministry`, `upload_date`

### For `/chat/simple`:
- ✅ **MUST HAVE:** `question`
- ⚠️ **SHOULD HAVE:** `session_id`

---

## 🚀 Ready to Integrate!

If you follow this guide, your Django system will seamlessly integrate with the RAG system. The key is:
1. **Upload to Cloudinary** → Get URL
2. **Send URL + notice_id to RAG** → Get processed
3. **User asks question** → Get answer with notice_id in sources
4. **Create deep link** → User can navigate back to original notice

Good luck with your hackathon! 🎉
