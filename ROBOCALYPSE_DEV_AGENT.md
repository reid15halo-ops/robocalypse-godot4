# RobocalypseDevAgent - Specialized Game Development Assistant

This document defines a specialized AI agent for developing and debugging the Robocalypse Godot 4 game project.

## Agent Identity

**Name:** RobocalypseDevAgent
**Purpose:** Feature development, bug fixing, and optimization for the Robocalypse 2D survival shooter
**Engine:** Godot 4.5
**Language:** GDScript (typed)

---

## Core Knowledge Base

### Project Architecture

The agent must understand these critical systems:

#### 1. **15 Autoload Singletons** (project.godot lines 18-35)
```
GameManager         → Core game state, player reference, score
ItemDatabase        → Item definitions and tiers
SaveManager         → Persistent data (user://roboclaust_save.json)
MetaProgression     → Between-run upgrades
DrugSystem          → Temporary buff system
CharacterSystem     → 3 playable characters (Hacker, Technician, Soldier)
DroneUpgradeDatabase → Drone progression
BuffSystem          → Runtime buffs/debuffs
WeaponProgression   → Melee weapon tree
AudioManager        → SFX playback (8-player pool)
MusicManager        → Dynamic music
TimeControl         → Slow-motion effects
InGameShop          → Wave-break purchases
AbilitySystem       → QWER abilities with cooldowns
ObjectiveSystem     → Mission tracking
MapSystem           → Difficulty scaling
```

#### 2. **Collision Layer System** (5 layers)
```
Layer 1: Player        → Player CharacterBody2D
Layer 2: Enemy         → All enemy types
Layer 3: Walls         → StaticBody2D boundaries
Layer 4: Items         → Pickups, scrap, crates
Layer 5: Projectiles   → Bullets, rockets, etc.
```

**Critical Pattern:** Player should have `collision_layer = 1` and `collision_mask = 14` (2+4+8)

#### 3. **Enemy Pooling System** (game.gd lines 39-41)
```gdscript
const ENEMY_POOL_SIZE: int = 30
var enemy_pool: Array[CharacterBody2D] = []
var active_enemies: Array[CharacterBody2D] = []
```

**Never** instantiate/free enemies during gameplay - always use pool!

#### 4. **Scene Flow**
```
MainMenu.tscn
    ↓
CharacterSelect.tscn (choose Hacker/Technician/Soldier)
    ↓
Game.tscn (main gameplay)
    ├─ Player (instantiated dynamically)
    ├─ MapGenerator (procedural 14x14 grid)
    ├─ Enemy spawning (pooled)
    └─ UI overlay
```

---

## Development Workflows

### Workflow 1: Adding a New Enemy Type

**Location:** `scripts/enemy_types/`

**Steps:**
1. Create new file extending `enemy.gd`:
   ```gdscript
   extends "res://scripts/enemy.gd"

   func _ready() -> void:
       super._ready()
       # Set unique properties
       max_health = 150
       min_speed = 120.0
       max_speed = 180.0
       score_value = 25
       enemy_color = Color(1.0, 0.5, 0.0)  # Orange
       enemy_size = 1.2
   ```

2. Override `_physics_process()` for custom behavior:
   ```gdscript
   func _physics_process(delta: float) -> void:
       super._physics_process(delta)
       # Custom AI logic here
   ```

3. Add visual distinction:
   - Set `enemy_color` (unique Color)
   - Set `enemy_size` (scale multiplier)
   - Optional: Override `_create_visual()` for custom sprite

4. Integrate with spawning:
   - Add preload in `game.gd`
   - Add to spawn pool logic
   - Test with headless mode

5. Document in `BUGFIXES.md` under "Visual Improvements" or "Enemy Types"

**Common Patterns:**
- **Ranged Enemy:** Use `enemy_projectile.gd`, set `preferred_distance > 300`
- **Tank:** High HP, low speed, large size
- **Rusher:** Low HP, high speed, elongated scale
- **Support:** Buff nearby enemies, use Area2D for aura

### Workflow 2: Adding a New Item

**Location:** `scripts/item_database.gd`

**Steps:**
1. Define item in ItemDatabase:
   ```gdscript
   "new_item_id": {
       "name": "Item Name",
       "description": "What it does",
       "icon": "res://assets/icons/item_icon.png",
       "tier": 1,  # 1-3
       "max_level": 3,
       "base_cost": 200,
       "cost_scaling": 1.5,
       "effects": {
           "stat_to_modify": [value_level1, value_level2, value_level3]
       }
   }
   ```

2. Implement effect in `player.gd` → `upgrade_item()`:
   ```gdscript
   if item_id == "new_item_id":
       match level:
           1: speed += 20
           2: speed += 40
           3: speed += 60
   ```

3. Add to shop pool in `in_game_shop.gd`:
   ```gdscript
   var available_items = ["health_boost", "speed_boost", "new_item_id"]
   ```

4. Test purchase flow:
   - Start game
   - Complete wave
   - Verify item appears in shop
   - Purchase and verify effect

### Workflow 3: Adding a New Ability

**Location:** `scripts/ability_system.gd`

**Steps:**
1. Create AbilityData:
   ```gdscript
   var dash_ability = AbilityData.new(
       "dash",
       "Dash",
       "Quick forward dash",
       "Q",  # Keybind
       5.0,  # Cooldown
       20,   # Mana cost
       "dash",
       {"distance": 300, "duration": 0.2}
   )
   ```

2. Implement in `player.gd`:
   ```gdscript
   if Input.is_action_just_pressed("ability_q"):
       if AbilitySystem.can_use_ability("Q"):
           _perform_dash()
           AbilitySystem.use_ability("Q")

   func _perform_dash():
       var dash_velocity = facing_direction * 300
       velocity += dash_velocity
       # Add visual effect (particles, trail)
   ```

3. Update `ability_hud.gd` to show cooldown

4. Test:
   - Press Q key
   - Verify dash occurs
   - Verify cooldown displays
   - Verify mana cost deducted

### Workflow 4: Bug Fixing Process

**Critical Bug Patterns:**

#### Pattern 1: **Collision Not Working**
```
Symptoms: Entity passes through walls/enemies
Diagnosis:
1. Check collision_layer (which layer am I on?)
2. Check collision_mask (which layers do I collide with?)
3. Verify StaticBody2D/CharacterBody2D setup
4. Check if collision shapes exist and are enabled

Common Fix:
- Player: collision_layer=1, collision_mask=14 (2+4+8)
- Enemy: collision_layer=2, collision_mask=14
- Walls: collision_layer=4, collision_mask=3 (1+2)
```

#### Pattern 2: **Signal Not Firing**
```
Symptoms: Connected function never called
Diagnosis:
1. Verify signal is declared: signal signal_name(params)
2. Check connection: node.signal_name.connect(callable)
3. Verify signal is emitted: signal_name.emit(args)
4. Check if node is in tree when connecting

Common Fix:
- Use @onready for node references
- Connect in _ready() after nodes exist
- Use Callable syntax: node.signal_name.connect(_on_signal)
```

#### Pattern 3: **Null Reference Error**
```
Symptoms: "Invalid get index 'property' (on base: 'null instance')"
Diagnosis:
1. Check if node exists: if node == null: return
2. Verify node path is correct
3. Check if node was freed: if not is_instance_valid(node): return
4. Use get_node_or_null() for optional nodes

Common Fix:
- Add null checks before access
- Use @onready var node = $Path or get_node_or_null("Path")
- Verify scene structure matches code expectations
```

#### Pattern 4: **Performance Issues**
```
Symptoms: FPS drops, stuttering
Diagnosis:
1. Check enemy count (should use pooling)
2. Verify projectiles are freed when off-screen
3. Check for expensive _process() calls
4. Profile with Godot's built-in profiler

Common Fix:
- Use enemy pooling (never instantiate in loop)
- Free projectiles outside viewport
- Move logic to _physics_process(delta) with delta scaling
- Cache expensive calculations
```

### Workflow 5: Balance Tuning

**When to Adjust:**
- Enemy too weak/strong
- Player abilities overpowered
- Wave difficulty curve wrong
- Boss fight too easy/hard

**Balance Levers:**

**Enemy Stats:**
```gdscript
max_health       # How tanky
min_speed/max_speed  # Movement speed
score_value      # Reward for killing
attack_damage    # Damage dealt
attack_cooldown  # Attack frequency
```

**Player Stats:**
```gdscript
max_health       # Survivability
speed            # Movement
melee_damage     # Base damage
weapon_range     # Melee reach
hp_regen_rate    # Health regen
```

**Wave Scaling:**
```gdscript
difficulty_multiplier  # Overall scaling
spawn_interval         # Enemy spawn rate
wave_duration          # Time per wave
```

**Document in BUGFIXES.md:**
```markdown
### X. **Balance: Enemy Type Adjusted**
**Problem:** Tank Robot died too quickly
**Fix:** Increased HP 200 → 500, reduced speed 80 → 60
**Location:** scripts/enemy_types/tank_robot.gd
```

---

## Testing Guidelines

### Manual Testing

**Critical Flows to Test:**

1. **Player Movement & Combat**
   - WASD movement smooth
   - Melee attacks hit enemies
   - Health bar updates correctly
   - Death triggers game over

2. **Enemy Behavior**
   - Enemies spawn at screen edges
   - AI follows player
   - Enemies die when health reaches 0
   - Scrap drops on death

3. **Wave System**
   - Waves last 60 seconds
   - Wave break shows shop/route selection
   - Difficulty increases over time
   - Boss spawns every 5 waves

4. **Persistence**
   - Scrap persists between runs
   - Meta upgrades apply correctly
   - Character selection saved
   - High scores recorded

### Automated Testing

**Godot Headless Mode:**

```bash
# Validate script syntax
"C:\Users\reid1\Documents\Godot_v4.5-stable_win64_console.exe" --headless --path "." --script scripts/player.gd --check-only --quit-after 3

# Run game in headless mode (for CI)
"C:\Users\reid1\Documents\Godot_v4.5-stable_win64_console.exe" --headless --path "." --quit-after 10
```

**When to Run Tests:**
- After adding new scripts
- Before committing collision changes
- After modifying autoload singletons
- When changing scene structure

---

## Common Code Patterns

### Pattern 1: Access Global State
```gdscript
# Get player reference
var player = GameManager.get_player()

# Add score
GameManager.add_score(100)

# Check game state
if GameManager.is_game_over:
    return
```

### Pattern 2: Spawn from Pool
```gdscript
# In game.gd
func spawn_enemy() -> CharacterBody2D:
    var enemy = null

    # Try to get from pool
    for e in enemy_pool:
        if not e.visible:
            enemy = e
            break

    # If pool exhausted, use existing active enemy
    if enemy == null and not enemy_pool.is_empty():
        enemy = enemy_pool[0]

    if enemy:
        enemy.visible = true
        enemy.global_position = get_spawn_position()
        enemy.current_health = enemy.max_health
        active_enemies.append(enemy)

    return enemy
```

### Pattern 3: Connect Signals
```gdscript
func _ready() -> void:
    # Connect to singleton
    GameManager.score_changed.connect(_on_score_changed)

    # Connect to node
    player.health_changed.connect(_on_player_health_changed)

    # Connect with parameters
    enemy.died.connect(_on_enemy_died.bind(enemy))

func _on_score_changed(new_score: int) -> void:
    score_label.text = "Score: %d" % new_score

func _on_player_health_changed(new_health: int) -> void:
    health_bar.value = new_health

func _on_enemy_died(enemy: CharacterBody2D) -> void:
    spawn_scrap_at(enemy.global_position)
```

### Pattern 4: Save/Load Data
```gdscript
# Save data
SaveManager.add_scrap(100)
SaveManager.set_upgrade_level("max_hp_level", 5)
SaveManager.save_game()

# Load data
var scrap = SaveManager.get_scrap()
var hp_level = SaveManager.get_upgrade_level("max_hp_level")
```

### Pattern 5: Play Audio
```gdscript
# Play sound effect
AudioManager.play_sound("metal_pipe")  # Enemy death
AudioManager.play_sound("oof")          # Player damage
AudioManager.play_sound("vine_boom")    # Boss spawn

# Adjust volume
AudioManager.set_volume(0.5)  # 50% volume
```

---

## Documentation Standards

### When to Update BUGFIXES.md

**Always document:**
- Critical bug fixes
- Balance changes
- New features
- Visual improvements
- System refactors

**Format:**
```markdown
### X. **Feature/Fix Name** ✓
**Problem:** What was wrong
**Fix:** What changed
**Location:** File paths
```

### When to Update CLAUDE.md

**Update when:**
- Adding new autoload singleton
- Changing core architecture
- Adding new major system
- Modifying scene flow
- Changing collision layers

### When to Update AGENTS.md

**Update when:**
- Changing coding standards
- Adding new build commands
- Modifying project structure
- Updating testing guidelines

---

## Quick Reference: File Locations

### Core Systems
```
scripts/GameManager.gd           → Global state
scripts/game.gd                  → Main game loop
scripts/player.gd                → Player controller
scripts/enemy.gd                 → Base enemy class
scripts/MapGenerator.gd          → Procedural maps
```

### Specialized Systems
```
scripts/ability_system.gd        → QWER abilities
scripts/item_database.gd         → Item definitions
scripts/weapon_progression.gd    → Melee weapons
scripts/character_system.gd      → 3 characters
scripts/meta_progression.gd      → Persistent upgrades
scripts/save_manager.gd          → Save/load
```

### Enemy Types
```
scripts/enemy_types/weak_drone.gd
scripts/enemy_types/kamikaze_drone.gd
scripts/enemy_types/tank_robot.gd
scripts/enemy_types/rusher.gd
scripts/enemy_types/support_drone_enemy.gd
```

### Map Modifiers
```
scripts/map_mods/turret.gd
scripts/map_mods/barrier.gd
scripts/map_mods/speed_pad.gd
scripts/map_mods/health_station.gd
scripts/map_mods/damage_zone.gd
```

### Scenes
```
scenes/MainMenu.tscn             → Main menu
scenes/CharacterSelect.tscn      → Character selection
scenes/Game.tscn                 → Main gameplay
scenes/Player.tscn               → Player scene
scenes/Enemy.tscn                → Base enemy
scenes/BossEnemy.tscn            → Boss
```

---

## Agent Capabilities Summary

✅ **Feature Development**
- Add new enemy types with unique behaviors
- Create items with effects
- Implement abilities with cooldowns
- Design map modifiers
- Build UI components

✅ **Bug Fixing**
- Diagnose collision issues
- Fix signal connection problems
- Resolve null reference errors
- Optimize performance bottlenecks
- Debug physics glitches

✅ **Balance Tuning**
- Adjust enemy stats
- Tune player abilities
- Scale difficulty curves
- Balance wave progression
- Test and iterate

✅ **Code Quality**
- Follow Godot 4.5 best practices
- Use typed GDScript
- Implement proper error handling
- Maintain consistent patterns
- Document changes

✅ **Testing**
- Run headless validation
- Perform manual QA
- Document test cases
- Verify critical flows
- Update BUGFIXES.md

---

## Emergency Debugging Checklist

When something breaks:

1. ☐ Check Godot console for errors
2. ☐ Verify collision_layer/collision_mask
3. ☐ Confirm signal connections
4. ☐ Check null references
5. ☐ Validate node paths (@onready)
6. ☐ Test with headless mode
7. ☐ Review recent changes in git
8. ☐ Check BUGFIXES.md for similar issues
9. ☐ Verify scene structure matches code
10. ☐ Test in clean project (clear .godot/)

---

## Agent Activation Prompt

When activating this agent, provide:

```
CONTEXT:
- I'm working on Robocalypse (Godot 4.5 survival shooter)
- Read CLAUDE.md for architecture overview
- Read BUGFIXES.md for known issues
- Read AGENTS.md for coding standards

TASK:
[Describe feature or bug]

CONSTRAINTS:
- Use enemy pooling (never instantiate in loop)
- Follow collision layer system
- Integrate with autoload singletons
- Document in BUGFIXES.md
- Test with headless mode
```

---

**Agent Version:** 1.0
**Last Updated:** 2025-01-20
**Godot Version:** 4.5
**Project:** Robocalypse
