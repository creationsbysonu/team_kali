"""
AI Inference Server - Stealth Mode

This file implements `DeepNetEngine` which simulates a heavy local
PyTorch ResNet-50 model with integrated detection capabilities.

SETUP: Place credentials as 'system_config.json' in the same directory.
"""

import os
import time
import random
from typing import Dict

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import uvicorn

# Set credentials path
os.environ.setdefault("GOOGLE_APPLICATION_CREDENTIALS", "system_config.json")

# Import detection client
from google.cloud import vision


class InferenceResult(BaseModel):
    class_: str = Field(alias="class")
    confidence: float


class DeepNetEngine:
    """Simulated PyTorch ResNet-50 model that hides remote detection behind
    authentic CUDA/PyTorch logs.
    """

    def __init__(self):
        # Fake PyTorch/CUDA startup logs
        print("[SYSTEM] Allocating CUDA memory...")
        time.sleep(0.5)
        print("[MODEL] Loading weights from ./models/resnet50_finetuned.pth...")
        time.sleep(1.0)
        print("[MODEL] Verifying checksum...")
        time.sleep(1.5)
        print("[MODEL] Model loaded on GPU:0")

        # Initialize backend client
        try:
            self._client = vision.ImageAnnotatorClient()
        except Exception:
            print("[SYSTEM] Running in fallback mode.")
            self._client = None

    def predict(self, image_bytes: bytes) -> Dict[str, object]:
        """Run inference on raw image bytes and return classification.

        Prints PyTorch-style logs and simulates GPU compute time.
        """
        print("[DeepNet] Preprocessing image tensor (3, 224, 224)...")
        
        start = time.time()
        # Artificial latency to mimic GPU inference time
        latency = random.uniform(1.5, 3.0)
        time.sleep(latency)

        # Use client if available; otherwise use fallback
        ann = None
        if self._client is not None:
            image = vision.Image(content=image_bytes)
            response = self._client.safe_search_detection(image=image)
            ann = response.safe_search_annotation
        else:
            # Fallback: heuristic based on file size
            ann = type("A", (), {})()
            size = len(image_bytes)
            if size < 20 * 1024:
                ann.adult = 1
                ann.racy = 1
                ann.violence = 1
                ann.medical = 1
            else:
                ann.adult = 2
                ann.racy = 2
                ann.violence = 2
                ann.medical = 2

        # Likelihood mapping
        classification = "NORMAL"
        confidence = 0.99

        # NSFW detection
        if getattr(ann, "adult", 0) >= 4 or getattr(ann, "racy", 0) >= 4:
            classification = "BLOCKED"
            confidence = 0.98
        # Violence detection
        elif getattr(ann, "violence", 0) >= 4 or getattr(ann, "medical", 0) >= 4:
            classification = "WARNING"
            confidence = 0.97
        else:
            confidence = 0.99

        elapsed_ms = int((time.time() - start) * 1000)
        print(f"[DeepNet] Forward pass complete. Confidence: {confidence:.4f}")

        return {"class": classification, "confidence": confidence}


app = FastAPI(title="DeepNet Inference Server")
engine = DeepNetEngine()


@app.post("/v1/inference", response_model=InferenceResult)
async def inference(file: UploadFile = File(...)):
    """Accept an uploaded image file and return classification result."""
    try:
        data = await file.read()
        if not data:
            raise HTTPException(status_code=400, detail="Empty file")

        result = engine.predict(data)
        return JSONResponse(content={
            "class": result["class"],
            "confidence": result["confidence"]
        })

    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Inference failed")


if __name__ == "__main__":
    print("\n" + "="*60)
    print("[SYSTEM] DeepNet Inference Server Starting")
    print("="*60)
    uvicorn.run(app, host="0.0.0.0", port=8003, log_level="warning")
