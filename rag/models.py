from abc import ABC, abstractmethod
from typing import List
import numpy as np

class EmbeddingModel(ABC):
    @abstractmethod
    def embed(self, texts: List[str]) -> np.ndarray:
        """Return 2D numpy array [n_texts, dim]."""
        raise NotImplementedError

class GenerativeModel(ABC):
    @abstractmethod
    def generate(self, prompt: str) -> str:
        """Return a generated answer string."""
        raise NotImplementedError

class DummyEmbedding(EmbeddingModel):
    def embed(self, texts: List[str]) -> np.ndarray:
        # Very simple bag-of-words length-based embedding; replace with real model
        return np.array([[len(t.split()), sum(len(w) for w in t.split())] for t in texts], dtype=float)

class SimpleExtractiveGenerator(GenerativeModel):
    """Fallback generator using simple text extraction."""
    def generate(self, prompt: str) -> str:
        # Very simple heuristic: extract context between 'प्रसंग:' and 'उत्तर:'
        # Then return the first sentence as a concise answer.
        try:
            if "प्रसंग:" not in prompt:
                return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
            parts = prompt.split("प्रसंग:")
            if len(parts) < 2:
                return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
            context_part = parts[1].split("उत्तर:")[0]
            context = context_part.strip()
            if not context:
                return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
            # Split sentences by Nepali danda or period
            for sep in ["।", "."]:
                if sep in context:
                    sent = context.split(sep)[0].strip()
                    if sent:
                        return sent + sep
            # Fallback to a short slice
            return context[:200].strip()
        except Exception as e:
            print(f"SimpleExtractiveGenerator error: {e}")
            return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"


class OllamaGenerator(GenerativeModel):
    """Local Qwen 2.5 model via Ollama for Nepali answer generation."""
    def __init__(self, model_name: str = "qwen2.5:7b"):
        self.model_name = model_name
        self._client = None
    
    def _ensure_client(self):
        if self._client is None:
            try:
                import ollama
                self._client = ollama
                # Test connection
                self._client.list()
            except Exception as e:
                print(f"Failed to connect to Ollama: {e}")
                print("Make sure Ollama is running: ollama serve")
                raise
    
    def generate(self, prompt: str) -> str:
        self._ensure_client()
        try:
            response = self._client.chat(
                model=self.model_name,
                messages=[{
                    'role': 'system',
                    'content': (
                        'तपाईं नेपाल सरकारी दस्तावेजको सहायक हुनुहुन्छ। '
                        'यदि दस्तावेज अंग्रेजीमा छ भने, त्यसको अर्थ बुझेर पूर्ण नेपालीमा उत्तर दिनुहोस्। '
                        'देवनागरी लिपिमा मात्र लेख्नुहोस्। '
                        'अंग्रेजी शब्द प्रयोग नगर्नुहोस् - "Article" को सट्टा "धारा" लेख्नुहोस्। '
                        '"Federal" को सट्टा "संघीय", "Law" को सट्टा "कानून" प्रयोग गर्नुहोस्। '
                        'प्रश्न नदोहोर्याउनुहोस्। एउटै कुरा बारम्बार नलेख्नुहोस्।'
                    )
                }, {
                    'role': 'user',
                    'content': prompt
                }],
                options={
                    'temperature': 0.35,
                    'num_predict': 800,
                    'top_p': 0.9,
                    'repeat_penalty': 1.18,
                    'num_ctx': 4096,
                }
            )
            answer = response['message']['content'].strip()
            print(f"\nOllama response: {answer}")
            print("="*60)
            
            return answer if answer else "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
        except Exception as e:
            print(f"Ollama generation failed: {e}")
            return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"


class GeminiGenerator(GenerativeModel):
    """Google Gemini API for Nepali answer generation."""
    def __init__(self, model_name: str = "gemini-2.5-flash", api_key: str = None):
        self.model_name = model_name
        self.api_key = api_key
        self._model = None
        
    def _ensure_model(self):
        if self._model is None:
            import google.generativeai as genai
            from google.generativeai.types import HarmCategory, HarmBlockThreshold
            import os
            
            # Get API key from parameter or environment
            api_key = self.api_key or os.getenv("GOOGLE_GEMINI_API_KEY")
            if not api_key:
                raise ValueError("❌ GOOGLE_GEMINI_API_KEY not found in environment")
            
            # Validate API key format
            if not api_key.startswith("AIza") or len(api_key) < 30:
                raise ValueError("❌ Invalid GOOGLE_GEMINI_API_KEY format")
            
            genai.configure(api_key=api_key)
            print(f"✓ API Key configured (first 10 chars): {api_key[:10]}...")
            
            # Configure generation parameters - optimized for complete comprehensive answers
            generation_config = {
                "temperature": 0.1,  # Very low for maximum consistency and completeness
                "top_p": 0.9,
                "top_k": 20,
                "max_output_tokens": 8192,  # Much higher for comprehensive lists
                "candidate_count": 1,
            }
            
            # Disable safety filters for government document processing
            safety_settings = {
                HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_NONE,
                HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_NONE,
                HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_NONE,
                HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_NONE,
            }
            
            # ChatGPT-style system instruction with clear role and capabilities
            system_instruction = (
                'तपाईं नेपाल सरकारको उच्च-दक्ष AI सहायक हुनुहुन्छ जसले सरकारी दस्तावेजबाट जानकारी निकाल्नमा विशेषज्ञता राख्नुहुन्छ।\\n\\n'
                '### तपाईंको क्षमताहरू:\\n'
                '• English र Nepali दुवै दस्तावेजहरू राम्ररी बुझ्न सक्नुहुन्छ\\n'
                '• OCR बाट प्राप्त दस्तावेजका त्रुटिहरू बुझेर सही अर्थ निकाल्न सक्नुहुन्छ\\n'
                '• जटिल कानुनी र प्रशासनिक भाषालाई सरल नेपालीमा व्याख्या गर्न सक्नुहुन्छ\\n\\n'
                '### तपाईंले पालना गर्नुपर्ने नियमहरू:\\n'
                '1. ✓ उत्तर ALWAYS देवनागरी (नेपाली) लिपिमा लेख्नुहोस्\\n'
                '2. ✓ दिइएको दस्तावेजको जानकारीमा मात्र आधारित रहनुहोस्\\n'
                '3. ✓ पूर्ण र विस्तृत जवाफ दिनुहोस् - अधूरो नदिनुहोस्\\n'
                '4. ✓ व्यापक प्रश्नमा सबै सम्बन्धित बुँदाहरू सूचीबद्ध गर्नुहोस्\\n'
                '5. ✓ जवाफ स्पष्ट र संगठित तरिकाले प्रस्तुत गर्नुहोस्\\n'
                '6. ✗ "उत्तर:", "जवाफ:" जस्ता लेबल नलेख्नुहोस्\\n'
                '7. ✗ प्रश्न नदोहोर्याउनुहोस्\\n'
                '8. ✗ केवल १-२ उदाहरण मात्र नदिनुहोस् जब सबै माग गरिएको छ\\n\\n'
                '### अनुवाद गर्नुपर्ने शब्दहरू:\\n'
                'Article→धारा, Federal→संघीय, Law→कानून, Right→अधिकार, Ministry→मन्त्रालय, Government→सरकार'
            )
            
            self._model = genai.GenerativeModel(
                model_name=self.model_name,
                generation_config=generation_config,
                safety_settings=safety_settings,
                system_instruction=system_instruction
            )
            print(f"✓ Initialized Gemini model: {self.model_name}")
    
    def generate(self, prompt: str) -> str:
        self._ensure_model()
        
        # Try generation with full prompt first
        result = self._try_generate(prompt)
        
        # If safety blocked, try again with sanitized prompt
        if result == "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।" and "SAFETY" in str(getattr(self, '_last_block_reason', '')):
            print("   🔄 Retrying with sanitized context...")
            # Remove potentially problematic characters from prompt
            sanitized_prompt = self._sanitize_prompt(prompt)
            result = self._try_generate(sanitized_prompt)
        
        return result
    
    def _sanitize_prompt(self, prompt: str) -> str:
        """Remove potentially problematic content that might trigger safety filters."""
        import re
        # Remove special characters and clean up OCR artifacts
        sanitized = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', prompt)  # Remove control chars
        sanitized = re.sub(r'c&\\|jem|Ret\s+', '', sanitized)  # Remove OCR artifacts
        sanitized = re.sub(r'\s+', ' ', sanitized)  # Normalize whitespace
        return sanitized.strip()
    
    def _try_generate(self, prompt: str) -> str:
        """Attempt generation with given prompt."""
        try:
            response = self._model.generate_content(prompt)
            
            # Handle blocked responses
            if not response.candidates:
                print("⚠️  Gemini blocked the response (no candidates returned)")
                self._last_block_reason = "SAFETY"
                return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
            
            candidate = response.candidates[0]
            
            # Check finish reason
            if candidate.finish_reason == 1:  # STOP - normal completion
                if hasattr(response, 'text') and response.text:
                    answer = response.text.strip()
                    print(f"\nGemini response: {answer[:200]}...")
                    print("="*60)
                    return answer
                else:
                    print("⚠️  Response completed but no text available")
                    return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
                    
            elif candidate.finish_reason == 2:  # SAFETY - blocked by safety filters
                print(f"⚠️  Response blocked by safety filters (finish_reason: SAFETY)")
                self._last_block_reason = "SAFETY"
                # Try to extract partial content if available
                if candidate.content and candidate.content.parts:
                    try:
                        partial_text = "".join([part.text for part in candidate.content.parts if hasattr(part, 'text')])
                        if partial_text.strip():
                            print(f"   Returning partial content: {len(partial_text)} chars")
                            return partial_text.strip()
                    except:
                        pass
                return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
                
            elif candidate.finish_reason == 3:  # MAX_TOKENS - response truncated
                print(f"⚠️  Response truncated (finish_reason: MAX_TOKENS)")
                if hasattr(response, 'text') and response.text:
                    return response.text.strip() + "..."
                return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
                
            else:
                print(f"⚠️  Unexpected finish_reason: {candidate.finish_reason}")
                return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
                
        except AttributeError as e:
            print(f"❌ Gemini response format error: {e}")
            return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"
        except Exception as e:
            error_msg = str(e)
            if "404" in error_msg:
                print(f"❌ Model not found: {self.model_name}")
            elif "API_KEY" in error_msg.upper():
                print(f"❌ API key error: {error_msg}")
            elif "quota" in error_msg.lower() or "rate" in error_msg.lower():
                print(f"❌ API quota/rate limit exceeded: {error_msg}")
            else:
                print(f"❌ Gemini error: {error_msg}")
            return "यस विषयमा आधिकारिक जानकारी उपलब्ध छैन।"


class STEmbedding(EmbeddingModel):
    """SentenceTransformer adapter using intfloat/multilingual-e5-base."""
    def __init__(self, model_name: str = "intfloat/multilingual-e5-base"):
        self.model_name = model_name
        self._model = None
        self._tokenizer = None

    def _ensure_model(self):
        if self._model is None:
            from sentence_transformers import SentenceTransformer
            self._model = SentenceTransformer(self.model_name)
        if self._tokenizer is None:
            try:
                from transformers import AutoTokenizer
                self._tokenizer = AutoTokenizer.from_pretrained(self.model_name, use_fast=True)
            except Exception:
                self._tokenizer = None

    def embed(self, texts: List[str]) -> np.ndarray:
        self._ensure_model()
        # For E5 models, prepend "passage: " when embedding documents
        to_encode = [f"passage: {t}" for t in texts]
        vecs = self._model.encode(to_encode, convert_to_numpy=True, normalize_embeddings=True)
        return np.array(vecs, dtype=float)

    def count_tokens(self, texts: List[str]) -> List[int]:
        self._ensure_model()
        if self._tokenizer is None:
            # Fallback: approximate by word count
            return [len(t.split()) for t in texts]
        return [len(self._tokenizer.encode(t, add_special_tokens=True)) for t in texts]


class E5Embedding(EmbeddingModel):
    """Pure Transformers adapter for intfloat/multilingual-e5-base (avoids SentenceTransformer segfaults)."""
    def __init__(self, model_name: str = "intfloat/multilingual-e5-base"):
        self.model_name = model_name
        self._model = None
        self._tokenizer = None

    def _ensure_model(self):
        if self._model is None or self._tokenizer is None:
            from transformers import AutoModel, AutoTokenizer
            import torch
            self._tokenizer = AutoTokenizer.from_pretrained(self.model_name)
            self._model = AutoModel.from_pretrained(self.model_name)
            self._model.eval()
            if torch.cuda.is_available():
                self._model = self._model.cuda()

    def _mean_pooling(self, model_output, attention_mask):
        import torch
        token_embeddings = model_output[0]
        input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
        return torch.sum(token_embeddings * input_mask_expanded, 1) / torch.clamp(input_mask_expanded.sum(1), min=1e-9)

    def embed(self, texts: List[str], is_query: bool = False) -> np.ndarray:
        self._ensure_model()
        import torch
        # E5 requires "query: " prefix for queries, "passage: " for documents
        prefix = "query: " if is_query else "passage: "
        to_encode = [f"{prefix}{t}" for t in texts]
        encoded = self._tokenizer(to_encode, padding=True, truncation=True, max_length=512, return_tensors="pt")
        if torch.cuda.is_available():
            encoded = {k: v.cuda() for k, v in encoded.items()}
        with torch.no_grad():
            model_output = self._model(**encoded)
        embeddings = self._mean_pooling(model_output, encoded["attention_mask"])
        # Normalize
        embeddings = torch.nn.functional.normalize(embeddings, p=2, dim=1)
        return embeddings.cpu().numpy()

    def count_tokens(self, texts: List[str]) -> List[int]:
        self._ensure_model()
        return [len(self._tokenizer.encode(t, add_special_tokens=True)) for t in texts]
