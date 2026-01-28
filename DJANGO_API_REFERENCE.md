# FastAPI RAG Server - Django Integration Guide

**Server:** `192.168.1.118:8001`
**Status:** ✅ Ready for Django Integration

---

## 🔌 PRIMARY: WebSocket Endpoint

**Endpoint:** `ws://192.168.1.118:8001/ws/chat`

**Usage:** Persistent connection for real-time chat

### Request Format
```json
{
  "query": "नेपाल सरकारको बारेमा बताउनुहोस्",
  "session_id": "optional-session-id"
}
```

### Response Format
```json
{
  "response": "नेपाल सरकार संघीय लोकतान्त्रिक गणतन्त्र हो...",
  "sources": [
    {
      "notice_id": "unique-notice-123",
      "ministry_name": "Ministry of Finance",
      "service_name": "Budget Department",
      "excerpt": "Document excerpt up to 200 chars..."
    }
  ]
}
```

### Python Example
```python
import asyncio
import websockets
import json

async def chat():
    async with websockets.connect("ws://192.168.1.118:8001/ws/chat") as ws:
        # Send query
        await ws.send(json.dumps({
            "query": "नेपाल सरकारको बारेमा बताउनुहोस्",
            "session_id": "my_session"
        }))
        
        # Receive response
        response = await ws.recv()
        data = json.loads(response)
        print(data["response"])
        print(f"Sources: {len(data['sources'])}")

asyncio.run(chat())
```

### JavaScript Example
```javascript
const ws = new WebSocket('ws://192.168.1.118:8001/ws/chat');

ws.onopen = () => {
    ws.send(JSON.stringify({
        query: 'नेपाल सरकारको बारेमा बताउनुहोस्',
        session_id: 'my_session'
    }));
};

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log('Response:', data.response);
    console.log('Sources:', data.sources);
};
```

---

## 📡 FALLBACK: HTTP Endpoint

**Endpoint:** `POST http://192.168.1.118:8001/chat`

**Usage:** HTTP fallback if WebSocket unavailable

### Request Format
```json
{
  "query": "नेपाल सरकारको बारेमा बताउनुहोस्",
  "session_id": "optional-session-id"
}
```

### Response Format
```json
{
  "response": "नेपाल सरकार संघीय लोकतान्त्रिक गणतन्त्र हो...",
  "sources": [
    {
      "notice_id": "unique-notice-123",
      "ministry_name": "Ministry of Finance",
      "service_name": "Budget Department",
      "excerpt": "Document excerpt up to 200 chars..."
    }
  ]
}
```

### Python Example
```python
import requests

response = requests.post(
    "http://192.168.1.118:8001/chat",
    json={
        "query": "नेपाल सरकारको बारेमा बताउनुहोस्",
        "session_id": "my_session"
    }
)

data = response.json()
print(data["response"])
print(f"Sources: {len(data['sources'])}")
```

### cURL Example
```bash
curl -X POST http://192.168.1.118:8001/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "नेपाल सरकारको बारेमा बताउनुहोस्",
    "session_id": "my_session"
  }'
```

---

## 📤 Ingestion Endpoint

**Endpoint:** `POST http://192.168.1.118:8001/ingest`

**Usage:** Upload documents from Cloudinary URLs

### Request Format
```json
{
  "file_url": "https://res.cloudinary.com/.../document.pdf",
  "notice_id": "unique-notice-123",
  "ministry_name": "Ministry of Finance",
  "service_name": "Budget Department"
}
```

### Response Format
```json
{
  "success": true,
  "notice_id": "unique-notice-123",
  "chunks_processed": 42
}
```

### Python Example
```python
import requests

response = requests.post(
    "http://192.168.1.118:8001/ingest",
    json={
        "file_url": "https://res.cloudinary.com/.../document.pdf",
        "notice_id": "notice_123",
        "ministry_name": "Ministry of Finance",
        "service_name": "Budget Department"
    }
)

print(response.json())
```

---

## 🔍 Health Check

**Endpoint:** `GET http://192.168.1.118:8001/health`

**Response:**
```json
{
  "status": "online",
  "message": "RAG System is running! ✅ Django-compatible",
  "server": "192.168.1.118:8001",
  "chunks_loaded": 1819,
  "endpoints": {
    "websocket": "WS /ws/chat - PRIMARY: Real-time chat",
    "http_chat": "POST /chat - HTTP fallback",
    "ingest": "POST /ingest - Upload PDF via Cloudinary URL",
    "stream": "POST /chat/stream - For UI streaming"
  }
}
```

---

## ⚠️ CRITICAL Field Names

Django specification requires these EXACT field names:

### Request Fields
- ✅ Use `query` (NOT `question`)
- ✅ Use `session_id` (optional)

### Response Fields
- ✅ Use `response` (NOT `answer`)
- ✅ Use `sources` (array of source objects)

### Source Object Fields
- ✅ `notice_id` (required) - for deep linking
- ✅ `ministry_name` (optional)
- ✅ `service_name` (optional)
- ✅ `excerpt` (optional) - max 200 characters

### Ingestion Fields
- ✅ `file_url` (required)
- ✅ `notice_id` (required)
- ✅ `ministry_name` (optional)
- ✅ `service_name` (optional)

---

## 🎯 Integration Checklist

Before going live, verify:

- [ ] Can connect to WebSocket at `ws://192.168.1.118:8001/ws/chat`
- [ ] WebSocket accepts JSON with `query` field
- [ ] WebSocket returns JSON with `response` field (not `answer`)
- [ ] HTTP fallback works at `POST /chat`
- [ ] HTTP accepts `query` field (not `question`)
- [ ] Sources include `notice_id` for deep linking
- [ ] Ingestion endpoint accepts Cloudinary URLs
- [ ] Health check returns status

---

## 🧪 Testing

Run the test script to verify all endpoints:

```bash
python test_django_integration.py
```

Expected output: All tests pass ✅

---

## 📞 Support

**Network:** Both Django and FastAPI must be on same WiFi
**IP:** 192.168.1.118
**Port:** 8001

**Test WebSocket from browser console:**
```javascript
const ws = new WebSocket('ws://192.168.1.118:8001/ws/chat');
ws.onopen = () => console.log('Connected!');
ws.onerror = (e) => console.error('Error:', e);
```

---

## 🚀 Quick Start

1. Verify server is running:
   ```bash
   curl http://192.168.1.118:8001/health
   ```

2. Test HTTP chat:
   ```bash
   curl -X POST http://192.168.1.118:8001/chat \
     -H "Content-Type: application/json" \
     -d '{"query": "test"}'
   ```

3. Connect WebSocket from your Django app using examples above

4. Start sending queries!

---

**Last Updated:** Ready for hackathon integration
**Specification:** Fully compliant with Django team requirements
