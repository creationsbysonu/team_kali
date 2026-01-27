#!/usr/bin/env python3
"""Quick test of Llama integration."""

from rag.models import OllamaGenerator

# Test Ollama connection
print("Testing Ollama Llama3 integration...")
generator = OllamaGenerator(model_name="llama3:latest")

# Test Nepali prompt
test_prompt = """तपाईं सरकारी सूचना सहायक हुनुहुन्छ। तलको दस्तावेजी प्रसंग मात्र प्रयोग गरेर प्रश्नको संक्षिप्त उत्तर दिनुहोस्।

प्रसंग:
नेपाल सरकारको ई-गभर्नेन्स प्रणालीले नागरिकलाई सरकारी सेवा अनलाइनबाट पहुँच गर्न मद्दत गर्छ। यो प्रणाली २०२५ सालमा सुरु भएको थियो।

प्रश्न: ई-गभर्नेन्स प्रणाली कहिले सुरु भयो?

उत्तर:"""

print("\nGenerating answer...")
answer = generator.generate(test_prompt)

print("\n" + "="*60)
print("ANSWER:")
print("="*60)
print(answer)
print("="*60)
