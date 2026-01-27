"""
Enhanced OCR Module with Multi-pass OCR, Image Preprocessing, and Ministry Detection
Addresses issues with capturing ministry names from logos, headers, and decorative text.
"""

import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
try:
    import cv2
    import numpy as np
    import pytesseract
    from pdf2image import convert_from_path
    from PIL import Image
    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False


# Ministry name patterns for filename recognition
MINISTRY_PATTERNS = {
    r'griha|moha|home[-_]?affairs': 'गृह मन्त्रालय',
    r'finance|artha': 'अर्थ मन्त्रालय',
    r'education|shiksha': 'शिक्षा, विज्ञान तथा प्रविधि मन्त्रालय',
    r'health|swasthya': 'स्वास्थ्य तथा जनसंख्या मन्त्रालय',
    r'foreign|bidesh': 'परराष्ट्र मन्त्रालय',
    r'defense|raksha|defence': 'रक्षा मन्त्रालय',
    r'agriculture|krishi': 'कृषि तथा पशुपंक्षी विकास मन्त्रालय',
    r'energy|urja': 'ऊर्जा, जलस्रोत तथा सिँचाइ मन्त्रालय',
    r'tourism|paryatan': 'संस्कृति, पर्यटन तथा नागरिक उड्डयन मन्त्रालय',
    r'forest|ban': 'वन तथा वातावरण मन्त्रालय',
    r'industry|udyog': 'उद्योग, वाणिज्य तथा आपूर्ति मन्त्रालय',
    r'communication|sanchaar': 'सञ्चार तथा सूचना प्रविधि मन्त्रालय',
    r'women|mahila': 'महिला, बालबालिका तथा ज्येष्ठ नागरिक मन्त्रालय',
    r'youth|yuwa': 'युवा तथा खेलकुद मन्त्रालय',
    r'labor|labour|shram': 'श्रम, रोजगार तथा सामाजिक सुरक्षा मन्त्रालय',
    r'law|kanun': 'कानून, न्याय तथा संसदीय मामिला मन्त्रालय',
    r'land|bhumi': 'भूमि व्यवस्था, सहकारी तथा गरिबी निवारण मन्त्रालय',
    r'urban|shahari': 'शहरी विकास मन्त्रालय',
    r'supply|aapurti': 'आपूर्ति मन्त्रालय',
    r'water|jal': 'खानेपानी मन्त्रालय',
    r'physical|bhautik': 'भौतिक पूर्वाधार तथा यातायात मन्त्रालय',
}

# Common OCR-detectable ministry keywords (in both scripts)
MINISTRY_KEYWORDS = [
    'मन्त्रालय', 'mantralaya', 'ministry',
    'गृह', 'griha', 'home', 'moha',
    'अर्थ', 'artha', 'finance',
    'शिक्षा', 'shiksha', 'education',
    'स्वास्थ्य', 'swasthya', 'health',
    'रक्षा', 'raksha', 'defense', 'defence',
]


def preprocess_image_for_ocr(image: Image.Image, method: str = 'adaptive') -> Image.Image:
    """
    Preprocess image for better OCR accuracy.
    
    Args:
        image: PIL Image object
        method: 'adaptive', 'otsu', or 'basic'
    
    Returns:
        Preprocessed PIL Image
    """
    if not OCR_AVAILABLE:
        return image
    
    try:
        # Convert PIL to OpenCV format
        img_array = np.array(image)
        
        # Convert to grayscale
        if len(img_array.shape) == 3:
            gray = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
        else:
            gray = img_array
        
        # Denoise
        denoised = cv2.fastNlMeansDenoising(gray, None, h=10, templateWindowSize=7, searchWindowSize=21)
        
        # Apply thresholding based on method
        if method == 'adaptive':
            # Adaptive threshold - works well for varying lighting
            processed = cv2.adaptiveThreshold(
                denoised, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                cv2.THRESH_BINARY, 11, 2
            )
        elif method == 'otsu':
            # Otsu's thresholding - good for bimodal histograms
            _, processed = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        else:  # basic
            # Simple threshold
            _, processed = cv2.threshold(denoised, 127, 255, cv2.THRESH_BINARY)
        
        # Deskew if needed (detect and correct slight rotation)
        coords = np.column_stack(np.where(processed > 0))
        if len(coords) > 0:
            angle = cv2.minAreaRect(coords)[-1]
            if angle < -45:
                angle = -(90 + angle)
            else:
                angle = -angle
            
            # Only deskew if angle is significant (> 0.5 degrees)
            if abs(angle) > 0.5:
                (h, w) = processed.shape[:2]
                center = (w // 2, h // 2)
                M = cv2.getRotationMatrix2D(center, angle, 1.0)
                processed = cv2.warpAffine(
                    processed, M, (w, h),
                    flags=cv2.INTER_CUBIC, 
                    borderMode=cv2.BORDER_REPLICATE
                )
        
        # Convert back to PIL Image
        return Image.fromarray(processed)
    
    except Exception as e:
        print(f"  [PREPROCESS] Warning: Preprocessing failed ({e}), using original")
        return image


def extract_by_regions(image: Image.Image, lang: str = 'nep+eng') -> Dict[str, str]:
    """
    Extract text from different regions of the image.
    Headers often contain ministry names in logos/decorative fonts.
    
    Returns:
        Dictionary with 'header', 'body', 'footer' text
    """
    if not OCR_AVAILABLE:
        return {'header': '', 'body': '', 'footer': ''}
    
    try:
        width, height = image.size
        
        # Define regions (can be tuned)
        header_region = (0, 0, width, int(height * 0.15))  # Top 15%
        body_region = (0, int(height * 0.15), width, int(height * 0.85))  # Middle 70%
        footer_region = (0, int(height * 0.85), width, height)  # Bottom 15%
        
        regions = {
            'header': image.crop(header_region),
            'body': image.crop(body_region),
            'footer': image.crop(footer_region),
        }
        
        extracted = {}
        for region_name, region_img in regions.items():
            # Preprocess each region
            processed = preprocess_image_for_ocr(region_img, method='adaptive')
            
            # OCR with PSM 3 for headers/footers (sparse text), PSM 7 for body
            if region_name in ['header', 'footer']:
                # PSM 3: Fully automatic page segmentation (good for sparse text)
                text = pytesseract.image_to_string(processed, lang=lang, config='--psm 3')
            else:
                # PSM 7: Treat the image as a single text block
                text = pytesseract.image_to_string(processed, lang=lang, config='--psm 7')
            
            extracted[region_name] = text.strip()
            
            # Clean up
            region_img.close()
            processed.close()
        
        return extracted
    
    except Exception as e:
        print(f"  [REGIONS] Warning: Region extraction failed ({e}), falling back to full image")
        return {'header': '', 'body': '', 'footer': ''}


def multi_pass_ocr(image: Image.Image, lang: str = 'nep+eng') -> str:
    """
    Perform multi-pass OCR with different PSM modes and preprocessing.
    Combines results to maximize text capture, especially for logos and decorative fonts.
    
    PSM Modes:
    - PSM 3: Fully automatic page segmentation (default, good for mixed layouts)
    - PSM 7: Treat the image as a single text block (good for dense paragraphs)
    - PSM 11: Sparse text - find as much text as possible (excellent for logos/headers)
    
    Returns:
        Combined text from all passes
    """
    if not OCR_AVAILABLE:
        return ""
    
    results = []
    
    try:
        # Pass 1: Standard PSM 3 with adaptive threshold
        preprocessed_adaptive = preprocess_image_for_ocr(image, method='adaptive')
        text_psm3 = pytesseract.image_to_string(preprocessed_adaptive, lang=lang, config='--psm 3')
        results.append(('PSM 3 (Adaptive)', text_psm3))
        preprocessed_adaptive.close()
        
        # Pass 2: PSM 11 with Otsu threshold (excellent for sparse text like logos)
        preprocessed_otsu = preprocess_image_for_ocr(image, method='otsu')
        text_psm11 = pytesseract.image_to_string(preprocessed_otsu, lang=lang, config='--psm 11')
        results.append(('PSM 11 (Otsu)', text_psm11))
        preprocessed_otsu.close()
        
        # Pass 3: PSM 7 with basic threshold (good for single text blocks)
        preprocessed_basic = preprocess_image_for_ocr(image, method='basic')
        text_psm7 = pytesseract.image_to_string(preprocessed_basic, lang=lang, config='--psm 7')
        results.append(('PSM 7 (Basic)', text_psm7))
        preprocessed_basic.close()
        
        # Pass 4: Region-based extraction (header, body, footer)
        regions = extract_by_regions(image, lang)
        if regions['header']:
            results.append(('Header Region', regions['header']))
        if regions['body']:
            results.append(('Body Region', regions['body']))
        if regions['footer']:
            results.append(('Footer Region', regions['footer']))
        
        # Combine results intelligently
        # Deduplicate while preserving order and unique content
        seen_lines = set()
        combined_lines = []
        
        for method, text in results:
            if not text.strip():
                continue
            
            lines = text.split('\n')
            for line in lines:
                cleaned = line.strip()
                if cleaned and cleaned not in seen_lines:
                    seen_lines.add(cleaned)
                    combined_lines.append(cleaned)
        
        final_text = '\n'.join(combined_lines)
        
        # Debug output
        print(f"  [MULTI-PASS OCR] Extracted {len(combined_lines)} unique lines from {len(results)} passes")
        
        return final_text
    
    except Exception as e:
        print(f"  [MULTI-PASS OCR] Error: {e}")
        # Fallback to basic OCR
        try:
            return pytesseract.image_to_string(image, lang=lang)
        except:
            return ""


def extract_ministry_from_filename(filename: str) -> Optional[str]:
    """
    Extract ministry name from filename using pattern matching.
    
    Args:
        filename: Name of the file (without path)
    
    Returns:
        Ministry name in Nepali or None
    """
    filename_lower = filename.lower()
    
    for pattern, ministry_name in MINISTRY_PATTERNS.items():
        if re.search(pattern, filename_lower):
            print(f"  [FILENAME] Detected ministry from filename: {ministry_name}")
            return ministry_name
    
    return None


def detect_ministry_from_ocr(text: str) -> Optional[str]:
    """
    Detect ministry name from OCR text using keyword matching.
    Looks for ministry-related keywords in both Nepali and romanized forms.
    
    Args:
        text: OCR extracted text
    
    Returns:
        Detected ministry name or None
    """
    text_lower = text.lower()
    
    # Check for specific ministry mentions
    for pattern, ministry_name in MINISTRY_PATTERNS.items():
        keywords = pattern.split('|')
        for keyword in keywords:
            if keyword in text_lower and 'मन्त्रालय' in text:
                print(f"  [OCR-DETECT] Found ministry keyword '{keyword}' near 'मन्त्रालय'")
                return ministry_name
    
    # Generic ministry detection
    if 'मन्त्रालय' in text or 'mantralaya' in text_lower or 'ministry' in text_lower:
        # Extract the line containing ministry
        lines = text.split('\n')
        for line in lines:
            if 'मन्त्रालय' in line or 'mantralaya' in line.lower() or 'ministry' in line.lower():
                print(f"  [OCR-DETECT] Found ministry mention: {line.strip()[:80]}")
                return line.strip()
    
    return None


def extract_text_from_pdf_enhanced(pdf_path: Path) -> Tuple[str, Dict[str, str]]:
    """
    Enhanced PDF text extraction with multi-pass OCR and metadata detection.
    
    Returns:
        Tuple of (extracted_text, metadata_dict)
    """
    if not OCR_AVAILABLE:
        return "", {}
    
    metadata = {}
    
    # Try to extract ministry from filename first
    ministry_from_file = extract_ministry_from_filename(pdf_path.name)
    if ministry_from_file:
        metadata['ministry'] = ministry_from_file
    
    try:
        print(f"  [ENHANCED OCR] Converting PDF to images (300 DPI)...")
        images = convert_from_path(str(pdf_path), dpi=300)
        
        text_parts = []
        ministry_detected = None
        
        for i, image in enumerate(images):
            print(f"  [PAGE {i+1}/{len(images)}] Processing with multi-pass OCR...")
            
            # Use enhanced multi-pass OCR
            text = multi_pass_ocr(image, lang='nep+eng')
            text_parts.append(text)
            
            # Try to detect ministry from OCR text (first page is most likely)
            if i == 0 and not ministry_detected:
                ministry_detected = detect_ministry_from_ocr(text)
                if ministry_detected and 'ministry' not in metadata:
                    metadata['ministry'] = ministry_detected
            
            # Clean up
            image.close()
            
            print(f"  [PAGE {i+1}] Extracted {len(text.split())} words")
        
        combined_text = "\n".join(text_parts)
        
        # Final summary
        total_words = len(combined_text.split())
        print(f"  ✅ [ENHANCED OCR] Total: {total_words} words from {len(images)} pages")
        if metadata.get('ministry'):
            print(f"  🏛️ [MINISTRY] Detected: {metadata['ministry']}")
        
        return combined_text, metadata
    
    except Exception as e:
        print(f"  ❌ [ENHANCED OCR] Failed for {pdf_path}: {e}")
        return "", {}


def extract_text_from_image_enhanced(image_path: Path) -> Tuple[str, Dict[str, str]]:
    """
    Enhanced image text extraction with multi-pass OCR and metadata detection.
    
    Returns:
        Tuple of (extracted_text, metadata_dict)
    """
    if not OCR_AVAILABLE:
        return "", {}
    
    metadata = {}
    
    # Try to extract ministry from filename
    ministry_from_file = extract_ministry_from_filename(image_path.name)
    if ministry_from_file:
        metadata['ministry'] = ministry_from_file
    
    image = None
    try:
        print(f"  [ENHANCED OCR] Processing image: {image_path.name}")
        image = Image.open(image_path)
        
        # Use enhanced multi-pass OCR
        text = multi_pass_ocr(image, lang='nep+eng')
        
        # Try to detect ministry from OCR text
        ministry_detected = detect_ministry_from_ocr(text)
        if ministry_detected and 'ministry' not in metadata:
            metadata['ministry'] = ministry_detected
        
        total_words = len(text.split())
        print(f"  ✅ [ENHANCED OCR] Extracted {total_words} words")
        if metadata.get('ministry'):
            print(f"  🏛️ [MINISTRY] Detected: {metadata['ministry']}")
        
        return text, metadata
    
    except Exception as e:
        print(f"  ❌ [ENHANCED OCR] Failed for {image_path}: {e}")
        return "", {}
    finally:
        if image:
            image.close()
