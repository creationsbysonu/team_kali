#!/usr/bin/env python3
"""Simple test without loading heavy models."""

from rag.db import connect, load_all_for_index
from rag.config import settings
from sklearn.neighbors import NearestNeighbors
import numpy as np

print("Loading data from database...")
conn = connect(settings.db_path)
texts, metas, embeddings = load_all_for_index(conn)
conn.close()

print(f"Loaded {len(texts)} chunks with {len(embeddings)} embeddings")
print(f"Embedding dimension: {embeddings[0].shape if len(embeddings) > 0 else 'N/A'}")

if len(texts) > 0:
    print(f"\nSample text 1: {texts[0][:150]}...")
    print(f"Sample meta 1: {metas[0]}")

# Test if embeddings are valid (not all zeros)
if len(embeddings) > 0:
    emb_mean = np.mean(np.abs(embeddings[0]))
    print(f"\nEmbedding check - mean absolute value: {emb_mean}")
    if emb_mean < 0.001:
        print("WARNING: Embeddings appear to be all zeros!")
    else:
        print("Embeddings look valid ✓")

# Build simple index
if len(embeddings) > 1:
    nn = NearestNeighbors(n_neighbors=min(4, len(texts)), metric="cosine")
    nn.fit(np.array(embeddings))
    print(f"\nIndex built successfully with {len(texts)} vectors")
    
    # Test search with the first embedding itself
    distances, indices = nn.kneighbors([embeddings[0]], n_neighbors=4)
    print(f"\nSelf-search test (should find itself):")
    for idx, dist in zip(indices[0], distances[0]):
        print(f"  Index {idx}, Distance: {dist:.4f}")
