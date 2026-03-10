from PIL import Image, ImageChops
import os

img_path = r'c:\MINI PROJECT-SGMSA\assets\images\logo.png'
if os.path.exists(img_path):
    img = Image.open(img_path).convert("RGBA")
    
    # Get bounding box of non-white pixels
    bg = Image.new("RGBA", img.size, (255,255,255,255))
    diff = ImageChops.difference(img, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    
    if bbox:
        cropped = img.crop(bbox)
        # Optional: Make white background transparent
        datas = cropped.getdata()
        newData = []
        for item in datas:
            # If pixel is practically white, make it transparent
            if item[0] >= 240 and item[1] >= 240 and item[2] >= 240:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)
        cropped.putdata(newData)
        cropped.save(img_path, "PNG")
        print(f"Cropped and made transparent image from {img.size} to {cropped.size}")
    else:
        print("Image might be completely white or transparent.")
else:
    print("File not found")
