# **ROBOCALYPSE - Godot 4 Game Development Prompt**

## **Quick Summary**
2D Top-Down Survival Shooter in Godot 4 inspired by Brotato. Play as a Hacker fighting robot waves in a post-apocalyptic arena with item upgrades, pet system, and wave-based progression.

---

## **🔴 CRITICAL PRIORITY #1: Fixed Playfield Boundaries**

**IMPLEMENT THIS FIRST!**

```gdscript
# In Game.tscn:
# Add StaticBody2D node named "Boundary"
#   → Add CollisionShape2D child
#   → Use RectangleShape2D covering playfield perimeter
#   → Set collision_layer = 4 (Boundary layer)

# Player setup (player.gd):
collision_layer = 1   # Layer 1: Player
collision_mask = 6    # Collides with Enemy (2) + Boundary (4)

# Enemy setup (enemy.gd):
collision_layer = 2   # Layer 2: Enemy
collision_mask = 5    # Collides with Player (1) + Boundary (4)

# Result: Neither player nor enemies can leave the arena!
```

---

## **Core Gameplay Loop**

### **Wave System (Brotato-Style)**
1. **Combat Phase** (60s): Survive enemy waves
2. **Break Phase**: Choose 3-4 random item upgrades
3. **Repeat**: Difficulty increases each wave
4. **Boss Wave**: Every 5-10 waves

### **Player (Hacker)**
- **Type**: CharacterBody2D (human, not robot)
- **Controls**: WASD/Arrow keys
- **Speed**: 200 px/s
- **HP**: 100 starting
- **Combat**: Melee (alternating punches) OR ranged weapons

### **Hacker Special Abilities**
- **Pet System**: Start each round with 1 hacked enemy robot as ally
- **Damage Bonus**: +25% vs robots
- **Firewall**: Press F for temporary invulnerability shield (15s cooldown, 5s duration)

---

## **Enemy System**

### **Standard Robots**
- **Scout Robots**: Fast (150 px/s), low HP
- **Combat Droids**: Medium speed (100 px/s), standard HP
- **Heavy Mechs**: Slow (75 px/s), high HP

**AI Behavior:**
- CharacterBody2D with move_and_slide()
- Pursue nearest target (player OR pet)
- Spawn at random screen edges
- Max 7 on field simultaneously

### **Boss Robots** (Phase 4)
- Special attack patterns
- Minion spawning
- Weakness mechanics
- Epic loot

### **Terminals** (Neutral Objects)
- Stationary structures
- 5 HP, destructible
- Drop **Medikits** (heal 25% max HP)

---

## **Item & Upgrade System** (Brotato-Style)

### **Item Categories**

**Weapons:**
- Laser Gun, Rocket Launcher, Shotgun
- Auto-turrets, Combat drones

**Defensive:**
- Energy Shield, Armor plating, HP regen

**Support:**
- Attack Drone, Shield Drone, Repair Drone, Scanner Drone
- Hack Module (convert enemies mid-game)

**Stats:**
- Movement speed, Attack damage, Fire rate, Crit chance

### **Item Synergies**
- Stack items for combo effects
- Example: 3x Speed = Unlock Dash ability
- Discover optimal builds

### **Currency**
- **XP**: 10 per enemy kill
- **Scrap**: Drops from enemies, used for meta-progression

---

## **Pet/Drone System**

### **Hacker Pet** (Start of Round)
- Convert 1 random enemy into ally
- Pet has same stats as original enemy
- Follows player (stays within 100px)
- Auto-attacks nearest enemy (0.75x damage)
- Can die from enemy damage

### **Support Drones** (Items)
- **Attack Drone**: Shoots enemies
- **Shield Drone**: Absorbs damage
- **Repair Drone**: Heals player
- **Scanner Drone**: Reveals hidden items/enemies

---

## **UI System**

### **HUD**
- Health bar (top left)
- XP/Score (top left)
- Scrap count (top right)
- Wave timer (top center)
- Firewall cooldown (bottom)

### **Menus**
- Main Menu: Start, Settings, Exit
- Character Select: Hacker, Technician, Soldier
- Pause Menu: ESC key
- Game Over: Final score, Restart, Quit
- **Between-Wave Shop**: Select 3-4 items

---

## **Technical Specs (Godot 4)**

### **Project Setup**
- **Engine**: Godot 4.3+
- **Resolution**: 1280x720
- **Physics Layers**:
  1. Player
  2. Enemy
  3. Boundary

### **Required Godot 4 Syntax**
```gdscript
# Signals
signal health_changed(new_health: int)
player.health_changed.connect(_on_health_changed)

# Movement
velocity = input_direction * speed
move_and_slide()  # NO parameters in Godot 4!

# Collision check
for i in get_slide_collision_count():
    var collision = get_slide_collision(i)
    var collider = collision.get_collider()
```

### **Scene Structure**
```
scenes/
  ├── MainMenu.tscn
  ├── Game.tscn (with Boundary StaticBody2D!)
  ├── Player.tscn
  ├── Enemy.tscn
  └── Boss.tscn

scripts/
  ├── GameManager.gd (Autoload)
  ├── player.gd
  ├── enemy.gd
  ├── game.gd
  ├── item_system.gd
  └── pet_system.gd
```

---

## **Development Roadmap**

### **✅ Already Done**
- Godot 4 project setup
- Player/Enemy movement
- Basic combat
- Health/Score UI
- GameManager singleton
- Character selection
- Pet system
- Terminals + Medikits
- Firewall ability

### **❌ To Do (Prioritized)**

**Phase 1: CRITICAL** ⚠️
1. Implement fixed playfield boundaries (StaticBody2D)
2. Fix melee attack hitbox (currently not hitting enemies consistently)
3. Test boundary collision for player + enemies

**Phase 2: HIGH**
1. Between-wave pause screen
2. Item selection UI (3-4 random items)
3. Item database (at least 10 items)
4. Apply item effects to player stats
5. Difficulty scaling per wave

**Phase 3: MEDIUM**
1. Support drone items
2. Item synergy system
3. Boss enemy type
4. Boss fight mechanics

**Phase 4: LOW**
1. Meta-progression (persistent upgrades)
2. Achievement system
3. Visual/audio polish
4. Particle effects

---

## **Key Design Goals**

1. **"One More Round" Addiction**: Fast 5-10 min runs
2. **Brotato-Style Items**: Focus on synergies & builds
3. **Trash Aesthetic**: Absurd, humorous, colorful
4. **Easy Controls, Deep Strategy**: Simple WASD, complex item choices
5. **Performance**: Must handle 100+ entities smoothly

---

## **Known Issues to Fix**

1. **Melee Attack**: Hitbox not reliably hitting enemies
   - Current: Small hitbox, offset positioning
   - Fix: Increase MELEE_RANGE, improve collision detection

2. **No Boundaries**: Player/enemies can leave screen
   - Fix: Add StaticBody2D boundaries (see Priority #1)

3. **No Between-Wave Pause**: Game ends after 60s wave
   - Fix: Add pause screen with item selection UI

---

## **Example Usage**

Give Claude Code specific instructions like:

```
"Implement fixed playfield boundaries using StaticBody2D.
Create a rectangular boundary around the 1280x720 game area.
Configure collision layers: Player (1), Enemy (2), Boundary (4).
Test that player and enemies cannot escape the arena."
```

Or:

```
"Fix melee attack hitbox. Increase MELEE_RANGE to 90.
Improve collision detection so punches reliably hit enemies.
Add visual feedback (flash enemy red) when hit."
```

Or:

```
"Create between-wave pause screen.
Show 3 random items from item database.
Player clicks to select 1 item.
Apply item effect to player stats.
Resume wave with 'Continue' button."
```

---

**That's the complete Robocalypse specification! Start with Phase 1, Task 1: Boundaries! 🤖⚡**
