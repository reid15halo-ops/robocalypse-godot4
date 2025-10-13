# Roboclaust - Perplexity Space Context Document

> **Vollständige Projekt-Dokumentation für Feature-Entwicklung**
> Version: 1.0.0 | Engine: Godot 4.5 | Language: GDScript

---

## 📋 Table of Contents

1. [Projektübersicht](#projektübersicht)
2. [Architektur](#architektur)
3. [Core Systems](#core-systems)
4. [Code-Konventionen](#code-konventionen)
5. [Feature Development](#feature-development)
6. [API Referenz](#api-referenz)
7. [Known Issues](#known-issues)

---

## 🎮 Projektübersicht

### Game Concept
**Roboclaust** ist ein 2D Top-Down Survival-Shooter im Rogue-Lite Genre.

**Kern-Gameplay:**
- Spieler kämpft gegen Wellen feindlicher Roboter-Drohnen
- Wave-basierte Struktur (60s pro Wave)
- Item-System mit permanenten Meta-Upgrades
- 3 spielbare Charaktere mit unterschiedlichen Fähigkeiten
- Route-Selection-System (alle 3 Waves)

### Tech Stack
- **Engine:** Godot 4.5 (C# NOT used, only GDScript)
- **Language:** GDScript
- **Platform:** Windows (primär), potentiell Linux/Web
- **Resolution:** 1280x720 (upscaled)

### Entwicklungsstand
- ✅ **Core Loop:** Komplett (Spawning, Combat, Death)
- ✅ **Item System:** Implementiert (60+ Items)
- ✅ **Meta Progression:** Shop funktioniert
- ✅ **Character System:** 3 Charaktere (Soldier, Hacker, Tank)
- 🔄 **Enemy AI:** Basic (neue ImprovedEnemy in Entwicklung)
- 🔄 **Balance:** Ongoing
- ❌ **Sound/Music:** Teilweise (mehr Tracks benötigt)

---

## 🏗️ Architektur

### Ordnerstruktur

```
Roboclaust/
├── scenes/
│   ├── MainMenu.tscn           # Hauptmenü
│   ├── CharacterSelect.tscn    # Charakterauswahl
│   ├── Game.tscn               # Hauptspiel-Scene
│   ├── GameMap.tscn            # Prozedurales Map TileMap
│   ├── Player.tscn             # Spieler-Szene
│   ├── Enemy.tscn              # Standard Enemy
│   ├── ImprovedEnemy.tscn      # Neue AI Enemy (in Dev)
│   ├── BossEnemy.tscn          # Boss (alle 10 Waves)
│   ├── RouteSelection.tscn     # Route-Auswahl UI
│   ├── MetaUpgradeShop.tscn    # Meta-Progression Shop
│   ├── [Projectiles].tscn      # Verschiedene Projektile
│   └── [UI Elements].tscn
│
├── scripts/
│   ├── singletons/             # Autoload-Singletons
│   │   ├── GameManager.gd      # Globaler State (Score, Wave, Pause)
│   │   ├── AudioManager.gd     # Sound/Music Management
│   │   ├── SaveManager.gd      # Save/Load System
│   │   ├── TimeControl.gd      # Slow-Motion Effects
│   │   ├── ItemDatabase.gd     # Item-Definitionen
│   │   ├── CharacterSystem.gd  # Charakter-Daten
│   │   ├── MetaProgression.gd  # Permanente Upgrades
│   │   ├── WeaponProgression.gd # Waffen-Tiers
│   │   ├── MapSystem.gd        # Area/Portal Management
│   │   ├── AbilitySystem.gd    # Q/E/R Abilities
│   │   └── DrugSystem.gd       # Drug Items (Buffs/Debuffs)
│   │
│   ├── player.gd               # Spieler-Logik
│   ├── enemy.gd                # Enemy-Basis-AI
│   ├── improved_enemy.gd       # Neue State Machine AI
│   ├── boss_enemy.gd           # Boss-Logik
│   ├── game.gd                 # Hauptspiel-Loop
│   ├── MapGenerator.gd         # Procedurale Map-Generierung
│   ├── AffixManager.gd         # Route-spezifische Hazards
│   ├── MinibossSpawner.gd      # Miniboss System (Wave 3, 6, 9)
│   └── [weitere scripts]
│
├── assets/
│   ├── sprites/
│   │   ├── player/             # Spieler-Animationen
│   │   ├── enemies/            # Enemy-Sprites (SpriteFrames)
│   │   └── items/              # Item-Icons
│   ├── tiles/                  # TileSet für Map
│   ├── sounds/                 # SFX
│   └── music/                  # Background Music
│
└── tools/                      # Editor-Tools
    └── [Asset processing tools]
```

### Scene Flow

```
MainMenu.tscn
    ↓
CharacterSelect.tscn
    ↓
Game.tscn (Hauptspiel)
    ├── GameMap (TileMap)
    ├── Player
    ├── Enemies (gepoolt)
    ├── UI
    │   ├── HealthBar
    │   ├── ScoreLabel
    │   ├── WaveTimer
    │   ├── AbilityHUD
    │   ├── PauseMenu
    │   ├── WaveCompleteScreen
    │   ├── GameOverScreen
    │   └── RouteSelection
    └── [Dynamische Nodes]
        ├── Projectiles
        ├── Explosions
        └── Affix Nodes

Nach Game Over:
    → MetaUpgradeShop.tscn (Scrap ausgeben)
    → MainMenu.tscn
```

### Singleton-System (Autoload)

**Alle wichtigen Singletons:**
```gdscript
# In Project Settings → Autoload:
GameManager      # globaler State, Signals
AudioManager     # Sound/Music
SaveManager      # Persistenz
TimeControl      # Slow-Motion
ItemDatabase     # Item-Daten
CharacterSystem  # Charaktere
MetaProgression  # Permanente Upgrades
WeaponProgression # Waffen-Tiers
MapSystem        # Area/Portal
AbilitySystem    # Q/E/R Slots
DrugSystem       # Drogen-Effekte
```

**Wichtigste Signals:**
```gdscript
# GameManager
signal score_changed(new_score: int)
signal game_over
signal wave_completed(wave_number: int)
signal route_selected(route: int)

# MapSystem
signal area_changed(area: Dictionary)
signal portal_appeared(position: Vector2)

# CharacterSystem
signal character_changed(character_id: String)
```

---

## ⚙️ Core Systems

### 1. Enemy System

**Pooling-Architektur:**
```gdscript
# game.gd
const ENEMY_POOL_SIZE: int = 30
var enemy_pool: Array[CharacterBody2D] = []

func _get_pooled_enemy() -> CharacterBody2D:
    # Holt Enemy aus Pool oder erstellt neuen

func _return_enemy_to_pool(enemy):
    # Gibt Enemy zurück (statt queue_free())
```

**Enemy-Typen:**
1. **Standard (Rot):** Balanced, 100 HP, 100-150 px/s
2. **Fast (Cyan):** Schnell, 60 HP, 200-250 px/s, Dash-Attack
3. **Heavy (Braun):** Langsam, 300 HP, 60-80 px/s, Projektile
4. **Kamikaze (Orange):** 40 HP, explodiert bei Kontakt
5. **Sniper (Grün):** 80 HP, hält Distanz, Laser-Angriff

**Metadata-System:**
```gdscript
enemy.set_meta("is_pooled", true)
enemy.set_meta("is_kamikaze", true)
enemy.set_meta("is_sniper", true)
enemy.set_meta("is_miniboss", true)
enemy.set_meta("explosion_damage", 80)
```

**Neue ImprovedEnemy AI:**
- State Machine (IDLE, PATROLLING, CHASING, ATTACKING, WALL_AVOIDING)
- NavigationAgent2D für Pfadfindung
- 5 RayCast2D für Wandvermeidung
- Smooth Acceleration/Deceleration
- Kreisförmiges Strafen

### 2. Item System

**Item-Struktur:**
```gdscript
# ItemDatabase.gd
var item = {
    "id": "laser_gun",
    "name": "Laser Rifle",
    "description": "Rapid fire energy weapon",
    "icon_path": "res://assets/items/laser.png",
    "icon_color": Color(0, 1, 1),
    "rarity": "common",  # common, uncommon, rare, epic
    "type": "weapon",
    "max_level": 3,  # Stackable bis Level 3
    "effects": {
        "weapon_type": "laser",
        "damage_multiplier": 1.2
    }
}
```

**Item-Kategorien:**
1. **Weapons:** Laser, Rocket, Shotgun
2. **Stat Boosts:** Speed, Damage, HP
3. **Drones:** Support, Attack, Repair
4. **Abilities:** Q/E/R Slot Items
5. **Active Items:** Time Bomb, Ghost Mode, Magnet Field, Black Hole
6. **Drugs:** Buffs mit Nebenwirkungen

**Upgrade-System:**
```gdscript
# player.gd
func upgrade_item(item_id: String, item_data) -> int:
    if not owned_items.has(item_id):
        owned_items[item_id] = 1  # Level 1
    elif owned_items[item_id] < item_data.max_level:
        owned_items[item_id] += 1  # Upgrade
    return owned_items[item_id]
```

### 3. Character System

**3 Charaktere:**

```gdscript
# CharacterSystem.gd
var CHARACTERS = {
    "soldier": {
        "name": "Soldier",
        "max_hp": 100,
        "speed": 200,
        "melee_damage": 20,
        "melee_interval": 0.5,
        "starting_weapon": "screwdriver",
        "description": "Balanced fighter"
    },
    "hacker": {
        "name": "Hacker",
        "max_hp": 80,
        "speed": 220,
        "melee_damage": 15,
        "melee_interval": 0.6,
        "starting_weapon": "wrench",
        "special_ability": "controllable_drone",
        "description": "Controls combat drone"
    },
    "tank": {
        "name": "Tank",
        "max_hp": 150,
        "speed": 150,
        "melee_damage": 30,
        "melee_interval": 0.8,
        "starting_weapon": "hammer",
        "damage_reduction": 0.15,
        "description": "High HP, slow"
    }
}
```

### 4. Weapon Progression

**Tier-System:**
```gdscript
# WeaponProgression.gd
var WEAPON_TIERS = [
    {"id": "screwdriver", "tier": 1, "damage": 20, "name": "Screwdriver"},
    {"id": "wrench", "tier": 2, "damage": 30, "name": "Wrench"},
    {"id": "pipe", "tier": 3, "damage": 45, "name": "Steel Pipe"},
    {"id": "hammer", "tier": 4, "damage": 60, "name": "Sledgehammer"},
    {"id": "chainsaw", "tier": 5, "damage": 80, "has_aoe": true, "name": "Chainsaw"},
    {"id": "plasma_cutter", "tier": 6, "damage": 120, "has_aoe": true, "name": "Plasma Cutter"}
]
```

**Upgrade-Mechanik:**
- Jede Wave: Chance auf Weapon Upgrade Item
- Linear progression durch Tiers
- Höhere Tiers haben AoE

### 5. Meta Progression

**Permanente Upgrades:**
```gdscript
# MetaProgression.gd
var META_UPGRADES = {
    "starting_hp": {
        "name": "Starting HP",
        "max_level": 5,
        "cost_per_level": [50, 100, 200, 400, 800],
        "bonus_per_level": 20
    },
    "scrap_multiplier": {
        "name": "Scrap Gain",
        "max_level": 3,
        "cost_per_level": [100, 300, 600],
        "bonus_per_level": 0.25  # +25% per level
    },
    # ... weitere Upgrades
}
```

**Scrap-System:**
- 10 Scrap pro Enemy kill (mit Multiplikator)
- Wave-Bonus beim Game Over
- Wird in `save_data.json` gespeichert

### 6. Map System

**Area-System:**
```gdscript
# MapSystem.gd
var AREAS = {
    "spawn": {"name": "Safe Zone", "difficulty": 1.0},
    "industrial": {"name": "Industrial Sector", "difficulty": 1.2},
    "danger": {"name": "Danger Zone", "difficulty": 1.5},
    "boss": {"name": "Boss Arena", "difficulty": 2.0}
}
```

**Procedurale Map-Generierung:**
- 18x18 Grid (256x256px Tiles)
- MapGenerator.gd erstellt Rooms/Corridors
- TileMap-basiert mit Navigation Mesh (optional)

**Portal-System:**
- Erscheint bei Wave-Completion
- Teleportiert zu anderer Area
- Ändert Difficulty Multiplier

### 7. Route Selection System

**3 Routes (alle 3 Waves):**
```gdscript
enum RouteModifier {
    SKYWARD_RUSH,   # Grün: Mobility (Jumppads, Teleporter)
    STORMFRONT,     # Gelb: Electric Hazards (Lightning, EMP)
    EMP_OVERLOAD    # Rot: Chaos (Tesla Coils, Random Lightning)
}
```

**Ablauf:**
1. Wave 3/6/9: Miniboss spawnt
2. Nach Miniboss-Tod: Route Selection UI
3. Spieler wählt Route → Affixes werden aktiviert
4. Nächste 3 Waves mit Route-Modifiers

**Affixes pro Route:**
```gdscript
# AffixManager.gd
var GREEN_ROUTE_AFFIXES = [
    JUMPPADS,           # Bounce Pads
    TELEPORT_PORTALS,   # Portale
    UPDRAFTS,           # Wind Boost
    SMOKE_CLOUDS        # Vision Obscuring
]

var YELLOW_ROUTE_AFFIXES = [
    SWAMP_ZONES,        # Slow Movement
    ACID_RAIN,          # Periodic Debuff
    LIGHTNING_BOLTS,    # Chain Lightning
    STATIC_FIELD        # Damage Zones
]

var RED_ROUTE_AFFIXES = [
    EMP_STORMS,         # Disable Drones
    RANDOM_LIGHTNING,   # Random Strikes
    MAGNETIC_PULSE,     # Pull Player
    TESLA_GRID          # Moving Barriers
]
```

### 8. Ability System

**Q/E/R Slot System:**
```gdscript
# AbilitySystem.gd
var equipped_abilities: Dictionary = {
    "Q": null,  # Ability ID or null
    "E": null,
    "R": null
}

func use_ability(slot: String, caster: Node) -> void:
    var ability_id = equipped_abilities.get(slot)
    if ability_id:
        _execute_ability(ability_id, caster)
```

**Ability-Beispiele:**
- **Dash:** Schneller Bewegungsschub
- **Shield:** Temporäre Invulnerability
- **Time Slow:** Slow-Motion für 3s
- **Teleport:** Instant-TP zu Mouse Position

### 9. Combat System

**Player Combat:**
- **Melee:** Automatisch alle 0.5s (alternierend links/rechts)
- **Ranged Weapons:** Auto-fire bei equipped_weapons
- **Collision Damage:** 10 DMG bei Enemy-Kontakt
- **Invulnerability:** 1s nach Damage

**Enemy Combat:**
- **Contact Damage:** 10 DMG bei Collision
- **Projektile:** Heavy Drone schießt alle 2s
- **Laser:** Sniper mit Vorwarnlinie
- **Explosion:** Kamikaze bei Tod/Kontakt

**Damage-System:**
```gdscript
func take_damage(damage: int):
    # Damage Reduction
    var final_damage = damage * (1.0 - damage_reduction)

    # Shield absorbiert zuerst
    if shield_hp > 0:
        if shield_hp >= final_damage:
            shield_hp -= int(final_damage)
            final_damage = 0
        else:
            final_damage -= shield_hp
            shield_hp = 0

    # Rest geht auf HP
    if final_damage > 0:
        current_health -= int(final_damage)
```

---

## 📝 Code-Konventionen

### GDScript Naming

```gdscript
# VARIABLEN: snake_case
var player_health: int = 100
var enemy_speed: float = 150.0

# KONSTANTEN: SCREAMING_SNAKE_CASE
const MAX_ENEMIES: int = 50
const SPAWN_DISTANCE: float = 700.0

# FUNKTIONEN: snake_case
func calculate_damage(base_damage: int) -> int:
    return base_damage

# PRIVATE FUNKTIONEN: _snake_case (underscore prefix)
func _internal_helper() -> void:
    pass

# SIGNALS: snake_case
signal health_changed(new_health: int)
signal player_died

# ENUMS: PascalCase für Enum, SCREAMING für Values
enum EnemyType {
    STANDARD,
    FAST,
    HEAVY
}

# KLASSEN: PascalCase
class_name PlayerController extends CharacterBody2D
```

### Export-Parameter

```gdscript
# Immer mit @export annotieren für Editor-Visibility
@export var speed: float = 200.0
@export var max_health: int = 100

# Gruppierung mit @export_category
@export_category("Movement")
@export var acceleration: float = 400.0
@export var deceleration: float = 600.0

@export_category("Combat")
@export var damage: int = 20
@export var attack_range: float = 90.0
```

### Signal Pattern

```gdscript
# Signal Definition (oben im Script)
signal health_changed(new_health: int)
signal died

# Signal Emitting
func take_damage(amount: int):
    current_health -= amount
    health_changed.emit(current_health)
    if current_health <= 0:
        died.emit()

# Signal Connection (in _ready oder external)
func _ready():
    player.health_changed.connect(_on_player_health_changed)
    player.died.connect(_on_player_died)

func _on_player_health_changed(new_health: int):
    health_bar.value = new_health
```

### Pooling Pattern

```gdscript
# NIEMALS queue_free() bei gepoolten Objects!
func die():
    if get_meta("is_pooled", false):
        # Deaktivieren statt freigeben
        visible = false
        process_mode = Node.PROCESS_MODE_DISABLED
        set_physics_process(false)
        global_position = Vector2(-10000, -10000)

        # Zurück zum Pool
        var game_scene = get_tree().get_first_node_in_group("game_scene")
        game_scene.call("_return_enemy_to_pool", self)
        return

    # Nur non-pooled Objects werden gefreed
    queue_free()
```

### Await Pattern

```gdscript
# IMMER Safety-Check nach await!
func attack_animation():
    modulate = Color(2, 2, 2)
    await get_tree().create_timer(0.5).timeout

    # Safety check!
    if is_queued_for_deletion() or not is_instance_valid(self):
        return

    modulate = Color.WHITE
```

### Metadata Usage

```gdscript
# Metadata für dynamische Properties
enemy.set_meta("is_kamikaze", true)
enemy.set_meta("explosion_radius", 150.0)

# Prüfen mit Fallback
if enemy.get_meta("is_sniper", false):
    # Sniper behavior
```

---

## 🚀 Feature Development

### Neues Item hinzufügen

**1. Item zu Database hinzufügen:**
```gdscript
# scripts/singletons/ItemDatabase.gd
func _define_items():
    items["new_item_id"] = {
        "id": "new_item_id",
        "name": "New Item",
        "description": "Does something cool",
        "icon_path": "res://assets/items/new_item.png",
        "icon_color": Color(1, 0.5, 0),
        "rarity": "uncommon",
        "type": "stat_boost",
        "max_level": 3,
        "effects": {
            "speed_multiplier": 1.15,  # +15% Speed
            "custom_effect": true
        }
    }
```

**2. Effekt implementieren:**
```gdscript
# scripts/game.gd → _apply_item_effects()
func _apply_item_effects(item):
    for effect_name in item.effects:
        var value = item.effects[effect_name]

        match effect_name:
            "speed_multiplier":
                player.speed *= value
            "custom_effect":
                _handle_custom_effect(item)
```

**3. Icon erstellen:**
- 64x64 PNG in `assets/items/`
- Oder: icon_color als Fallback

### Neuen Enemy-Typ erstellen

**1. Setup-Funktion in game.gd:**
```gdscript
func _setup_new_drone_type(enemy: CharacterBody2D) -> void:
    enemy.enemy_color = Color(1.0, 0.0, 1.0)  # Magenta
    enemy.enemy_size = 1.2
    enemy.max_health = 200
    enemy.min_speed = 120.0
    enemy.max_speed = 140.0
    enemy.score_value = 40

    # Custom metadata
    enemy.set_meta("custom_ability", true)
```

**2. Behavior-Funktion in enemy.gd:**
```gdscript
func _custom_behavior():
    # Custom AI logic
    var distance = global_position.distance_to(player.global_position)
    # ... implementation
```

**3. Spawn in _create_random_enemy_type():**
```gdscript
elif roll < 0.95:
    _setup_new_drone_type(enemy)
```

### Neue Ability hinzufügen

**1. Ability Definition:**
```gdscript
# scripts/singletons/AbilitySystem.gd
var ABILITIES = {
    "new_ability": {
        "name": "New Ability",
        "cooldown": 10.0,
        "description": "Does cool stuff",
        "icon_path": "res://assets/abilities/new_ability.png"
    }
}
```

**2. Execution Logic:**
```gdscript
func _execute_ability(ability_id: String, caster: Node):
    match ability_id:
        "new_ability":
            _use_new_ability(caster)

func _use_new_ability(caster):
    print("New Ability activated!")
    # Implementation
```

**3. Item zum Freischalten:**
```gdscript
# ItemDatabase.gd
"ability_unlock_new": {
    "effects": {
        "unlock_ability": "new_ability",
        "ability_slot": "Q"
    }
}
```

### Neue Route-Affixes

**1. Affix-Enum erweitern:**
```gdscript
# AffixManager.gd
enum AffixType {
    # ... existing
    NEW_AFFIX  # Neue Entry
}
```

**2. Init-Funktion:**
```gdscript
func _init_new_affix() -> void:
    # Spawn Nodes, setup logic
    var container = Node2D.new()
    container.name = "NewAffix"
    # ... implementation
    game_scene.add_child(container)
    affix_nodes[AffixType.NEW_AFFIX] = container
```

**3. Zu Route-Pool hinzufügen:**
```gdscript
var GREEN_ROUTE_AFFIXES = [
    AffixType.JUMPPADS,
    AffixType.NEW_AFFIX  # Add here
]
```

---

## 📚 API Referenz

### GameManager (Singleton)

```gdscript
# State
var score: int
var wave_count: int
var is_paused: bool
var is_game_over: bool
var current_route: int

# Methods
func add_score(amount: int)
func reset_game()
func toggle_pause()
func trigger_game_over()
func get_player() -> CharacterBody2D

# Signals
signal score_changed(new_score: int)
signal game_over
signal wave_completed(wave_number: int)
signal route_selected(route: int)
```

### ItemDatabase (Singleton)

```gdscript
# Methods
func get_item_by_id(id: String) -> Dictionary
func get_random_items(count: int) -> Array
func get_items_by_rarity(rarity: String) -> Array
func get_items_by_type(type: String) -> Array

# Rarities
"common", "uncommon", "rare", "epic"

# Types
"weapon", "stat_boost", "drone", "ability", "active", "drug"
```

### Player (CharacterBody2D)

```gdscript
# Properties
var current_health: int
var max_health: int
var speed: float
var melee_damage: int
var invulnerable: bool
var equipped_weapons: Array

# Methods
func take_damage(damage: int)
func heal(amount: int)
func add_weapon(weapon_type: String)
func perform_melee_attack()

# Signals
signal health_changed(new_health: int)
signal died
```

### Enemy (CharacterBody2D)

```gdscript
# Properties
var current_health: int
var max_health: int
var current_speed: float
var enemy_color: Color
var enemy_size: float

# Methods
func take_damage(damage: int)
func die()

# Metadata Keys
"is_pooled", "is_kamikaze", "is_sniper", "is_miniboss",
"explosion_damage", "explosion_radius", "attack_range"
```

### MapSystem (Singleton)

```gdscript
# Methods
func get_difficulty_multiplier() -> float
func complete_wave()
func create_portal_visual(scene: Node, position: Vector2)

# Signals
signal area_changed(area: Dictionary)
signal portal_appeared(position: Vector2)
```

### AudioManager (Singleton)

```gdscript
# Methods
func play_damage_sound()
func play_big_damage_sound()
func play_death_sound()
func play_enemy_death_sound()
func play_explosion_sound()
func play_ability_sound()
func play_game_over_sound()
func play_boss_rage_sound()
func play_portal_spawn_sound()
```

---

## ⚠️ Known Issues & TODOs

### Performance

**Bottlenecks:**
- [ ] **Enemy Pooling:** 30 Enemies, könnte auf 50 erhöht werden
- [ ] **RayCast Overhead:** ImprovedEnemy mit 5 RayCasts pro Enemy (150 checks bei 30 Enemies)
- [ ] **Tween Cleanup:** AffixManager erstellt viele Tweens (jetzt getrackt, aber Performance?)

**Optimierungen:**
- [x] Enemy Pooling implementiert
- [x] Object Pooling für Projectiles (TODO)
- [ ] NavigationMesh baken für bessere Pfadfindung
- [ ] RayCast-Checks nur alle N Frames

### Fehlende Features

**High Priority:**
- [ ] **Boss Fight Improvement:** Boss AI ist zu simpel
- [ ] **More Sound Effects:** Mehr Variety in Sounds
- [ ] **Background Music:** Nur 5 Tracks, mehr benötigt
- [ ] **Tutorial:** Kein Ingame-Tutorial
- [ ] **Controller Support:** Nur Keyboard+Mouse

**Medium Priority:**
- [ ] **Achievement System:** Keine Achievements
- [ ] **Leaderboard:** Kein Online-Leaderboard
- [ ] **More Enemies:** Nur 5 Typen + Boss
- [ ] **More Bosses:** Nur 1 Boss-Typ
- [ ] **More Abilities:** Nur ~10 Abilities

**Low Priority:**
- [ ] **Multiplayer:** Co-Op wäre cool
- [ ] **Mobile Port:** Touch Controls
- [ ] **Mod Support:** Custom Items/Enemies

### Bug Tracking

**Known Bugs:**
- [ ] **Enemy Stuck:** Manchmal bleiben Enemies an Wänden hängen (ImprovedEnemy sollte lösen)
- [ ] **Portal Z-Fighting:** Portale manchmal unter Tiles
- [ ] **Audio Overlap:** Zu viele simultane Sounds → Clipping
- [ ] **Memory Leak:** Tweens in AffixManager (FIXED in recent commit)

---

## 💡 Design Philosophie

### Balance-Prinzipien

1. **Power Fantasy:** Spieler sollte sich stark fühlen
2. **Fair Challenge:** Schwer aber fair, kein unfaires Instant-Death
3. **Build Variety:** Viele viable Item-Kombinationen
4. **Risk/Reward:** Rote Route schwerer aber bessere Rewards
5. **Short Runs:** 10-15 Min pro Run optimal

### Meta-Progression

- **Nicht Pay-to-Win:** Meta-Upgrades helfen, aber Skill wichtiger
- **Sinnvolle Upgrades:** Jedes Upgrade spürbar
- **Keine Grind-Wall:** Scrap-Gain fair balanced

### Item-Design

- **Clear Description:** Jedes Item erklärt was es tut
- **Visual Feedback:** Items haben sichtbare Effekte
- **Synergien:** Items kombinieren sich interessant
- **No Trap Choices:** Keine komplett nutzlosen Items

---

## 🔮 Zukünftige Features (Roadmap)

### Version 1.1 (Next)
- [ ] ImprovedEnemy als Standard-Enemy
- [ ] NavigationRegion2D Setup
- [ ] Boss-Fight Verbesserungen
- [ ] 20+ neue Items
- [ ] Controller Support

### Version 1.2
- [ ] Achievement System
- [ ] 3 neue Enemy-Typen
- [ ] 2 neue Boss-Typen
- [ ] More Music Tracks
- [ ] In-Game Tutorial

### Version 2.0 (Future)
- [ ] Co-Op Multiplayer
- [ ] New Game+ Mode
- [ ] Daily Challenges
- [ ] Mod Support
- [ ] Steam Workshop Integration

---

## 📊 File Size Overview

```
Total Project Size: ~150 MB

Breakdown:
- Scripts:  ~500 KB (GDScript text files)
- Scenes:   ~2 MB (.tscn files)
- Sprites:  ~50 MB (PNG assets)
- Tiles:    ~30 MB (TileSet textures)
- Sounds:   ~40 MB (WAV/OGG files)
- Music:    ~30 MB (OGG files)
```

---

## 🛠️ Development Workflow

### Testing

```bash
# Godot öffnen
godot project.godot

# Direkter Play
godot --path . scenes/MainMenu.tscn

# Headless test (ohne GUI)
godot --headless --quit-after 10
```

### Debugging

**Print Debugging:**
```gdscript
print("Debug: ", variable)
print("Position: ", global_position)
```

**Breakpoints:**
- Godot Editor: Click auf Zeilen-Nummer

**Remote Debugging:**
- Debug → Deploy with Remote Debug

### Git Workflow (falls verwendet)

```bash
# Feature Branch
git checkout -b feature/new-enemy-type

# Commit
git add scripts/enemy.gd
git commit -m "Add teleporter enemy type"

# Merge
git checkout main
git merge feature/new-enemy-type
```

---

## 📞 Quick Reference

### Layer-Mask-Bits

```
Layer 1 (0001): Player
Layer 2 (0010): Enemy
Layer 3 (0100): Walls/Obstacles
Layer 4 (1000): Boundary
```

### Common Collision Masks

```gdscript
# Player
collision_layer = 1
collision_mask = 14  # Enemy (2) + Walls (4) + Boundary (8)

# Enemy
collision_layer = 2
collision_mask = 13  # Player (1) + Walls (4) + Boundary (8)

# Projectile
collision_layer = 0
collision_mask = 2   # Enemy only
```

### Input Actions

```
move_up: W / ArrowUp
move_down: S / ArrowDown
move_left: A / ArrowLeft
move_right: D / ArrowRight

ability_q: Q
ability_e: E
ability_r: R

pause: Escape
ui_accept: Space (für Menüs)
```

---

**Ende des Dokuments**

> Für Feature-Entwicklung in Perplexity Space: Dieser Context enthält alle wichtigen Informationen über Architektur, Systeme, Konventionen und APIs. Bei Fragen zu spezifischen Implementierungen siehe entsprechende Script-Dateien im `scripts/` Ordner.
