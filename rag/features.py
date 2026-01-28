"""
Advanced features for the RAG system:
- Document statistics and analytics
- Key information extraction
- Related documents finder
- Document comparison
- Batch processing
"""
from typing import List, Dict, Any, Optional, Tuple
import re
from collections import Counter
from datetime import datetime


class AdvancedFeatures:
    """Advanced features for document analysis and retrieval."""
    
    def __init__(self, pipeline):
        """Initialize with RAG pipeline reference."""
        self.pipeline = pipeline
    
    def get_document_statistics(self) -> Dict[str, Any]:
        """Get comprehensive statistics about indexed documents."""
        if not self.pipeline.index.texts:
            return {
                "total_documents": 0,
                "total_chunks": 0,
                "ministries": {},
                "services": {},
                "average_chunk_length": 0
            }
        
        # Aggregate stats
        ministries = Counter()
        services = Counter()
        titles = set()
        chunk_lengths = []
        
        for meta in self.pipeline.index.metas:
            if meta.get('ministry'):
                ministries[meta['ministry']] += 1
            if meta.get('service_name'):
                services[meta['service_name']] += 1
            if meta.get('title'):
                titles.add(meta['title'])
        
        for text in self.pipeline.index.texts:
            chunk_lengths.append(len(text.split()))
        
        avg_length = sum(chunk_lengths) / len(chunk_lengths) if chunk_lengths else 0
        
        return {
            "total_documents": len(titles),
            "total_chunks": len(self.pipeline.index.texts),
            "ministries": dict(ministries),
            "services": dict(services),
            "average_chunk_length": round(avg_length, 2),
            "total_words": sum(chunk_lengths),
            "ministry_count": len(ministries),
            "service_count": len(services)
        }
    
    def extract_key_information(self, question: str, top_k: int = 3) -> Dict[str, Any]:
        """Extract key facts and information related to a query."""
        # Search for relevant chunks
        results = self.pipeline.index.search(question, k=top_k)
        
        if not results:
            return {
                "query": question,
                "key_facts": [],
                "sources": [],
                "confidence": 0.0
            }
        
        key_facts = []
        sources = set()
        total_confidence = 0.0
        
        for r in results:
            meta = r['meta']
            text = r['text']
            score = r['score']
            
            # Extract sentences as facts
            sentences = re.split(r'[।\.\n]+', text)
            for sent in sentences:
                sent = sent.strip()
                if len(sent.split()) >= 5:  # Meaningful sentences only
                    key_facts.append({
                        "fact": sent,
                        "confidence": round(score, 4),
                        "source": meta.get('title', 'Unknown')
                    })
            
            sources.add(meta.get('title', 'Unknown'))
            total_confidence += score
        
        avg_confidence = total_confidence / len(results) if results else 0.0
        
        # Sort by confidence
        key_facts.sort(key=lambda x: x['confidence'], reverse=True)
        
        return {
            "query": question,
            "key_facts": key_facts[:10],  # Top 10 facts
            "sources": list(sources),
            "confidence": round(avg_confidence, 4),
            "total_facts_found": len(key_facts)
        }
    
    def find_related_documents(self, document_title: str, top_k: int = 5) -> List[Dict[str, Any]]:
        """Find documents related to a given document."""
        # Find chunks from the source document
        source_chunks = []
        for i, meta in enumerate(self.pipeline.index.metas):
            if meta.get('title') == document_title:
                source_chunks.append(i)
        
        if not source_chunks:
            return []
        
        # Use first chunk as query representation
        query_idx = source_chunks[0]
        query_text = self.pipeline.index.texts[query_idx]
        
        # Search for similar documents
        results = self.pipeline.index.search(query_text, k=top_k + len(source_chunks))
        
        # Filter out the source document itself
        related = []
        seen_titles = set()
        
        for r in results:
            title = r['meta'].get('title', 'Unknown')
            if title != document_title and title not in seen_titles:
                seen_titles.add(title)
                related.append({
                    "title": title,
                    "ministry": r['meta'].get('ministry', 'Unknown'),
                    "service": r['meta'].get('service_name', 'Unknown'),
                    "relevance_score": round(r['score'], 4),
                    "notice_id": r['meta'].get('notice_id', '')
                })
        
        return related[:top_k]
    
    def compare_documents(self, doc1_title: str, doc2_title: str) -> Dict[str, Any]:
        """Compare two documents and highlight similarities/differences."""
        # Get chunks for both documents
        doc1_chunks = []
        doc2_chunks = []
        
        for i, meta in enumerate(self.pipeline.index.metas):
            title = meta.get('title', '')
            if title == doc1_title:
                doc1_chunks.append(self.pipeline.index.texts[i])
            elif title == doc2_title:
                doc2_chunks.append(self.pipeline.index.texts[i])
        
        if not doc1_chunks or not doc2_chunks:
            return {
                "error": "एक वा दुवै दस्तावेज फेला परेन",
                "doc1_found": bool(doc1_chunks),
                "doc2_found": bool(doc2_chunks)
            }
        
        # Combine chunks for comparison
        doc1_text = " ".join(doc1_chunks)
        doc2_text = " ".join(doc2_chunks)
        
        # Extract keywords
        doc1_words = set(re.findall(r'\b\w+\b', doc1_text.lower()))
        doc2_words = set(re.findall(r'\b\w+\b', doc2_text.lower()))
        
        common_words = doc1_words & doc2_words
        unique_doc1 = doc1_words - doc2_words
        unique_doc2 = doc2_words - doc1_words
        
        similarity_ratio = len(common_words) / max(len(doc1_words | doc2_words), 1)
        
        return {
            "document1": doc1_title,
            "document2": doc2_title,
            "similarity_score": round(similarity_ratio, 4),
            "common_topics": len(common_words),
            "unique_to_doc1": len(unique_doc1),
            "unique_to_doc2": len(unique_doc2),
            "doc1_length_words": len(doc1_words),
            "doc2_length_words": len(doc2_words),
            "comparison_summary": self._generate_comparison_summary(
                doc1_title, doc2_title, similarity_ratio
            )
        }
    
    def _generate_comparison_summary(self, doc1: str, doc2: str, similarity: float) -> str:
        """Generate a human-readable comparison summary."""
        if similarity > 0.7:
            level = "धेरै मिल्दोजुल्दो"
        elif similarity > 0.4:
            level = "केही मिल्दोजुल्दो"
        else:
            level = "फरक"
        
        return f"{doc1} र {doc2} {level} छन् (समानता: {similarity*100:.1f}%)"
    
    def search_by_filter(self, query: str, ministry: Optional[str] = None, 
                        service: Optional[str] = None, top_k: int = 6) -> List[Dict[str, Any]]:
        """Search with ministry/service filters."""
        # Get all results first
        results = self.pipeline.index.search(query, k=top_k * 3)
        
        # Apply filters
        filtered = []
        for r in results:
            meta = r['meta']
            
            # Check ministry filter
            if ministry and meta.get('ministry', '') != ministry:
                continue
            
            # Check service filter
            if service and meta.get('service_name', '') != service:
                continue
            
            filtered.append({
                "text": r['text'][:200] + "...",
                "score": round(r['score'], 4),
                "ministry": meta.get('ministry', 'Unknown'),
                "service": meta.get('service_name', 'Unknown'),
                "title": meta.get('title', 'Unknown'),
                "notice_id": meta.get('notice_id', '')
            })
        
        return filtered[:top_k]
    
    def batch_query(self, questions: List[str]) -> List[Dict[str, Any]]:
        """Process multiple questions in batch."""
        results = []
        
        for i, question in enumerate(questions):
            try:
                answer = self.pipeline.answer(question)
                results.append({
                    "question_number": i + 1,
                    "question": question,
                    "answer": answer,
                    "status": "success"
                })
            except Exception as e:
                results.append({
                    "question_number": i + 1,
                    "question": question,
                    "answer": None,
                    "error": str(e),
                    "status": "failed"
                })
        
        return results
    
    def get_ministry_documents(self, ministry_name: str) -> List[Dict[str, Any]]:
        """Get all documents from a specific ministry."""
        documents = {}
        
        for meta in self.pipeline.index.metas:
            if meta.get('ministry') == ministry_name:
                title = meta.get('title', 'Unknown')
                if title not in documents:
                    documents[title] = {
                        "title": title,
                        "ministry": ministry_name,
                        "service": meta.get('service_name', 'Unknown'),
                        "notice_id": meta.get('notice_id', ''),
                        "chunk_count": 0
                    }
                documents[title]["chunk_count"] += 1
        
        return list(documents.values())
    
    def get_service_documents(self, service_name: str) -> List[Dict[str, Any]]:
        """Get all documents from a specific service."""
        documents = {}
        
        for meta in self.pipeline.index.metas:
            if meta.get('service_name') == service_name:
                title = meta.get('title', 'Unknown')
                if title not in documents:
                    documents[title] = {
                        "title": title,
                        "ministry": meta.get('ministry', 'Unknown'),
                        "service": service_name,
                        "notice_id": meta.get('notice_id', ''),
                        "chunk_count": 0
                    }
                documents[title]["chunk_count"] += 1
        
        return list(documents.values())
