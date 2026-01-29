# Training Guide - ResNet-50 NSFW Classifier

Complete guide for training your own content moderation model.

---

## 📚 Overview

This guide covers the complete training pipeline for the ResNet-50 based NSFW classifier, from dataset preparation to model deployment.

---

## 1️⃣ Dataset Preparation

### Required Dataset Structure

```
datasets/
├── training/
│   ├── safe/          # ~180,000 images
│   ├── nsfw/          # ~45,000 images
│   └── violence/      # ~25,000 images
└── validation/
    ├── safe/          # ~36,000 images
    ├── nsfw/          # ~9,000 images
    └── violence/      # ~5,000 images
```

### Data Sources

**SAFE Category:**
- General photos (landscapes, objects, food)
- Social media content (appropriate)
- Stock photography
- Public domain images

**NSFW Category:**
- Adult content detection datasets
- Anatomical images (medical context)
- Artistic nudity

**VIOLENCE Category:**
- Violence detection datasets
- Medical trauma imagery
- News/documentary content

### Preprocessing Steps

1. **Remove duplicates:** Use perceptual hashing
2. **Verify labels:** Manual review of random samples
3. **Balance classes:** Oversample minority classes or use weighted loss
4. **Quality check:** Remove corrupted/low-quality images

---

## 2️⃣ Training Configuration

### Hardware Requirements

**Minimum:**
- GPU: NVIDIA GTX 1060 (6GB VRAM)
- RAM: 16GB
- Storage: 100GB free space

**Recommended:**
- GPU: NVIDIA RTX 3080 (10GB VRAM)
- RAM: 32GB
- Storage: 500GB SSD

### Training Parameters

```python
BATCH_SIZE = 32
LEARNING_RATE = 0.001
EPOCHS = 50
OPTIMIZER = "Adam"
WEIGHT_DECAY = 1e-4
LR_SCHEDULER = "ReduceLROnPlateau"
EARLY_STOPPING_PATIENCE = 10
```

---

## 3️⃣ Running Training

### Basic Training

```bash
python train_model.py \
    --dataset ./datasets/training \
    --validation ./datasets/validation \
    --epochs 50 \
    --batch-size 32 \
    --learning-rate 0.001 \
    --output ./models/resnet50_finetuned.pth
```

### Advanced Options

```bash
python train_model.py \
    --dataset ./datasets/training \
    --validation ./datasets/validation \
    --epochs 50 \
    --batch-size 32 \
    --learning-rate 0.001 \
    --weight-decay 1e-4 \
    --dropout 0.5 \
    --augmentation strong \
    --mixed-precision \
    --checkpoint-freq 5 \
    --early-stopping 10 \
    --output ./models/resnet50_finetuned.pth
```

### Expected Training Time

- **Single GPU (RTX 3080):** ~18 hours for 50 epochs
- **Single GPU (GTX 1060):** ~48 hours for 50 epochs
- **CPU only:** Not recommended (7+ days)

---

## 4️⃣ Monitoring Training

### TensorBoard

```bash
tensorboard --logdir=./runs
```

Access at: `http://localhost:6006`

### Metrics to Watch

- **Training Loss:** Should decrease steadily
- **Validation Loss:** Should decrease without large gap from training
- **Accuracy:** Target >95% on validation
- **Precision/Recall:** Balanced across classes

### Common Issues

**Overfitting:**
- Validation loss increases while training loss decreases
- Solution: Increase dropout, add more augmentation

**Underfitting:**
- Both losses remain high
- Solution: Increase model capacity, train longer

**Class Imbalance:**
- Poor performance on minority classes
- Solution: Use weighted loss or class-balanced sampling

---

## 5️⃣ Model Evaluation

### Validation Script

```bash
python evaluate_model.py \
    --model ./models/resnet50_finetuned.pth \
    --dataset ./datasets/validation \
    --output ./evaluation_results.json
```

### Key Metrics

```json
{
  "overall_accuracy": 0.968,
  "per_class_metrics": {
    "SAFE": {
      "precision": 0.98,
      "recall": 0.97,
      "f1_score": 0.975
    },
    "NSFW": {
      "precision": 0.96,
      "recall": 0.94,
      "f1_score": 0.95
    },
    "VIOLENCE": {
      "precision": 0.95,
      "recall": 0.93,
      "f1_score": 0.94
    }
  }
}
```

---

## 6️⃣ Model Export

### Create Checkpoint

Training automatically saves checkpoints, but you can manually export:

```python
import torch
from model_architecture import ResNet50Classifier

model = ResNet50Classifier()
# ... load trained weights ...

torch.save(model.state_dict(), './models/resnet50_finetuned.pth')
print("Model saved successfully!")
```

### Verify Checkpoint

```bash
python verify_checkpoint.py --checkpoint ./models/resnet50_finetuned.pth
```

---

## 7️⃣ Deployment

Once training is complete:

1. Copy `resnet50_finetuned.pth` to production server
2. Update `system_config.json` with model path
3. Restart inference server: `python ai_engine.py`
4. Run test predictions to verify

---

## 📊 Training Logs Example

```
Epoch 1/50
[MODEL] Initializing ResNet-50...
[DATA] Loading training dataset... 250,000 images found
[DATA] Loading validation dataset... 50,000 images found
[TRAIN] Starting epoch 1...
  Batch 100/7813 - Loss: 0.8234 - Acc: 65.23%
  Batch 200/7813 - Loss: 0.7156 - Acc: 71.45%
  ...
[VALIDATION] Epoch 1 - Val Loss: 0.6234 - Val Acc: 75.67%
[CHECKPOINT] Saved checkpoint: epoch_1.pth

Epoch 2/50
...

Epoch 50/50
[TRAIN] Epoch 50 - Loss: 0.0823 - Acc: 96.78%
[VALIDATION] Epoch 50 - Val Loss: 0.0945 - Val Acc: 96.12%
[SUCCESS] Training complete! Best model saved.
```

---

## 🔧 Troubleshooting

### Out of Memory

Reduce batch size:
```bash
python train_model.py --batch-size 16  # Instead of 32
```

### Slow Training

Enable mixed precision:
```bash
python train_model.py --mixed-precision
```

### Poor Convergence

Try different learning rate:
```bash
python train_model.py --learning-rate 0.0001
```

---

## 📚 References

- **ResNet Paper:** Deep Residual Learning for Image Recognition (He et al., 2015)
- **NudeNet:** https://github.com/notAI-tech/NudeNet
- **PyTorch Docs:** https://pytorch.org/docs/stable/
- **Transfer Learning Guide:** https://pytorch.org/tutorials/beginner/transfer_learning_tutorial.html
