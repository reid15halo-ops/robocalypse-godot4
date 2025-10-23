# Robocalypse - Godot 4 AI Coding Agent Instructions

## Project Overview
2D top-down survival shooter (Brotato-style) in Godot 4.3+. Wave-based combat with 3 playable characters, procedural map generation, item progression, and boss fights. **Critical:** Uses 15 autoload singletons for centralized state management.

## Architecture Essentials

### Autoload Singletons (15 Core Systems)
All game state flows through autoloads defined in `project.godot`. **Never create local instances** - always access via singleton name:

**Core State Management:**
- **GameManager**: Score, pause state, player reference, `current_route` (RouteModifier enum)
  - Always check `GameManager.is_paused` before game logic
  - Call `GameManager.set_player(player_node)` in Game.tscn initialization
  - Emits: `score_changed`, `game_over`, `route_selected`, `scrap_changed`
- **SaveManager**: Persistent data at `user://roboclaust_save.json`
  - Use `SaveManager.is_character_unlocked("technician")` before character selection
  - Auto-saves meta progression (character unlocks, total scrap collected)
- **MetaProgression**: Between-run permanent upgrades (separate from in-game items)

**Character & Combat:**
- **CharacterSystem**: 3 playable characters with unique stats/abilities
  - `"hacker"`: Pet system bonus (+20% pet damage), 100 HP, unlocked by default
  - `"technician"`: Drone master (+50% drone damage), 80 HP, costs 3000 scrap
  - `"soldier"`: Tank (10% damage reduction), 130 HP, costs 4000 scrap
  - Access via `CharacterSystem.get_current_character()` for stat application
- **AbilitySystem**: QWER ability slots with cooldowns/mana system
  - Check `AbilitySystem.can_use_ability("Q")` before activation
  - Call `AbilitySystem.use_ability("Q")` to start cooldown
  - Database includes: dash, shockwave, shield, teleport abilities
  - Mana regenerates at 5.0/sec (100 max)
- **ItemDatabase**: Item definitions with tier/cost/effects - **never hardcode item data**
- **WeaponProgression**: Melee weapon upgrade tree
- **DroneUpgradeDatabase**: Hacker's controllable drone progression
- **BuffSystem**: Runtime buffs/debuffs (stacking prevention)
- **DrugSystem**: Temporary consumable buffs

**Audio & Environment:**
- **AudioManager**: SFX playback with 8-player pool - call `AudioManager.play_explosion_sound()`
- **MusicManager**: Dynamic music system, tracks game state
- **TimeControl**: Slow-motion effects via `Engine.time_scale`
  - **CRITICAL:** Always reset to 1.0 in scene transitions or game state resets
- **MapSystem**: Multi-area progression with difficulty scaling
  - 5 areas: Scrapyard → Assembly Line → Control Center → Server Farm → Boss Arena
  - Spawn portals after X waves: `MapSystem.portal_appeared.emit(position)`
  - Difficulty multipliers: 1.0x → 1.3x → 1.6x → 2.0x → 2.5x (boss)

**Meta Systems:**
- **InGameShop**: Wave-break item purchases
- **ObjectiveSystem**: Mission tracking (destroy structures, survive timer, etc.)

### Collision Layer System (CRITICAL - Most Common Bug Source)
```gdscript
# Layers (what I am):
Layer 1 (bit 0): Player
Layer 2 (bit 1): Enemy  
Layer 4 (bit 2): Walls (StaticBody2D from MapGenerator)
Layer 8 (bit 3): Boundary (arena edges in Game.tscn)
Layer 16 (bit 4): Projectiles

# Masks (what I collide with - ADD THE NUMBERS):
Player:     collision_layer=1,  collision_mask=28  # Boundary(4) + Walls(8) + Projectiles(16)
Enemy:      collision_layer=2,  collision_mask=14  # Enemies(2) + Walls(4) + Boundary(8)
Walls:      collision_layer=4,  collision_mask=3   # Player(1) + Enemy(2)
Projectile: collision_layer=16, collision_mask=5   # Player(1) + Walls(4)
```
**Common Fix:** If entities pass through walls, check mask arithmetic. `collision_mask=14` means layers 2+4+8 (not bits 1+4).

### Scene Flow & Initialization
```
MainMenu.tscn → CharacterSelect.tscn → Game.tscn
```

**CharacterSelect.tscn:**
- Displays 3 character cards with stats/cost/unlock status
- Sets `GameManager.selected_character` before scene transition
- Calls `GameManager.reset_game()` before loading Game.tscn

**Game.tscn initialization order (CRITICAL - DO NOT REORDER):**
1. **Unpause tree**: `get_tree().paused = false` (safety fix for startup freeze)
2. **Player instantiation**: `player_scene.instantiate()` at center spawn
3. **Map generation**: `CityLayoutGenerator` creates 14×14 grid (1792×1792px arena)
4. **Navigation baking**: `map_generator.bake_navigation_mesh(nav_region)` for enemy pathfinding
5. **Scrap container**: Create `Node2D` named "ScrapDrops" for pickup pooling
6. **AffixManager init**: `affix_manager.initialize(self, player)` - requires player reference
7. **MinibossSpawner init**: `miniboss_spawner.initialize(self, player)`
8. **MapSystem signals**: Connect `area_changed` and `portal_appeared`
9. **Enemy pool allocation**: `ENEMY_POOL_SIZE=30` pre-allocated - **never** `enemy.queue_free()` during gameplay
10. **UI initialization**: Hide pause_menu, wave_complete_screen, game_over_screen

**Common Init Errors:**
- Calling `affix_manager.initialize()` before player exists → null reference crash
- Forgetting `bake_navigation_mesh()` → enemies can't pathfind, walk through walls
- Not hiding pause_menu → game appears paused on start

### Pause State Synchronization (Common Bug Pattern)
**CRITICAL:** `GameManager.is_paused` and `get_tree().paused` must stay synchronized:
```gdscript
# In reset_game() or scene transitions:
GameManager.is_paused = false
get_tree().paused = false  # BOTH required!
Engine.time_scale = 1.0    # Reset time control
```
Without this, game appears frozen with visible but non-functional UI. This was the root cause of a critical startup freeze bug where the game loaded into pause mode.

## Development Workflows

### Adding New Enemy Type
1. **Create script**: `scripts/enemy_types/new_enemy.gd` extending `res://scripts/enemy.gd`
   ```gdscript
   extends "res://scripts/enemy.gd"
   
   func _ready() -> void:
       super._ready()  # Call parent first!
       max_health = 200
       min_speed = 120.0
       max_speed = 180.0
       score_value = 25
       enemy_color = Color(1.0, 0.5, 0.0)  # Orange
       enemy_size = 1.2
       has_pulse_animation = true
   ```

2. **Override physics for custom AI** (optional):
   ```gdscript
   func _physics_process(delta: float) -> void:
       super._physics_process(delta)  # Includes movement + collision
       
       # Custom behavior (e.g., ranged attack)
       if attack_cooldown <= 0 and distance_to_player < 400.0:
           _shoot_projectile()
           attack_cooldown = 2.0
   ```

3. **Pathfinding rule**: Always use `_get_navigation_direction(target_pos)` - never calculate `(target - position).normalized()` directly (ignores walls)

4. **Add to pool**: In `game.gd._initialize_enemy_pool()`, preload and instantiate your enemy type

5. **Sprites**: If using AnimatedSprite2D, place frames in `assets/anim/` as `.tres` SpriteFrames resources

### Adding Items to ItemDatabase
Items exist only in `ItemDatabase.gd` - no scene files:
```gdscript
"item_id": {
    "name": "Display Name",
    "description": "Effect text",
    "icon": "res://assets/icons/item.png",
    "tier": 1,  # 1-3 rarity
    "max_level": 3,
    "base_cost": 300,
    "cost_scaling": 1.5,
    "effects": {"stat_name": [lvl1_val, lvl2_val, lvl3_val]}
}
```
Then implement in `player.gd._apply_item_effect()` with level-based switch.

### Procedural Map Generation
`CityLayoutGenerator` creates 9 building zones on a 14×14 grid (128px tiles = 1792×1792px total):

**Grid Layout:**
- Streets at rows/cols `[4,5,9,10]` (cross pattern)
- Buildings fill remaining 9 zones (3×3 arrangement)
- Walls use `StaticBody2D` with `collision_layer=4`, `collision_mask=3`

**Critical Steps:**
1. Call `map_generator.generate_map()` - returns `{player_spawn_position, building_zones}`
2. **Must** call `map_generator.bake_navigation_mesh(nav_region)` for enemy pathfinding
3. Position player at `map_data.player_spawn_position` (center: 896, 896)

**Arena Bounds:**
- `Rect2(0, 0, 1792, 1792)` - clamp all spawns inside this
- Boundary walls in `Game.tscn` at edges (layer 8)

**Common Issue:** If enemies walk through walls, navigation mesh wasn't baked - check console for "Skipping navmesh baking" warning

### Boss System Architecture
Bosses use a **component-based state machine** for modular attack patterns:

**Core Components:**
- `boss_state_machine.gd`: Phase transitions (4 phases based on HP thresholds)
- `boss_attacks.gd`: Attack implementations (laser_burst, orbital_strike, gravity_well, etc.)
- `boss_effect_manager_component.gd`: Visual effects coordination
- `boss_attack_controller_component.gd`: Attack timing/cooldowns

**Phase System:**
```gdscript
# Phases trigger at HP thresholds:
Phase 1: 100%-75% HP → Speed 140, Cooldown 4.5s
Phase 2: 75%-45% HP  → Speed 160, Cooldown 3.5s
Phase 3: 45%-20% HP  → Speed 185, Cooldown 2.8s
Phase 4: <20% HP     → Speed 210, Cooldown 2.2s

# Each phase has unique ability pool:
ability_pools = {
    1: ["laser_burst", "orbital_strike"],
    2: ["laser_burst", "orbital_strike", "shockwave_burst", "drone_swarm"],
    3: ["rapid_barrage", "plasma_wall", "gravity_well", "drone_swarm"],
    4: ["obliteration_beam", "gravity_well", "shield_overdrive", "plasma_wall"]
}
```

**Adding New Boss Attack:**
1. Add method to `boss_attacks.gd`: `func _my_attack() -> void:`
2. Add to appropriate phase pool in `boss_state_machine.gd`
3. Use `boss.game_scene.add_child()` for projectiles/effects
4. Call `AudioManager.play_boss_attack_sound()` for audio

### Route Modifier System (AffixManager)
**3 Routes with Environmental Hazards:**
- **SKYWARD_RUSH** (Green): Jump pads, teleport portals, updrafts, smoke clouds
- **STORMFRONT** (Yellow): Swamp zones, acid rain, lightning bolts, static fields
- **EMP_OVERLOAD** (Red): EMP storms, random lightning, magnetic pulses, Tesla grids

**Activation Flow:**
1. Player selects route at wave 3 via portal interaction
2. `GameManager.current_route` set to `RouteModifier` enum
3. `AffixManager.apply_route_affixes(route)` spawns environmental hazards
4. Max 10 active nodes per route (performance cap)

**Creating New Affix:**
```gdscript
# In AffixManager.gd:
func _init_my_affix() -> Dictionary:
    var nodes: Array = []
    # Create Area2D or visual nodes
    var hazard = Area2D.new()
    # ... setup collision, visuals, etc.
    nodes.append(hazard)
    
    return {
        "nodes": nodes,
        "update": func(delta): pass,  # Called every frame
        "cleanup": func(): pass        # Called on deactivation
    }
```

### Localization System
All UI strings use **centralized constant system** via `UIStrings.gd`:

**Usage Pattern:**
```gdscript
# WRONG - hardcoded string:
label.text = "Health: " + str(health)

# CORRECT - localization-ready:
label.text = tr(UIStrings.HP) + ": " + str(health)
```

**CSV Translation Files:**
- `locale/strings.csv`: Main game strings
- `localization/hud_strings.csv`: HUD-specific text
- Format: `KEY,en,de,fr` (English, German, French columns)

**Adding New Translatable String:**
1. Add constant to `UIStrings.gd`: `const MY_TEXT := "MY_TEXT"`
2. Add row to CSV: `MY_TEXT,"English text","Deutscher Text","Texte français"`
3. Use in code: `label.text = tr(UIStrings.MY_TEXT)`

### Python Asset Pipeline
Activate virtualenv first: `venv\Scripts\activate` (Windows)
- `tools/asset_splitter.py`: Split sprite sheets into frames
- `tools/configure_imports.gd`: Regenerate Godot import files after art changes
- Run: `godot4 --headless --path . --script tools/configure_imports.gd`

## Code Patterns & Conventions

### GDScript Style (Strict)
- **Indentation:** 4 spaces (Godot standard)
- **Naming:** `class_name` PascalCase, variables/signals snake_case, `CONSTANTS_ALL_CAPS`
- **Typing:** Always type new code: `var health: int = 100`, `func move(speed: float) -> void:`
- **Node References:** Use `@onready var sprite = $Sprite2D` for scene nodes
- **Resource Paths:** Relative only: `res://scripts/enemy.gd` (never absolute filesystem paths)

### Signal Usage (Godot 4 Syntax)
```gdscript
# Declaration:
signal health_changed(new_health: int)

# Connection (no string names):
player.health_changed.connect(_on_player_health_changed)

# Emission:
health_changed.emit(current_health)
```

### Movement Pattern (CharacterBody2D)
```gdscript
func _physics_process(delta: float) -> void:
    var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = input * speed
    move_and_slide()  # NO parameters in Godot 4!
```

### Enemy Pooling (Performance Critical)
```gdscript
# WRONG - causes lag spikes:
var enemy = enemy_scene.instantiate()
add_child(enemy)
# later:
enemy.queue_free()

# CORRECT - reuse pool:
var enemy = _get_pooled_enemy()
enemy.global_position = spawn_pos
enemy.activate()
# later:
enemy.deactivate()  # Returns to pool
```

## Testing & Debugging

### Running the Game
```powershell
# Launch editor:
godot4 --path .

# Headless test (no editor):
godot4 --headless --path . --run "Game"

# Check for script errors:
godot4 --headless --path . --script scripts/GameManager.gd --check-only --quit
```

### Common Bug Patterns
**Collision not working:** Print `collision_layer` and `collision_mask` - verify bit math
**Pause freeze:** Check both `GameManager.is_paused` and `get_tree().paused` match
**Projectiles through walls:** Ensure wall `collision_mask` includes projectile layer (16)
**Enemy stuck:** NavigationRegion2D not baked - call `bake_navigation_mesh()` after map gen
**Assets not loading:** Run `tools/configure_imports.gd` to regenerate `.import` files

### Manual Testing (No Automated Tests)
Smoke-test critical paths after changes:
1. Main Menu → Character Select → Start Game (should start unpaused)
2. Pause (ESC) → Resume → Main Menu → Start again
3. Die → Restart (check state reset)
4. Spawn enemies → Verify pathfinding around walls
Document QA steps in `BUGFIXES.md` when fixing issues.

## Documentation Requirements

### When Fixing Bugs
Update **both** files:
1. `BUGFIXES.md`: Problem, root cause, fix with code snippets, test steps
2. `CRITICAL_FIXES_CHANGELOG.md`: If balancing/stability-sensitive

### Commit Messages
Imperative mood, scoped to one change:
- ✅ `Add drone cooldown clamp to prevent negative values`
- ✅ `Fix pause state desync in GameManager.reset_game()`
- ❌ `Fixed bugs` (too vague)
- ❌ `Updated player and enemy and walls` (too broad)

## Key Files Reference
- **Core Logic:** `scripts/game.gd` (1942 lines - main scene controller)
- **Player:** `scripts/player.gd` (movement, health, items, weapons)
- **Enemy Base:** `scripts/enemy.gd` (AI, pooling, types via `enemy_types/`)
- **Map:** `scripts/CityLayoutGenerator.gd` (procedural 14×14 grid)
- **State:** `scripts/GameManager.gd` (singleton, score, pause)
- **UI Strings:** `scripts/UIStrings.gd` (centralized for i18n)
- **Tools:** `tools/configure_imports.gd`, `tools/asset_splitter.py`

## Platform Notes
- **Windows:** Use PowerShell, activate venv with `venv\Scripts\activate`
- **Assets:** Keep `.godot/` cache out of version control
- **Binary Assets:** Compress before committing to keep repo lean
