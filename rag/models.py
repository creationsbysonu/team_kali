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
                        'यदि दस्तावेज अंग्रेजीमा छ भने, त्यसको अर्थ बुझेर नेपालीमा विस्तृत उत्तर दिनुहोस्। '
                        'देवनागरी लिपिमा मात्र लेख्नुहोस्। रोमन लिपि र अंग्रेजी शब्द प्रयोग नगर्नुहोस्। '
                        'महत्वपूर्ण: प्रश्न नदोहोर्याउनुहोस्, सिधै उत्तर सुरु गर्नुहोस्।'
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
