# ImprovedEnemy - Advanced AI System

## 🎯 Überblick

Das neue **ImprovedEnemy** System bietet eine vollständig überarbeitete KI mit:

- ✅ **Zustandsmaschine** mit 5 States (IDLE, PATROLLING, CHASING, ATTACKING, WALL_AVOIDING)
- ✅ **NavigationAgent2D** für intelligente Pfadfindung
- ✅ **5 RayCast2D Nodes** für Wanddetektion (360° Coverage)
- ✅ **Glattes Beschleunigungs-/Bremssystem** (acceleration/deceleration)
- ✅ **Kreisförmiges Strafen** im Angriffsmodus
- ✅ **Kompatibel mit Enemy Pooling System**
- ✅ **Alle 5 Drohnen-Typen** werden unterstützt

## 📁 Neue Dateien

```
scripts/improved_enemy.gd       - Hauptskript mit State Machine
scenes/ImprovedEnemy.tscn       - Scene mit NavigationAgent2D und RayCasts
```

## 🔧 Integration in game.gd

### Option 1: Komplett ersetzen (Breaking Change)

```gdscript
# In game.gd _ready():
var enemy_scene = preload("res://scenes/ImprovedEnemy.tscn")
```

### Option 2: Parallel testen (Empfohlen)

```gdscript
# In game.gd - neue Variable hinzufügen:
var improved_enemy_scene = preload("res://scenes/ImprovedEnemy.tscn")

# Neue Test-Funktion:
func spawn_improved_enemy() -> void:
    var enemy = improved_enemy_scene.instantiate()
    var angle = randf() * TAU
    var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * spawn_distance
    enemy.global_position = spawn_pos
    add_child(enemy)

# Zum Testen im _process():
if Input.is_action_just_pressed("ui_accept"):  # Spacebar
    spawn_improved_enemy()
```

### Option 3: Schrittweise Migration

```gdscript
# 50% Chance für ImprovedEnemy, 50% für normalen Enemy:
func spawn_enemy():
    var enemy
    if randf() > 0.5:
        enemy = improved_enemy_scene.instantiate()
    else:
        enemy = enemy_scene.instantiate()
    # ... rest of spawning code
```

## 🎮 State Machine Erklärung

### 1. IDLE
- **Trigger:** Kein Spieler in aggro_range (600px)
- **Verhalten:** Steht still, decelerated zu 0
- **Transition:** → PATROLLING nach 2s, → CHASING wenn Spieler näher

### 2. PATROLLING
- **Trigger:** 2s im IDLE state
- **Verhalten:** Bewegt sich zu zufälligen Punkten im patrol_radius (300px)
- **Transition:** → CHASING wenn Spieler in aggro_range

### 3. CHASING
- **Trigger:** Spieler in aggro_range (600px)
- **Verhalten:** Verfolgt Spieler mit NavigationAgent2D
- **Transition:** → ATTACKING bei attack_range (200px), → IDLE wenn zu weit

### 4. ATTACKING
- **Trigger:** Spieler in attack_range (200px)
- **Verhalten:** Kreisförmiges Strafen + typ-spezifische Angriffe
- **Transition:** → CHASING wenn zu weit

### 5. WALL_AVOIDING
- **Trigger:** RayCast detektiert Wand
- **Verhalten:** Bewegt sich weg von Kollisionen
- **Priorität:** Höchste (überschreibt alle anderen States)

## 🤖 Drohnen-Typ Unterstützung

### Standard (Rot)
- Einfaches Chasing/Attacking Verhalten
- Standardgeschwindigkeit

### Fast Drone (Cyan)
- **Dash Attack:** Alle 3s Boost auf 2.5x Speed
- Höhere Basisgeschwindigkeit

### Heavy Drone (Braun)
- **Projectile Shooting:** Alle 2s im ATTACKING state
- Langsamer, aber stärker

### Kamikaze (Orange)
- **Beschleunigung:** Bei < 150px Distanz 2x Speed
- **Explosion:** Bei Kontakt (40px) oder Tod

### Sniper (Grün)
- **Distanz halten:** Bleibt 300-500px vom Spieler entfernt
- **Laser Attack:** Alle 3s mit Vorwarnlinie

## 🔍 RayCast Configuration

Alle 5 RayCasts haben:
- **collision_mask = 12** (Walls Layer 4 + Boundary Layer 8)
- **target_position:** 100px in jeweilige Richtung
- **hit_from_inside = true**

Layout:
```
        Left90 (-90°)
            |
    Left45  |  Right45
       \    |    /
        \   |   /
   ------Forward------
            |
        Right90 (+90°)
```

## ⚙️ Export-Parameter

```gdscript
# Bewegung
min_speed: 100.0          # Minimale Geschwindigkeit
max_speed: 150.0          # Maximale Geschwindigkeit
acceleration: 400.0       # Beschleunigung (px/s²)
deceleration: 600.0       # Abbremsung (px/s²)

# AI Verhalten
aggro_range: 600.0        # Reichweite für CHASING
attack_range: 200.0       # Reichweite für ATTACKING
patrol_radius: 300.0      # Patrol-Bereich um Spawn-Position

# Gesundheit
max_health: 100           # Maximale HP (mit area scaling)

# Visuals
enemy_color: Color(1,0.2,0.2)  # Drohnenfarbe
enemy_size: 1.0                 # Skalierungsfaktor
has_pulse_animation: true       # Pulsierendes Skalieren
has_rotation_animation: true    # Rotation
```

## 🧪 Testing Checklist

### Basis-Tests
- [ ] Enemy spawnt korrekt
- [ ] IDLE State: Steht still
- [ ] PATROLLING: Bewegt sich zufällig
- [ ] CHASING: Verfolgt Spieler
- [ ] ATTACKING: Kreisförmiges Strafen funktioniert
- [ ] WALL_AVOIDING: Weicht Wänden aus

### Drohnen-Typ Tests
- [ ] Standard: Normales Verhalten
- [ ] Fast: Dash Attack funktioniert
- [ ] Heavy: Schießt Projektile
- [ ] Kamikaze: Beschleunigt und explodiert
- [ ] Sniper: Hält Distanz und schießt Laser

### Pooling Tests
- [ ] Enemy wird korrekt gepoolt
- [ ] `_return_enemy_to_pool()` wird aufgerufen
- [ ] Keine Fehler beim Respawn

### Performance Tests
- [ ] 30+ Enemies spawnen ohne Lag
- [ ] RayCasts verursachen keine Performance-Probleme
- [ ] NavigationAgent2D funktioniert mit mehreren Enemies

## ⚠️ Bekannte Limitierungen

### 1. NavigationAgent2D benötigt Navigation Mesh
**Problem:** GameMap.tscn hat aktuell kein NavigationRegion2D Setup.

**Lösung:** Script hat Fallback zu direkter Bewegung wenn nav_agent null ist.

**Bessere Lösung:** NavigationRegion2D zu GameMap.tscn hinzufügen:
1. GameMap.tscn im Editor öffnen
2. NavigationRegion2D Node hinzufügen
3. TileMapLayer mit Physics Layer markieren
4. "Bake NavigationPolygon" ausführen

### 2. RayCast Performance
**Problem:** 5 RayCasts × 30 Enemies = 150 RayCast Checks pro Frame

**Lösung 1:** RayCasts nur alle N Frames updaten (bereits optimiert)
**Lösung 2:** Enemy Pooling reduziert aktive Enemies

### 3. State Machine Komplexität
**Problem:** Mehr Code = mehr potenzielle Bugs

**Lösung:** Ausführliche Tests mit allen Drohnen-Typen durchführen

## 🔄 Rollback Plan

Falls Probleme auftreten:

```gdscript
# Zurück zum alten System:
var enemy_scene = preload("res://scenes/Enemy.tscn")

# ImprovedEnemy Dateien löschen (optional):
# - scripts/improved_enemy.gd
# - scenes/ImprovedEnemy.tscn
```

## 📊 Vergleich: Old vs New

| Feature | Old Enemy | ImprovedEnemy |
|---------|-----------|---------------|
| **Bewegung** | Direkte Velocity | State Machine + Navigation |
| **Wandvermeidung** | Keine | 5 RayCasts + Avoidance Logic |
| **Pfadfindung** | Direkt zum Ziel | NavigationAgent2D |
| **Beschleunigung** | Instant | Smooth (acceleration/deceleration) |
| **AI States** | Keine | 5 States (IDLE, PATROL, CHASE, ATTACK, AVOID) |
| **Strafen** | Nur Sniper | Alle im ATTACKING state |
| **Pooling** | ✅ | ✅ |
| **Performance** | Leichter | Etwas schwerer (RayCasts) |

## 🎯 Nächste Schritte

1. **Testen** mit verschiedenen Drohnen-Typen
2. **NavigationRegion2D** zu GameMap hinzufügen
3. **Performance profiling** mit 50+ Enemies
4. **Feintuning** der State Machine Parameter
5. **Optional:** Weitere AI-Features (Formation Flying, Cooperation, etc.)

## 💡 Erweiterungsmöglichkeiten

### Kurzzeitig:
- [ ] **Cooperative AI:** Enemies koordinieren Angriffe
- [ ] **Formation Flying:** Gruppen bewegen sich in Formation
- [ ] **Dynamic Difficulty:** Passt aggro_range/attack_range basierend auf Player HP an

### Langfristig:
- [ ] **Behavior Trees:** Noch flexibleres AI-System
- [ ] **Machine Learning:** AI lernt Spieler-Verhalten
- [ ] **Squad System:** Leader + Follower Hierarchie

---

**Created:** 2025-01-11
**Author:** Claude Code
**Version:** 1.0.0
