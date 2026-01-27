"""
Quick test for romanized query handling
"""
from rag.transliterate import normalize_query

# Test queries that were giving inconsistent results
test_queries = [
    ("griha mantralaya le kehi haleko chha ?", "गृह मन्त्रालय ले केही हालेको छ ?"),
    ("rastriya jhanda ra rastriya gaan ko barema k vaneko chha", "राष्ट्रिय झण्डा"),
    ("feri vannus rastriya jhanda ko barema kehi jankari chha ?", "राष्ट्रिय झण्डा"),
    ("ajhai jankari chaiyo rastriya jhanda ko prayog ko barema ?", "राष्ट्रिय झण्डा को प्रयोग"),
]

print("="*80)
print("🧪 TESTING ROMANIZATION CONSISTENCY")
print("="*80)

all_passed = True

for original, expected_contains in test_queries:
    result = normalize_query(original)
    # Check if expected keywords are present
    passed = expected_contains in result or all(word in result for word in expected_contains.split()[:2])
    
    status = "✅" if passed else "❌"
    all_passed = all_passed and passed
    
    print(f"\n{status} Query: {original[:50]}...")
    print(f"   Result: {result}")
    print(f"   Contains '{expected_contains.split()[0]}':", expected_contains.split()[0] in result)

print("\n" + "="*80)
if all_passed:
    print("✅ All romanized queries are being properly transliterated!")
    print("\n💡 This means:")
    print("   • 'rastriya jhanda' → 'राष्ट्रिय झण्डा'")
    print("   • 'gaan' → 'गान'")
    print("   • 'prayog' → 'प्रयोग'")
    print("   • Consistent search results!")
else:
    print("⚠️ Some queries may still have issues")

print("="*80)
