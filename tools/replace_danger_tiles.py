# Replace old danger tiles with new generated tiles
from PIL import Image
import os, shutil

# Source tiles
SOURCE_TILES = [
    "assets/sprites/tile_scrapyard_64.png",
    "assets/sprites/tile_factory_64.png",
    "assets/sprites/tile_control_center_64.png",
    "assets/sprites/tile_server_room_64.png",
]

# Target directory
TARGET_DIR = "assets/tiles/danger"

# Make sure source tiles exist
os.chdir("C:/Users/reid1/Documents/Roboclaust")

print("============================================================")
print("Replacing danger tiles with new generated tiles")
print("============================================================")

# Create target directory
os.makedirs(TARGET_DIR, exist_ok=True)

# Copy each source tile 16 times with variations
tile_counter = 0
for i, source_path in enumerate(SOURCE_TILES):
    if not os.path.exists(source_path):
        print(f"WARNING: Source tile not found: {source_path}")
        continue

    print(f"\nProcessing {source_path}...")
    base_img = Image.open(source_path)

    # Create 16 variations per source tile
    for variant in range(16):
        target_path = f"{TARGET_DIR}/danger_tile_{tile_counter:02d}.png"

        # Create variations by rotating, flipping, or color shifting
        img = base_img.copy()

        if variant % 4 == 1:
            img = img.rotate(90)
        elif variant % 4 == 2:
            img = img.rotate(180)
        elif variant % 4 == 3:
            img = img.rotate(270)

        if variant >= 8:
            img = img.transpose(Image.FLIP_LEFT_RIGHT)

        # Save
        img.save(target_path, "PNG")
        print(f"  Created {target_path}")

        tile_counter += 1

print(f"\n============================================================")
print(f"Replaced {tile_counter} danger tiles successfully!")
print(f"============================================================")
