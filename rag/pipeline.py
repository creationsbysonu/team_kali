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

    def answer(self, question: str) -> str:
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
        
        print(f"\n{'='*80}")
        
        # Multi-query search for better retrieval
        all_results = []
        seen_ids = set()
        
        # 1. Search with normalized Nepali query
        nepali_results = self.index.search(normalized_question, top_k=settings.top_k)
        for r in nepali_results:
            result_id = r.get('id') or r['text'][:100]
            if result_id not in seen_ids:
                all_results.append(r)
                seen_ids.add(result_id)
        
        # 2. Search with original query (before normalization)
        if question != normalized_question:
            original_results = self.index.search(question, top_k=settings.top_k)
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
            core_results = self.index.search(core_query, top_k=settings.top_k)
            for r in core_results:
                result_id = r.get('id') or r['text'][:100]
                if result_id not in seen_ids:
                    all_results.append(r)
                    seen_ids.add(result_id)
        
        # Sort all results by score and take top_k
        all_results.sort(key=lambda x: x['score'], reverse=True)
        retrieved = all_results[:settings.top_k]
        
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
        
        # Build context with chunk numbers for better clarity
        context_blocks = []
        sources_lines = []
        seen_sources = set()
        
        for i, r in enumerate(retrieved, 1):
            meta = r["meta"]
            # Add chunk with numbering
            context_blocks.append(f"[{i}] {r['text']}") 
            # Deduplicate sources
            source_key = f"{meta.get('title','Unknown')}"
            if source_key not in seen_sources:
                seen_sources.add(source_key)
                sources_lines.append(
                    f"📄 {meta.get('title','Unknown')} "
                    f"({meta.get('ministry','Unknown')}, {meta.get('upload_date','Unknown')})"
                )
        
        context_text = "\n\n".join(context_blocks)
        sources_text = "\n".join(sources_lines)

        # Simple but effective prompt that works with English source documents
        prompt = (
            f"प्रसंग (दस्तावेजको जानकारी):\n{context_text}\n\n"
            f"प्रश्न: {normalized_question}\n\n"
            f"माथिको प्रसंगबाट प्रश्नको विस्तृत उत्तर नेपालीमा दिनुहोस्:"
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
