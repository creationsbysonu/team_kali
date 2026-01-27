#!/usr/bin/env python3
"""Test query flow to debug 'information not available' issue."""

from rag.models import E5Embedding, OllamaGenerator
from rag.pipeline import RAGPipeline
from rag.db import connect
from rag.config import settings

print("Initializing RAG pipeline...")
embedder = E5Embedding()
generator = OllamaGenerator(model_name="llama3:latest")
pipeline = RAGPipeline(embedder, generator)

print("Loading from database...")
conn = connect(settings.db_path)
pipeline.index.build_from_db(conn)
conn.close()

print(f"Loaded {len(pipeline.index.texts)} chunks")
if len(pipeline.index.texts) > 0:
    print(f"\nSample chunk: {pipeline.index.texts[0][:100]}...")

# Test queries
test_queries = [
    "नेपाल सरकार",
    "e-governance",
    "यो के हो?",
]

for q in test_queries:
    print(f"\n{'='*60}")
    print(f"Query: {q}")
    print(f"{'='*60}")
    
    # Check what chunks are retrieved
    retrieved = pipeline.index.search(q, top_k=4)
    print(f"Retrieved chunks: {len(retrieved)}")
    
    if retrieved:
        print("\nRetrieved content preview:")
        for i, r in enumerate(retrieved[:2]):
            print(f"{i+1}. {r['text'][:150]}... (score: {r.get('score', 'N/A')})")
    
    # Get full answer
    answer = pipeline.answer(q)
    print(f"\nAnswer: {answer[:300]}")
