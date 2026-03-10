from PIL import Image
import os

img_path = r'c:\MINI PROJECT-SGMSA\assets\images\logo.png'
if os.path.exists(img_path):
    img = Image.open(img_path)
    # Convert to RGBA to handle transparency if any
    img = img.convert("RGBA")
    
    # Get the bounding box of the non-transparent/non-white area
    # If the background is white, we might need to be careful.
    # The user provided image looks like it has a white background.
    
    # Try to find content
    bbox = img.getbbox()
    if bbox:
        # Crop to content
        cropped = img.crop(bbox)
        # Save it back
        cropped.save(img_path)
        print(f"Cropped image from {img.size} to {cropped.size}")
    else:
        print("Could not find content to crop")
else:
    print("File not found")
