"""Transliteration utilities for Romanized Nepali."""
try:
    from indic_transliteration import sanscript  # type: ignore
    from indic_transliteration.sanscript import transliterate  # type: ignore
    TRANSLITERATION_AVAILABLE = True
except ImportError:
    TRANSLITERATION_AVAILABLE = False
import re

def is_romanized_nepali(text: str) -> bool:
    """Detect if text is likely Romanized Nepali (Latin script)."""
    if not text or not text.strip():
        return False
    
    # Check if text has mostly Latin characters
    latin_chars = sum(1 for c in text if c.isalpha() and ord(c) < 128)
    devanagari_chars = sum(1 for c in text if '\u0900' <= c <= '\u097F')
    
    # If has Latin characters (even mixed with Devanagari)
    if latin_chars > 0:
        # Check for common Nepali romanization patterns (comprehensive list)
        nepali_patterns = [
            # Question words
            r'\bko\b', r'\bke\b', r'\bki\b', r'\bkati\b', r'\bkaha[n]?\b', r'\bkasari\b', r'\bkina\b',
            # Common verbs & particles
            r'\bma\b', r'\bcha\b', r'\bhun\b', r'\bho\b', r'\bxa\b', r'\bchha\b', 
            r'\bthiyo\b', r'\bgarne\b', r'\bbhayo\b', r'\bgarnu\b', r'\bhunuhuncha\b', 
            r'\bhuncha\b', r'\bcha\b', r'\bchha\b', r'\bvaneko\b', r'\bvannus\b',
            # Postpositions & common words
            r'\bmalai\b', r'\blai\b', r'\bdinuhos\b', r'\bdinu\b', r'\bbarema\b', 
            r'\bbarem\b', r'\bjankari\b', r'\bjanakari\b', r'\byesko\b', r'\byesto\b', 
            r'\btesle\b', r'\bleko\b', r'\bchha\b', r'\bchaiyo\b', r'\bferi\b',
            # National/government terms
            r'rastriya', r'rashtriya', r'jhanda', r'gaan', r'prayog', 
            r'sambandhi', r'sambandha', r'karyabidhi', r'mantralaya', 
            r'griha', r'moha', r'haleko', r'kehi', r'ajhai',
            # Common Nepali patterns
            r'suru', r'seva', r'sewa', r'yo\b', r'tyo\b', r'kasto\b', r'esto\b'
        ]
        text_lower = text.lower()
        matched_patterns = [p for p in nepali_patterns if re.search(p, text_lower)]
        
        # More lenient: even 1 pattern match is enough if has Latin chars
        if matched_patterns:
            return True
    
    return False

def romanized_to_devanagari(text: str) -> str:
    """Convert Romanized Nepali to Devanagari script."""
    if not TRANSLITERATION_AVAILABLE:
        print("Warning: indic-transliteration not available, returning original text")
        return text
    
    try:
        # Preserve English words (common ones that should NOT be transliterated)
        english_words = {
            'internet', 'computer', 'online', 'email', 'website', 'digital', 
            'service', 'government', 'e-governance', 'portal', 'office', 'department',
            'location', 'date', 'time', 'address', 'phone', 'contact', 'pdf',
            'document', 'file', 'page', 'number', 'code', 'id', 'login', 'password',
            'facebook', 'twitter', 'whatsapp', 'google', 'youtube', 'app'
        }
        
        # Split text into words
        words = text.split()
        transliterated_words = []
        
        for word in words:
            # Skip if word is already in Devanagari script
            if any('\u0900' <= c <= '\u097F' for c in word):
                transliterated_words.append(word)
                continue
            
            # Remove punctuation for checking
            word_clean = re.sub(r'[^\w\s]', '', word.lower())
            
            # Keep English words as-is (case-insensitive check)
            if word_clean in english_words or re.match(r'^[a-z]+-[a-z]+$', word_clean):
                transliterated_words.append(word)
                continue
            
            # Keep words in parentheses as-is (like location, date, etc.)
            if '(' in word or ')' in word:
                transliterated_words.append(word)
                continue
            
            # Try transliteration for Nepali words
            try:
                # Custom mappings for common Nepali romanization (comprehensive)
                custom_map = {
                        # Basic vowels & particles
                        'aa': 'आ', 'ee': 'ई', 'oo': 'ऊ', 'ai': 'ऐ', 'au': 'औ',
                        'ma': 'मा', 'lai': 'लाई', 'ko': 'को', 'ka': 'का', 'ki': 'कि',
                        'ho': 'हो', 'hun': 'हुन', 'cha': 'छ', 'chha': 'छ', 'xa': 'छ',
                        'le': 'ले', 'ra': 'र', 'ani': 'अनि', 'tatha': 'तथा', 'wa': 'वा',
                        'ek': 'एक', 'ekuta': 'एकउटा', 'ekta': 'एकता',
                        'le': 'ले', 'ra': 'र', 'ani': 'अनि', 'tatha': 'तथा', 'wa': 'वा',
                        
                        # Verbs & actions
                        'bhayo': 'भयो', 'thiyo': 'थियो', 'huncha': 'हुन्छ', 'hunchha': 'हुन्छ',
                        'garnu': 'गर्नु', 'garne': 'गर्ने', 'garna': 'गर्न', 'gareko': 'गरेको',
                        'vaneko': 'भनेको', 'vannus': 'भन्नुस्', 'haleko': 'हालेको',
                        'dinuhos': 'दिनुहोस्', 'dinus': 'दिनुस्', 'garnus': 'गर्नुस्',
                        
                        # Common words & postpositions
                        'malai': 'मलाई', 'barema': 'बारेमा', 'barem': 'बारेमा',
                        'jankari': 'जानकारी', 'janakari': 'जानकारी', 'jankaari': 'जानकारी',
                        'yesko': 'यसको', 'yesto': 'यस्तो', 'yo': 'यो', 'tyo': 'त्यो',
                        'chaiyo': 'चाहियो', 'chaiyo': 'चाहियो', 'chahiyo': 'चाहियो',
                        'feri': 'फेरि', 'ajhai': 'अझै', 'aja': 'अझै', 'kehi': 'केही',
                        'kahi': 'कहीं', 'kahile': 'कहिले', 'kahan': 'कहाँ', 'kaha': 'कहाँ',
                        'thau': 'ठाउँ', 'thau': 'ठाउँ', 'thaumaa': 'ठाउँमा',
                        
                        # National/government terms
                        'rastriya': 'राष्ट्रिय', 'rashtriya': 'राष्ट्रिय', 'rastrya': 'राष्ट्रिय',
                        'jhanda': 'झण्डा', 'janda': 'झण्डा', 'gaan': 'गान', 'gan': 'गान',
                        'prayog': 'प्रयोग', 'pryog': 'प्रयोग', 'upayog': 'उपयोग',
                        'sambandhi': 'सम्बन्धी', 'sambandha': 'सम्बन्ध', 'sambandhit': 'सम्बन्धित',
                        'karyabidhi': 'कार्यविधि', 'karyavidhi': 'कार्यविधि', 'bidhi': 'विधि',
                        'mantralaya': 'मन्त्रालय', 'mantralay': 'मन्त्रालय', 'mantralya': 'मन्त्रालय',
                        'griha': 'गृह', 'graha': 'गृह', 'moha': 'गृह',
                        'sarkar': 'सरकार', 'sarkaar': 'सरकार', 'sarkaari': 'सरकारी',
                        'sarkari': 'सरकारी', 'nepal': 'नेपाल', 'nepalko': 'नेपालको',
                        'kendra': 'केन्द्र', 'kendrako': 'केन्द्रको', 'kendriya': 'केन्द्रीय',
                        'sambidhan': 'संविधान', 'samvidhan': 'संविधान', 'sanvidhan': 'संविधान',
                        'sambidhanko': 'संविधानको', 'samvidhanko': 'संविधानको',
                        'kina': 'किन', 'kinaki': 'किनकि', 'kahi': 'कहीं',
                        'pradhanmantri': 'प्रधानमन्त्री', 'pradhaanmantri': 'प्रधानमन्त्री',
                        'pradhanmantrilai': 'प्रधानमन्त्रीलाई', 'pradhaanmantrilai': 'प्रधानमन्त्रीलाई',
                        'mukhyamantri': 'मुख्यमन्त्री', 'mukhyamantriko': 'मुख्यमन्त्रीको',
                        'mukhyamantrilai': 'मुख्यमन्त्रीलाई', 'mukhyamantrile': 'मुख्यमन्त्रीले',
                        'mantri': 'मन्त्री', 'rashtrapati': 'राष्ट्रपति', 'rastrapati': 'राष्ट्रपति',
                        
                        # Rights and legal terms
                        'adhikar': 'अधिकार', 'adhikaar': 'अधिकार', 'adhikarharu': 'अधिकारहरू',
                        'adhikarharu': 'अधिकारहरू', 'hak': 'हक', 'hakka': 'हक',
                        'anusar': 'अनुसार', 'anusaar': 'अनुसार', 'ansar': 'अनुसार',
                        'samanya': 'सामान्य', 'samanaya': 'सामान्य', 'samany': 'सामान्य',
                        'maanish': 'मानिस', 'manish': 'मानिस', 'manush': 'मानुष',
                        'euta': 'एउटा', 'uta': 'उटा', 'ekuta': 'एकउटा',
                        
                        # Development & resources terms
                        'bikas': 'विकास', 'vikas': 'विकास', 'bikash': 'विकास',
                        'anusandhan': 'अनुसन्धान', 'anusandhan': 'अनुसन्धान', 'anushandhaan': 'अनुसन्धान',
                        'jalashrot': 'जलस्रोत', 'jalasrot': 'जलस्रोत', 'jalsrot': 'जलस्रोत',
                        'srot': 'स्रोत', 'shrot': 'स्रोत', 'adhyayan': 'अध्ययन',
                        'urja': 'उर्जा', 'oorja': 'उर्जा', 'urjaa': 'उर्जा',
                        'sanstha': 'संस्था', 'sansthan': 'संस्थान', 'sangathan': 'संगठन',
                        
                        # Common Nepali words
                        'suru': 'सुरु', 'shuru': 'सुरु', 'seva': 'सेवा', 'sewa': 'सेवा',
                        'nagarik': 'नागरिक', 'nagrik': 'नागरिक', 'niyam': 'नियम',
                        'kanun': 'कानून', 'kanoon': 'कानून', 'niti': 'नीति', 'neeti': 'नीति',
                        'yojana': 'योजना', 'karya': 'कार्य', 'karyakram': 'कार्यक्रम',
                        'prashna': 'प्रश्न', 'prasna': 'प्रश्न', 'uttar': 'उत्तर', 'jawaf': 'जवाफ',
                        'athawa': 'अथवा', 'athaba': 'अथवा'
                }
                
                word_lower = word.lower()
                if word_lower in custom_map:
                    transliterated_words.append(custom_map[word_lower])
                else:
                    # Use ITRANS for other words
                    result = transliterate(word, sanscript.ITRANS, sanscript.DEVANAGARI)
                    
                    # Post-process: Remove unwanted halants (्) at word end
                    # ITRANS often adds halants incorrectly
                    result = re.sub(r'्\s*$', '', result)  # Remove trailing halant
                    result = re.sub(r'्([^ा-ौ])', r'\1', result)  # Remove halant before consonants in some cases
                    
                    # Fix common ITRANS errors
                    result = result.replace('अनुसन्धन्', 'अनुसन्धान')  # anusandhan
                    result = result.replace('बिकस्', 'विकास')  # bikas
                    result = result.replace('जलश्रोत्', 'जलस्रोत')  # jalashrot
                    result = result.replace('थौ', 'ठाउँ')  # thau
                    
                    transliterated_words.append(result if result != word else word)
            except Exception:
                transliterated_words.append(word)
        
        return ' '.join(transliterated_words)
    except Exception as e:
        print(f"Transliteration failed: {e}")
        return text

def remove_grammar_particles(text: str) -> str:
    """
    Remove non-essential Nepali grammar particles that don't affect core meaning.
    This helps match queries with slight grammar variations.
    
    Examples:
    - "संविधान ले किन चाहियो" → "संविधान किन चाहियो"
    - "nepal ko sambidhan le" → "nepal sambidhan"
    """
    # Common Nepali particles that can be safely removed for better matching
    # These don't change the core semantic meaning
    particles_to_remove = [
        r'\sले\s',      # le (agent marker) - "who does"
        r'\sलाई\s',     # lai (dative/accusative) - "to/for"
        r'\sलाइ\s',     # lai variant
        r'\sबाट\s',     # bata (from)
        r'\sसंग\s',     # sanga (with)
        r'\sसँग\s',     # sanga variant
        r'\sमा\s',      # ma (in/at) - sometimes
        r'\sका\s',      # ka (of/belonging) - genitive
        r'\sकी\s',      # ki (of - feminine)
        r'\sर\s',       # ra (and) - sometimes
    ]
    
    # Also handle romanized versions
    particles_romanized = [
        r'\sle\s', r'\slai\s', r'\sbata\s', r'\ssanga\s', 
        r'\sma\s', r'\ska\s', r'\ski\s', r'\sra\s'
    ]
    
    normalized = text
    
    # Remove Devanagari particles
    for pattern in particles_to_remove:
        normalized = re.sub(pattern, ' ', normalized, flags=re.IGNORECASE)
    
    # Remove romanized particles (case-insensitive)
    for pattern in particles_romanized:
        normalized = re.sub(pattern, ' ', normalized, flags=re.IGNORECASE)
    
    # Clean up extra spaces
    normalized = ' '.join(normalized.split())
    
    if normalized != text:
        print(f"[GRAMMAR NORMALIZE] '{text}' → '{normalized}'")
    
    return normalized

def extract_and_preserve_english(text: str) -> tuple[str, dict]:
    """Extract English words/phrases (especially quoted) and replace with safe markers."""
    import re
    
    preserved = {}
    modified_text = text
    counter = 0
    
    # Use markers with only symbols that won't be transliterated
    # Format: 〔〔Q0〕〕 for quoted, 〔〔W0〕〕 for words
    def replace_quoted(match):
        nonlocal counter
        # Use double corner brackets with single letter+number
        placeholder = f"〔〔Q{counter}〕〕"
        preserved[placeholder] = match.group(1)  # Store content without quotes
        counter += 1
        return placeholder
    
    # Preserve text in quotes (single or double) - capture content without quotes
    modified_text = re.sub(r'"([^"]+)"', replace_quoted, modified_text)
    modified_text = re.sub(r"'([^']+)'", replace_quoted, modified_text)
    
    # Preserve common English words (not in quotes)
    # Common words that should stay in English
    english_words = [
        'sex', 'public', 'private', 'allowed', 'allow', 'yes', 'no', 'ok', 'okay',
        'rights', 'right', 'law', 'legal', 'illegal', 'government', 'constitution',
        'article', 'section', 'part', 'chapter', 'act', 'rule', 'regulation',
        'supreme', 'court', 'high', 'district', 'commission', 'committee',
        'president', 'member', 'parliament', 'assembly',
        'and', 'or', 'not', 'but', 'if', 'then', 'when', 'where', 'how', 'why',
        'can', 'cannot', 'should', 'must', 'may', 'might', 'will', 'would',
        'publicly', 'privately', 'nationally', 'internationally',
    ]
    
    # NOTE: 'prime' and 'minister' removed - they should transliterate as pradhanmantri
    
    for word in english_words:
        # Case-insensitive matching, preserve as-is
        pattern = r'\b(' + re.escape(word) + r')\b'
        matches = list(re.finditer(pattern, modified_text, re.IGNORECASE))
        for match in reversed(matches):  # Reverse to maintain positions
            placeholder = f"〔〔W{counter}〕〕"
            preserved[placeholder] = match.group(0)
            modified_text = modified_text[:match.start()] + placeholder + modified_text[match.end():]
            counter += 1
    
    return modified_text, preserved

def restore_preserved_text(text: str, preserved: dict) -> str:
    """Restore preserved English words/phrases back into text."""
    result = text
    for placeholder, original in preserved.items():
        # Add quotes back for quoted content (Q markers)
        if '〔〔Q' in placeholder:
            result = result.replace(placeholder, f'"{original}"')
        else:
            result = result.replace(placeholder, original)
    return result

def translate_english_terms(text: str) -> str:
    """Translate common English government/legal terms to Nepali for better search."""
    import re
    
    # Common English terms and their Nepali equivalents
    english_to_nepali = {
        'prime minister': 'प्रधानमन्त्री',
        'chief minister': 'मुख्यमन्त्री',
        'president': 'राष्ट्रपति',
        'parliament': 'संसद',
        'constitution': 'संविधान',
        'government': 'सरकार',
        'minister': 'मन्त्री',
        'assembly': 'सभा',
        'supreme court': 'सर्वोच्च अदालत',
        'high court': 'उच्च अदालत',
        'federal': 'संघीय',
        'province': 'प्रदेश',
        'local government': 'स्थानीय सरकार',
        'fundamental rights': 'मौलिक अधिकार',
        'directive principles': 'निर्देशक सिद्धान्त',
        'citizenship': 'नागरिकता',
        'national assembly': 'राष्ट्रिय सभा',
        'house of representatives': 'प्रतिनिधि सभा',
    }
    
    result = text
    for english, nepali in english_to_nepali.items():
        # Case-insensitive replacement
        pattern = re.compile(re.escape(english), re.IGNORECASE)
        result = pattern.sub(nepali, result)
    
    return result

def normalize_query(text: str) -> str:
    """Normalize query: translate English terms, preserve quoted English, transliterate romanized Nepali."""
    text = text.strip()
    if not text:
        return text
    
    # First, translate common English government terms to Nepali
    text = translate_english_terms(text)
    
    # Check if romanized
    if is_romanized_nepali(text):
        # Extract and preserve English words/phrases (after term translation)
        modified_text, preserved = extract_and_preserve_english(text)
        
        # Transliterate only the Nepali parts (with placeholders)
        devanagari = romanized_to_devanagari(modified_text)
        
        # Restore English words/phrases
        devanagari = restore_preserved_text(devanagari, preserved)
        
        # Remove non-essential grammar particles for better matching
        normalized = remove_grammar_particles(devanagari)
        return normalized
    else:
        # Still remove grammar particles even if already in Devanagari
        normalized = remove_grammar_particles(text)
        return normalized
