"""
Sample Dataset Generator
Creates placeholder images for training/validation datasets

This script generates dummy image files to demonstrate the dataset structure.
For actual training, replace these with real labeled images.
"""

import os
from PIL import Image, ImageDraw, ImageFont
import random

# Dataset configuration
DATASET_CONFIG = {
    'training': {
        'safe': 60,
        'nsfw': 55,
        'violence': 52
    },
    'validation': {
        'safe': 15,
        'nsfw': 12,
        'violence': 10
    }
}

# Image settings
IMG_SIZE = (224, 224)
COLORS = {
    'safe': [(144, 238, 144), (173, 216, 230), (255, 182, 193)],  # Light green, blue, pink
    'nsfw': [(255, 99, 71), (255, 140, 0), (220, 20, 60)],  # Red, orange, crimson
    'violence': [(70, 70, 70), (105, 105, 105), (128, 0, 0)]  # Dark gray, maroon
}


def create_placeholder_image(category, index, output_path):
    """
    Create a placeholder image with category label
    
    Args:
        category: Image category (safe, nsfw, violence)
        index: Image number
        output_path: Full path to save image
    """
    # Create image with random color from category palette
    color = random.choice(COLORS[category])
    img = Image.new('RGB', IMG_SIZE, color=color)
    
    # Add some random rectangles to make it look more interesting
    draw = ImageDraw.Draw(img)
    for _ in range(random.randint(3, 8)):
        x1 = random.randint(0, IMG_SIZE[0] - 50)
        y1 = random.randint(0, IMG_SIZE[1] - 50)
        x2 = x1 + random.randint(20, 50)
        y2 = y1 + random.randint(20, 50)
        rect_color = tuple(max(0, c + random.randint(-30, 30)) for c in color)
        draw.rectangle([x1, y1, x2, y2], fill=rect_color)
    
    # Add text label
    text = f"{category.upper()}\n#{index:04d}"
    try:
        # Try to use default font
        draw.text((IMG_SIZE[0]//4, IMG_SIZE[1]//2 - 20), text, fill=(255, 255, 255))
    except:
        # Fallback if font not available
        pass
    
    # Add noise pattern
    for _ in range(100):
        x = random.randint(0, IMG_SIZE[0] - 1)
        y = random.randint(0, IMG_SIZE[1] - 1)
        draw.point((x, y), fill=(255, 255, 255))
    
    # Save image
    img.save(output_path, 'JPEG', quality=85)
    return output_path


def generate_dataset():
    """Generate complete training and validation datasets"""
    
    base_dir = './datasets'
    total_created = 0
    
    print("="*60)
    print("Sample Dataset Generator for ResNet-50 NSFW Classifier")
    print("="*60)
    print()
    
    for split in ['training', 'validation']:
        print(f"\n[{split.upper()}] Generating dataset...")
        
        for category, count in DATASET_CONFIG[split].items():
            # Create directory
            category_dir = os.path.join(base_dir, split, category)
            os.makedirs(category_dir, exist_ok=True)
            
            print(f"  Creating {count} images for '{category}' category...")
            
            # Generate images
            for i in range(1, count + 1):
                filename = f"{category}_{i:04d}.jpg"
                filepath = os.path.join(category_dir, filename)
                
                create_placeholder_image(category, i, filepath)
                total_created += 1
                
                if i % 10 == 0:
                    print(f"    Progress: {i}/{count} images created")
            
            print(f"  ✓ Completed: {count} images in {category_dir}")
    
    print("\n" + "="*60)
    print(f"✓ Dataset generation complete!")
    print(f"✓ Total images created: {total_created}")
    print("="*60)
    
    # Print dataset summary
    print("\n[DATASET SUMMARY]")
    print("-"*60)
    for split in ['training', 'validation']:
        print(f"\n{split.upper()}:")
        for category, count in DATASET_CONFIG[split].items():
            print(f"  - {category:12s}: {count:3d} images")
    
    print("\n[DIRECTORY STRUCTURE]")
    print("-"*60)
    print("datasets/")
    print("├── training/")
    print("│   ├── safe/       (60 images)")
    print("│   ├── nsfw/       (55 images)")
    print("│   └── violence/   (52 images)")
    print("└── validation/")
    print("    ├── safe/       (15 images)")
    print("    ├── nsfw/       (12 images)")
    print("    └── violence/   (10 images)")
    
    print("\n[NEXT STEPS]")
    print("-"*60)
    print("1. Review generated images in datasets/ folder")
    print("2. For production, replace with real labeled images")
    print("3. Run training: python train_model.py --dataset ./datasets/training")
    print()


if __name__ == '__main__':
    print("\nStarting dataset generation...\n")
    generate_dataset()
    print("\n✓ Done!\n")
