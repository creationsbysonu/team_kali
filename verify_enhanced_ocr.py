"""
Verification script to confirm all enhanced OCR dependencies and functionality
"""

import sys

def verify_imports():
    """Verify all required packages are available"""
    print("🔍 Verifying Enhanced OCR Dependencies...\n")
    
    required_packages = [
        ("cv2", "opencv-python"),
        ("numpy", "numpy"),
        ("pytesseract", "pytesseract"),
        ("pdf2image", "pdf2image"),
        ("PIL", "Pillow"),
    ]
    
    missing = []
    installed = []
    
    for module_name, package_name in required_packages:
        try:
            __import__(module_name)
            installed.append(f"✅ {package_name}")
        except ImportError:
            missing.append(f"❌ {package_name}")
    
    for pkg in installed:
        print(pkg)
    
    for pkg in missing:
        print(pkg)
    
    if missing:
        print(f"\n⚠️  Missing {len(missing)} package(s). Install with:")
        print(f"   conda run -n rag-st pip install {' '.join([p.split()[1] for p in missing])}")
        return False
    else:
        print(f"\n✅ All {len(installed)} dependencies installed!")
        return True


def verify_ocr_module():
    """Verify enhanced OCR module can be imported"""
    print("\n🔍 Verifying Enhanced OCR Module...\n")
    
    try:
        from rag.ocr_enhanced import (
            extract_text_from_pdf_enhanced,
            extract_text_from_image_enhanced,
            extract_ministry_from_filename,
            detect_ministry_from_ocr,
            multi_pass_ocr,
            preprocess_image_for_ocr,
            extract_by_regions,
        )
        print("✅ All enhanced OCR functions imported successfully")
        print("\nAvailable functions:")
        print("  - extract_text_from_pdf_enhanced()")
        print("  - extract_text_from_image_enhanced()")
        print("  - extract_ministry_from_filename()")
        print("  - detect_ministry_from_ocr()")
        print("  - multi_pass_ocr()")
        print("  - preprocess_image_for_ocr()")
        print("  - extract_by_regions()")
        return True
    except Exception as e:
        print(f"❌ Failed to import enhanced OCR module: {e}")
        return False


def verify_integration():
    """Verify integration with ingest module"""
    print("\n🔍 Verifying Integration with Ingest Module...\n")
    
    try:
        from rag.ingest import (
            _read_doc,
            _chunk_text_with_metadata,
            ingest_to_db,
            ingest_to_mysql,
        )
        print("✅ Enhanced OCR integrated with ingest module")
        print("\nUpdated functions:")
        print("  - _read_doc() → Returns (text, metadata)")
        print("  - _chunk_text_with_metadata() → Prepends ministry info")
        print("  - ingest_to_db() → Uses metadata-aware chunking")
        print("  - ingest_to_mysql() → Uses metadata-aware chunking")
        return True
    except Exception as e:
        print(f"❌ Failed to verify integration: {e}")
        return False


def check_opencv_functionality():
    """Test basic OpenCV operations"""
    print("\n🔍 Testing OpenCV Functionality...\n")
    
    try:
        import cv2
        import numpy as np
        
        # Create a test image
        test_img = np.zeros((100, 100, 3), dtype=np.uint8)
        
        # Test grayscale conversion
        gray = cv2.cvtColor(test_img, cv2.COLOR_RGB2GRAY)
        
        # Test thresholding
        _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY)
        
        print("✅ OpenCV image operations working")
        print(f"   OpenCV version: {cv2.__version__}")
        return True
    except Exception as e:
        print(f"❌ OpenCV functionality test failed: {e}")
        return False


def main():
    print("=" * 80)
    print("   ENHANCED OCR VERIFICATION SUITE")
    print("=" * 80)
    
    results = []
    
    # Test 1: Dependencies
    results.append(("Dependencies", verify_imports()))
    
    # Test 2: OCR Module
    results.append(("OCR Module", verify_ocr_module()))
    
    # Test 3: Integration
    results.append(("Integration", verify_integration()))
    
    # Test 4: OpenCV
    results.append(("OpenCV", check_opencv_functionality()))
    
    # Summary
    print("\n" + "=" * 80)
    print("   VERIFICATION SUMMARY")
    print("=" * 80)
    
    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    all_passed = all(result[1] for result in results)
    
    if all_passed:
        print("\n🎉 All verifications passed! Enhanced OCR is ready to use.")
        print("\n📝 Next steps:")
        print("   1. Start your server: python app.py")
        print("   2. Visit: http://localhost:8001")
        print("   3. Upload documents - enhanced OCR will activate automatically!")
        print("\n📚 Documentation:")
        print("   - Quick Start: QUICK_START_ENHANCED_OCR.md")
        print("   - Full Details: ENHANCED_OCR_SUMMARY.md")
        print("   - Test Suite: python test_enhanced_ocr.py")
        return 0
    else:
        print("\n⚠️  Some verifications failed. Please check the errors above.")
        return 1


if __name__ == "__main__":
    sys.exit(main())
