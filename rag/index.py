from typing import List, Dict, Any
import numpy as np
from sklearn.neighbors import NearestNeighbors

from .models import EmbeddingModel
from .db import load_all_for_index
from .db_mysql import load_all_for_index_mysql

class VectorIndex:
    def __init__(self, embedder: EmbeddingModel):
        self.embedder = embedder
        self.nn = None
        self.embeddings = None  # np.ndarray
        self.metadata: List[Dict[str, Any]] = []
        self.texts: List[str] = []

    def build(self, chunks: List[str], metas: List[Dict[str, Any]]):
        self.texts = chunks
        self.metadata = metas
        self.embeddings = self.embedder.embed(chunks)
        self.nn = NearestNeighbors(n_neighbors=min(10, len(chunks)), metric="cosine")
        self.nn.fit(self.embeddings)

    def build_from_db(self, conn):
        texts, metas, embeddings = load_all_for_index(conn)
        self.texts = texts
        self.metadata = metas
        self.embeddings = embeddings
        if len(texts) == 0:
            self.nn = None
            return
        self.nn = NearestNeighbors(n_neighbors=min(10, len(texts)), metric="cosine")
        self.nn.fit(self.embeddings)

    def build_from_mysql(self, conn):
        texts, metas, embeddings = load_all_for_index_mysql(conn)
        self.texts = texts
        self.metadata = metas
        self.embeddings = embeddings
        if len(texts) == 0:
            self.nn = None
            return
        self.nn = NearestNeighbors(n_neighbors=min(10, len(texts)), metric="cosine")
        self.nn.fit(self.embeddings)

    def search(self, query: str, top_k: int = 4):
        if self.nn is None or len(self.texts) == 0:
            return []
        if not query or not query.strip():
            return []
        # Use is_query=True for E5 model to add "query: " prefix
        if hasattr(self.embedder, 'embed'):
            import inspect
            sig = inspect.signature(self.embedder.embed)
            if 'is_query' in sig.parameters:
                qvec = self.embedder.embed([query], is_query=True)
            else:
                qvec = self.embedder.embed([query])
        else:
            qvec = self.embedder.embed([query])
        
        distances, indices = self.nn.kneighbors(qvec, n_neighbors=min(top_k, len(self.texts)))
        results = []
        for idx, dist in zip(indices[0], distances[0]):
            # Convert cosine distance to similarity score
            similarity = float(1.0 - dist)
            results.append({
                "text": self.texts[idx],
                "meta": self.metadata[idx],
                "score": similarity,
                "distance": float(dist)
            })
        # Filter out very low similarity results (< 0.3)
        results = [r for r in results if r["score"] > 0.3]
        return results
