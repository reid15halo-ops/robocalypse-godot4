# Phase 1 Asset Specifications - Robocalypse

## Overview
This document specifies the asset requirements for **Phase 1** of the Robocalypse visual enhancement initiative. Phase 1 focuses on implementing type-specific animated sprites for enemies, player animation states, and projectile visuals.

**Related Issue:** #4 (Improve Visual Assets Beyond Colored Rectangles)  
**Implementation Status:** Code Complete - Assets Needed  
**Last Updated:** 2025-01-XX

---

## 1. Enemy Drone Sprites

### 1.1 General Specifications
- **Format:** PNG sprite sheets → Godot `.tres` SpriteFrames resources
- **Dimensions:** 40×40 pixels per frame
- **Frame Count:** 6 frames per animation
- **FPS:** 12 (0.083s per frame = 0.5s total loop)
- **Loop:** True (continuous hover/idle animation)
- **Background:** Transparent
- **Export Settings:** Import as Texture, Filter: Nearest (pixel art style)

### 1.2 Enemy Type Assets

#### Standard Drone (`drone_standard.tres`)
- **File Path:** `res://assets/anim/drone_standard.tres`
- **Script Usage:** `weak_drone.gd`, base `enemy.gd` (default fallback)
- **Visual Identity:** Balanced design, red/neutral color scheme
- **Animation:** "hover" or "idle" - gentle bobbing motion
- **Color Modulation:** Bright green in weak_drone (0.5, 1.5, 0.5), red in enemy.gd (1.0, 0.2, 0.2)

#### Fast Drone (`drone_fast.tres`)
- **File Path:** `res://assets/anim/drone_fast.tres`
- **Script Usage:** `rusher.gd`, base `enemy.gd` (fast type)
- **Visual Identity:** Streamlined, elongated body, cyan/yellow accents
- **Animation:** "hover" - faster bobbing/vibration (implies speed)
- **Color Modulation:** Bright yellow-orange (1.5, 1.0, 0)

#### Heavy Drone (`drone_heavy.tres`)
- **File Path:** `res://assets/anim/drone_heavy.tres`
- **Script Usage:** `tank_robot.gd`, base `enemy.gd` (heavy type)
- **Visual Identity:** Bulky, armored chassis, dark gray/metallic
- **Animation:** "hover" - slow, heavy movement with slight rotation
- **Color Modulation:** Dark gray (0.3, 0.3, 0.3)
- **Scale Override:** 1.8× in tank_robot.gd

#### Kamikaze Drone (`drone_kamikaze.tres`)
- **File Path:** `res://assets/anim/drone_kamikaze.tres`
- **Script Usage:** `kamikaze_drone.gd`, base `enemy.gd` (kamikaze type)
- **Visual Identity:** Compact, pulsing red core, explosive payload visible
- **Animation:** "hover" - erratic shaking/warning blink
- **Color Modulation:** Very bright red (2.0, 0.2, 0.2) with pulsing tween
- **Special:** Pulsing effect in script (0.3s cycle between 2.0-2.5 red intensity)

#### Sniper Drone (`drone_sniper.tres`)
- **File Path:** `res://assets/anim/drone_sniper.tres`
- **Script Usage:** `support_drone_enemy.gd`, base `enemy.gd` (sniper type)
- **Visual Identity:** Long-range sensor array, precision optics, blue/cyan accents
- **Animation:** "hover" - slow, stable hover with targeting scanner glow
- **Color Modulation:** Varies by support_drone_enemy aura type (cyan/orange/blue)

### 1.3 Implementation Notes
- **Fallback Behavior:** If `.tres` file missing, scripts fall back to ColorRect visuals
- **Metadata Tags:** Enemies set `drone_type` metadata ("standard", "fast", "heavy", "kamikaze", "sniper")
- **Override Pattern:** `tank_robot.gd` and `rusher.gd` override `_set_sprite_frames()` method
- **Standalone Drones:** `kamikaze_drone.gd`, `weak_drone.gd`, `support_drone_enemy.gd` have custom `_setup_sprite()` methods

---

## 2. Player Sprites

### 2.1 General Specifications
- **Format:** PNG sprite sheets → Godot `.tres` SpriteFrames resource
- **Dimensions:** 64×64 pixels per frame
- **Frame Counts:** Varies by animation
- **FPS:** 12
- **Loop:** Varies by animation (see below)
- **Background:** Transparent
- **Character Variants:** 3 (Hacker, Technician, Soldier) - Phase 1 uses shared base sprite

### 2.2 Animation States

#### Idle Animation ("idle")
- **Frame Count:** 4 frames
- **Duration:** 0.33s (12 FPS)
- **Loop:** True
- **Description:** Breathing/standby motion, slight weapon sway

#### Walk Animation ("walk")
- **Frame Count:** 8 frames
- **Duration:** 0.67s
- **Loop:** True
- **Description:** Running cycle with weapon held ready

#### Attack Animation ("attack") - OPTIONAL for Phase 1
- **Frame Count:** 4 frames
- **Duration:** 0.33s
- **Loop:** False
- **Description:** Melee swing/punch motion
- **Trigger:** `perform_melee_attack()` in player.gd
- **Behavior:** Auto-returns to idle/walk after completion
- **Note:** If missing, animation system uses walk animation as fallback

#### Damaged Animation ("damaged") - OPTIONAL for Phase 1
- **Frame Count:** 3 frames
- **Duration:** 0.25s
- **Loop:** False
- **Description:** Flinch/recoil reaction
- **Trigger:** `take_damage()` in player.gd
- **Behavior:** Auto-returns to previous state after completion

#### Death Animation ("death") - OPTIONAL for Phase 1
- **Frame Count:** 6 frames
- **Duration:** 0.5s
- **Loop:** False
- **Description:** Fall/explosion/disintegration sequence
- **Trigger:** `die()` in player.gd
- **Behavior:** Remains on final frame, game over triggered
- **Fallback:** Fade to 50% opacity gray if animation missing

### 2.3 Implementation Notes
- **File Path:** Configured in `Player.tscn` scene (not hardcoded in script)
- **State Machine:** Enum `AnimState` {IDLE, WALK, ATTACK, DAMAGED, DEATH}
- **Direction Flip:** `sprite.flip_h = (facing_direction == -1)` for left movement
- **Scale Override:** 1.3× in `_setup_visual()`
- **Character-Specific Sprites:** Future enhancement - Phase 1 uses single shared sprite

---

## 3. Projectile Sprites

### 3.1 General Specifications
- **Format:** PNG sprite sheets → Godot `.tres` SpriteFrames resources
- **Dimensions:** 32×32 pixels per frame
- **Frame Count:** 4 frames per animation
- **FPS:** 12
- **Loop:** True (continuous flight animation)
- **Background:** Transparent
- **Rotation:** Sprites auto-rotate via `rotation = direction.angle()` in script

### 3.2 Projectile Types

#### Bullet (`projectile_bullet.tres`)
- **File Path:** `res://assets/anim/projectile_bullet.tres`
- **Script Usage:** `projectile.gd` with `projectile_type = ProjectileType.BULLET`
- **Visual Identity:** Small kinetic round, yellow/orange tracer
- **Animation:** "fly" - spinning/glowing tracer effect
- **Scale:** 0.8×
- **Fallback:** 8×4 yellow ColorRect

#### Laser (`projectile_laser.tres`)
- **File Path:** `res://assets/anim/projectile_laser.tres`
- **Script Usage:** `projectile.gd` with `projectile_type = ProjectileType.LASER`
- **Visual Identity:** Cyan energy beam, particle trail
- **Animation:** "fly" - pulsing energy wave
- **Scale:** 1.0×
- **Fallback:** 12×6 cyan ColorRect

#### Missile (`projectile_missile.tres`)
- **File Path:** `res://assets/anim/projectile_missile.tres`
- **Script Usage:** `projectile.gd` with `projectile_type = ProjectileType.MISSILE`
- **Visual Identity:** Rocket with flame exhaust, orange-red trail
- **Animation:** "fly" - flickering exhaust flame
- **Scale:** 1.2×
- **Fallback:** 16×8 orange-red ColorRect

### 3.3 Optional Impact Animation
- **Animation Name:** "impact"
- **Frame Count:** 4 frames
- **Duration:** 0.33s
- **Loop:** False
- **Behavior:** If present, plays on collision before `queue_free()`
- **Trigger:** `_destroy_projectile()` in projectile.gd

---

## 4. File Organization

### 4.1 Directory Structure
```
assets/
├── anim/                          # SpriteFrames .tres resources
│   ├── drone_standard.tres
│   ├── drone_fast.tres
│   ├── drone_heavy.tres
│   ├── drone_kamikaze.tres
│   ├── drone_sniper.tres
│   ├── player_hacker.tres         # Future: Character-specific sprites
│   ├── player_technician.tres
│   ├── player_soldier.tres
│   ├── projectile_bullet.tres
│   ├── projectile_laser.tres
│   └── projectile_missile.tres
├── sprites/                       # Source PNG sprite sheets
│   ├── enemies/
│   │   ├── drone_standard_40x40_6f.png
│   │   ├── drone_fast_40x40_6f.png
│   │   ├── drone_heavy_40x40_6f.png
│   │   ├── drone_kamikaze_40x40_6f.png
│   │   └── drone_sniper_40x40_6f.png
│   ├── player/
│   │   ├── player_idle_64x64_4f.png
│   │   ├── player_walk_64x64_8f.png
│   │   ├── player_attack_64x64_4f.png  # Optional
│   │   ├── player_damaged_64x64_3f.png # Optional
│   │   └── player_death_64x64_6f.png   # Optional
│   └── projectiles/
│       ├── projectile_bullet_32x32_4f.png
│       ├── projectile_laser_32x32_4f.png
│       ├── projectile_missile_32x32_4f.png
│       ├── projectile_bullet_impact_32x32_4f.png  # Optional
│       ├── projectile_laser_impact_32x32_4f.png   # Optional
│       └── projectile_missile_impact_32x32_4f.png # Optional
```

### 4.2 Naming Convention
- **Pattern:** `<entity>_<variant>_<size>_<frames>.png`
- **Examples:**
  - `drone_kamikaze_40x40_6f.png` (6 frames, 240×40 sprite sheet)
  - `player_walk_64x64_8f.png` (8 frames, 512×64 sprite sheet)
  - `projectile_laser_32x32_4f.png` (4 frames, 128×32 sprite sheet)

---

## 5. SpriteFrames Resource Configuration

### 5.1 Creating .tres Files
**In Godot Editor:**
1. Right-click `assets/anim/` → New Resource → SpriteFrames
2. Name: `drone_kamikaze.tres` (example)
3. Double-click to open SpriteFrames panel
4. Add animation: "hover" (or "idle" for fallback compatibility)
5. Import sprite sheet PNG
6. Split frames: Horizontal 6, Vertical 1 (for 6-frame animation)
7. Set FPS: 12
8. Loop: Enabled
9. Save resource

### 5.2 Import Settings (PNG Files)
**In Godot Import Tab:**
- **Compress:** Lossless
- **Flags:**
  - Filter: Disabled (pixel art sharpness)
  - Mipmaps: Disabled
  - Repeat: Disabled
- **Process > Size Limit:** 0 (no resize)

---

## 6. Testing Checklist

### 6.1 Enemy Sprites
- [ ] Standard drone appears with green modulation (weak_drone)
- [ ] Fast drone appears with yellow-orange modulation (rusher)
- [ ] Heavy drone appears 1.8× larger with gray modulation (tank_robot)
- [ ] Kamikaze drone pulses red (check pulsing tween active)
- [ ] Sniper drone loads in support_drone_enemy with aura colors
- [ ] All drones hover/animate smoothly at 12 FPS
- [ ] Console shows no "sprite not found" warnings

### 6.2 Player Animations
- [ ] Player starts in "idle" animation when stationary
- [ ] Player transitions to "walk" when moving (velocity > 12.0)
- [ ] Player flips horizontally when moving left (facing_direction = -1)
- [ ] Attack animation triggers on melee attack (if available)
- [ ] Damage animation plays on taking damage (if available)
- [ ] Death animation plays on game over (if available)
- [ ] Fallbacks work: walk animation used if attack missing

### 6.3 Projectile Sprites
- [ ] Bullets appear with yellow tracer effect
- [ ] Lasers appear with cyan beam visual
- [ ] Missiles appear with orange-red exhaust
- [ ] Projectiles rotate to face direction of travel
- [ ] Impact animation plays on collision (if available)
- [ ] Fallback ColorRects appear if sprite missing

### 6.4 Performance
- [ ] No frame rate drops with 30+ enemies on screen
- [ ] No memory leaks after spawning/destroying 1000+ entities
- [ ] Sprite loading does not cause startup lag

---

## 7. Phase 2 & 3 Preview

### Phase 2: Boss Assets (Issue #4)
- Boss core sprite (128×128, 8 frames, pulsing animation)
- Boss attack effects (orbital strike, gravity well, plasma wall)
- Explosion variants (generic 64×64, kamikaze 64×64, boss 128×128)
- Estimated: 15 new sprite sheets

### Phase 3: Polish & Particles (Issue #4)
- Particle effects (muzzle flash, impact sparks, warp trails)
- Environmental tiles (scrapyard, factory, server room, control center)
- UI icons (health, scrap, weapon upgrades)
- Item pickup sprites
- Estimated: 25 new sprite sheets + tile sets

---

## 8. Asset Creation Guidelines

### 8.1 Art Style
- **Theme:** Industrial cyberpunk, dystopian robot uprising
- **Palette:** Desaturated grays/browns + bright accent colors (red, cyan, orange)
- **Detail Level:** Medium - readable at 1080p, but not overly complex (performance)
- **References:** Brotato, Vampire Survivors, Enter the Gungeon (top-down shooter aesthetics)

### 8.2 Technical Requirements
- **Resolution:** Native pixel art at specified dimensions (no upscaling)
- **Color Depth:** 32-bit RGBA PNG
- **Compression:** Lossless PNG (Godot handles runtime compression)
- **Frame Alignment:** Centered sprites for rotation consistency
- **Transparency:** Use alpha channel, no background color leakage

### 8.3 Delivery Format
- **Sprite Sheets:** Horizontal strip (e.g., 6 frames = 240×40 for 40px sprites)
- **Separate Frames:** Also acceptable - Godot can assemble into SpriteFrames
- **Source Files:** Provide .aseprite or .psd if available for future edits

---

## 9. Asset Request Summary (Phase 1 Minimum)

### Priority 1 (Core Gameplay)
1. `drone_standard_40x40_6f.png` (hover animation)
2. `drone_fast_40x40_6f.png` (hover animation)
3. `drone_heavy_40x40_6f.png` (hover animation)
4. `drone_kamikaze_40x40_6f.png` (hover animation)
5. `drone_sniper_40x40_6f.png` (hover animation)
6. `player_idle_64x64_4f.png`
7. `player_walk_64x64_8f.png`

### Priority 2 (Enhanced Feedback)
8. `player_attack_64x64_4f.png`
9. `player_damaged_64x64_3f.png`
10. `projectile_bullet_32x32_4f.png`
11. `projectile_laser_32x32_4f.png`
12. `projectile_missile_32x32_4f.png`

### Priority 3 (Polish)
13. `player_death_64x64_6f.png`
14. `projectile_*_impact_32x32_4f.png` (3 variants)

**Total Assets:** 16 sprite sheets minimum, 7 core + 5 enhanced + 4 polish

---

## 10. Code Integration Status

### ✅ Completed
- Enemy base class virtual method `_set_sprite_frames()` (enemy.gd)
- Enemy type overrides (tank_robot.gd, rusher.gd)
- Standalone enemy sprite setup (kamikaze_drone.gd, weak_drone.gd, support_drone_enemy.gd)
- Player animation state machine (player.gd)
- Projectile AnimatedSprite2D support (projectile.gd)

### ⏳ Pending (Asset Creation)
- Create 16 sprite sheet PNG files
- Generate 11 .tres SpriteFrames resources in Godot
- Test asset loading with complete visual pipeline
- Update Issue #4 with screenshots

### 📋 Documentation
- This specification file (docs/ASSET_SPECS_PHASE1.md)
- Update README.md with asset pipeline info
- Update .github/copilot-instructions.md with Phase 1 completion notes

---

## Contact & Feedback
**Repository:** github.com/reid15halo-ops/robocalypse-godot4  
**Issue Tracker:** Issue #4 (Asset Improvements)  
**Questions:** Open discussion in Issue #4 comments

**Last Reviewed:** 2025-01-XX  
**Next Review:** After Phase 1 asset delivery
