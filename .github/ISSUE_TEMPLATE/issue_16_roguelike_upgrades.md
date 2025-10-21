---
name: Roguelike Upgrades System
about: Implementiere Upgrade-System mit zufälligen Auswahl nach Wellen
title: '[GAMEPLAY] Roguelike Elements: Random Upgrades System'
labels: gameplay, enhancement, roguelike
assignees: ''
---

## 🎯 Ziel
Implementiere Roguelike-Style Upgrade-System: Nach jeder Welle wählt Spieler 1 von 3 zufälligen Upgrades. Inspiriert von Vampire Survivors, Brotato.

## 📋 Kontext
- **Problem:** Keine Progression innerhalb eines Runs (außer XP/Scrap)
- **Impact:** Wenig Build-Variety, jeder Run spielt sich gleich
- **Inspiration:** Vampire Survivors, Brotato, Halls of Torment

## ✅ Akzeptanzkriterien
- [ ] Mindestens 25 verschiedene Upgrades definiert
- [ ] Nach jeder Welle: Pause + Auswahl von 3 random Upgrades
- [ ] Upgrades stacken mit Diminishing Returns
- [ ] Upgrade-History im Pause-Menü sichtbar
- [ ] Synergien zwischen bestimmten Upgrades
- [ ] Rarity-System: Common (70%), Rare (25%), Legendary (5%)

## 🎲 Upgrade-Kategorien (25+ Upgrades)

### Waffen-Upgrades (8)
1. **Rapid Fire** - Fire Rate +30% (stackt bis +150%)
2. **Multi-Shot** - +1 Projektil pro Schuss (max 5)
3. **Piercing Rounds** - Projektile durchdringen 1 Enemy (stackt +1)
4. **Explosive Bullets** - 20% Chance auf AOE-Explosion
5. **Homing Missiles** - Projektile verfolgen Gegner
6. **Ricochet** - Geschosse prallen 2x ab
7. **Critical Master** - Crit Chance +15%, Crit Damage +50%
8. **Overcharge** - Damage +25%, Fire Rate -10%

### Verteidigungs-Upgrades (6)
9. **Max HP Up** - Max HP +20
10. **Shield Boost** - Max Shield +30
11. **Regeneration** - Regen 1 HP alle 5s
12. **Thorns** - 20% des Schadens zurück reflektieren
13. **Dodge Master** - 15% Chance Angriffe auszuweichen
14. **Second Wind** - Bei HP < 20%: +50% Speed für 3s

### Bewegungs-Upgrades (4)
15. **Speed Demon** - Movement Speed +15%
16. **Dash Cooldown** - Dash Cooldown -20%
17. **Ghost Mode** - Kurze Unverwundbarkeit nach Dash
18. **Momentum** - Je länger du dich bewegst, +10% Damage (max +50%)

### Drohnen-Upgrades (4)
19. **Drone Damage** - Drone Damage +25%
20. **Second Drone** - Spawne zweite Drohne (einmalig)
21. **Kamikaze Drone** - Drohne explodiert bei Tod (AOE)
22. **Chain Lightning** - Drohne: Angriffe springen zu 2 Zielen

### Utility-Upgrades (5)
23. **Scrap Magnet** - Pickup-Radius +50%
24. **XP Boost** - XP Gain +25%
25. **Lucky Strike** - +10% Drop-Chance für Items
26. **Time Dilation** - Slow Enemies 20% in 5m Radius
27. **Lifesteal** - 10% Damage als HP zurück

### Spezial-Upgrades (Legendary, 3)
28. **Nuke** - Jede 60s: Bildschirm-Clear AOE
29. **Time Freeze** - Aktivierbar: Freeze alle Enemies 3s (90s CD)
30. **Clone Army** - Spawne 3 temporäre Clones für 10s

## 🤖 Claude Sonnet AI Prompt

```markdown
You are Claude Sonnet 4 acting as a Godot 4 game systems developer. Implement roguelike-style upgrade system for robocalypse-godot4.

CONTEXT:
- Repository: reid15halo-ops/robocalypse-godot4
- Branch: work-version
- Goal: After each wave, player chooses 1 of 3 random upgrades (like Vampire Survivors)
- Need upgrade data structure, UI, and stat modification system

REQUIREMENTS:

1. CREATE UpgradeData RESOURCE (res://resources/UpgradeData.gd):
   ```gdscript
   extends Resource
   class_name UpgradeData
   
   enum Rarity { COMMON, RARE, LEGENDARY }
   enum Category { WEAPON, DEFENSE, MOVEMENT, DRONE, UTILITY, SPECIAL }
   
   @export var id: String = ""
   @export var name: String = ""
   @export var description: String = ""
   @export var icon: Texture2D
   @export var rarity: Rarity = Rarity.COMMON
   @export var category: Category = Category.WEAPON
   @export var max_stacks: int = 5
   @export var has_diminishing_returns: bool = true
   
   var current_stacks: int = 0
   
   func get_effect_value(base_value: float) -> float:
       if not has_diminishing_returns:
           return base_value * current_stacks
       # Diminishing returns formula: value * (1 - 0.15 * (stack - 1))
       var multiplier = 1.0
       for i in range(1, current_stacks):
           multiplier *= 0.85
       return base_value * current_stacks * multiplier
   ```

2. CREATE UpgradeManager AUTOLOAD (res://scripts/UpgradeManager.gd):
   ```gdscript
   extends Node
   class_name UpgradeManager
   
   signal upgrade_selected(upgrade: UpgradeData)
   
   var all_upgrades: Dictionary = {}
   var active_upgrades: Dictionary = {}  # id -> UpgradeData
   var upgrade_history: Array[UpgradeData] = []
   
   func _ready():
       _initialize_upgrades()
   
   func _initialize_upgrades():
       # Define all 25+ upgrades
       _add_upgrade("rapid_fire", "Rapid Fire", "Fire Rate +30%", 
           UpgradeData.Rarity.COMMON, UpgradeData.Category.WEAPON, 5)
       _add_upgrade("multi_shot", "Multi-Shot", "+1 Projectile", 
           UpgradeData.Rarity.RARE, UpgradeData.Category.WEAPON, 5)
       # ... add all 30 upgrades
   
   func get_random_upgrades(count: int = 3) -> Array[UpgradeData]:
       var available = _get_available_upgrades()
       var selected: Array[UpgradeData] = []
       
       # Weight by rarity
       for i in count:
           var upgrade = _select_by_rarity(available)
           if upgrade:
               selected.append(upgrade)
               available.erase(upgrade)
       
       return selected
   
   func _select_by_rarity(upgrades: Array) -> UpgradeData:
       var roll = randf()
       var rarity_filter = UpgradeData.Rarity.COMMON
       
       if roll < 0.05:  # 5% Legendary
           rarity_filter = UpgradeData.Rarity.LEGENDARY
       elif roll < 0.30:  # 25% Rare
           rarity_filter = UpgradeData.Rarity.RARE
       
       # Filter by rarity
       var filtered = upgrades.filter(func(u): return u.rarity == rarity_filter)
       if filtered.is_empty():
           filtered = upgrades  # Fallback
       
       return filtered[randi() % filtered.size()]
   
   func apply_upgrade(upgrade: UpgradeData):
       if active_upgrades.has(upgrade.id):
           active_upgrades[upgrade.id].current_stacks += 1
       else:
           upgrade.current_stacks = 1
           active_upgrades[upgrade.id] = upgrade
       
       upgrade_history.append(upgrade)
       _apply_upgrade_effects(upgrade)
       upgrade_selected.emit(upgrade)
   
   func _apply_upgrade_effects(upgrade: UpgradeData):
       # Modify player stats based on upgrade
       match upgrade.id:
           "rapid_fire":
               var bonus = upgrade.get_effect_value(0.30)
               GameManager.player.fire_rate_multiplier += bonus
           "max_hp_up":
               GameManager.player.max_hp += 20 * upgrade.current_stacks
           "speed_demon":
               var bonus = upgrade.get_effect_value(0.15)
               GameManager.player.speed_multiplier += bonus
           # ... handle all upgrade IDs
   ```

3. CREATE UPGRADE SELECTION UI (res://scenes/ui/UpgradeSelection.tscn):
   ```
   Control (UpgradeSelection)
   └── ColorRect (Semi-transparent overlay)
       └── CenterContainer
           └── PanelContainer
               └── VBoxContainer
                   ├── Label ("Choose Your Upgrade")
                   ├── HBoxContainer (3 upgrade cards)
                   │   ├── UpgradeCard 1
                   │   ├── UpgradeCard 2
                   │   └── UpgradeCard 3
                   └── Label ("Press 1, 2, or 3")
   
   UpgradeCard:
   └── Button
       └── VBoxContainer
           ├── TextureRect (Icon)
           ├── Label (Name)
           ├── Label (Description)
           ├── Label (Rarity badge)
           └── Label ("Stack: X/5" if already owned)
   ```

4. INTEGRATE IN GAME (res://scripts/game.gd):
   ```gdscript
   func _on_wave_completed():
       wave_timer = 0.0
       current_wave += 1
       
       # Pause for upgrade selection
       _show_upgrade_selection()
   
   func _show_upgrade_selection():
       var upgrades = UpgradeManager.get_random_upgrades(3)
       upgrade_selection_ui.show_upgrades(upgrades)
       GameManager.pause_game()  # Pause without showing pause menu
   
   func _on_upgrade_selected(upgrade: UpgradeData):
       UpgradeManager.apply_upgrade(upgrade)
       upgrade_selection_ui.hide()
       GameManager.unpause_game()
       _start_next_wave()
   ```

5. SYNERGIES SYSTEM (Optional):
   ```gdscript
   # In UpgradeManager
   var synergies = {
       ["multi_shot", "piercing_rounds"]: "spray_and_pray",  # Unlocks new upgrade
       ["drone_damage", "second_drone"]: "drone_army"
   }
   
   func check_synergies():
       for combo in synergies:
           if _has_all_upgrades(combo):
               _unlock_synergy_upgrade(synergies[combo])
   ```

IMPLEMENTATION STEPS:
1. Create UpgradeData resource script
2. Create UpgradeManager autoload with all 30 upgrades
3. Create UpgradeSelection UI scene
4. Integrate upgrade selection after each wave
5. Implement stat modification for each upgrade
6. Add keyboard shortcuts (1, 2, 3) for selection
7. Create upgrade history screen (pause menu)
8. Test: Each upgrade works, stacking works, diminishing returns correct
9. Balance: Adjust values based on playtesting

RETURN FORMAT:
Provide complete UpgradeData.gd, UpgradeManager.gd, UI structure, and game.gd integration.
```

## 📝 UI Mockup

```
╔══════════════════════════════════════════════════╗
║          🎲 CHOOSE YOUR UPGRADE 🎲              ║
║                                                  ║
║  ┌─────────────┐  ┌─────────────┐  ┌─────────┐║
║  │ [⚡]        │  │ [🛡️]        │  │ [💀]    │║
║  │ Rapid Fire  │  │ Shield Up   │  │ Nuke    │║
║  │             │  │             │  │         │║
║  │ Fire Rate   │  │ Max Shield  │  │ Clear   │║
║  │ +30%        │  │ +30         │  │ Screen  │║
║  │             │  │             │  │         │║
║  │ [COMMON]    │  │ [RARE]      │  │[LEGENDARY]║
║  │ Stack: 2/5  │  │             │  │         │║
║  └─────────────┘  └─────────────┘  └─────────┘║
║      Press 1          Press 2         Press 3  ║
╚══════════════════════════════════════════════════╝
```

## 🧪 Testing Checklist
- [ ] After each wave, upgrade selection appears
- [ ] 3 random upgrades displayed
- [ ] Rarity distribution: ~70% Common, ~25% Rare, ~5% Legendary
- [ ] Keyboard (1,2,3) and mouse selection works
- [ ] Selected upgrade applies stats correctly
- [ ] Stacking works (same upgrade multiple times)
- [ ] Diminishing returns calculated correctly
- [ ] Max stacks enforced (upgrade disappears from pool)
- [ ] Upgrade history visible in pause menu
- [ ] Game pauses during selection
- [ ] Game resumes after selection
- [ ] Synergies unlock correctly (if implemented)

## 🔗 Related Issues
- Enhances: Overall gameplay loop
- Synergy with: #10 (Drone XP), #12 (Achievements)

## 📚 References
- Game Design: Vampire Survivors upgrade system
- Godot Docs: Resources, Autoload, UI
- Balancing: Diminishing Returns formulas
