from PIL import Image

# Load the sprite
img_path = r"C:\Users\reid1\source\repos\reid15halo-ops\robocalypse-godot4\assets\sprites\player\hacker_1_laufanimationen.png"
img = Image.open(img_path)

print(f"Original mode: {img.mode}")
print(f"Original size: {img.size}")

# Convert to RGBA if not already
if img.mode != 'RGBA':
    img = img.convert('RGBA')
    print("Converted to RGBA")
else:
    print("Already in RGBA mode")

# Get pixel data
pixels = img.load()
width, height = img.size

# Analyze alpha channel and colors
alpha_values = {}
white_count = 0
gray_count = 0
transparent_count = 0
total_pixels = width * height

print("\nAnalyzing pixels...")

for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[x, y]

        # Track alpha distribution
        alpha_values[a] = alpha_values.get(a, 0) + 1

        # Count specific pixel types
        if a == 0:
            transparent_count += 1
        elif a > 0:
            # Check if white/gray
            if r > 200 and g > 200 and b > 200:
                white_count += 1
            elif 100 < r < 200 and 100 < g < 200 and 100 < b < 200:
                gray_count += 1

print("\nAlpha value distribution:")
for alpha in sorted(alpha_values.keys()):
    count = alpha_values[alpha]
    percentage = (count / total_pixels) * 100
    print(f"  Alpha {alpha}: {count} pixels ({percentage:.2f}%)")

print(f"\nPixel analysis:")
print(f"Fully transparent (a=0): {transparent_count} ({(transparent_count/total_pixels)*100:.2f}%)")
print(f"White-like pixels: {white_count} ({(white_count/total_pixels)*100:.2f}%)")
print(f"Gray-like pixels: {gray_count} ({(gray_count/total_pixels)*100:.2f}%)")

# If there's a significant amount of white/gray, create a cleaned version
if white_count > total_pixels * 0.05:  # More than 5% white pixels
    print("\n!!! DETECTED WHITE/GRAY BACKGROUND !!!")
    print("Creating cleaned version...")

    # Create new image with cleaned pixels
    cleaned_img = Image.new('RGBA', (width, height))
    cleaned_pixels = cleaned_img.load()

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]

            # Make white/gray pixels fully transparent
            if a > 0 and ((r > 200 and g > 200 and b > 200) or
                          (100 < r < 200 and 100 < g < 200 and 100 < b < 200)):
                cleaned_pixels[x, y] = (r, g, b, 0)
            else:
                cleaned_pixels[x, y] = (r, g, b, a)

    # Save cleaned version
    output_path = r"C:\Users\reid1\source\repos\reid15halo-ops\robocalypse-godot4\assets\sprites\player\hacker_1_laufanimationen_clean.png"
    cleaned_img.save(output_path)
    print(f"Saved cleaned version to: {output_path}")
    print("\nReplace the original file with the clean version, or update player.gd to use '_clean.png'")
else:
    print("\nNo significant white background detected.")
    print("Transparency issue may be in Godot import settings or rendering.")
