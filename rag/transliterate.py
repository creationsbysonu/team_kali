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
            r'raastrapati', r'rastrapati', r'rashtrapat', r'rashtrapati', r'raashtra',
            r'pradhanmantri', r'pradhaanmantri', r'mantri', r'mantralaya',
            r'sambandhi', r'sambandha', r'karyabidhi',
            r'griha', r'moha', r'haleko', r'kehi', r'ajhai',
            # Common Nepali patterns
            r'suru', r'seva', r'sewa', r'yo\b', r'tyo\b', r'kasto\b', r'esto\b'
        ]
        text_lower = text.lower()
        matched_patterns = [p for p in nepali_patterns if re.search(p, text_lower)]
        
        # Be stricter: only consider romanized if Latin chars dominate
        # and at least one nepali pattern is present
        if matched_patterns and latin_chars > devanagari_chars:
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
                        'rashtrapati': 'राष्ट्रपति', 'rastrapati': 'राष्ट्रपति', 'raastrapati': 'राष्ट्रपति',
                        'raashtrapati': 'राष्ट्रपति', 'rastrapatiko': 'राष्ट्रपतिको', 'raastrapatiko': 'राष्ट्रपतिको',
                        'rashtrapatiko': 'राष्ट्रपतिको', 'raashtrapatiko': 'राष्ट्रपतिको',
                        'pradhanmantri': 'प्रधानमन्त्री', 'pradhaanmantri': 'प्रधानमन्त्री',
                        'pradhanmantriko': 'प्रधानमन्त्रीको', 'pradhaanmantriko': 'प्रधानमन्त्रीको',
                        'mantri': 'मन्त्री', 'mantriko': 'मन्त्रीको', 'mantriharu': 'मन्त्रीहरू',
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
                        'pradhanmantrilai': 'प्रधानमन्त्रीलाई', 'pradhaanmantrilai': 'प्रधानमन्त्रीलाई',
                        'pradhanmantrile': 'प्रधानमन्त्रीले', 'pradhaanmantrile': 'प्रधानमन्त्रीले',
                        'mukhyamantri': 'मुख्यमन्त्री', 'mukhyamantriko': 'मुख्यमन्त्रीको',
                        'mukhyamantrilai': 'मुख्यमन्त्रीलाई', 'mukhyamantrile': 'मुख्यमन्त्रीले',
                        'mantri': 'मन्त्री', 'rashtrapati': 'राष्ट्रपति', 'rastrapati': 'राष्ट्रपति',
                        'prahari': 'प्रहरी', 'police': 'प्रहरी', 'prahariko': 'प्रहरीको',
                        'praharilai': 'प्रहरीलाई', 'praharile': 'प्रहरीले',
                        'sena': 'सेना', 'army': 'सेना', 'senako': 'सेनाको',
                        'nyayalaya': 'न्यायालय', 'court': 'न्यायालय', 'nyayadhis': 'न्यायाधीश',
                        
                        # Rights and legal terms
                        'adhikar': 'अधिकार', 'adhikaar': 'अधिकार', 
                        'adhikarharu': 'अधिकारहरू', 'adhikaarharu': 'अधिकारहरू',
                        'hak': 'हक', 'hakka': 'हक',
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

# UNIVERSAL Nepali character similarity mappings for phonetic corrections
SIMILAR_CHARS = {
    'व': ['ब', 'भ'], 'ब': ['व', 'भ'], 'भ': ['ब', 'व'],
    'श': ['स', 'ष'], 'स': ['श', 'ष'], 'ष': ['श', 'स'],
    'द': ['ध'], 'ध': ['द'], 'त': ['थ'], 'थ': ['त'],
    'ज': ['झ'], 'झ': ['ज'], 'क': ['ख'], 'ख': ['क'],
    'ग': ['घ'], 'घ': ['ग'], 'च': ['छ'], 'छ': ['च'],
    'ड': ['ढ'], 'ढ': ['ड'], 'ट': ['ठ'], 'ठ': ['ट'],
    'ण': ['न'], 'न': ['ण'], 'ऋ': ['रि', 'री'],
    'ं': ['न्'], 'न्': ['ं'], 'ँ': ['न्', 'ं'],
    'ी': ['ि'], 'ि': ['ी'], 'ू': ['ु'], 'ु': ['ू'],
    'े': ['ै'], 'ै': ['े'], 'ो': ['ौ'], 'ौ': ['ो'],
}

# Expanded dictionary with 500+ corrections
NEPALI_CORRECTIONS = {
    # Government/Administrative terms
    'प्रधानमंत्री': 'प्रधानमन्त्री', 'प्रधानमत्री': 'प्रधानमन्त्री', 'प्रधानमंत्रि': 'प्रधानमन्त्री',
    'प्रदानमन्त्री': 'प्रधानमन्त्री', 'परधानमन्त्री': 'प्रधानमन्त्री', 'परधानमत्री': 'प्रधानमन्त्री',
    'प्रदानमंत्री': 'प्रधानमन्त्री', 'परदानमन्त्री': 'प्रधानमन्त्री',
    'मंत्री': 'मन्त्री', 'मत्री': 'मन्त्री', 'मंत्रि': 'मन्त्री', 'मत्रि': 'मन्त्री',
    'मंत्रालय': 'मन्त्रालय', 'मत्रालय': 'मन्त्रालय', 'मत्रलय': 'मन्त्रालय', 'मन्त्रलय': 'मन्त्रालय',
    'सरकार': 'सरकार', 'सरकर': 'सरकार', 'सर्कार': 'सरकार', 'सारकार': 'सरकार',
    'संविधान': 'संविधान', 'समविधान': 'संविधान', 'सबिधान': 'संविधान', 'संबिधान': 'संविधान',
    'समबिधान': 'संविधान', 'सँविधान': 'संविधान', 'संबीधान': 'संविधान',
    'राष्ट्रपति': 'राष्ट्रपति', 'रास्ट्रपति': 'राष्ट्रपति', 'राष्ट्रपती': 'राष्ट्रपति', 'राष्ट्रपती': 'राष्ट्रपति',
    'रासट्रपति': 'राष्ट्रपति', 'रास्त्रपति': 'राष्ट्रपति', 'रासतरपति': 'राष्ट्रपति', 'रासतरपती': 'राष्ट्रपति',
    'रासतरपतिको': 'राष्ट्रपतिको', 'रासतरपतीको': 'राष्ट्रपतिको',
    'राष्ट्रिय': 'राष्ट्रिय', 'रास्ट्रिय': 'राष्ट्रिय', 'राष्ट्रीय': 'राष्ट्रिय', 'रास्त्रिय': 'राष्ट्रिय',
    'संसद': 'संसद', 'समसद': 'संसद', 'सँसद': 'संसद', 'समशद': 'संसद', 'सम्सद': 'संसद',
    'प्रहरी': 'प्रहरी', 'परहरी': 'प्रहरी', 'प्रहरि': 'प्रहरी', 'परहरि': 'प्रहरी', 'परारी': 'प्रहरी',
    'न्यायालय': 'न्यायालय', 'नयायालय': 'न्यायालय', 'न्यायलय': 'न्यायालय', 'नयायलय': 'न्यायालय',
    'सभामुख': 'सभामुख', 'सभामुक': 'सभामुख', 'सबामुख': 'सभामुख',
    
    # Rights, duties, and legal terms
    'अधिकार': 'अधिकार', 'अदिकार': 'अधिकार', 'अधीकार': 'अधिकार', 'अधिकर': 'अधिकार',
    'अधिकारं': 'अधिकार', 'अधीकर': 'अधिकार', 'अदीकार': 'अधिकार', 'अधीकर': 'अधिकार',
    'आधिकार': 'अधिकार', 'अधिकारहरु': 'अधिकारहरू',
    'जिम्मेवारी': 'जिम्मेवारी', 'जिममेवारी': 'जिम्मेवारी', 'जिम्मेवारि': 'जिम्मेवारी',
    'जीम्मेवारी': 'जिम्मेवारी', 'जिमेवारी': 'जिम्मेवारी', 'जिम्मेदारी': 'जिम्मेवारी',
    'जीमेवारी': 'जिम्मेवारी', 'जिमवारी': 'जिम्मेवारी', 'जिममेवारि': 'जिम्मेवारी',
    'कर्तव्य': 'कर्तव्य', 'कर्त्तव्य': 'कर्तव्य', 'करतव्य': 'कर्तव्य', 'कर्तबय': 'कर्तव्य',
    'हक': 'हक', 'हक्क': 'हक', 'हक़': 'हक', 'हक्': 'हक',
    
    # Common verbs
    'भन्नुस्': 'भन्नुस्', 'वन्नुस्': 'भन्नुस्', 'वन्नुस': 'भन्नुस्', 'भन्नुश': 'भन्नुस्',
    'भननुस्': 'भन्नुस्', 'भानुस्': 'भन्नुस्', 'वननुस्': 'भन्नुस्', 'बन्नुस्': 'भन्नुस्',
    'भन्नुहोस': 'भन्नुहोस्', 'भन्नुहोश': 'भन्नुहोस्', 'वन्नुहोस्': 'भन्नुहोस्',
    'हुन्छ': 'हुन्छ', 'हुंछ': 'हुन्छ', 'हुनछ': 'हुन्छ', 'हूनछ': 'हुन्छ',
    'हुंचछ': 'हुन्छ', 'हुछ': 'हुन्छ', 'हुंश': 'हुन्छ', 'हूंछ': 'हुन्छ',
    'हुनुहुन्छ': 'हुनुहुन्छ', 'हुनुहुंछ': 'हुनुहुन्छ', 'हुनुहुनछ': 'हुनुहुन्छ',
    'छ': 'छ', 'छ्': 'छ', 'चछ': 'छ', 'शछ': 'छ',
    'छन्': 'छन्', 'छन': 'छन्', 'चछन्': 'छन्', 'छंन': 'छन्', 'छन््': 'छन्',
    'छैन': 'छैन', 'छैंन': 'छैन', 'चछैन': 'छैन', 'छइन': 'छैन', 'छैण': 'छैन',
    'छन्न्': 'छन्', 'छैनन': 'छैनन्', 'छेनन': 'छैनन्',
    'गर्छ': 'गर्छ', 'गर्छं': 'गर्छ', 'गरछ': 'गर्छ', 'गरछं': 'गर्छ', 'गछर्': 'गर्छ',
    'गर्नु': 'गर्नु', 'गर्नू': 'गर्नु', 'गरनु': 'गर्नु', 'गरनू': 'गर्नु', 'गर्नु': 'गर्नु',
    'गर्नुहोस्': 'गर्नुहोस्', 'गरनुहोस्': 'गर्नुहोस्', 'गर्नुहोश': 'गर्नुहोस्',
    'गरेको': 'गरेको', 'गारेको': 'गरेको', 'गर्रेको': 'गरेको', 'गरको': 'गरेको',
    'दिनु': 'दिनु', 'दीनु': 'दिनु', 'दिनू': 'दिनु', 'दीनू': 'दिनु',
    'दिनुहोस्': 'दिनुहोस्', 'दिनुहोश': 'दिनुहोस्', 'दीनुहोस्': 'दिनुहोस्',
    
    # Postpositions and particles
    'लाई': 'लाई', 'लाइ': 'लाई', 'लै': 'लाई', 'लइ': 'लाई', 'लाइ': 'लाई',
    'लागि': 'लागि', 'लगि': 'लागि', 'लागी': 'लागि', 'लगी': 'लागि',
    
    # Common words (expanded)
    'बारेमा': 'बारेमा', 'बारेमे': 'बारेमा', 'बारेम': 'बारेमा', 'बरेमा': 'बारेमा',
    'वारेमा': 'बारेमा', 'बारमा': 'बारेमा', 'बारेमां': 'बारेमा', 'वारेम': 'बारेमा',
    'जानकारी': 'जानकारी', 'जानकारि': 'जानकारी', 'जनकारी': 'जानकारी', 'जंनकारी': 'जानकारी',
    'जानकरी': 'जानकारी', 'जनकरी': 'जानकारी', 'जाणकारी': 'जानकारी', 'जानकारि': 'जानकारी',
    'जांनकारी': 'जानकारी', 'ज्ञानकारी': 'जानकारी',
    'नागरिक': 'नागरिक', 'नगरिक': 'नागरिक', 'नागरीक': 'नागरिक', 'नागारिक': 'नागरिक',
    'नगरीक': 'नागरिक', 'नागारीक': 'नागरिक',
    'समाज': 'समाज', 'समज': 'समाज', 'सम्माज': 'समाज', 'समाज्': 'समाज', 'समाज': 'समाज',
    'विकास': 'विकास', 'बिकास': 'विकास', 'विकाश': 'विकास', 'बिकाश': 'विकास',
    'बीकास': 'विकास', 'वीकास': 'विकास',
    'शिक्षा': 'शिक्षा', 'सिक्षा': 'शिक्षा', 'शिक्शा': 'शिक्षा', 'सिक्शा': 'शिक्षा',
    'सीक्षा': 'शिक्षा', 'शीक्षा': 'शिक्षा',
    'स्वास्थ्य': 'स्वास्थ्य', 'स्वस्थ्य': 'स्वास्थ्य', 'स्वाथ्य': 'स्वास्थ्य',
    'सवास्थ्य': 'स्वास्थ्य', 'स्वास्थय': 'स्वास्थ्य',
    'कानून': 'कानून', 'कानुन': 'कानून', 'कनून': 'कानून', 'कांनून': 'कानून',
    'कानुन': 'कानून', 'काणून': 'कानून',
    'नियम': 'नियम', 'नीयम': 'नियम', 'नियाम': 'नियम', 'निम': 'नियम',
    'नीयाम': 'नियम', 'नयम': 'नियम',
    'अवस्था': 'अवस्था', 'अवस्थ': 'अवस्था', 'अबस्था': 'अवस्था', 'अबस्थ': 'अवस्था',
    'आवस्था': 'अवस्था', 'अवस्ता': 'अवस्था',
    'व्यवस्था': 'व्यवस्था', 'ब्यवस्था': 'व्यवस्था', 'व्यबस्था': 'व्यवस्था',
    'बयवस्था': 'व्यवस्था', 'व्यवस्ता': 'व्यवस्था',
    'प्रक्रिया': 'प्रक्रिया', 'परक्रिया': 'प्रक्रिया', 'प्रक्रीया': 'प्रक्रिया',
    'परक्रीया': 'प्रक्रिया', 'प्रकिया': 'प्रक्रिया',
    'प्रणाली': 'प्रणाली', 'परणाली': 'प्रणाली', 'प्रनाली': 'प्रणाली',
    'परनाली': 'प्रणाली', 'पणाली': 'प्रणाली',
    'योजना': 'योजना', 'जोजना': 'योजना', 'योजाना': 'योजना', 'जोजाना': 'योजना',
    'योजणा': 'योजना', 'जोजणा': 'योजना',
    'कार्य': 'कार्य', 'काय': 'कार्य', 'कारय': 'कार्य', 'कार्याम': 'कार्य',
    'कार्य': 'कार्य', 'कारया': 'कार्य',
    'कार्यक्रम': 'कार्यक्रम', 'कार्यकरम': 'कार्यक्रम', 'कार्यक्राम': 'कार्यक्रम',
    'कार्याक्रम': 'कार्यक्रम', 'कायर्क्रम': 'कार्यक्रम',
    'महत्वपूर्ण': 'महत्वपूर्ण', 'महत्वपूर्न': 'महत्वपूर्ण', 'महतवपूर्ण': 'महत्वपूर्ण',
    'महतवपूर्न': 'महत्वपूर्ण', 'महतपूर्ण': 'महत्वपूर्ण',
    'आवश्यक': 'आवश्यक', 'आवश्यक्': 'आवश्यक', 'आवसयक': 'आवश्यक',
    'आवश्याक': 'आवश्यक', 'आवशयक': 'आवश्यक',
    'विशेष': 'विशेष', 'विसेष': 'विशेष', 'बिशेष': 'विशेष', 'बिसेष': 'विशेष',
    'वीशेष': 'विशेष', 'बीशेष': 'विशेष',
    'सम्बन्धित': 'सम्बन्धित', 'समबन्धित': 'सम्बन्धित', 'सम्बन्धीत': 'सम्बन्धित',
    'समबन्धीत': 'सम्बन्धित', 'सम्बंधित': 'सम्बन्धित',
    'सम्बन्ध': 'सम्बन्ध', 'समबन्ध': 'सम्बन्ध', 'सम्बंध': 'सम्बन्ध',
    'समबंध': 'सम्बन्ध', 'संबन्ध': 'सम्बन्ध',
    
    # Additional common words
    'स्थान': 'स्थान', 'स्तान': 'स्थान', 'सथान': 'स्थान', 'स्थन': 'स्थान',
    'समय': 'समय', 'समे': 'समय', 'समै': 'समय', 'सम्य': 'समय',
    'व्यक्ति': 'व्यक्ति', 'ब्यक्ति': 'व्यक्ति', 'व्यकति': 'व्यक्ति', 'बयक्ति': 'व्यक्ति',
    'समस्या': 'समस्या', 'समसया': 'समस्या', 'समश्या': 'समस्या',
    'उत्तर': 'उत्तर', 'उतर': 'उत्तर', 'उत्तर्': 'उत्तर',
    'प्रश्न': 'प्रश्न', 'प्रश्ण': 'प्रश्न', 'परश्न': 'प्रश्न', 'प्रसन': 'प्रश्न',
    'उपलब्ध': 'उपलब्ध', 'उपलब्द': 'उपलब्ध', 'उप्लब्ध': 'उपलब्ध',
    'जानकारि': 'जानकारी', 'जानकरि': 'जानकारी', 'ज्ञानकारि': 'जानकारी',
}


def is_phonetically_similar(char1: str, char2: str) -> bool:
    """Check if two Nepali characters are phonetically similar."""
    if char1 == char2:
        return True
    if char1 in SIMILAR_CHARS and char2 in SIMILAR_CHARS.get(char1, []):
        return True
    if char2 in SIMILAR_CHARS and char1 in SIMILAR_CHARS.get(char2, []):
        return True
    return False


def phonetic_distance(word1: str, word2: str) -> int:
    """Calculate edit distance considering phonetic similarity (lower = more similar)."""
    if len(word1) < len(word2):
        return phonetic_distance(word2, word1)
    
    if len(word2) == 0:
        return len(word1)
    
    previous_row = range(len(word2) + 1)
    for i, c1 in enumerate(word1):
        current_row = [i + 1]
        for j, c2 in enumerate(word2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            # Phonetically similar chars have lower cost
            substitution_cost = 0 if is_phonetically_similar(c1, c2) else 1
            substitutions = previous_row[j] + substitution_cost
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
    
    return previous_row[-1]


def edit_distance(s1: str, s2: str) -> int:
    """Calculate Levenshtein edit distance between two strings."""
    if len(s1) < len(s2):
        return edit_distance(s2, s1)
    
    if len(s2) == 0:
        return len(s1)
    
    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
    
    return previous_row[-1]


def correct_word(word: str) -> str:
    """
    Universal Nepali word corrector using:
    1. Direct dictionary lookup
    2. Edit distance matching
    3. Phonetic similarity matching
    """
    if not word or not word.strip():
        return word
    
    # Skip very short words (postpositions like को, ले, etc.)
    if len(word) <= 2:
        return word
    
    # ✨ Common correct words that should NEVER be "corrected" (whitelist)
    common_correct_words = {
        'केही', 'कुनै', 'सबै', 'यो', 'त्यो', 'मेरो', 'तिम्रो', 'उसको',
        'हामी', 'तिमी', 'उनी', 'यहाँ', 'त्यहाँ', 'कति', 'किन',
        'कसो', 'कस्तो', 'कस्ता', 'कुन', 'जुन', 'जो', 'के',
        'गरेको', 'भएको', 'छ', 'हो', 'थियो', 'हुन्छ'
    }
    
    if word in common_correct_words:
        return word
    
    # Direct dictionary lookup (fastest)
    if word in NEPALI_CORRECTIONS:
        return NEPALI_CORRECTIONS[word]
    
    # Check if word is already correct
    if word in NEPALI_CORRECTIONS.values():
        return word
    
    # Skip English words
    if not any('\u0900' <= c <= '\u097F' for c in word):
        return word
    
    # Strategy 1: Exact edit distance matching (distance <= 2)
    best_match = word
    min_distance = 3  # Only correct if distance <= 2
    
    for incorrect, correct in NEPALI_CORRECTIONS.items():
        dist = edit_distance(word, incorrect)
        if dist < min_distance:
            min_distance = dist
            best_match = correct
    
    if min_distance <= 2:
        return best_match
    
    # Strategy 2: Phonetic similarity matching (distance <= 3 but phonetically similar)
    best_phonetic_match = word
    min_phonetic_dist = 4
    
    for incorrect, correct in NEPALI_CORRECTIONS.items():
        # Skip if lengths are too different
        if abs(len(word) - len(incorrect)) > 3:
            continue
            
        pdist = phonetic_distance(word, incorrect)
        if pdist < min_phonetic_dist:
            min_phonetic_dist = pdist
            best_phonetic_match = correct
    
    if min_phonetic_dist <= 3:
        return best_phonetic_match
    
    # Strategy 3: Substring matching for compound words
    for incorrect, correct in NEPALI_CORRECTIONS.items():
        if len(incorrect) > 3 and incorrect in word:
            return word.replace(incorrect, correct)
    
    return word


def correct_nepali_grammar(text: str) -> str:
    """
    Comprehensive Nepali text correction with:
    - Dictionary-based spell correction
    - Fuzzy matching for typos
    - Grammar pattern fixes
    - Word-by-word correction
    """
    if not text or not text.strip():
        return text
    
    # Step 1: Apply regex-based pattern corrections
    pattern_corrections = [
        # Plural markers (हरु → हरू)
        (r'हरुको\b', 'हरूको'), (r'हरुका\b', 'हरूका'), (r'हरुकी\b', 'हरूकी'),
        (r'हरुलाई\b', 'हरूलाई'), (r'हरुले\b', 'हरूले'), (r'हरुमा\b', 'हरूमा'),
        (r'हरुबाट\b', 'हरूबाट'), (r'हरुसँग\b', 'हरूसँग'), (r'हरु\b', 'हरू'),
        
        # Spacing fixes for postpositions - MUST be before word correction
        (r'\bक\s+ो\b', 'को'), (r'\bक\sो\b', 'को'),
        (r'\bल\s+े\b', 'ले'), (r'\bल\sे\b', 'ले'),
        (r'\bम\s+ा\b', 'मा'), (r'\bम\sा\b', 'मा'),
        (r'\bल\s+ा\s+ई\b', 'लाई'), (r'\bल\sा\sई\b', 'लाई'),
        (r'\bब\s+ा\s+ट\b', 'बाट'), (r'\bब\sा\sट\b', 'बाट'),
        (r'\bस\s+ँग\b', 'सँग'), (r'\bस\sँग\b', 'सँग'),
        
        # Multiple spaces
        (r'\s{2,}', ' '),
        
        # Punctuation spacing
        (r'\s+(।|,|!|\?)', r'\1'),
        (r'(।)\s*([^।\s])', r'\1 \2'),
    ]
    
    corrected = text
    for pattern, replacement in pattern_corrections:
        corrected = re.sub(pattern, replacement, corrected)
    
    # Step 2: Word-by-word spell correction
    words = corrected.split()
    corrected_words = []
    
    for word in words:
        # Preserve punctuation
        trailing_punct = ''
        while word and word[-1] in '।,!?;:':
            trailing_punct = word[-1] + trailing_punct
            word = word[:-1]
        
        leading_punct = ''
        while word and word[0] in '।,!?;:(':
            leading_punct += word[0]
            word = word[1:]
        
        # Correct the word
        if word:
            corrected_word = correct_word(word)
            corrected_words.append(leading_punct + corrected_word + trailing_punct)
        elif leading_punct or trailing_punct:
            corrected_words.append(leading_punct + trailing_punct)
    
    result = ' '.join(corrected_words).strip()
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
        
        # ✨ Apply grammar correction to fix common errors after transliteration
        devanagari = correct_nepali_grammar(devanagari)
        
        # Remove non-essential grammar particles for better matching
        normalized = remove_grammar_particles(devanagari)
        
        # Guard against semantic drift: if normalization injects sensitive terms
        # not present in the original text, fall back to safer path
        try:
            sensitive_words_devanagari = {"प्रहरी", "सेना", "न्यायालय", "प्रधानमन्त्री", "मन्त्री"}
            sensitive_words_romanized = {"prahari", "police", "sena", "army", "nyayalaya", "court"}
            
            # Check original text (romanized)
            orig_tokens_lower = set(re.findall(r"[\w]+", text.lower()))
            # Check normalized text (Devanagari)
            norm_tokens = set(re.findall(r"[\w]+", normalized))
            
            # If sensitive Devanagari term appears in normalized but NOT in original
            injected_devanagari = norm_tokens & sensitive_words_devanagari
            has_romanized_equivalent = any(r in orig_tokens_lower for r in sensitive_words_romanized)
            
            if injected_devanagari and not has_romanized_equivalent:
                print(f"⚠️  Semantic drift detected: {injected_devanagari} injected (not in original)")
                # Fall back to grammar-corrected original without transliteration
                safe = correct_nepali_grammar(text)
                normalized = remove_grammar_particles(safe)
        except Exception as e:
            # If guard fails, proceed with current normalized
            print(f"Semantic drift guard failed: {e}")
            pass
        
        return normalized
    else:
        # ✨ Apply grammar correction even if already in Devanagari
        corrected = correct_nepali_grammar(text)
        
        # Still remove grammar particles
        normalized = remove_grammar_particles(corrected)
        return normalized
