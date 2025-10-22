# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Robocalypse is a 2D top-down survival shooter built with Godot 4.5. Players fight through waves of robotic enemies in procedurally generated urban arenas, using a combination of melee and ranged weapons, character abilities, and upgradeable support drones.

## Development Commands

```bash
# Open Godot Editor (from project root)
godot --path "."

# Run game directly (headless mode for testing)
godot --headless --path "." --quit-after 3

# Validate a specific script
godot --headless --path "." --script scripts/player.gd --check-only --quit-after 3

# Run with verbose output for debugging
godot --headless --verbose --path "." --quit-after 5

# Run main scene for playtesting
godot --path "." scenes/MainMenu.tscn
```

**Note**: Replace `godot` with the full path to your Godot 4.5 executable if not in PATH. On Windows, this is typically `Godot_v4.5-stable_win64.exe` (editor) or `Godot_v4.5-stable_win64_console.exe` (console).

## Core Architecture

### Autoload Singletons (Critical Dependencies)

The project relies heavily on 16 autoloaded singletons defined in [project.godot](project.godot) lines 18-36. These must be initialized in the correct order:

1. **GameManager** - Core game state (score, wave count, player reference, route modifiers)
2. **ItemDatabase** - Centralized item definitions and upgrade tiers
3. **SaveManager** - Persistent data (scrap currency, meta upgrades, unlocked content)
4. **MetaProgression** - Between-run upgrade system (HP, speed, damage, scrap multipliers)
5. **DrugSystem** - Temporary buff system with addiction mechanics
6. **CharacterSystem** - Character definitions (Hacker, Technician, Soldier) with unique stats
7. **DroneUpgradeDatabase** - Support drone progression tree
8. **BuffSystem** - Runtime buff/debuff management
9. **WeaponProgression** - Melee weapon upgrade tree (screwdriver → energy blade)
10. **AudioManager** - SFX playback
11. **MusicManager** - Dynamic music system with combat/menu tracks
12. **TimeControl** - Slow-motion effects for abilities
13. **InGameShop** - Wave-break item purchasing
14. **AbilitySystem** - Active abilities (QWER) with cooldowns and mana
15. **ObjectiveSystem** - Mission/challenge tracking
16. **MapSystem** - Procedural map difficulty scaling
17. **LanguageManager** - Internationalization and localization system

**Important**: Any script that needs access to player, score, or game state should reference `GameManager.get_player()` or `GameManager.score`.

### Scene Flow

```
MainMenu.tscn (main_menu.gd)
    ↓
CharacterSelect.tscn (character_select.gd) - Choose Hacker/Technician/Soldier
    ↓
Game.tscn (game.gd) - Main gameplay loop
    ├─ Player.tscn (player.gd) - Instantiated dynamically
    ├─ MapGenerator (generated at runtime)
    ├─ Enemy spawning system
    ├─ UI overlay (health, abilities, wave timer)
    └─ Wave break screens (RouteSelection, InGameShop, MetaUpgradeShop)
```

### Game Loop Architecture

[game.gd](scripts/game.gd) orchestrates the main gameplay:

1. **Initialization** (`_ready`):
   - Instantiates player from selected character
   - Generates procedural map via `MapGenerator.gd`
   - Initializes enemy pool (30 pre-allocated enemies)
   - Creates UI connections (health bars, ability HUD, affix indicators)

2. **Wave System** (`_process`):
   - 60-second waves with increasing difficulty
   - Spawns enemies at screen edges every 2 seconds
   - Wave breaks show route selection (3 modifiers) or item shop
   - Boss spawns every 5 waves

3. **Enemy Management**:
   - Object pooling pattern for performance (see `enemy_pool`, `active_enemies`)
   - Enemies deactivated to pool instead of freed
   - Supports multiple enemy types via inheritance:
     - `enemy.gd` - Base class
     - `improved_enemy.gd` - Enhanced AI
     - `boss_enemy.gd` - Wave 5/10/15 bosses
     - `scripts/enemy_types/` - Specialized variants (Kamikaze, Tank, Rusher, etc.)

## Key Systems

### Character System

Three playable characters with different stat profiles:

- **Hacker** (default): Balanced stats, +20% pet effectiveness, starts with laser
- **Technician** (3000 scrap): +50% drone damage, -20% HP, drone specialist
- **Soldier** (4000 scrap): +30% HP, +20% damage, -15% speed, 10% damage reduction, starts with shotgun

Character stats are applied in [player.gd](scripts/player.gd) on spawn. Current character stored in `CharacterSystem.current_character`.

### Meta Progression

Persistent upgrades purchased with scrap in [MetaUpgradeShop.tscn](scenes/MetaUpgradeShop.tscn):

- **Vitality Boost**: +5% max HP per level (max 10)
- **Speed Enhancement**: +3% movement speed per level (max 8)
- **Damage Amplifier**: +5% damage per level (max 10)
- **Scrap Collector**: +10% scrap gain per level (max 5)

Costs scale exponentially (1.2x per level). Saved via [SaveManager](scripts/save_manager.gd) to `user://roboclaust_save.json`.

### Procedural Map Generation

[MapGenerator.gd](scripts/MapGenerator.gd) creates 14x14 grid arenas:

- **Streets**: 2-cell wide paths for navigation
- **Avenues**: 5+ cell wide primary routes
- **Buildings**: 3x3+ solid structures with wall collision
- **Alleys**: Narrow shortcuts
- **Diagonals**: Angled connections

Grid uses 128px cells with 64px textures (2x2 tiles per cell). Walls are StaticBody2D on layer 3 (Walls).

**Important**: Map boundaries are enforced - spawning logic in [game.gd](scripts/game.gd) uses `spawn_distance` to place enemies outside viewport.

### Weapon Progression

Two weapon categories:

1. **Melee** (always equipped):
   - Progression tree in [WeaponProgression](scripts/weapon_progression.gd)
   - Upgrades: Screwdriver → Wrench → Electro Shocker → Plasma Cutter → Energy Blade
   - Purchased in InGameShop with scrap

2. **Ranged** (up to 3 simultaneous):
   - Laser (0.3s cooldown), Rocket (1.5s), Shotgun (0.8s)
   - Auto-fire at nearest enemy within 800px range
   - Managed in [player.gd](scripts/player.gd) via `equipped_weapons` array

### Ability System

MOBA-style active abilities on QWER keys:

- **Cooldown-based**: Each ability has independent cooldown timer
- **Mana cost**: 100 max mana, 5/sec regen
- **Ability types**: Dash, AOE damage, shield, summon, etc.
- **Character-specific**: Hacker gets pet bonuses, Technician gets drone buffs

Defined in [AbilitySystem](scripts/ability_system.gd). UI in [ability_hud.gd](scripts/ability_hud.gd).

### Route Modifiers (Affixes)

Every 3 waves, player selects 1 of 3 route modifiers (like Slay the Spire paths):

- **Skyward Rush** (Green): Bounce pads, updrafts, smoke bombs
- **Stormfront** (Yellow): Lightning rods, puddles, electrified trails
- **EMP Overload** (Red): EMP pulses, magnetic shields, Tesla coils

Handled by [AffixManager.gd](scripts/AffixManager.gd) and [MinibossSpawner.gd](scripts/MinibossSpawner.gd). Note: Currently disabled in latest commit.

### Save System

[SaveManager](scripts/save_manager.gd) persists:

- Scrap currency
- Meta upgrade levels
- Unlocked characters and items
- Statistics (kills, highest wave, total runs)
- Drug addiction state

Save file: `user://roboclaust_save.json` (typically `%APPDATA%\Godot\app_userdata\Robocalypse\`)

### Internationalization (i18n)

[LanguageManager](scripts/LanguageManager.gd) handles multi-language support with translation files in `locale/`:

- **Supported Languages**: English (en), German (de), Spanish (es)
- **Translation Files**:
  - `locale/strings.en.translation` - English strings
  - `locale/strings.de.translation` - German strings
  - `locale/strings.es.translation` - Spanish strings
- **String Access**: Use [UIStrings.gd](scripts/UIStrings.gd) for centralized UI text keys
- **Runtime Switching**: `LanguageManager` allows language changes without restart

**Adding a New Language:**
1. Create new `.csv` file in `localization/` directory with translation keys
2. Export as `.translation` file in Godot Editor (Import tab)
3. Add to `project.godot` under `[internationalization]` → `locale/translations`
4. Update `LanguageManager.gd` to include new language option

**Important**: All user-facing text should use translation keys via `tr("KEY_NAME")` for proper localization support.

## Godot 4 Specifics

### Physics and Movement

- **CharacterBody2D** (not KinematicBody2D): Player and enemies
- **move_and_slide()**: No parameters, velocity is a property
- **collision_layer/collision_mask**: Bit masks for physics filtering

### Collision Layers (project.godot lines 131-136)

1. **Layer 1**: Player
2. **Layer 2**: Enemy
3. **Layer 3**: Walls
4. **Layer 4**: Items
5. **Layer 5**: Projectiles

Example: Player has `collision_layer = 1`, `collision_mask = 14` (2 + 4 + 8 = Enemies + Walls + Items)

### Signals

Modern Godot 4 syntax:
```gdscript
signal health_changed(new_health: int)
signal died

# Connection
player.health_changed.connect(_on_player_health_changed)
```

### Input Actions

Defined in [project.godot](project.godot) lines 43-128:

- **Movement**: WASD + Arrow keys
- **Pause**: ESC
- **Abilities**: Q, W, E, R
- **Interact**: F
- **Passives**: 1, 2, 3, 4, 5
- **Switch Mode**: E

## Project Structure

See **Quick Reference → Directory Structure** section for complete layout.

### Editor Tools

The `tools/` directory contains utilities for asset management:
- `asset_splitter.gd` - Split sprite sheets into individual tiles
- `create_tilemap.gd` / `create_new_tilemap.gd` - Tilemap generation
- `configure_imports.gd` - Batch import configuration

Run with: `godot --headless --path "." --script tools/<name>.gd`

## Common Patterns

### Adding a New Enemy Type

1. Extend `enemy.gd` in `scripts/enemy_types/`
2. Override `_physics_process()` for custom behavior
3. Set `score_value`, `max_health`, speed ranges
4. Create matching scene in `scenes/` (optional if using code-only)
5. Add spawn logic in [game.gd](scripts/game.gd) or [MinibossSpawner.gd](scripts/MinibossSpawner.gd)

### Adding a New Item

1. Define in [ItemDatabase](scripts/item_database.gd)
2. Add icon texture path
3. Implement effects in [player.gd](scripts/player.gd) `upgrade_item()` method
4. Add to shop pool in [InGameShop](scripts/in_game_shop.gd)

### Adding a New Ability

1. Create `AbilityData` in [AbilitySystem](scripts/ability_system.gd)
2. Implement effect in `use_ability()` method
3. Add visual feedback (particles, sound)
4. Update [ability_hud.gd](scripts/ability_hud.gd) UI

## Quick Reference

### Most Commonly Modified Files

| Task | Files to Edit | Documentation |
|------|--------------|---------------|
| Add new enemy type | `scripts/enemy_types/<name>.gd`, `scripts/game.gd` (spawn logic) | See [ROBOCALYPSE_DEV_AGENT.md](ROBOCALYPSE_DEV_AGENT.md) Workflow 1 |
| Add new item | `scripts/item_database.gd`, `scripts/player.gd` (upgrade_item), `scripts/in_game_shop.gd` | See Common Patterns above |
| Add new ability | `scripts/ability_system.gd`, `scripts/player.gd`, `scripts/ability_hud.gd` | See Common Patterns above |
| Balance enemy stats | `scripts/enemy_types/<type>.gd` (max_health, speed, damage) | Document in [BUGFIXES.md](BUGFIXES.md) |
| Adjust wave difficulty | `scripts/game.gd` (spawn_interval, difficulty_multiplier) | Test thoroughly |
| Add translation | `localization/*.csv`, `scripts/LanguageManager.gd` | See Internationalization above |
| Fix collision bugs | Check collision_layer/mask in enemy/player .gd or .tscn | See Common Bug Patterns above |
| Modify UI | `scenes/*.tscn`, `scripts/UIStrings.gd` | Use translation keys |

### Key System Files

| System | Primary File(s) | Purpose |
|--------|----------------|---------|
| **Core Game Loop** | `scripts/game.gd` | Wave spawning, enemy pooling, UI management |
| **Player Controller** | `scripts/player.gd` | Movement, combat, abilities, item effects |
| **Enemy AI** | `scripts/enemy.gd`, `scripts/improved_enemy.gd` | Base enemy behavior and pathfinding |
| **Map Generation** | `scripts/MapGenerator.gd`, `scripts/CityLayoutGenerator.gd` | Procedural arena creation |
| **Persistence** | `scripts/save_manager.gd`, `scripts/meta_progression.gd` | Save/load, between-run upgrades |
| **Items** | `scripts/item_database.gd` | Item definitions, tiers, effects |
| **Weapons** | `scripts/weapon_progression.gd` | Melee weapon tree |
| **Abilities** | `scripts/ability_system.gd` | QWER ability definitions and cooldowns |
| **Audio** | `scripts/audio_manager.gd`, `scripts/music_manager.gd` | Sound effects and dynamic music |
| **Localization** | `scripts/LanguageManager.gd`, `scripts/UIStrings.gd` | Multi-language support |

### Directory Structure

```
robocalypse-godot4/
├── scripts/
│   ├── enemy_types/         # Specialized enemy variants
│   ├── map_mods/           # Interactive map objects
│   ├── GameManager.gd      # Core singleton
│   ├── game.gd             # Main game loop
│   ├── player.gd           # Player controller
│   └── ...                 # Other systems
├── scenes/
│   ├── map_mods/           # Scene files for map objects
│   ├── Game.tscn           # Main gameplay scene
│   ├── Player.tscn         # Player scene
│   ├── MainMenu.tscn       # Main menu
│   └── ...                 # Other scenes
├── assets/                 # Sprites, textures
├── sounds/                 # Audio files
├── locale/                 # Translation files
├── localization/           # Translation source CSVs
└── tools/                  # Editor utilities
```

### Important GitHub References

- **Issues**: Check [GitHub Issues](https://github.com/reid15halo-ops/robocalypse-godot4/issues) for current TODO items and known bugs
- **Bug Tracking**: Update [BUGFIXES.md](BUGFIXES.md) when fixing issues
- **Critical Changes**: Document in [CRITICAL_FIXES_CHANGELOG.md](CRITICAL_FIXES_CHANGELOG.md)
- **Development Workflows**: See [ROBOCALYPSE_DEV_AGENT.md](ROBOCALYPSE_DEV_AGENT.md) for detailed procedures

## Performance Considerations

- **Enemy Pooling**: Reuse enemy instances instead of instantiate/free (see [game.gd](scripts/game.gd) lines 39-41)
- **Z-Index Sorting**: Floor at -5, Walls at 0, Entities at 1+
- **Viewport Size**: 1280x720 with viewport stretch mode ([project.godot](project.godot) lines 37-41)
- **Scrap Pickup**: Limited to manageable number, cleaned up when off-screen

## Common Bug Patterns

These are the most frequent issues encountered in the codebase. See [ROBOCALYPSE_DEV_AGENT.md](ROBOCALYPSE_DEV_AGENT.md) for detailed debugging workflows.

### Collision Issues

**Symptoms**: Entity passes through walls/enemies, projectiles don't hit

**Common Causes**:
- Incorrect `collision_layer` or `collision_mask` settings
- Missing or disabled CollisionShape2D nodes
- Wrong node type (Area2D vs CharacterBody2D)

**Fix**:
```gdscript
# Player should have:
collision_layer = 1  # Layer 1: Player
collision_mask = 14  # Layers 2+4+8 (Enemy + Walls + Items)

# Enemy should have:
collision_layer = 2  # Layer 2: Enemy
collision_mask = 13  # Layers 1+4+8 (Player + Walls + Items)

# Walls should have:
collision_layer = 4  # Layer 3: Walls
collision_mask = 3   # Layers 1+2 (Player + Enemy)
```

### Signal Connection Failures

**Symptoms**: Connected function never called, no response to events

**Common Causes**:
- Signal not declared or misspelled
- Connection made before node exists in tree
- Using old Godot 3 syntax (`.connect()` with string)

**Fix**:
```gdscript
# Correct Godot 4 syntax
signal health_changed(new_health: int)

func _ready():
    # Connect after node is in tree
    player.health_changed.connect(_on_player_health_changed)

func _on_player_health_changed(new_health: int) -> void:
    health_bar.value = new_health
```

### Null Reference Errors

**Symptoms**: "Invalid get index 'property' (on base: 'null instance')"

**Common Causes**:
- Node freed or not yet instantiated
- Incorrect node path
- Weak references becoming null

**Fix**:
```gdscript
# Always check before access
if player == null or not is_instance_valid(player):
    return

# Use @onready for node references
@onready var health_bar = $UI/HealthBar

# Use get_node_or_null for optional nodes
var optional_node = get_node_or_null("Path/To/Node")
if optional_node:
    optional_node.do_something()
```

### Enemy Pooling Mistakes

**Symptoms**: Performance drops, enemies behave incorrectly, memory leaks

**Common Causes**:
- Instantiating enemies directly instead of using pool
- Not resetting enemy state when returning to pool
- Freeing pooled enemies

**Fix**:
```gdscript
# WRONG - Never instantiate in gameplay loop
var enemy = enemy_scene.instantiate()
add_child(enemy)

# CORRECT - Use pool from game.gd
func spawn_enemy():
    for e in enemy_pool:
        if not e.visible:
            e.visible = true
            e.global_position = spawn_pos
            e.current_health = e.max_health
            return e
```

## Testing

### Automated Testing Commands

```bash
# Validate all scripts for syntax errors
godot --headless --path "." --script scripts/player.gd --check-only --quit-after 3

# Run game in headless mode (for CI/CD)
godot --headless --path "." --quit-after 10

# Test specific enemy type
godot --headless --path "." --script scripts/enemy_types/tank_robot.gd --check-only --quit-after 3
```

### Critical Test Scenarios

When making changes, manually verify these flows:

1. **Player Movement & Combat**:
   - WASD movement responsive and smooth
   - Melee attacks connect with enemies
   - Health bar updates on damage
   - Death triggers game over properly

2. **Enemy Behavior**:
   - Enemies spawn at screen edges
   - AI follows player correctly
   - Enemies die at 0 health and drop scrap
   - No lingering references after death

3. **Wave Progression**:
   - Waves last 60 seconds
   - Wave breaks show correct UI (shop/route)
   - Difficulty scales properly
   - Boss spawns at wave 5/10/15

4. **Save/Load Persistence**:
   - Scrap persists between runs
   - Meta upgrades apply correctly
   - Character selection saved
   - No save corruption

### Debugging Tools

- **Godot Console**: Check for errors/warnings during runtime
- **Profiler**: Monitor performance (`Debug` → `Profiler`)
- **Remote Scene Tree**: Inspect running game (`Debug` → `Remote`)
- **Git History**: Check recent changes if new bugs appear

## Known Issues / Recent Changes

- Minibosses and non-standard walls disabled in commit `0848bdc` (see git log)
- Route modifiers (affixes) currently disabled
- Enemy behavior adjustments in latest commit

**For current TODO items and active development tasks**, check the [GitHub Issues](https://github.com/reid15halo-ops/robocalypse-godot4/issues) page.

## Additional Resources

- **[ROBOCALYPSE_DEV_AGENT.md](ROBOCALYPSE_DEV_AGENT.md)**: Detailed development workflows, bug patterns, and code examples
- **[BUGFIXES.md](BUGFIXES.md)**: Complete changelog of fixes and improvements
- **[CRITICAL_FIXES_CHANGELOG.md](CRITICAL_FIXES_CHANGELOG.md)**: Breaking changes and critical fixes
- **[AGENTS.md](AGENTS.md)**: Repository guidelines and coding standards
- **[GitHub Issues](https://github.com/reid15halo-ops/robocalypse-godot4/issues)**: Active TODO items and bug reports
