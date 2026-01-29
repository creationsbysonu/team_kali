"""
Data Loading and Preprocessing Utilities
For ResNet-50 NSFW Classifier Training

Handles dataset loading, augmentation, and preprocessing
"""

import torch
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from PIL import Image
import os


class NSFWDataset(Dataset):
    """
    Custom dataset for NSFW classification
    
    Expected directory structure:
        dataset_root/
        ├── safe/
        │   ├── img1.jpg
        │   ├── img2.jpg
        │   └── ...
        ├── nsfw/
        │   ├── img1.jpg
        │   ├── img2.jpg
        │   └── ...
        └── violence/
            ├── img1.jpg
            ├── img2.jpg
            └── ...
    """
    
    def __init__(self, root_dir, transform=None):
        self.root_dir = root_dir
        self.transform = transform
        self.classes = ['safe', 'nsfw', 'violence']
        self.class_to_idx = {cls: idx for idx, cls in enumerate(self.classes)}
        
        # Load image paths and labels
        self.images = []
        self.labels = []
        
        for class_name in self.classes:
            class_dir = os.path.join(root_dir, class_name)
            if not os.path.exists(class_dir):
                continue
                
            for img_name in os.listdir(class_dir):
                if img_name.lower().endswith(('.png', '.jpg', '.jpeg')):
                    img_path = os.path.join(class_dir, img_name)
                    self.images.append(img_path)
                    self.labels.append(self.class_to_idx[class_name])
    
    def __len__(self):
        return len(self.images)
    
    def __getitem__(self, idx):
        img_path = self.images[idx]
        label = self.labels[idx]
        
        # Load image
        image = Image.open(img_path).convert('RGB')
        
        # Apply transforms
        if self.transform:
            image = self.transform(image)
        
        return image, label


def get_train_transforms():
    """
    Data augmentation for training
    
    Includes:
    - Random rotation
    - Random horizontal flip
    - Color jitter
    - Random crop
    - Normalization (ImageNet stats)
    """
    return transforms.Compose([
        transforms.Resize(256),
        transforms.RandomCrop(224),
        transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(15),
        transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        )
    ])


def get_val_transforms():
    """
    Preprocessing for validation/inference
    
    Only resizing, center crop, and normalization
    """
    return transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        )
    ])


def create_dataloaders(train_dir, val_dir, batch_size=32, num_workers=4):
    """
    Create training and validation dataloaders
    
    Args:
        train_dir: Path to training dataset
        val_dir: Path to validation dataset
        batch_size: Batch size for dataloaders
        num_workers: Number of worker processes
        
    Returns:
        train_loader: Training dataloader
        val_loader: Validation dataloader
    """
    
    # Create datasets
    train_dataset = NSFWDataset(train_dir, transform=get_train_transforms())
    val_dataset = NSFWDataset(val_dir, transform=get_val_transforms())
    
    # Create dataloaders
    train_loader = DataLoader(
        train_dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=True
    )
    
    val_loader = DataLoader(
        val_dataset,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=True
    )
    
    return train_loader, val_loader


if __name__ == '__main__':
    print("="*60)
    print("NSFW Dataset Loader")
    print("="*60)
    
    print("\nExpected directory structure:")
    print("  datasets/training/")
    print("    ├── safe/")
    print("    ├── nsfw/")
    print("    └── violence/")
    
    print("\nSupported formats: .jpg, .jpeg, .png")
    print("Image preprocessing: 224x224 RGB")
    print("Normalization: ImageNet statistics")
    
    # Test transforms
    print("\n[Testing transforms...]")
    train_transform = get_train_transforms()
    val_transform = get_val_transforms()
    print("✓ Train transforms loaded")
    print("✓ Validation transforms loaded")
