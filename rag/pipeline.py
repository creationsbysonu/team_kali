from typing import List
import re

from .config import settings
from .index import VectorIndex
from .models import EmbeddingModel, GenerativeModel
from .transliterate import normalize_query
from .cache import query_cache
from .logger import log_info, log_debug, log_error

class RAGPipeline:
    def __init__(self, embedder: EmbeddingModel, generator: GenerativeModel):
        self.index = VectorIndex(embedder)
        self.generator = generator

    def build_index(self, chunks: List[str], metas: List[dict]):
        self.index.build(chunks, metas)
    
    def _clean_chunk_for_llm(self, text: str) -> str:
        """Aggressively clean chunk text to avoid triggering safety filters."""
        import re
        
        # Remove all source metadata tags first
        text = re.sub(r'\[.*?\]', '', text)
        
        # Remove OCR artifacts and gibberish patterns
        ocr_patterns = [
            r'c&\\+',
            r'\bjem\b',
            r'Ret\s+',
            r'we\s*\|',
            r'\|\s*\w{1,3}\s*\|',  # Pipe-separated short words
            r'\d+\s*\|',  # Numbers with pipes
            r'[०-९]+\s*।',  # Nepali numbers with dandas
        ]
        for pattern in ocr_patterns:
            text = re.sub(pattern, '', text, flags=re.IGNORECASE)
        
        # Remove URLs and email patterns
        text = re.sub(r'http[s]?://\S+', '', text)
        text = re.sub(r'[\w\.-]+@[\w\.-]+', '', text)
        
        # Remove excessive punctuation
        text = re.sub(r'[।\.,]{3,}', '।', text)
        text = re.sub(r'[-_=]{3,}', ' ', text)
        
        # Remove control characters
        text = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', text)
        
        # Normalize whitespace
        text = re.sub(r'\s+', ' ', text)
        
        # Remove standalone numbers or single characters at start/end
        text = re.sub(r'^[\d\W]+|[\d\W]+$', '', text)
        
        return text.strip()

    def answer(self, question: str, conversation_history: List[dict] = None) -> str:
        """Answer a question using RAG, with conversation context awareness."""
        conversation_history = conversation_history or []
        
        # Check cache first (only for non-context queries)
        if settings.enable_cache and not conversation_history:
            cached_answer = query_cache.get(question)
            if cached_answer:
                log_debug("Cache hit", query=question[:50])
                print(f"\n⚡ CACHE HIT - Returning cached answer")
                return cached_answer
        
        # Detect context-aware queries (asking about previous answer)
        context_indicators = [
            'छोट्करी', 'छोट्करीमा', 'संक्षेप', 'संक्षिप्त', 'chhotkari', 'sankshep', 'brief', 'summary', 'summarize',
            'पहिलेको', 'माथिको', 'अघिल्लो', 'previous', 'above', 'earlier', 'यसलाई', 'this', 'यो'
        ]
        is_context_query = any(ind in question.lower() for ind in context_indicators)
        
        # Get last assistant message from history
        last_answer = None
        last_question = None
        if conversation_history:
            for msg in reversed(conversation_history):
                if msg['role'] == 'assistant' and not last_answer:
                    last_answer = msg['content']
                elif msg['role'] == 'user' and not last_question:
                    last_question = msg['content']
                if last_answer and last_question:
                    break
        
        # Handle summarization requests
        if is_context_query and last_answer:
            summary_keywords = ['छोट्करी', 'chhotkari', 'संक्षेप', 'brief', 'summary', 'summarize', 'संक्षिप्त']
            is_summary_request = any(kw in question.lower() for kw in summary_keywords)
            
            if is_summary_request:
                print(f"\n📝 SUMMARIZATION REQUEST DETECTED")
                print(f"   Previous Q: {last_question[:80]}...")
                print(f"   Previous A: {last_answer[:80]}...")
                
                # Generate summary using LLM
                summary_prompt = (
                    f"मूल प्रश्न: {last_question}\n\n"
                    f"विस्तृत उत्तर:\n{last_answer}\n\n"
                    f"निर्देशन: माथिको विस्तृत उत्तरलाई अति संक्षिप्त रूपमा (छोट्करीमा) प्रस्तुत गर्नुहोस्। "
                    f"मुख्य बुँदाहरू मात्र राख्नुहोस्। विस्तृत विवरण हटाउनुहोस्। "
                    f"नेपालीमा मात्र जवाफ दिनुहोस्।\n\n"
                    f"छोट्करी उत्तर:"
                )
                
                summary = self.generator.generate(summary_prompt)
                
                # Clean summary
                summary = re.sub(r'^छोट्करी.*?:', '', summary, flags=re.IGNORECASE).strip()
                
                print(f"\n📤 SUMMARY GENERATED: {len(summary)} chars")
                return summary
        
        # Handle follow-up questions needing context expansion
        followup_keywords = ['यसको', 'बारेमा', 'अझ', 'विस्तार', 'more', 'detail', 'explain', 'व्याख्या', 'थप']
        is_followup = is_context_query and any(kw in question.lower() for kw in followup_keywords)
        
        if is_followup and last_question:
            print(f"\n🔗 FOLLOW-UP QUESTION DETECTED")
            print(f"   Combining with previous context: {last_question[:60]}...")
            # Enhance current question with previous context
            question = f"{last_question} - {question}"
            print(f"   Enhanced query: {question[:80]}...")
        
        # Validate input
        if not question or not question.strip():
            return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
        
        # Check query length
        if len(question) > settings.max_query_length:
            log_error("Query too long", length=len(question))
            return f"प्रश्न धेरै लामो छ । कृपया छोटो पार्नुहोस् (maximum {settings.max_query_length} characters)"
        
        # Detect if user wants a brief/concise answer from the start
        brief_keywords = ['छोट्करी', 'छोट्करीमा', 'संक्षेप', 'संक्षिप्त', 'chhotkari', 'chhotkarimaa', 'sankshep', 'brief', 'shortly', 'संक्षेपमा']
        wants_brief_answer = any(kw in question.lower() for kw in brief_keywords)
        
        if wants_brief_answer:
            print(f"\n📝 BRIEF ANSWER REQUESTED (in initial query)")
        
        print(f"\n{'='*80}")
        print(f"{'RAG PIPELINE DEBUG OUTPUT':^80}")
        print(f"{'='*80}")
        
        # Normalize query (transliterate if romanized + grammar correction)
        normalized_question = normalize_query(question)
        
        # Query expansion for better retrieval (generate variations)
        query_variations = [normalized_question]
        
        # Extract key entities and concepts for expansion
        print(f"\n🔍 QUERY EXPANSION:")
        
        # Common synonyms and related terms for better matching
        expansion_map = {
            'अभिमुखीकरण': ['तालिम', 'प्रशिक्षण', 'orientation', 'training'],
            'तालिम': ['अभिमुखीकरण', 'प्रशिक्षण', 'शिक्षा'],
            'सेवा': ['नोकरी', 'कार्य', 'पद', 'service', 'job'],
            'आवेदन': ['दरखास्त', 'निवेदन', 'application'],
            'परीक्षा': ['exam', 'test', 'examination', 'इम्तिहान'],
            'योग्यता': ['qualification', 'eligibility', 'पात्रता'],
            'समय': ['मिति', 'date', 'time', 'अवधि'],
            'प्रक्रिया': ['process', 'procedure', 'विधि', 'तरिका'],
            'शुल्क': ['fee', 'charge', 'दस्तुर'],
            'कागजात': ['document', 'papers', 'दस्तावेज'],
            'सूचना': ['notice', 'announcement', 'information', 'जानकारी']
        }
        
        # Find key terms in query and add variations
        query_lower = normalized_question.lower()
        expanded_terms = set()
        for term, synonyms in expansion_map.items():
            if term in query_lower:
                expanded_terms.update([term] + synonyms[:2])  # Add top 2 synonyms
                print(f"   • Found '{term}' → Adding: {', '.join(synonyms[:2])}")
        
        # If we found expandable terms, create an expanded query
        if expanded_terms:
            # Keep original query as primary, but log expansion for future hybrid search
            print(f"   ✓ Expanded with {len(expanded_terms)} related terms")
        else:
            print(f"   • No common terms to expand")
        
        # For LLM prompt, get the grammar-corrected version WITHOUT particle removal
        from rag.transliterate import correct_nepali_grammar, romanized_to_devanagari, is_romanized_nepali, translate_english_terms, extract_and_preserve_english, restore_preserved_text
        
        # Create corrected query for LLM (with grammar fixes but keeping particles)
        llm_question = translate_english_terms(question)
        if is_romanized_nepali(llm_question):
            modified_text, preserved = extract_and_preserve_english(llm_question)
            llm_question = romanized_to_devanagari(modified_text)
            llm_question = restore_preserved_text(llm_question, preserved)
        llm_question = correct_nepali_grammar(llm_question)  # Grammar corrected but particles kept
        
        print(f"\n📥 INPUT (Original Question):")
        print(f"   {question}")
        
        print(f"\n🔄 NORMALIZED for Search (particles removed):")
        print(f"   {normalized_question}")
        
        print(f"\n✨ CORRECTED for LLM (grammar fixed, particles kept):")
        print(f"   {llm_question}")
        
        if question != normalized_question:
            print(f"\n✓ Romanization applied: YES")
        else:
            print(f"\n✓ Romanization applied: NO (already in Devanagari)")
        
        # Detect if this is a comprehensive query needing more chunks
        comprehensive_indicators = ['सबै', 'सब', 'सम्पूर्ण', 'पूर्ण', 'के के', 'कति', 'सबै ', 'all', 'complete', 'full', 'list']
        is_comprehensive = any(indicator in question.lower() or indicator in normalized_question.lower() for indicator in comprehensive_indicators)
        
        if is_comprehensive:
            print(f"\n🔍 COMPREHENSIVE QUERY DETECTED - Retrieving extra chunks")
            retrieval_multiplier = 3  # 6 * 3 = 18 chunks
        else:
            retrieval_multiplier = 1
        
        print(f"\n{'='*80}")
        
        # Multi-query search for better retrieval
        all_results = []
        seen_ids = set()
        
        expanded_top_k = settings.top_k * retrieval_multiplier
        
        # 1. Search with normalized Nepali query
        nepali_results = self.index.search(normalized_question, top_k=expanded_top_k)
        for r in nepali_results:
            result_id = r.get('id') or r['text'][:100]
            if result_id not in seen_ids:
                all_results.append(r)
                seen_ids.add(result_id)
        
        # 2. Search with original query (before normalization)
        if question != normalized_question:
            original_results = self.index.search(question, top_k=expanded_top_k)
            for r in original_results:
                result_id = r.get('id') or r['text'][:100]
                if result_id not in seen_ids:
                    all_results.append(r)
                    seen_ids.add(result_id)
        
        # 3. Extract key terms and search with them
        # Remove grammar particles and search with core terms
        from rag.transliterate import remove_grammar_particles
        core_query = remove_grammar_particles(normalized_question)
        if core_query != normalized_question:
            core_results = self.index.search(core_query, top_k=expanded_top_k)
            for r in core_results:
                result_id = r.get('id') or r['text'][:100]
                if result_id not in seen_ids:
                    all_results.append(r)
                    seen_ids.add(result_id)
        
        # Sort all results by score and take expanded top_k
        all_results.sort(key=lambda x: x['score'], reverse=True)
        retrieved = all_results[:expanded_top_k]
        
        # === HYBRID RERANKING (Semantic + Lexical) ===
        print(f"\n🔄 HYBRID RERANKING:")
        print(f"   Initial results: {len(retrieved)}")
        
        # Extract query terms for lexical matching
        query_terms = set(normalized_question.lower().split())
        # Also extract terms from original question
        query_terms.update(question.lower().split())
        
        # Remove very short terms (noise)
        query_terms = {t for t in query_terms if len(t) > 2}
        
        print(f"   Key query terms: {', '.join(list(query_terms)[:8])}")
        
        # Rerank each chunk with hybrid score
        for r in retrieved:
            # Safe text extraction with None check
            chunk_text = r.get('text', '') or ''
            chunk_text_lower = chunk_text.lower()
            chunk_terms = set(chunk_text_lower.split())
            
            # 1. Semantic score (already from embedding search)
            semantic_score = r.get('score', 0.0)
            
            # 2. Lexical score (keyword matching)
            # Count how many query terms appear in chunk
            matching_terms = query_terms & chunk_terms
            lexical_score = len(matching_terms) / len(query_terms) if query_terms else 0
            
            # 3. Exact phrase bonus
            exact_phrases_bonus = 0
            # Check if multi-word phrases from query appear exactly in chunk
            query_words = normalized_question.split()
            for i in range(len(query_words) - 1):
                bigram = f"{query_words[i]} {query_words[i+1]}"
                if bigram in chunk_text_lower:
                    exact_phrases_bonus += 0.05
            
            # 4. Title/metadata relevance bonus
            meta_bonus = 0
            meta = r.get('meta', {}) or {}
            title = (meta.get('title') or '').lower()
            service = (meta.get('service_name') or '').lower()
            ministry = (meta.get('ministry') or '').lower()
            
            # Check if query terms match title/service/ministry
            for term in query_terms:
                if term in title or term in service or term in ministry:
                    meta_bonus += 0.03
            
            # Combine scores with weights
            # Semantic: 60%, Lexical: 25%, Exact phrases: 10%, Metadata: 5%
            hybrid_score = (
                semantic_score * 0.60 +
                lexical_score * 0.25 +
                exact_phrases_bonus * 0.10 +
                meta_bonus * 0.05
            )
            
            # Store both scores
            r['semantic_score'] = semantic_score
            r['lexical_score'] = lexical_score
            r['hybrid_score'] = hybrid_score
            
            # Update main score with hybrid
            r['score'] = hybrid_score
        
        # Re-sort by hybrid score
        retrieved.sort(key=lambda x: x['hybrid_score'], reverse=True)
        
        # Show top 3 reranking results
        print(f"\n   Top 3 after reranking:")
        for i, r in enumerate(retrieved[:3], 1):
            sem = r.get('semantic_score', 0)
            lex = r.get('lexical_score', 0)
            hyb = r.get('hybrid_score', 0)
            title = r.get('meta', {}).get('title', 'Unknown')[:30]
            print(f"   [{i}] {title}: semantic={sem:.3f}, lexical={lex:.3f} → hybrid={hyb:.3f}")
        
        # Apply recency boost: prioritize recent documents
        from datetime import datetime
        for r in retrieved:
            upload_date = r['meta'].get('upload_date', 'Unknown')
            if upload_date and upload_date != 'Unknown':
                try:
                    # Parse date and calculate recency boost
                    doc_date = datetime.strptime(upload_date, "%Y-%m-%d %H:%M:%S")
                    days_old = (datetime.now() - doc_date).days
                    
                    # Boost recent documents using config values
                    if days_old <= settings.recency_boost_days_high:
                        r['score'] *= settings.recency_boost_high
                        r['recency_boost'] = True
                    elif days_old <= settings.recency_boost_days_medium:
                        r['score'] *= settings.recency_boost_medium
                        r['recency_boost'] = True
                    else:
                        r['recency_boost'] = False
                except Exception:
                    # Failed to parse date, no boost applied
                    r['recency_boost'] = False
            else:
                r['recency_boost'] = False
        
        # Re-sort after recency boost
        all_results.sort(key=lambda x: x['score'], reverse=True)
        retrieved = all_results[:expanded_top_k]
        
        # Filter by relevance threshold to avoid completely irrelevant chunks
        retrieved = [r for r in retrieved if r['score'] >= settings.relevance_threshold]
        
        print(f"\n🔍 SEARCH RESULTS: Retrieved {len(retrieved)} chunks (threshold: {settings.relevance_threshold})")
        recent_count = sum(1 for r in retrieved if r.get('recency_boost', False))
        if recent_count > 0:
            print(f"   ⏰ {recent_count} recent documents boosted (within 90 days)")
        
        if not retrieved:
            # Detect if asking "who is" about a government position
            person_query_patterns = [
                'को हो', 'को हुन्', 'को हुनुहुन्छ', 'को छ', 'को छन्',
                'who is', 'who are', 
                'को नाम', 'को नाम के', 'name of', 'नाम के हो',
                'हाल को', 'current', 'वर्तमान',
                'कस्को', 'कसको'
            ]
            
            government_positions = [
                'राष्ट्रपति', 'president', 
                'प्रधानमन्त्री', 'प्रधान मन्त्री', 'prime minister',
                'मन्त्री', 'minister',
                'सभामुख', 'speaker',
                'प्रमुख न्यायाधीश', 'chief justice',
                'महान्यायाधिवक्ता', 'attorney general'
            ]
            
            q_lower = normalized_question.lower()
            is_person_query = any(pattern in q_lower for pattern in person_query_patterns)
            is_about_position = any(pos in q_lower for pos in government_positions)
            
            if is_person_query and is_about_position:
                print(f"\n👤 PERSON-QUERY DETECTED (asking 'who is' about government position)")
                
                # Extract the position being asked about
                position_asked = "यस पद"
                for pos in government_positions:
                    if pos in q_lower:
                        position_asked = pos
                        break
                
                # Provide helpful clarification
                final_answer = (
                    f"📌 वर्तमान {position_asked}को नाम/पहिचान सरकारी दस्तावेजहरूमा उल्लेख छैन।\n\n"
                    f"तर, मसँग {position_asked}को **भूमिका, अधिकार र जिम्मेवारी** बारेमा जानकारी छ।\n\n"
                    f"यदि तपाईंलाई {position_asked}को:\n"
                    f"• कार्यक्षेत्र\n"
                    f"• अधिकारहरू\n"
                    f"• जिम्मेवारीहरू\n"
                    f"• नियुक्ति प्रक्रिया\n\n"
                    f"बारे जान्न चाहनुहुन्छ भने, कृपया सोध्नुहोस्! 😊"
                )
                
                print(f"\n📤 OUTPUT (Helpful clarification provided):")
                print(f"   {final_answer[:150]}...")
                print(f"\n{'='*80}\n")
                return final_answer
            
            # Default "not found" response for other queries
            final_answer = "यो जानकारी उपलब्ध दस्तावेजमा छैन।"
            print(f"\n📤 OUTPUT (Sent to Frontend):")
            print(f"   {final_answer}")
            print(f"\n{'='*80}\n")
            return final_answer
        
        # Show similarity scores and content for debugging
        print(f"\n📊 CHUNK DETAILS:")
        for i, r in enumerate(retrieved, 1):
            print(f"\n   [{i}] Score: {r['score']:.4f} | Source: {r['meta'].get('title', 'Unknown')}")
            print(f"       Preview: {r['text'][:120]}...")
                # Smart filtering for comprehensive queries
        if is_comprehensive:
            # Detect if asking about constitutional/fundamental topics
            constitutional_keywords = ['अधिकार', 'हक', 'संविधान', 'समबिधान', 'नागरिक', 'मौलिक', 'rights', 'constitution']
            is_constitutional = any(kw in question.lower() or kw in normalized_question.lower() for kw in constitutional_keywords)
            
            if is_constitutional:
                # Filter out press releases and keep only constitution/law documents
                print(f"\n\U0001f4dc Constitutional query detected - filtering documents")
                constitution_chunks = [r for r in retrieved if r['meta'].get('type') in ['constitution', 'law', 'act']]
                
                # If we have enough constitution chunks, use only those
                if len(constitution_chunks) >= 12:
                    retrieved = constitution_chunks
                    print(f"   ✓ Using {len(retrieved)} constitution/law chunks only")
                else:
                    print(f"   ⚠ Only {len(constitution_chunks)} constitution chunks found, using all {len(retrieved)}")
                # Build context with chunk numbers for better clarity
        # Group chunks by document type for better organization
        constitution_chunks = []
        law_chunks = []
        other_chunks = []
        sources_lines = []
        seen_sources = set()
        
        for i, r in enumerate(retrieved, 1):
            meta = r.get("meta", {}) or {}
            
            # Clean chunk text to avoid safety filter triggers
            chunk_text = r.get('text', '') or ''
            cleaned_text = self._clean_chunk_for_llm(chunk_text)
            
            # Categorize chunks
            doc_type = meta.get('type', 'other') or 'other'
            
            # Build rich context with metadata
            meta_info = []
            if meta.get('title'):
                meta_info.append(f"शीर्षक: {meta['title']}")
            if meta.get('ministry') and meta['ministry'] != 'Unknown':
                meta_info.append(f"मन्त्रालय: {meta['ministry']}")
            if meta.get('service_name') and meta['service_name'] != 'Unknown':
                meta_info.append(f"सेवा: {meta['service_name']}")
            if meta.get('notice_id'):
                meta_info.append(f"सूचना नं: {meta['notice_id']}")
            if meta.get('upload_date') and meta['upload_date'] != 'Unknown':
                meta_info.append(f"मिति: {meta['upload_date']}")
            
            # Format chunk with rich metadata for better LLM understanding
            if meta_info:
                chunk_entry = f"[{i}] ({', '.join(meta_info)})\n{cleaned_text}"
            else:
                chunk_entry = f"[{i}] {cleaned_text}"
            
            if doc_type == 'constitution':
                constitution_chunks.append(chunk_entry)
            elif doc_type in ['law', 'act']:
                law_chunks.append(chunk_entry)
            else:
                other_chunks.append(chunk_entry)
            
            # Deduplicate sources and try to extract page info from chunk
            source_key = f"{meta.get('title') or 'Unknown'}"
            title = meta.get('title') or 'Unknown'
            
            # Skip test/dummy documents and unknown titles
            if any(skip in title.lower() for skip in ['test-', 'dummy', 'unknown', 'untitled']):
                continue
            
            # Clean up document name - remove file extensions and clean formatting
            clean_title = title.replace('_', ' ').replace('-', ' ')
            # Remove common suffixes
            for suffix in ['.pdf', '.txt', '.md', 'www.', '.gov', '.np']:
                clean_title = clean_title.replace(suffix, '')
            # Simplify long government document names
            if 'Constitution' in clean_title and 'Nepal' in clean_title:
                clean_title = 'नेपालको संविधान 2072'
            
            # Try to find page reference in chunk text
            page_info = ""
            import re as regex_module
            page_match = regex_module.search(r'(?:Page|पृष्ठ|p\.?)\s*(\d+)', cleaned_text, regex_module.IGNORECASE)
            if page_match:
                page_info = f" (पृष्ठ {page_match.group(1)})"
            
            if source_key not in seen_sources:
                seen_sources.add(source_key)
                
                # Format source line with complete metadata including date
                source_parts = [f"📄 {clean_title}{page_info}"]
                
                ministry = meta.get('ministry', '')
                service = meta.get('service_name', '')
                upload_date = meta.get('upload_date', '')
                
                if ministry and ministry != 'Unknown' and ministry.strip():
                    source_parts.append(ministry)
                if service and service != 'Unknown' and service.strip():
                    source_parts.append(f"सेवा: {service}")
                if upload_date and upload_date != 'Unknown':
                    # Show both date and time
                    source_parts.append(f"📅 {upload_date}")
                
                source_line = " • ".join(source_parts)
                sources_lines.append(source_line)
        
        # Build organized context with intelligent grouping for multi-document understanding
        context_sections = []
        
        # Add metadata summary to help LLM understand document relationships
        doc_summary = []
        doc_types_present = set()
        ministries_present = set()
        date_range = []
        
        for r in retrieved:
            meta = r.get("meta", {}) or {}
            doc_type = meta.get('type', 'other') or 'other'
            ministry = meta.get('ministry', '') or ''
            upload_date = meta.get('upload_date', '') or ''
            
            if doc_type:
                doc_types_present.add(doc_type)
            if ministry and ministry != 'Unknown':
                ministries_present.add(ministry)
            if upload_date and upload_date != 'Unknown':
                date_range.append(upload_date)
        
        # Create context overview to help LLM connect concepts
        overview = "📋 **दस्तावेज सारांश:** "
        overview_parts = []
        if doc_types_present:
            types_str = ', '.join(doc_types_present)
            overview_parts.append(f"प्रकार: {types_str}")
        if ministries_present:
            ministries_str = ', '.join(list(ministries_present)[:3])  # Show max 3
            overview_parts.append(f"मन्त्रालय: {ministries_str}")
        if date_range:
            dates_sorted = sorted(date_range, reverse=True)
            if len(dates_sorted) > 1:
                overview_parts.append(f"मिति: {dates_sorted[0]} देखि {dates_sorted[-1]} सम्म")
            else:
                overview_parts.append(f"मिति: {dates_sorted[0]}")
        
        if overview_parts:
            overview += " | ".join(overview_parts)
            context_sections.append(overview)
        
        # Organize chunks by type with clear separators
        if constitution_chunks:
            section = f"📜 **संविधानबाट** ({len(constitution_chunks)} खण्ड):\n" + "\n\n".join(constitution_chunks)
            context_sections.append(section)
        if law_chunks:
            section = f"⚖️ **कानून/ऐनबाट** ({len(law_chunks)} खण्ड):\n" + "\n\n".join(law_chunks)
            context_sections.append(section)
        if other_chunks:
            section = f"📄 **अन्य सरकारी दस्तावेजबाट** ({len(other_chunks)} खण्ड):\n" + "\n\n".join(other_chunks)
            context_sections.append(section)
        
        # Add cross-reference note if multiple document types present
        if len(doc_types_present) > 1:
            context_sections.append(
                "\n💡 **ध्यान दिनुहोस्:** माथि विभिन्न प्रकारका दस्तावेजहरू छन्। "
                "यदि कुनै विषयमा धेरै source छन् भने ती सबैको जानकारी एकै ठाउँमा जोड्नुहोस्।"
            )
        
        context_text = "\n\n".join(context_sections)
        sources_text = "\n".join(sources_lines)

        # Build ChatGPT-style prompt with enhanced reasoning instructions
        system_message = (
            "तपाईं नेपाल सरकारको विशेषज्ञ AI सहायक हुनुहुन्छ जसले ChatGPT जस्तै गहिरो सोच र विश्लेषण गर्छ।\n\n"
            "🧠 **तपाईंको सोच प्रक्रिया (यो देखाउनु पर्दैन, तर पालना गर्नुहोस्):**\n"
            "1. प्रश्न के सोधिएको छ? (मुख्य अवधारणा, निकाय, र सन्दर्भ पहिचान गर्नुहोस्)\n"
            "2. कुन दस्तावेजमा के जानकारी छ? (प्रत्येक chunk को सम्बद्धता जाँच्नुहोस्)\n"
            "3. विभिन्न दस्तावेजहरूबीच के सम्बन्ध छ? (एउटै विषयमा फरक source हरूको जानकारी जोड्नुहोस्)\n"
            "4. कुन जानकारी प्राथमिकतामा राख्ने? (मिति हेर्नुहोस् - नयाँ > पुरानो)\n"
            "5. कुन जानकारी अधूरो वा missing छ? (यदि छ भने स्पष्ट उल्लेख गर्नुहोस्)\n\n"
            "✅ **तपाईंको काम:**\n"
            "• दिइएको दस्तावेजहरूबाट सटीक जानकारी निकाल्ने\n"
            "• पूर्ण र व्यापक उत्तर दिने (अधूरो नहुनुहोस्)\n"
            "• सबै सम्बन्धित बुँदाहरू समावेश गर्ने\n"
            "• विभिन्न sources बाट आएका जानकारी एकै ठाउँमा जोड्ने\n"
            "• स्पष्ट र संगठित तरिकाले प्रस्तुत गर्ने\n"
            "• केवल दिइएको दस्तावेजको आधारमा उत्तर दिने (अनुमान नगर्ने)\n"
            "• दस्तावेजसँग आएको सन्दर्भ (मन्त्रालय, सेवा, सूचना नं, मिति) ध्यानपूर्वक हेर्ने\n"
            "• हालैका दस्तावेजलाई प्राथमिकता दिने - यदि conflict छ भने नयाँ जानकारी प्रयोग गर्ने\n\n"
            "⚠️ **यदि जानकारी अपूर्ण छ:**\n"
            "• के जानकारी छ - पहिले त्यो दिनुहोस्\n"
            "• के जानकारी छैन - स्पष्ट भन्नुहोस्\n"
            "• अनुमान नगर्नुहोस् - केवल दस्तावेजमा भएको कुरा मात्र भन्नुहोस्"
        )
        
        # Adjust instructions based on query type
        if wants_brief_answer:
            # User explicitly asked for brief/concise answer
            task_instruction = (
                "**यो संक्षिप्त उत्तर चाहने प्रश्न हो - छोट्करीमा मात्र जवाफ दिनुहोस्:**\n\n"
                "कृपया:\n"
                "• केवल मुख्य बुँदाहरू मात्र उल्लेख गर्नुहोस् (३-५ वाक्य)\n"
                "• विस्तृत विवरण नदिनुहोस्\n"
                "• सरल र स्पष्ट भाषा प्रयोग गर्नुहोस्\n"
                "• लामो सूची वा विस्तार नगर्नुहोस्\n\n"
                "माथिको दस्तावेजको आधारमा प्रश्नको संक्षिप्त उत्तर नेपालीमा दिनुहोस्।"
            )
        elif is_comprehensive:
            task_instruction = (
                "**यो व्यापक प्रश्न हो - सबै जानकारी चाहिन्छ:**\n\n"
                "कृपया माथिका सबै दस्तावेजहरूबाट:\n"
                "• प्रत्येक सम्बन्धित बुँदा पहिचान गर्नुहोस्\n"
                "• सबै बुँदाहरूलाई क्रमबद्ध तरिकाले सूचीबद्ध गर्नुहोस्\n"
                "• कुनै पनि बुँदा छुटाउनु हुँदैन\n"
                "• प्रत्येक बुँदाको छोटो विवरण दिनुहोस्\n\n"
                "उदाहरण ढाँचा:\n"
                "१. पहिलो अधिकार: (विवरण)\n"
                "२. दोस्रो अधिकार: (विवरण)\n"
                "३. तेस्रो अधिकार: (विवरण)\n"
                "... र यसरी सबै\n\n"
                "ध्यान दिनुहोस्: केवल १-२ उदाहरण मात्र नभई COMPLETE LIST दिनुहोस्!"
            )
        else:
            task_instruction = (
                "माथिको दस्तावेजको आधारमा प्रश्नको सटीक र विस्तृत उत्तर नेपालीमा दिनुहोस्।"
            )

        # ChatGPT-style structured prompt
        prompt = (
            f"{system_message}\n\n"
            f"{'='*60}\n"
            f"📚 उपलब्ध दस्तावेजहरू:\n\n"
            f"{context_text}\n\n"
            f"{'='*60}\n\n"
            f"❓ प्रश्न: {llm_question}\n\n"
            f"{task_instruction}\n\n"
            f"💡 उत्तर (नेपालीमा, पूर्ण र विस्तृत):"
        )
        
        print(f"\n{'='*80}")
        print(f"⚙️  SENDING TO LLM ")
        answer_body = self.generator.generate(prompt)
        
        print(f"\n🤖 RAW LLM RESPONSE:")
        print(f"   {answer_body[:200]}..." if len(answer_body) > 200 else f"   {answer_body}")
        
        # Clean up answer - remove instruction echoes and nonsense
        answer_body = answer_body.strip()
        
        # Check if output is in romanized form (has Latin diacritics)
        romanized_chars = ['ā', 'ī', 'ū', 'ṛ', 'ṃ', 'ṅ', 'ñ', 'ṭ', 'ḍ', 'ṇ', 'ś', 'ṣ']
        if any(char in answer_body for char in romanized_chars):
            print(f"⚠️  WARNING: Romanized output detected, rejecting")
            answer_body = "यो जानकारी उपलब्ध दस्तावेजमा छैन।"
            final_answer = answer_body  # No sources for error case
            print(f"\n📤 OUTPUT (Sent to Frontend):")
            print(f"   {answer_body}")
            print(f"\n{'='*80}\n")
            return final_answer
        
        # Remove "उत्तर:" label if LLM echoed it
        if answer_body.lower().startswith("उत्तर:"):
            answer_body = answer_body[6:].strip()
            print(f"🧹 Removed 'उत्तर:' label")
        
        # Remove system role echoes at the very beginning
        system_role_patterns = [
            r'^नेपाल सरकारी कागजातको विज्ञ सहायक हुनुहुन्छ[।\.\s]+',
            r'^तपाईं नेपाल सरकारको सूचना सहायक हुनुहुन्छ[।\.\s]+',
            r'^नेपाल सरकारी कागजातको सहायक[।\.\s]+',
            r'^उत्तर:\s*',
        ]
        for pattern in system_role_patterns:
            if re.match(pattern, answer_body, re.IGNORECASE):
                answer_body = re.sub(pattern, '', answer_body, flags=re.IGNORECASE).strip()
                print(f"🧹 Removed system role echo")
        
        # Remove English translations in parentheses
        # Pattern: (Translation: ...)
        if '(Translation:' in answer_body or '(translation:' in answer_body.lower():
            answer_body = re.sub(r'\(Translation:.*?\)', '', answer_body, flags=re.IGNORECASE | re.DOTALL)
            print(f"🧹 Removed English translation")
        # Pattern: (Any English text in parentheses)
        answer_body = re.sub(r'\([a-zA-Z\s,\.;:]+\)\.?', '', answer_body)
        
        # Replace common English words mixed in Nepali text
        english_replacements = {
            'Prosperous': 'समृद्ध',
            'prosperous': 'समृद्ध',
            'nation': 'राष्ट्र',
            'Nation': 'राष्ट्र',
            'prosperity': 'समृद्धि',
            'Prosperity': 'समृद्धि',
            'justice': 'न्याय',
            'Justice': 'न्याय',
            'equality': 'समानता',
            'Equality': 'समानता',
        }
        for eng, nep in english_replacements.items():
            answer_body = answer_body.replace(eng, nep)
        
        # Clean article reference abbreviations from English source
        answer_body = re.sub(r'प्र\.\s*(\d+)', r'धारा \1', answer_body)
        
        # Remove trailing question echoes (questions at the end)
        trailing_question_patterns = [
            r'[।\.]?\s*यस्तै के के [^।]+छन\s*[?।\?]+\s*$',
            r'[।\.]?\s*के के [^।]+छन\s*[?।\?]+\s*$',
            r'[।\.]?\s*किन\s*[?।\?]+\s*$',
        ]
        for pattern in trailing_question_patterns:
            if re.search(pattern, answer_body):
                answer_body = re.sub(pattern, '।', answer_body).strip()
                print(f"🧹 Removed trailing question echo")
        
        answer_body = answer_body.strip()
        
        # Remove instruction echoes and meta-commentary
        instruction_patterns = [
            "माथिको प्रसंगको जानकारीलाई आधार बनाएर विस्तृत उत्तर दिनुहोस्",
            "तलको प्रसंगबाट प्रश्नको सीधा उत्तर दिनुहोस्",
            "सिधा जवाफ मात्र, प्रश्न नदोहोर्याउनुहोस्",
            "तपाईं सरकारी सूचना सहायक हुनुहुन्छ",
            "तपाईं नेपाल सरकारको सूचना सहायक हुनुहुन्छ",
            "तपाईं सहायक हुनुहुन्छ",
            "तपाईं नेपाल सरकारी कागजातको सहायक हुनुहुन्छ",
            "तपाईंले प्रश्न पूछेको छ",
            "तपाईंले केही प्रश्न पूछेको छ",
            "हामीले माथिको प्रसंगको जानकारीलाई आधार बनाएर",
            "विस्तृत उत्तर दिनुहोस्",
            "तपाईंको प्रश्न हो",
            "प्रयोगकर्ताको प्रश्न",
            "संस्थाको कार्य बारे:",
            "ठेगाना/स्थान:",
            "स्पष्ट रूपमा दिनुहोस्",
            "३-५ वाक्यमा सम्पूर्ण र स्पष्ट जानकारी",
            "सम्पूर्ण र स्पष्ट जानकारी:",
        ]
        
        # First pass: Remove lines with instruction patterns or meta-labels
        lines = answer_body.split('\n')
        clean_lines = []
        for line in lines:
            line_stripped = line.strip()
            if not line_stripped:
                continue
            
            # Remove lines starting with meta-labels
            meta_labels = ['संस्थाको कार्य बारे:', 'ठेगाना/स्थान:', 'उद्देश्य:', 
                          'नोट:', 'महत्वपूर्ण:', 'जानकारी:', 'विवरण:']
            if any(line_stripped.startswith(label) for label in meta_labels):
                print(f"🧹 Removed meta-label line: {line_stripped[:60]}...")
                continue
            
            # Check if line contains any instruction pattern
            contains_instruction = False
            for pattern in instruction_patterns:
                if pattern.lower() in line_stripped.lower():
                    print(f"🧹 Removed instruction echo: {line_stripped[:60]}...")
                    contains_instruction = True
                    break
            if not contains_instruction:
                clean_lines.append(line)
        
        answer_body = '\n'.join(clean_lines).strip()
        
        # Remove question echoes at the start
        # Pattern: "तपाईंको प्रश्न हो-" or similar
        question_echo_patterns = [
            r'^तपाईंको प्रश्न हो[:\-\s]+["\'].*?["\']',
            r'^तपाईंले सोध्नुभएको प्रश्न[:\-\s]+',
            r'^प्रश्न[:\-\s]+',
        ]
        for pattern in question_echo_patterns:
            answer_body = re.sub(pattern, '', answer_body, flags=re.IGNORECASE)
            answer_body = answer_body.strip()
        
        # Remove question echoes - if answer starts with question or romanized garbage
        # Split by newlines or । to find question echo
        sentences = answer_body.split('।')
        clean_sentences = []
        question_lower = normalized_question.lower()
        question_words = set(question_lower.split())
        
        for i, sent in enumerate(sentences):
            sent = sent.strip()
            if not sent:
                continue
            
            sent_lower = sent.lower()
            sent_words = set(sent_lower.split())
            
            # If first sentence and has >70% question word overlap, skip it
            if i == 0 and len(question_words) > 0:
                overlap = len(question_words & sent_words)
                overlap_ratio = overlap / len(question_words)
                if overlap_ratio > 0.7:
                    print(f"🧹 Removed question echo: {sent[:80]}...")
                    continue
            
            # Skip sentences with excessive garbage transliteration (random consonant clusters)
            # Pattern like: षांबईडःआण (should be संविधान)
            garbage_chars = ['ष', 'ड़', 'ः', 'ॅ', 'ँ', 'ऑ']
            garbage_count = sum(1 for char in sent if char in garbage_chars)
            if len(sent) > 0 and garbage_count / len(sent) > 0.15:
                print(f"🧹 Removed garbage transliteration: {sent[:60]}...")
                continue
            
            clean_sentences.append(sent)
        
        if clean_sentences:
            # Remove duplicate consecutive sentences
            unique_sentences = []
            prev_sent_normalized = ""
            for sent in clean_sentences:
                # Normalize for comparison (remove spaces, punctuation)
                sent_normalized = re.sub(r'[\s।,.]+', '', sent.lower())
                if sent_normalized != prev_sent_normalized:
                    unique_sentences.append(sent)
                    prev_sent_normalized = sent_normalized
                else:
                    print(f"🧹 Removed duplicate sentence: {sent[:60]}...")
            
            answer_body = '। '.join(unique_sentences)
            if answer_body and not answer_body.endswith('।'):
                answer_body += '।'
        
        answer_body = answer_body.strip()
        
        # Check if response is in English (reject it)
        english_words = ['based', 'on', 'the', 'information', 'provided', 'here', 'are', 
                        'regarding', 'usage', 'regulation', 'note', 'if', 'there', 'is', 
                        'no', 'available', 'this', 'document', 'would']
        answer_lower = answer_body.lower()
        english_word_count = sum(1 for word in english_words if word in answer_lower)
        
        print(f"\n🔍 English words detected: {english_word_count}")
        
        # If too many English words detected, reject and return fallback
        if english_word_count >= 5:
            print(f"⚠️  WARNING: English response rejected (threshold: 5)")
            answer_body = "यो जानकारी उपलब्ध दस्तावेजमा छैन।"
        
        # === ANSWER VALIDATION AGAINST SOURCES ===
        print(f"\n✅ VALIDATING ANSWER AGAINST SOURCE CHUNKS:")
        
        # Extract key claims from the answer (sentences with specific facts)
        answer_sentences = [s.strip() for s in answer_body.split('।') if len(s.strip()) > 10]
        
        # Check if answer contains information that's actually in the chunks
        validation_passed = True
        unsupported_claims = []
        
        # Combine all chunk texts for validation
        all_chunk_text = ' '.join([r['text'].lower() for r in retrieved])
        
        # Look for specific numeric values or dates in answer
        import re as regex_validation
        numbers_in_answer = regex_validation.findall(r'\d+', answer_body)
        
        if numbers_in_answer:
            numbers_found_in_chunks = 0
            for num in numbers_in_answer[:5]:  # Check first 5 numbers
                if num in all_chunk_text:
                    numbers_found_in_chunks += 1
            
            # If answer has specific numbers, at least some should appear in chunks
            if len(numbers_in_answer) >= 3 and numbers_found_in_chunks == 0:
                print(f"   ⚠️  WARNING: Answer contains numbers not found in chunks")
                validation_passed = False
        
        # Check for key terms mentioned in answer
        key_terms_in_answer = []
        for sentence in answer_sentences[:3]:  # Check first 3 sentences
            # Extract potential key terms (words longer than 4 chars in Devanagari)
            words = sentence.split()
            for word in words:
                cleaned_word = word.strip('।,;:()[]"\'')
                # Check if it's a Devanagari word of reasonable length
                if len(cleaned_word) > 4 and any('\u0900' <= c <= '\u097F' for c in cleaned_word):
                    key_terms_in_answer.append(cleaned_word.lower())
        
        # Verify at least 60% of key terms appear in chunks
        if key_terms_in_answer:
            terms_found = sum(1 for term in key_terms_in_answer if term in all_chunk_text)
            coverage = terms_found / len(key_terms_in_answer) if key_terms_in_answer else 0
            
            print(f"   • Key terms coverage: {coverage:.1%} ({terms_found}/{len(key_terms_in_answer)})")
            
            if coverage < 0.6:
                print(f"   ⚠️  WARNING: Low coverage - answer may not be well-supported")
                validation_passed = False
        
        # Final validation result
        if validation_passed:
            print(f"   ✅ Answer validation PASSED - content is supported by sources")
        else:
            print(f"   ⚠️  Answer validation FAILED - some claims may not be well-supported")
            print(f"   💡 Consider: Answer might be hallucinated or inferred")
        
            final_answer = answer_body  # No sources for error case
            print(f"\n📤 OUTPUT (Sent to Frontend):")
            print(f"   {answer_body}")
            print(f"\n{'='*80}\n")
            return final_answer
        
        # Remove lines that are just repetitive nonsense
        lines = answer_body.split('\n')
        clean_lines = []
        prev_line = ""
        for line in lines:
            line = line.strip()
            if not line:
                continue
            # Skip duplicate lines
            if line == prev_line:
                print(f"🧹 Removed duplicate line: {line[:60]}...")
                continue
            # Skip lines with excessive repetition of same words
            words = line.split()
            if len(words) > 3 and len(set(words)) / len(words) < 0.4:  # Too repetitive
                print(f"🧹 Removed repetitive line: {line[:60]}...")
                continue
            clean_lines.append(line)
            prev_line = line
        
        answer_body = '\n\n'.join(clean_lines)
        
        if not answer_body:
            answer_body = "यो जानकारी उपलब्ध दस्तावेजमा छैन।"
        
        # Detect if LLM says "no information available" AND provides nothing else
        # Only suppress sources if the answer is SHORT and says "not found"
        answer_lower = answer_body.lower()
        
        # Check if answer is very short (likely just "no info" message)
        is_short_answer = len(answer_body) < 150
        
        # Check if it's genuinely a "no info" response
        no_info_indicators = [
            'जानकारी उपलब्ध दस्तावेजमा छैन',  # Exact phrase
            'यो जानकारी छैन',
            'कुनै जानकारी उपलब्ध छैन'
        ]
        
        # Only mark as "no info" if short AND has exact phrase
        llm_says_no_info = is_short_answer and any(phrase in answer_lower for phrase in no_info_indicators)
        
        # Check if LLM response indicates "person identity not available"
        # This happens when user asks "who is president?" but docs only have role info
        person_not_found_patterns = [
            'को हुनुहुन्छ भन्ने.*?जानकारी.*?छैन',
            'को हो.*?जानकारी.*?छैन',
            'को नाम.*?उल्लेख.*?छैन',
            'व्यक्तिको नाम.*?छैन',
            'पहिचान.*?जानकारी.*?छैन',
            'who.*?is.*?not.*?mentioned',
            'name.*?not.*?mentioned'
        ]
        
        llm_says_person_not_found = any(re.search(pattern, answer_lower) for pattern in person_not_found_patterns)
        
        if llm_says_person_not_found:
            # Check if original question was asking "who is"
            person_query_patterns = [
                'को हो', 'को हुन्', 'को हुनुहुन्छ', 'को छ', 'को छन्',
                'who is', 'who are', 
                'को नाम', 'name of', 'हाल को', 'current', 'वर्तमान'
            ]
            
            government_positions = [
                'राष्ट्रपति', 'president', 
                'प्रधानमन्त्री', 'प्रधान मन्त्री', 'prime minister',
                'मन्त्री', 'minister',
                'सभामुख', 'speaker',
                'प्रमुख न्यायाधीश', 'chief justice'
            ]
            
            q_lower = normalized_question.lower()
            is_person_query = any(pattern in q_lower for pattern in person_query_patterns)
            is_about_position = any(pos in q_lower for pos in government_positions)
            
            if is_person_query and is_about_position:
                print(f"\n✨ DETECTED: LLM says person name not found + user asked 'who is' query")
                print(f"   Adding helpful guidance...")
                
                # Extract position being asked about
                position_asked = "यस पद"
                for pos in government_positions:
                    if pos in q_lower:
                        position_asked = pos
                        break
                
                # Enhance answer with helpful guidance
                enhanced_answer = (
                    f"{answer_body}\n\n"
                    f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
                    f"💡 **मद्दत:** वर्तमान {position_asked}को नाम/पहिचान सरकारी दस्तावेजहरूमा उल्लेख छैन।\n\n"
                    f"तर मसँग **{position_asked}को भूमिका, अधिकार र जिम्मेवारी** बारेमा विस्तृत जानकारी छ!\n\n"
                    f"यदि तपाईंलाई जान्न चाहनुहुन्छ:\n"
                    f"• {position_asked}को कार्यक्षेत्र\n"
                    f"• अधिकारहरू र शक्तिहरू\n"
                    f"• जिम्मेवारीहरू\n"
                    f"• नियुक्ति प्रक्रिया\n\n"
                    f"तब कृपया सोध्नुहोस्! उदाहरण: \"{position_asked}को अधिकारहरू के के छन्?\" 😊"
                )
                answer_body = enhanced_answer
        
        # Only add sources if:
        # 1. Sources exist (non-empty list)
        # 2. LLM provided real content (not just "no info")
        # 3. Answer is substantial (has meaningful content)
        should_show_sources = (
            sources_lines and 
            len(sources_lines) > 0 and 
            not llm_says_no_info and
            len(answer_body.strip()) > 50  # Ensure answer has real content
        )
        
        if should_show_sources:
            final_answer = f"{answer_body}\n\n📚 **संदर्भ स्रोतहरू:**\n{sources_text}"
        else:
            final_answer = answer_body
        
        print(f"\n✨ CLEANED ANSWER:")
        print(f"   {answer_body[:200]}..." if len(answer_body) > 200 else f"   {answer_body}")
        
        print(f"\n📤 FINAL OUTPUT (Sent to Frontend):")
        print(f"   Length: {len(final_answer)} characters")
        print(f"   Sources shown: {'Yes' if should_show_sources else 'No'} ({len(sources_lines)} available)")
        
        print(f"\n{'='*80}\n")
        
        return final_answer
