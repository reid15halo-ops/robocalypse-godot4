# Robocalypse Development Quick Reference

Schnelle Referenz für häufige Entwicklungsaufgaben.

---

## 🎮 Häufige Aufgaben

### Neuen Gegner hinzufügen

**1. Datei erstellen:** `scripts/enemy_types/mein_gegner.gd`
```gdscript
extends "res://scripts/enemy.gd"

func _ready() -> void:
    super._ready()
    max_health = 200
    min_speed = 100.0
    max_speed = 150.0
    score_value = 15
    enemy_color = Color(0.5, 1.0, 0.5)  # Grün
    enemy_size = 1.0
```

**2. In game.gd hinzufügen:**
```gdscript
var mein_gegner_scene = preload("res://scripts/enemy_types/mein_gegner.gd")
```

**3. Spawning-Logik erweitern** (in `_spawn_enemy()` Funktion)

---

### Neues Item hinzufügen

**1. In ItemDatabase definieren:**
```gdscript
"mein_item": {
    "name": "Mein Item",
    "description": "Was es macht",
    "icon": "res://assets/icons/item.png",
    "tier": 1,
    "max_level": 3,
    "base_cost": 300,
    "cost_scaling": 1.5,
    "effects": {"stat": [10, 20, 30]}
}
```

**2. In player.gd implementieren:**
```gdscript
if item_id == "mein_item":
    match level:
        1: max_health += 10
        2: max_health += 20
        3: max_health += 30
```

**3. Zu Shop hinzufügen** (in_game_shop.gd)

---

### Neue Fähigkeit hinzufügen

**1. In ability_system.gd:**
```gdscript
var ability = AbilityData.new(
    "id", "Name", "Beschreibung",
    "Q",  # Taste
    10.0, # Cooldown
    30,   # Mana-Kosten
    "typ",
    {"param": value}
)
```

**2. In player.gd:**
```gdscript
if Input.is_action_just_pressed("ability_q"):
    if AbilitySystem.can_use_ability("Q"):
        _meine_faehigkeit()
        AbilitySystem.use_ability("Q")
```

---

## 🔧 Debugging

### Collision funktioniert nicht?

**Prüfen:**
```gdscript
print("Layer: ", collision_layer)  # Auf welchem Layer bin ich?
print("Mask: ", collision_mask)    # Mit welchen Layern kollidiere ich?
```

**Richtige Werte:**
- **Player:** `collision_layer = 1`, `collision_mask = 14` (2+4+8)
- **Enemy:** `collision_layer = 2`, `collision_mask = 14`
- **Walls:** `collision_layer = 4`, `collision_mask = 3` (1+2)

### Signal wird nicht ausgelöst?

**Checkliste:**
1. ✓ Signal deklariert? `signal mein_signal(param)`
2. ✓ Verbindung korrekt? `node.mein_signal.connect(_on_signal)`
3. ✓ Signal emittiert? `mein_signal.emit(value)`
4. ✓ Node existiert? `if node != null:`

### Null Reference Error?

**Fix:**
```gdscript
# Vor Zugriff prüfen
if node == null:
    return

# Oder optional holen
var node = get_node_or_null("Path/To/Node")
if node:
    node.do_something()
```

---

## 📊 Wichtige Systeme

### GameManager (Global State)
```gdscript
GameManager.get_player()           # Spieler-Referenz
GameManager.add_score(100)         # Score erhöhen
GameManager.is_game_over           # Game Over Check
GameManager.score                  # Aktueller Score
```

### SaveManager (Persistenz)
```gdscript
SaveManager.add_scrap(50)          # Scrap hinzufügen
SaveManager.get_scrap()            # Scrap abfragen
SaveManager.set_upgrade_level("id", 5)  # Upgrade setzen
SaveManager.save_game()            # Speichern
```

### AudioManager (Sound)
```gdscript
AudioManager.play_sound("oof")          # Spieler Schaden
AudioManager.play_sound("metal_pipe")   # Gegner Tod
AudioManager.play_sound("vine_boom")    # Boss Spawn
AudioManager.set_volume(0.7)            # Lautstärke 70%
```

### ItemDatabase (Items)
```gdscript
ItemDatabase.get_item("item_id")   # Item-Daten holen
ItemDatabase.get_all_items()       # Alle Items
```

### CharacterSystem (Charaktere)
```gdscript
CharacterSystem.select_character("hacker")
CharacterSystem.get_current_character()
CharacterSystem.apply_character_to_player(player)
```

---

## 🎯 Collision Layer System

```
Layer 1: Player      → Spieler
Layer 2: Enemy       → Alle Gegner
Layer 3: Walls       → Wände/Grenzen
Layer 4: Items       → Pickups, Scrap
Layer 5: Projectiles → Geschosse
```

**Mask Berechnung:**
- Layer 1+2+3 = 1+2+4 = 7
- Layer 2+3+4 = 2+4+8 = 14
- Layer 1+2 = 1+2 = 3

---

## 🧪 Testing

### Script validieren
```bash
"C:\Users\reid1\Documents\Godot_v4.5-stable_win64_console.exe" --headless --path "." --script scripts/mein_script.gd --check-only --quit-after 3
```

### Headless Mode ausführen
```bash
"C:\Users\reid1\Documents\Godot_v4.5-stable_win64_console.exe" --headless --path "." --quit-after 10
```

### Editor öffnen
```bash
"C:\Users\reid1\Documents\Godot_v4.5-stable_win64.exe" --path "."
```

---

## 📁 Wichtige Dateien

### Core Scripts
- `scripts/GameManager.gd` → Globaler State
- `scripts/game.gd` → Main Game Loop
- `scripts/player.gd` → Spieler-Controller
- `scripts/enemy.gd` → Basis-Gegner-Klasse

### Systeme
- `scripts/ability_system.gd` → QWER Fähigkeiten
- `scripts/item_database.gd` → Item-Definitionen
- `scripts/save_manager.gd` → Speichern/Laden
- `scripts/character_system.gd` → 3 Charaktere

### Enemy Types
- `scripts/enemy_types/weak_drone.gd`
- `scripts/enemy_types/kamikaze_drone.gd`
- `scripts/enemy_types/tank_robot.gd`
- `scripts/enemy_types/rusher.gd`

### Scenes
- `scenes/MainMenu.tscn` → Hauptmenü
- `scenes/CharacterSelect.tscn` → Charakter-Auswahl
- `scenes/Game.tscn` → Hauptspiel
- `scenes/Player.tscn` → Spieler-Szene

---

## 🔥 Performance-Tipps

### Enemy Pooling verwenden
```gdscript
# ❌ FALSCH - Nicht so:
var enemy = enemy_scene.instantiate()
add_child(enemy)

# ✅ RICHTIG - Pool verwenden:
var enemy = get_from_enemy_pool()
enemy.visible = true
enemy.global_position = spawn_pos
```

### Projektile aufräumen
```gdscript
func _physics_process(delta: float) -> void:
    # Projektil außerhalb des Bildschirms?
    if global_position.length() > 2000:
        queue_free()
```

### Delta-Time verwenden
```gdscript
# ❌ FALSCH:
position.x += 100

# ✅ RICHTIG:
position.x += 100 * delta
```

---

## 📝 Dokumentations-Checkliste

Nach Feature/Fix:

- [ ] Code kommentiert?
- [ ] BUGFIXES.md aktualisiert?
- [ ] Getestet (headless mode)?
- [ ] Balance-Werte dokumentiert?
- [ ] Breaking Changes in CLAUDE.md?

Format für BUGFIXES.md:
```markdown
### X. **Feature-Name** ✓
**Problem:** Was war das Problem
**Fix:** Was wurde geändert
**Location:** scripts/datei.gd
```

---

## 🆘 Häufige Fehler

### "Invalid get index on base: 'null instance'"
→ Node existiert nicht, null-check hinzufügen

### "Attempt to call function 'X' in base 'null instance'"
→ Referenz ist null, mit `get_node_or_null()` prüfen

### "body->get_space(): Condition 'ERR_FAIL_COND_V...'"
→ Node wurde freed aber wird noch verwendet, `is_instance_valid()` prüfen

### "Invalid type in function 'X'"
→ Falscher Typ übergeben, Type-Hints prüfen

### Spieler fällt durch Boden
→ Collision Layer/Mask prüfen, Boden muss Layer 3 haben

### Gegner spawnen nicht
→ Enemy Pool voll? Spawn-Logik prüfen, Timer korrekt?

---

## 🎨 Visuelle Unterscheidung

### Gegner-Farben
```gdscript
enemy_color = Color(R, G, B)
```

**Beispiele:**
- Rot: `Color(2.0, 0.2, 0.2)` - Kamikaze
- Grün: `Color(0.5, 1.5, 0.5)` - Weak Drone
- Cyan: `Color(0.2, 1.8, 1.8)` - Support (Speed)
- Orange: `Color(1.8, 0.5, 0)` - Support (Damage)
- Gelb: `Color(1.5, 1.0, 0)` - Rusher
- Grau: `Color(0.3, 0.3, 0.3)` - Tank

### Gegner-Größen
```gdscript
enemy_size = 1.5  # 150% normal size
```

**Beispiele:**
- Klein (0.6-0.7): Weak, Rusher
- Normal (0.9-1.2): Standard, Kamikaze, Support
- Groß (1.5-1.8): Tank, Boss

---

## 💡 Best Practices

1. **Immer typed GDScript verwenden**
   ```gdscript
   var health: int = 100
   func get_damage() -> int:
   ```

2. **@onready für Node-Referenzen**
   ```gdscript
   @onready var sprite = $Sprite2D
   ```

3. **Super-Calls bei Vererbung**
   ```gdscript
   func _ready() -> void:
       super._ready()
       # Mein Code
   ```

4. **Null-Checks vor Zugriff**
   ```gdscript
   if player and is_instance_valid(player):
       player.take_damage(10)
   ```

5. **Signals statt direkte Aufrufe**
   ```gdscript
   signal health_changed(new_health: int)
   health_changed.emit(current_health)
   ```

---

## 🔗 Weitere Dokumentation

- **CLAUDE.md** → Vollständige Architektur-Übersicht
- **BUGFIXES.md** → Alle bisherigen Fixes und Features
- **AGENTS.md** → Coding-Standards und Build-Commands
- **ROBOCALYPSE_DEV_AGENT.md** → Detaillierte Agent-Workflows

---

**Version:** 1.0
**Letztes Update:** 2025-01-20
**Godot Version:** 4.5
