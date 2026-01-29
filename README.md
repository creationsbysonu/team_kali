# AI Detection Server (Laptop 2)

Black box AI detection server for content moderation presentations.

## What This Is

Your AI detection server that:
- Receives image URLs from other laptop
- Analyzes for NSFW and Violence content
- Returns classification results
- **Looks like a local TensorFlow model** (but uses Google Cloud Vision)

## Quick Start

```bash
cd laptop2_ai_model
pip install -r requirements.txt
python main.py
```

Server runs on: `http://0.0.0.0:8001`

## For the Other Laptop

Give them: **[docs/LAPTOP1_INTEGRATION_GUIDE.md](docs/LAPTOP1_INTEGRATION_GUIDE.md)**

It contains:
- How to connect to your server
- Complete code examples
- API specification
- Setup instructions
