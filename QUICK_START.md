# 🚀 QUICK START - Modern Chat Interface

## Start in 3 Steps

### Step 1: Open Terminal
```bash
cd /Users/sonu/Desktop/nova2
```

### Step 2: Start Server
```bash
./start_chat.sh
```

OR

```bash
conda activate rag-st
python app_chat.py
```

### Step 3: Open Browser
Visit: **http://localhost:8001**

## 💬 Using the Chat Interface

### Ask Questions
1. Type your question in the input box at the bottom
2. Press **Ctrl+Enter** (or **Cmd+Enter** on Mac) OR click 📤 button
3. Watch the AI respond with typewriter effect!

Examples:
- `राष्ट्रिय झण्डा बारे बताउनुहोस्`
- `griha mantralaya bare ma jankari`
- `What are the rules for the national flag?`

### Upload Documents
1. Click **📤 कागजात अपलोड गर्नुहोस्** button in sidebar
2. Drag files into the upload area OR click to select
3. Click **अपलोड र प्रोसेस गर्नुहोस्**
4. Wait for processing (progress bar shows status)
5. Documents are now searchable!

Supported formats:
- PDF (scanned or digital)
- Images (JPG, PNG, TIFF)
- Text files (TXT, MD)

### Manage Chats
- **New Chat**: Click **➕ नयाँ कुराकानी** button
- **Load Chat**: Click any chat in the sidebar
- **Clear Chat**: Click **🗑️** button in top-right

## ✨ Features You'll Love

✅ **Typewriter Effect** - Responses appear character-by-character like ChatGPT  
✅ **Chat History** - All your conversations are saved automatically  
✅ **Enhanced OCR** - Extracts ministry names from logos and headers  
✅ **Drag & Drop** - Upload multiple files at once  
✅ **Responsive** - Works on desktop, tablet, and mobile  

## 🎯 Pro Tips

1. **Upload first, ask later** - Upload your documents before querying
2. **Be specific** - Mention ministry names for better results
3. **Use keyboard shortcuts** - Ctrl/Cmd+Enter to send quickly
4. **Create new chats** - Organize different topics in separate chats
5. **Clear old chats** - Keep your sidebar clean and organized

## 🐛 Troubleshooting

### Server won't start?
```bash
# Kill any existing process
lsof -ti:8001 | xargs kill -9

# Try again
./start_chat.sh
```

### Can't see the interface?
- Make sure server shows: "Application startup complete"
- Check URL is exactly: http://localhost:8001
- Try clearing browser cache (Ctrl+Shift+R or Cmd+Shift+R)

### Upload not working?
- Check file size (max 50MB per file)
- Verify file format is supported
- Look for error messages in the upload status

## 📚 More Help

- Full Guide: `CHAT_INTERFACE_GUIDE.md`
- Implementation Details: `IMPLEMENTATION_SUMMARY.md`
- OCR System: `ENHANCED_OCR_SUMMARY.md`

## 🎉 That's It!

You're ready to use your modern AI chatbot with:
- ChatGPT-style typewriter effect
- Full chat history
- Drag-and-drop uploads
- Enhanced OCR for Nepali documents

**Enjoy!** 🇳🇵✨
