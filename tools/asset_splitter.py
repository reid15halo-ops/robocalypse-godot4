#!/usr/bin/env python3
"""
Asset Splitter for Roboclaust
Splits JPEG sprite sheets into individual PNG files
"""

from PIL import Image
import os
import sys

# Define output directories
DIRS = {
    "enemies": "assets/sprites/enemies",
    "player": "assets/sprites/player",
    "boss": "assets/sprites/boss",
    "effects": "assets/sprites/effects",
    "projectiles": "assets/sprites/projectiles",
    "weapons": "assets/sprites/weapons",
    "items": "assets/sprites/items",
    "drugs": "assets/sprites/drugs",
    "tiles_factory": "assets/tiles/factory",
    "tiles_danger": "assets/tiles/danger",
}


def create_directories():
    """Create all output directories"""
    base_path = os.path.join(os.path.dirname(__file__), "..")
    for dir_path in DIRS.values():
        full_path = os.path.join(base_path, dir_path)
        os.makedirs(full_path, exist_ok=True)
        print(f"Created directory: {full_path}")


def split_sprite_sheet(input_path, output_dir, grid_cols, grid_rows, names):
    """
    Split sprite sheet into individual images

    Args:
        input_path: Path to input JPEG
        output_dir: Output directory for PNGs
        grid_cols: Number of columns in grid
        grid_rows: Number of rows in grid
        names: List of output file names (without .png extension)
    """
    base_path = os.path.join(os.path.dirname(__file__), "..")
    full_input = os.path.join(base_path, input_path)
    full_output = os.path.join(base_path, output_dir)

    print(f"\n=== Processing: {input_path} ===")
    print(f"Grid: {grid_cols}x{grid_rows}")

    img = Image.open(full_input)
    img = img.convert("RGBA")  # Ensure RGBA mode
    width, height = img.size

    cell_width = width // grid_cols
    cell_height = height // grid_rows

    print(f"Image size: {width}x{height}")
    print(f"Cell size: {cell_width}x{cell_height}")

    count = 0
    for row in range(grid_rows):
        for col in range(grid_cols):
            index = row * grid_cols + col
            if index >= len(names):
                break

            name = names[index]
            if name == "skip":  # Skip empty cells
                continue

            left = col * cell_width
            top = row * cell_height
            right = left + cell_width
            bottom = top + cell_height

            cell = img.crop((left, top, right, bottom))

            # Auto-crop transparent borders (optional)
            # bbox = cell.getbbox()
            # if bbox:
            #     cell = cell.crop(bbox)

            output_path = os.path.join(full_output, name + ".png")
            cell.save(output_path, "PNG")
            count += 1
            print(f"  [{count}] Saved: {name}.png")

    print(f"Completed: {count} images extracted\n")


def process_drones():
    """Process dronen-1.jpg - Enemy drones"""
    split_sprite_sheet(
        "assets/dronen-1.jpg",
        DIRS["enemies"],
        grid_cols=2,
        grid_rows=3,
        names=[
            "standard_drone",
            "fast_drone",
            "heavy_drone",
            "explosion_smoke",
            "kamikaze_drone",
            "sniper_drone"
        ]
    )


def process_player():
    """Process hacker-1.jpg - Player character"""
    # Single image, just convert to PNG
    base_path = os.path.join(os.path.dirname(__file__), "..")
    input_path = os.path.join(base_path, "assets/hacker-1.jpg")
    output_path = os.path.join(base_path, DIRS["player"], "player.png")

    print(f"\n=== Processing: hacker-1.jpg ===")
    img = Image.open(input_path)
    img = img.convert("RGBA")
    img.save(output_path, "PNG")
    print(f"Saved: player.png\n")


def process_boss():
    """Process boss-gegner1.jpg - Boss enemy"""
    base_path = os.path.join(os.path.dirname(__file__), "..")
    input_path = os.path.join(base_path, "assets/boss-gegner1.jpg")
    output_path = os.path.join(base_path, DIRS["boss"], "boss_mech.png")

    print(f"\n=== Processing: boss-gegner1.jpg ===")
    img = Image.open(input_path)
    img = img.convert("RGBA")
    img.save(output_path, "PNG")
    print(f"Saved: boss_mech.png\n")


def process_effects():
    """Process effects-1.jpg - VFX effects"""
    split_sprite_sheet(
        "assets/effects-1.jpg",
        DIRS["effects"],
        grid_cols=2,
        grid_rows=3,
        names=[
            "laser_beam",
            "explosion_burst",
            "energy_blast",
            "portal_ring",
            "skip",  # Empty cell
            "lightning_wave"
        ]
    )


def process_projectiles():
    """Process geschosse-1.jpg - Projectiles"""
    split_sprite_sheet(
        "assets/geschosse-1.jpg",
        DIRS["projectiles"],
        grid_cols=2,
        grid_rows=3,
        names=[
            "energy_bullet",
            "energy_beam",
            "energy_laser",
            "rocket",
            "grenade",
            "energy_orb"
        ]
    )


def process_weapons():
    """Process weapons-1.jpg - Weapons"""
    split_sprite_sheet(
        "assets/weapons-1.jpg",
        DIRS["weapons"],
        grid_cols=3,
        grid_rows=3,
        names=[
            "pistol_energy",
            "pistol_gray",
            "skip",
            "rifle_blue",
            "rifle_gray",
            "skip",
            "sword_energy",
            "gun_heavy",
            "skip"
        ]
    )


def process_materials():
    """Process materialien-1.jpg - Items and drugs"""
    # This is a 6x6 grid with 36 items
    # We'll map them to items and drugs
    split_sprite_sheet(
        "assets/materialien-1.jpg",
        DIRS["items"],
        grid_cols=6,
        grid_rows=6,
        names=[
            # Row 1
            "metal_rusty", "crystal_cyan", "crystal_pink",
            "tech_panel", "shard_cyan", "orb_blue",
            # Row 2
            "cube_empty", "cube_filled", "tile_cracked_1",
            "cube_glass", "tile_cracked_2", "orb_tech_blue",
            # Row 3
            "orb_purple", "orb_glow_blue", "tile_cracked_3",
            "crystal_blue", "crystal_purple", "orb_green",
            # Row 4
            "crystal_green", "gem_blue", "gem_pink",
            "gem_purple", "gem_rainbow", "star_purple",
            # Row 5
            "crystal_white", "tile_metal", "gem_holo_purple",
            "ring_tech_black", "crystal_rainbow", "crystal_green_2",
            # Row 6 (These can be drug icons!)
            "tile_dark_1", "tile_dark_2", "tile_dark_3",
            "tile_dark_4", "tile_dark_5", "tile_dark_6"
        ]
    )


def process_drugs():
    """Copy specific items as drug icons"""
    print("\n=== Creating Drug Icons ===")
    base_path = os.path.join(os.path.dirname(__file__), "..")
    items_dir = os.path.join(base_path, DIRS["items"])
    drugs_dir = os.path.join(base_path, DIRS["drugs"])

    # Map items to drugs
    drug_mapping = {
        "crystal_pink.png": "stim_pack.png",       # Pink = Stimulant
        "crystal_purple.png": "nano_boost.png",    # Purple = Nano
        "gem_rainbow.png": "combat_drug.png",      # Rainbow = Combat
        "orb_glow_blue.png": "focus_serum.png",    # Glowing Blue = Focus
        "gem_holo_purple.png": "rage_pill.png",    # Holo Purple = Rage
        "crystal_cyan.png": "speed_injector.png",  # Cyan = Speed
    }

    for source, dest in drug_mapping.items():
        source_path = os.path.join(items_dir, source)
        dest_path = os.path.join(drugs_dir, dest)

        if os.path.exists(source_path):
            img = Image.open(source_path)
            img.save(dest_path, "PNG")
            print(f"Created drug icon: {dest}")

    print()


def process_map_tiles():
    """Process map-2.jpg - Danger zone tiles"""
    # map-2.jpg appears to be a grid of tiles
    # Let's extract them in an 8x8 grid
    split_sprite_sheet(
        "assets/map-2.jpg",
        DIRS["tiles_danger"],
        grid_cols=8,
        grid_rows=8,
        names=[f"danger_tile_{i:02d}" for i in range(64)]
    )


def main():
    print("=" * 60)
    print("Roboclaust Asset Splitter")
    print("=" * 60)

    # Create all directories
    create_directories()

    # Process all sprite sheets
    process_player()
    process_drones()
    process_boss()
    process_effects()
    process_projectiles()
    process_weapons()
    process_materials()
    process_drugs()
    process_map_tiles()

    print("=" * 60)
    print("Asset splitting complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Open Godot and reimport all PNG files")
    print("2. Set import settings: Filter = Nearest, Mipmaps = Off")
    print("3. Create SpriteFrames resources for animated sprites")
    print("4. Enable use_sprites = true in enemy.gd, player.gd, boss_enemy.gd")


if __name__ == "__main__":
    main()
