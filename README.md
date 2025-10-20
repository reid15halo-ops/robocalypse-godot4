# Robocalypse - Asset Repository

This directory contains all visual and audio assets for the Robocalypse project. Please follow these guidelines to maintain consistency and organization.

## Directory Structure

- **/assets/anim/:** Contains Godot `SpriteFrames` resources (`.tres` files) for animations. These are generated from the source sprite sheets.
- **/assets/sprites/:** Contains the source `.png` sprite sheets for characters, enemies, projectiles, and effects.
- **/assets/tiles/:** Contains the `.png` files for the procedural map generator's tileset (walls, floors, decorations).
- **/sounds/:** Contains all audio files (`.wav`, `.ogg`).
  - **/sounds/music/:** Background music tracks.
  - **/sounds/sfx/:** Sound effects for actions, UI, and enemies.

## Naming Conventions

To keep assets organized and easy to find, please use the following naming scheme:

- **Sprites:** `<category>_<name>_<dimensions>_<frames>f.png`
  - *Example:* `enemy_drone_standard_40x40_6f.png` (A 6-frame animation for the standard drone, where each frame is 40x40 pixels).
  - *Example:* `player_hacker_64x64.png` (A static sprite for the hacker character).
- **Tiles:** `tile_<description>_<size>.png`
  - *Example:* `tile_wall_64.png`
- **Animations (`.tres`):** `<category>_<name>.tres`
  - *Example:* `drone_standard.tres`
- **Audio:** `<category>_<description>.ogg`
  - *Example:* `sfx_explosion.ogg`
  - *Example:* `music_wave_1.ogg`

## Workflow for Adding New Animated Sprites

1. **Create the Sprite Sheet:**
   - Design your animation frames and arrange them horizontally in a single `.png` file.
   - Ensure all frames have the same dimensions.
   - Save the file in `/assets/sprites/` following the naming convention.

2. **Create the `SpriteFrames` Resource in Godot:**
   - In the Godot editor, navigate to the `/assets/anim/` directory in the FileSystem dock.
   - Right-click -> New Resource... -> `SpriteFrames`.
   - Save the new resource with a name matching the sprite (e.g., `new_enemy.tres`).

3. **Configure the Animation:**
   - Double-click the newly created `.tres` file to open the Animation panel.
   - In the Animation panel, select "Add frames from a Sprite Sheet".
   - Select your `.png` sprite sheet from `/assets/sprites/`.
   - Enter the correct number of horizontal (`Hframes`) and vertical (`Vframes`) frames.
   - Select all frames you want to add to an animation (e.g., a `hover` or `death` animation).
   - Click "Add Frames".
   - Rename the default animation to something descriptive (e.g., `hover`, `attack`).
   - Adjust the animation speed (FPS) and looping as needed.

4. **Assign to an `AnimatedSprite2D`:**
   - In your character or enemy scene, select the `AnimatedSprite2D` node.
   - Drag your new `.tres` resource from the FileSystem dock into the `Sprite Frames` property in the Inspector.
