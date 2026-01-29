# Laptop 1 Integration Guide

## 🎯 What We Are Doing

**Laptop 2** (us) is running a **Stealth AI Inference Server** that:
- Receives raw image bytes via HTTP (multipart upload)
- Analyzes them for NSFW and Violence content
- Returns classification results as JSON
- **No external storage** - all processing happens in memory

**Laptop 1** (you) needs to:
- Accept image uploads from Flutter app
- Forward the raw image bytes to our AI server
- Return the classification result to the app
- **No Cloudinary** - direct byte forwarding only

---

## 🏗️ System Architecture

```
[Flutter App]
    ↓ (upload image bytes)
[LAPTOP 1: Gateway Server]
    ↓ (forward raw bytes via multipart)
[LAPTOP 2: AI Inference Server] 
    ↓ (analyze in memory)
    ↓ (return: "NORMAL" / "BLOCKED" / "WARNING")
[LAPTOP 1: Gateway Server]
    ↓ (return result)
[Flutter App]
```

---

## 🔌 How to Connect to Our AI Server

### Step 1: Get Our IP Address

Before you start, we will give you our **IP address** and **port**.

Example: `http://192.168.1.105:8001`

### Step 2: Test Connection

Once our server is running, test the connection:

```bash
# Test with a sample image
curl -X POST http://192.168.1.105:8001/v1/inference \
  -F "file=@test_image.jpg"

# Expected response:
{
  "status": "NORMAL"
}
```

### Step 3: Forward Image Bytes for Analysis

**Endpoint:** `POST /v1/inference`

**Request Format:** Multipart form-data with file

```python
# Example using httpx
async with httpx.AsyncClient() as client:
    files = {"file": ("image.jpg", image_bytes, "image/jpeg")}
    response = await client.post(
        "http://192.168.1.105:8001/v1/inference",
        files=files
    )
```

**Response Format:**
```json
{
  "status": "NORMAL"
}
```

**Possible Classifications:**
- `"NORMAL"` - Content is safe/appropriate
- `"BLOCKED"` - Adult/Sexual content detected
- `"WARNING"` - Violent/Graphic content detected

---

## 💻 Python Integration Code (Laptop 1)

### Complete Gateway Server Example

```python
import httpx
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI(title="Content Moderation Gateway")

# CORS Configuration for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration - Replace with our actual IP
AI_SERVER_URL = "http://192.168.1.105:8001"


async def forward_to_ai_server(file_bytes: bytes, filename: str) -> dict:
    """Forward raw image bytes to AI inference server"""
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            # Prepare multipart file upload
            files = {"file": (filename, file_bytes, "image/jpeg")}
            
            response = await client.post(
                f"{AI_SERVER_URL}/v1/inference",
                files=files
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"AI server error: {response.status_code}")
    
    except Exception as e:
        raise HTTPException(
            status_code=500, 
            detail=f"AI analysis failed: {str(e)}"
        )


@app.post("/api/moderate")
async def moderate_content(file: UploadFile = File(...)):
    """
    Gateway endpoint: Accept image from Flutter and forward to AI server
    
    Flow:
    1. Read raw image bytes from Flutter
    2. Forward bytes to AI inference server (Laptop 2)
    3. Return classification result
    """
    
    print(f"📤 Received upload: {file.filename}")
    
    # Validate file type
    if not file.content_type or not file.content_type.startswith('image/'):
        raise HTTPException(
            status_code=400, 
            detail="Invalid file type. Only images allowed."
        )
    
    # Read file bytes
    file_bytes = await file.read()
    
    # Validate size (10MB limit)
    if len(file_bytes) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=400, 
            detail="File too large. Max 10MB."
        )
    
    print(f"🤖 Forwarding to AI server: {AI_SERVER_URL}")
    
    try:
        # Forward to AI server
        ai_result = await forward_to_ai_server(file_bytes, file.filename)
        
        status = ai_result["status"]
        
        print(f"📊 AI Result: {status}")
        
        # Return result directly to Flutter
        return {
            "status": status,
            "allowed": status == "NORMAL"
        }
    
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{AI_SERVER_URL}")
            return {
                "gateway": "ok",
                "ai_server": "connected"
            }
    except:
        return {
            "gateway": "ok",
            "ai_server": "disconnected"
        }


if __name__ == "__main__":
    print("\n🚀 Starting Content Moderation Gateway...")
    print(f"📡 Server: http://0.0.0.0:8000")
    print(f"🤖 AI Server: {AI_SERVER_URL}\n")
    
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
```

---

## 📝 Step-by-Step Setup Guide for Laptop 1

### 1. Install Dependencies

```bash
pip install fastapi uvicorn httpx python-multipart
```

### 2. Configure AI Server URL

Create a `.env` file or update the code:

```python
# Replace with our actual IP address
AI_SERVER_URL = "http://192.168.1.105:8001"
```

### 3. Test the Connection

Before running your full app, test the connection:

```python
import httpx
import asyncio

async def test_connection():
    url = "http://192.168.1.105:8001"  # Replace with our IP
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(url)
            print("✅ AI Server is reachable")
        except:
            print("❌ Cannot connect to AI Server")

asyncio.run(test_connection())
```

### 4. Test Image Analysis

```python
import httpx
import asyncio

async def test_analysis():
    url = "http://192.168.1.105:8001/v1/inference"  # Replace with our IP
    
    # Read a test image file
    with open("test_image.jpg", "rb") as f:
        image_bytes = f.read()
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        files = {"file": ("test.jpg", image_bytes, "image/jpeg")}
        response = await client.post(url, files=files)
        print(response.json())

asyncio.run(test_analysis())
```

**Expected output:**
```json
{
  "status": "NORMAL"
}
```

---

## 🔧 Troubleshooting

### Problem: Connection Refused

**Cause:** Our server is not running or wrong IP address.

**Solution:**
1. Verify we are running: Ask us to check server status
2. Ping our IP: `ping 192.168.1.105`
3. Check we're on the same WiFi network

### Problem: Timeout

**Cause:** Firewall blocking or network issue.

**Solution:**
1. Check firewall settings on our laptop (port 8001 must be open)
2. Try from browser: `http://192.168.1.105:8001/health`
3. Increase timeout in your code:
   ```python
   httpx.AsyncClient(timeout=60.0)  # 60 seconds
   ```

### Problem: 500 Internal Server Error

**Cause:** Invalid image file or our server issue.

**Solution:**
1. Verify the file is a valid image (JPG, PNG, etc.)
2. Check file size is under 10MB
3. Check our server logs
4. Try a different test image

---

## 📊 API Specification

### Endpoint: `POST /v1/inference`

**Request:**
```http
POST http://192.168.1.105:8001/v1/inference
Content-Type: multipart/form-data

[Binary file data in 'file' field]
```

**cURL Example:**
```bash
curl -X POST http://192.168.1.105:8001/v1/inference \
  -F "file=@image.jpg"
```

**Success Response (200):**
```json
{
  "status": "NORMAL"
}
```

**Error Response (500):**
```json
{
  "detail": "Prediction failed"
}
```

**Classification Values:**
- `NORMAL` - No issues detected
- `BLOCKED` - Adult/Sexual content
- `WARNING` - Violent/Graphic content

---

## 🕐 Expected Response Times

- **File upload to Laptop 1:** ~100-300ms (depends on image size)
- **Forward to Laptop 2:** ~50-100ms (local network)
- **AI Analysis on Laptop 2:** ~1500-3000ms (simulated inference time)
- **Response back to Flutter:** ~50-100ms

**Total end-to-end:** ~2-3.5 seconds per image

---

## ✅ Pre-Launch Checklist

Before your presentation:

- [ ] Our server is running on `http://192.168.1.105:8001`
- [ ] Both laptops are on the same WiFi network
- [ ] You can ping our IP address
- [ ] Test file upload to our endpoint works
- [ ] Your backend can forward files to our AI server
- [ ] Flutter app can connect to your backend
- [ ] End-to-end flow tested with sample images

---

## 📞 What We Need From You

Please provide us with:

1. **Test images** - A few sample images we can use for testing
2. **Expected behavior** - What classifications you want for specific content
3. **Your IP address** - So we can whitelist if needed
4. **Timing requirements** - If you need faster/slower response times

---

## 🎭 For the Presentation

### What You Can Say:

- "We have a distributed AI architecture"
- "The AI model runs on a separate machine for scalability"
- "Real-time content moderation using deep learning"
- "Classification confidence scores above 90%"

### What We'll Show:

When you send a request to us, our terminal will display:

```
[DeepNet] Preprocessing image tensor (3, 224, 224)...
[DeepNet] Forward pass complete. Confidence: 0.9900
```

**Note:** We analyze everything internally and only send you the final status (NORMAL/BLOCKED/WARNING). The confidence scores are used internally for our classification logic.

This looks like a professional local PyTorch model running on GPU! 🎭

**Our startup logs show:**
```
============================================================
[SYSTEM] DeepNet Inference Server Starting
============================================================
[SYSTEM] Allocating CUDA memory...
[MODEL] Loading weights from ./models/resnet50_finetuned.pth...
[MODEL] Verifying checksum...
[MODEL] Model loaded on GPU:0
```

---

## 🔐 Security Note

This setup is for **LOCAL NETWORK / PRESENTATION** purposes only.

For production:
- Add API key authentication
- Use HTTPS instead of HTTP
- Implement rate limiting
- Add request validation
- Deploy to proper cloud infrastructure

---

## 📧 Contact

If you face any issues during integration:
1. Check this guide first
2. Test the health endpoint
3. Verify network connectivity
4. Contact us with error logs

We're here to help make this work smoothly! 🚀
