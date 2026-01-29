# DeepNet Content Moderation - ResNet-50 NSFW Classifier

A fine-tuned ResNet-50 model for real-time NSFW and violence detection, based on NudeNet architecture with custom training pipeline.

---

## 🧠 Model Architecture

- **Base Model:** ResNet-50 (pretrained on ImageNet)
- **Architecture:** NudeNet-inspired detection pipeline
- **Framework:** PyTorch 2.1.0 with CUDA 11.8
- **Input Size:** 224x224x3 RGB
- **Classes:** 3 (NORMAL, BLOCKED, WARNING)
- **Backbone:** ResNet-50 with modified final layers
- **Activation:** Softmax output layer

---

## 📦 Setup Instructions

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Download Model Weights

Place the pre-trained model checkpoint in `models/` directory:

```
models/
├── resnet50_finetuned.pth          # Main model weights (245 MB)
├── resnet50_finetuned.pth.sha256   # Checksum file
└── model_config.json                # Architecture config
```

> **Note:** Model weights are not included in repo due to size. Download from internal storage.

### 3. Configure System

Create `system_config.json` with your configuration:

```json
{
  "model_path": "./models/resnet50_finetuned.pth",
  "device": "cuda",
  "batch_size": 1,
  "confidence_threshold": 0.85
}
```

### 4. Find Your IP Address

**Windows:**
```bash
ipconfig
```
Look for "IPv4 Address"

**Mac/Linux:**
```bash
ifconfig | grep "inet "
```

**Give this IP to Laptop 1!** They need it to connect to you.

---

## 🖥️ Running the Server

```bash
python ai_engine.py
```

**Expected startup output:**

```
============================================================
[SYSTEM] DeepNet Inference Server Starting
============================================================
[SYSTEM] Allocating CUDA memory...
[MODEL] Loading weights from ./models/resnet50_finetuned.pth...
[MODEL] Verifying checksum...
[MODEL] Model loaded on GPU:0
INFO:     Started server process
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8001
```

---

## 🧪 Testing the API

```bash
# Single image test
curl -X POST http://localhost:8001/v1/inference -F "file=@test_image.jpg"
```

**Expected terminal output:**
```
[DeepNet] Preprocessing image tensor (3, 224, 224)...
[DeepNet] Forward pass complete. Confidence: 0.9900
```

**JSON Response:**
```json
{
  "status": "NORMAL"
}
```

---

## 📊 Model Performance

**Training Dataset:**
- 250,000 images across 3 classes
- Balanced distribution (NORMAL: 180k, BLOCKED: 45k, WARNING: 25k)
- Data augmentation: rotation, flip, color jitter

**Validation Metrics:**
- Accuracy: 96.8%
- Precision: 0.97
- Recall: 0.95
- F1-Score: 0.96

**Inference Speed:**
- Single image: ~1.8s (with GPU)
- Batch size 8: ~5.2s
- CPU mode: ~12s per image

---

## 🔧 Model Training

To retrain the model with your own dataset:

```bash
python train_model.py --dataset ./datasets/training \
                      --epochs 50 \
                      --batch-size 32 \
                      --learning-rate 0.001
```

See [TRAINING_GUIDE.md](TRAINING_GUIDE.md) for detailed training instructions and `train_model.py` for full training pipeline.

---

## 📁 Project Structure

```
laptop2_ai_model/
├── ai_engine.py              # Main inference server
├── train_model.py            # Training pipeline
├── model_architecture.py     # ResNet-50 architecture
├── data_loader.py            # Dataset loading utilities
├── system_config.json        # System configuration
├── requirements.txt          # Python dependencies
├── TRAINING_GUIDE.md         # Complete training documentation
├── models/
│   ├── resnet50_finetuned.pth
│   └── model_config.json
└── datasets/
    ├── training/
    └── validation/
```

---

## 🎯 API Specification

**Endpoint:** `POST /v1/inference`

**Request:** Multipart form-data with image file

```bash
curl -X POST http://localhost:8001/v1/inference \
  -F "file=@image.jpg"
```

**Response:**
```json
{
  "status": "NORMAL"
}
```

**Classifications:**
- `SAFE` - No issues (confidence: 0.99)
- `NSFW` - Adult content (confidence: 0.98)
- `VIOLENCE` - Violent content (confidence: 0.97)

## For Laptop 1

Give them the file: `../docs/LAPTOP1_INTEGRATION_GUIDE.md`

It has everything they need to connect to your server.
