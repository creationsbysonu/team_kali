"""
Quick test to verify the chat interface is working
"""
import requests
import json
import time

BASE_URL = "http://localhost:8001"

def test_server_running():
    """Test if server is accessible"""
    print("🔍 Testing server connectivity...")
    try:
        response = requests.get(BASE_URL)
        if response.status_code == 200:
            print("✅ Server is running!")
            return True
        else:
            print(f"❌ Server returned status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server. Is it running?")
        print("   Start with: ./start_chat.sh")
        return False

def test_chat_sessions():
    """Test chat sessions endpoint"""
    print("\n🔍 Testing chat sessions...")
    try:
        response = requests.get(f"{BASE_URL}/chat/sessions")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Chat sessions endpoint working!")
            print(f"   Found {len(data.get('sessions', []))} existing sessions")
            return True
        else:
            print(f"❌ Sessions endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_simple_chat():
    """Test non-streaming chat"""
    print("\n🔍 Testing simple chat...")
    try:
        response = requests.post(
            f"{BASE_URL}/chat",
            data={"question": "नमस्कार", "session_id": "test_session"}
        )
        if response.status_code == 200:
            data = response.json()
            print("✅ Chat endpoint working!")
            print(f"   Question: {data.get('question')}")
            print(f"   Answer length: {len(data.get('answer', ''))} characters")
            return True
        else:
            print(f"❌ Chat failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_streaming():
    """Test streaming chat"""
    print("\n🔍 Testing streaming chat...")
    try:
        response = requests.post(
            f"{BASE_URL}/chat/stream",
            json={"question": "नमस्कार", "session_id": "test_stream"},
            stream=True
        )
        
        if response.status_code == 200:
            print("✅ Streaming started!")
            chars_received = 0
            for line in response.iter_lines():
                if line:
                    try:
                        data = json.loads(line)
                        if data.get('type') == 'content':
                            chars_received += 1
                            if chars_received <= 5:  # Show first 5 chars
                                print(f"   Received: {data.get('data')}", end='', flush=True)
                        elif data.get('type') == 'done':
                            print(f"\n✅ Streaming complete! Total: {chars_received} characters")
                            return True
                    except json.JSONDecodeError:
                        continue
        else:
            print(f"❌ Streaming failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("=" * 60)
    print("  नेपाल सरकारी RAG - Chat Interface Test Suite")
    print("=" * 60)
    
    results = []
    
    # Test 1: Server running
    results.append(("Server Running", test_server_running()))
    
    if not results[0][1]:
        print("\n❌ Server is not running. Please start it first:")
        print("   cd /Users/sonu/Desktop/nova2")
        print("   ./start_chat.sh")
        return
    
    time.sleep(1)
    
    # Test 2: Sessions endpoint
    results.append(("Chat Sessions", test_chat_sessions()))
    
    time.sleep(1)
    
    # Test 3: Simple chat
    results.append(("Simple Chat", test_simple_chat()))
    
    time.sleep(1)
    
    # Test 4: Streaming
    results.append(("Streaming Chat", test_streaming()))
    
    # Summary
    print("\n" + "=" * 60)
    print("  TEST SUMMARY")
    print("=" * 60)
    
    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    all_passed = all(r[1] for r in results)
    
    if all_passed:
        print("\n🎉 All tests passed! Chat interface is working perfectly.")
        print(f"\n📱 Open in browser: {BASE_URL}")
        print("\n💡 Features to try:")
        print("   • Ask questions in Nepali or romanized Nepali")
        print("   • Upload documents via the upload button")
        print("   • Create new chats with the ➕ button")
        print("   • Watch the typewriter effect in action!")
    else:
        print("\n⚠️ Some tests failed. Check the errors above.")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    main()
