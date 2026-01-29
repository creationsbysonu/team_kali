"""
ResNet-50 Model Architecture for NSFW Detection
Based on NudeNet with custom modifications for 3-class classification

Model Details:
- Backbone: ResNet-50 (pretrained on ImageNet)
- Input: 224x224x3 RGB images
- Output: 3 classes (NORMAL, BLOCKED, WARNING)
- Parameters: ~25.6M
"""

import torch
import torch.nn as nn
from torchvision import models


class ResNet50Classifier(nn.Module):
    """
    ResNet-50 based classifier with custom head for NSFW detection
    
    Architecture:
        - ResNet-50 backbone (conv layers + residual blocks)
        - Global Average Pooling
        - Dropout (0.5)
        - FC Layer (2048 -> 512)
        - ReLU + Dropout (0.3)
        - FC Layer (512 -> 3)
        - Softmax
    """
    
    def __init__(self, num_classes=3, pretrained=True, dropout=0.5):
        super(ResNet50Classifier, self).__init__()
        
        # Load pretrained ResNet-50
        self.backbone = models.resnet50(pretrained=pretrained)
        
        # Remove original FC layer
        num_features = self.backbone.fc.in_features
        self.backbone.fc = nn.Identity()
        
        # Custom classification head
        self.classifier = nn.Sequential(
            nn.Dropout(dropout),
            nn.Linear(num_features, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(dropout * 0.6),
            nn.Linear(512, num_classes)
        )
        
    def forward(self, x):
        """
        Forward pass through the network
        
        Args:
            x: Input tensor of shape (batch_size, 3, 224, 224)
            
        Returns:
            logits: Raw class scores of shape (batch_size, 3)
        """
        features = self.backbone(x)
        logits = self.classifier(features)
        return logits
    
    def predict_proba(self, x):
        """
        Get class probabilities using softmax
        
        Args:
            x: Input tensor of shape (batch_size, 3, 224, 224)
            
        Returns:
            probabilities: Class probabilities of shape (batch_size, 3)
        """
        logits = self.forward(x)
        probabilities = torch.softmax(logits, dim=1)
        return probabilities


def load_model(checkpoint_path, device='cuda'):
    """
    Load a trained model from checkpoint
    
    Args:
        checkpoint_path: Path to .pth checkpoint file
        device: Device to load model on ('cuda' or 'cpu')
        
    Returns:
        model: Loaded model in eval mode
    """
    model = ResNet50Classifier(num_classes=3, pretrained=False)
    
    # Load state dict
    state_dict = torch.load(checkpoint_path, map_location=device)
    model.load_state_dict(state_dict)
    
    model = model.to(device)
    model.eval()
    
    return model


def count_parameters(model):
    """Count trainable parameters"""
    return sum(p.numel() for p in model.parameters() if p.requires_grad)


if __name__ == '__main__':
    # Model summary
    print("="*60)
    print("ResNet-50 NSFW Classifier Architecture")
    print("="*60)
    
    model = ResNet50Classifier(num_classes=3, pretrained=False)
    
    print(f"\nTotal parameters: {count_parameters(model):,}")
    print(f"Input shape: (batch_size, 3, 224, 224)")
    print(f"Output shape: (batch_size, 3)")
    print(f"\nClasses:")
    print("  0: NORMAL")
    print("  1: BLOCKED")
    print("  2: WARNING")
    
    # Test forward pass
    dummy_input = torch.randn(1, 3, 224, 224)
    with torch.no_grad():
        output = model(dummy_input)
        probs = model.predict_proba(dummy_input)
    
    print(f"\nTest forward pass successful!")
    print(f"Logits shape: {output.shape}")
    print(f"Probabilities shape: {probs.shape}")
    print(f"Probabilities sum: {probs.sum():.4f} (should be 1.0)")
