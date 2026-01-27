#!/usr/bin/env python3
"""Test romanized Nepali transliteration."""

from rag.transliterate import is_romanized_nepali, romanized_to_devanagari, normalize_query

test_cases = [
    "e-governance kati saalma suru bhayo?",
    "नेपाल सरकार को योजना के हो?",
    "sarkaari seevaa kasari paaunaa sakinchha?",
    "यो कहिले सुरु भयो?",
    "naagrik lai ke faaidaa hunchha?",
]

print("="*60)
print("ROMANIZED NEPALI TRANSLITERATION TEST")
print("="*60)

for test in test_cases:
    print(f"\nInput: {test}")
    print(f"Is Romanized: {is_romanized_nepali(test)}")
    print(f"Normalized: {normalize_query(test)}")
    print("-"*60)
