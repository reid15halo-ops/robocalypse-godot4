from PIL import Image

# Load the image
img_path = r"C:\Users\reid1\source\repos\reid15halo-ops\robocalypse-godot4\assets\sprites\player\hacker_1_laufanimationen.png"
img = Image.open(img_path)

width, height = img.size
print(f"Image dimensions: {width}x{height}")

# Calculate frame size
# Layout: 4 columns, 2 rows (4 frames top, 2 frames bottom)
cols = 4
rows = 2

frame_width = width // cols
frame_height = height // rows

print(f"Frame size: {frame_width}x{frame_height}")
print(f"Total frames: 6 (4 in row 1, 2 in row 2)")
