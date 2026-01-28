from typing import List
import re

from .config import settings
from .index import VectorIndex
from .models import EmbeddingModel, GenerativeModel
from .transliterate import normalize_query

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
        
        print(f"\n{'='*80}")
        print(f"{'RAG PIPELINE DEBUG OUTPUT':^80}")
        print(f"{'='*80}")
        
        # Normalize query (transliterate if romanized)
        normalized_question = normalize_query(question)
        
        print(f"\n📥 INPUT (Original Question):")
        print(f"   {question}")
        
        print(f"\n🔄 NORMALIZED (After Romanization):")
        print(f"   {normalized_question}")
        
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
        
        # Filter by relevance threshold to avoid completely irrelevant chunks
        RELEVANCE_THRESHOLD = 0.65  # Lowered for cross-lingual queries
        retrieved = [r for r in retrieved if r['score'] >= RELEVANCE_THRESHOLD]
        
        print(f"\n🔍 SEARCH RESULTS: Retrieved {len(retrieved)} chunks (threshold: {RELEVANCE_THRESHOLD})")
        
        if not retrieved:
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
            meta = r["meta"]
            
            # Clean chunk text to avoid safety filter triggers
            cleaned_text = self._clean_chunk_for_llm(r['text'])
            
            # Categorize chunks
            doc_type = meta.get('type', 'other')
            chunk_entry = f"[{i}] {cleaned_text}"
            
            if doc_type == 'constitution':
                constitution_chunks.append(chunk_entry)
            elif doc_type in ['law', 'act']:
                law_chunks.append(chunk_entry)
            else:
                other_chunks.append(chunk_entry)
            
            # Deduplicate sources and try to extract page info from chunk
            source_key = f"{meta.get('title','Unknown')}"
            
            # Try to find page reference in chunk text (often in format "Page X" or "पृष्ठ X")
            page_info = ""
            import re as regex_module
            page_match = regex_module.search(r'(?:Page|पृष्ठ|p\.?)\s*(\d+)', cleaned_text, regex_module.IGNORECASE)
            if page_match:
                page_info = f" (पृष्ठ {page_match.group(1)})"
            
            if source_key not in seen_sources:
                seen_sources.add(source_key)
                sources_lines.append(
                    f"📄 {meta.get('title','Unknown')}{page_info} "
                    f"- {meta.get('ministry','Unknown')}"
                )
        
        # Build organized context with sections
        context_sections = []
        
        if constitution_chunks:
            context_sections.append("📜 संविधानबाट:\n" + "\n\n".join(constitution_chunks))
        if law_chunks:
            context_sections.append("⚖️ कानून/ऐनबाट:\n" + "\n\n".join(law_chunks))
        if other_chunks:
            context_sections.append("📄 अन्य दस्तावेजबाट:\n" + "\n\n".join(other_chunks))
        
        context_text = "\n\n".join(context_sections)
        sources_text = "\n".join(sources_lines)

        # Build ChatGPT-style prompt with system message and structured instructions
        system_message = (
            "तपाईं नेपाल सरकारको विशेषज्ञ AI सहायक हुनुहुन्छ। तपाईंको काम:\n"
            "1. दिइएको दस्तावेजहरूबाट सटीक जानकारी निकाल्ने\n"
            "2. पूर्ण र व्यापक उत्तर दिने (अधूरो नहुनुहोस्)\n"
            "3. सबै सम्बन्धित बुँदाहरू समावेश गर्ने\n"
            "4. स्पष्ट र संगठित तरिकाले प्रस्तुत गर्ने\n"
            "5. केवल दिइएको दस्तावेजको आधारमा उत्तर दिने"
        )
        
        # Adjust instructions based on query type
        if is_comprehensive:
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
            f"❓ प्रश्न: {normalized_question}\n\n"
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
            final_answer = f"{answer_body}\n\n📚 स्रोतहरू:\n{sources_text}"
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
            final_answer = f"{answer_body}\n\n📚 स्रोतहरू:\n{sources_text}"
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
        
        final_answer = f"{answer_body}\n\n📚 स्रोतहरू:\n{sources_text}"
        
        print(f"\n✨ CLEANED ANSWER:")
        print(f"   {answer_body[:200]}..." if len(answer_body) > 200 else f"   {answer_body}")
        
        print(f"\n📤 FINAL OUTPUT (Sent to Frontend):")
        print(f"   Length: {len(final_answer)} characters")
        print(f"   Sources: {len(sources_lines)} document(s)")
        
        print(f"\n{'='*80}\n")
        
        return final_answer
