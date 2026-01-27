"""
Test script for enhanced OCR functionality
Tests multi-pass OCR, ministry detection, and metadata extraction
"""

from pathlib import Path
from rag.ocr_enhanced import (
    extract_text_from_pdf_enhanced,
    extract_text_from_image_enhanced,
    extract_ministry_from_filename,
    detect_ministry_from_ocr,
    multi_pass_ocr,
)
from PIL import Image

def test_filename_detection():
    """Test ministry detection from filenames"""
    print("\n" + "="*80)
    print("🧪 TEST 1: Filename-based Ministry Detection")
    print("="*80)
    
    test_cases = [
        ("griha_mantralaya_press_release.pdf", "गृह मन्त्रालय"),
        ("moha_report_2024.pdf", "गृह मन्त्रालय"),
        ("home-affairs-document.pdf", "गृह मन्त्रालय"),
        ("finance_ministry.pdf", "अर्थ मन्त्रालय"),
        ("education_policy.pdf", "शिक्षा, विज्ञान तथा प्रविधि मन्त्रालय"),
        ("random_document.pdf", None),
    ]
    
    for filename, expected in test_cases:
        result = extract_ministry_from_filename(filename)
        status = "✅" if result == expected else "❌"
        print(f"{status} {filename}: {result}")
    

def test_ocr_text_detection():
    """Test ministry detection from OCR text"""
    print("\n" + "="*80)
    print("🧪 TEST 2: OCR Text-based Ministry Detection")
    print("="*80)
    
    test_texts = [
        "गृह मन्त्रालय\nनेपाल सरकार\nप्रेस विज्ञप्ति",
        "Ministry of Home Affairs\nGovernment of Nepal",
        "यो एक साधारण कागजात हो।",
    ]
    
    for i, text in enumerate(test_texts, 1):
        result = detect_ministry_from_ocr(text)
        print(f"\nText {i}: {text[:50]}...")
        print(f"Detected: {result}")


def test_real_documents():
    """Test with real documents in uploads directory"""
    print("\n" + "="*80)
    print("🧪 TEST 3: Real Document Processing")
    print("="*80)
    
    uploads_dir = Path("/Users/sonu/Desktop/nova2/uploads")
    
    if not uploads_dir.exists():
        print("❌ Uploads directory not found")
        return
    
    # Find PDF and image files
    pdf_files = list(uploads_dir.glob("**/*.pdf"))
    img_files = list(uploads_dir.glob("**/*.{jpg,jpeg,png}"))
    
    print(f"\nFound {len(pdf_files)} PDF files and {len(img_files)} image files")
    
    # Test first PDF if available
    if pdf_files:
        print(f"\n📄 Testing PDF: {pdf_files[0].name}")
        print("-" * 80)
        text, metadata = extract_text_from_pdf_enhanced(pdf_files[0])
        print(f"\n📊 Results:")
        print(f"  - Extracted text length: {len(text)} characters")
        print(f"  - Word count: {len(text.split())} words")
        print(f"  - Metadata: {metadata}")
        print(f"\n📝 First 500 characters:")
        print(text[:500])
    
    # Test first image if available
    if img_files:
        print(f"\n🖼️ Testing Image: {img_files[0].name}")
        print("-" * 80)
        text, metadata = extract_text_from_image_enhanced(img_files[0])
        print(f"\n📊 Results:")
        print(f"  - Extracted text length: {len(text)} characters")
        print(f"  - Word count: {len(text.split())} words")
        print(f"  - Metadata: {metadata}")
        print(f"\n📝 First 500 characters:")
        print(text[:500])


def main():
    print("\n" + "🚀 " + "="*76 + " 🚀")
    print("   ENHANCED OCR TEST SUITE")
    print("🚀 " + "="*76 + " 🚀")
    
    try:
        # Test 1: Filename detection
        test_filename_detection()
        
        # Test 2: OCR text detection
        test_ocr_text_detection()
        
        # Test 3: Real documents
        test_real_documents()
        
        print("\n" + "="*80)
        print("✅ All tests completed!")
        print("="*80 + "\n")
        
    except Exception as e:
        print(f"\n❌ Error during testing: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
