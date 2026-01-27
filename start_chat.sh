#!/bin/bash
# Startup script for the chat interface

echo "="*80
echo "🚀 Starting नेपाल सरकारी RAG Chat Interface"
echo "="*80

cd /Users/sonu/Desktop/nova2

# Activate conda environment and run
conda run -n rag-st python app_chat.py
