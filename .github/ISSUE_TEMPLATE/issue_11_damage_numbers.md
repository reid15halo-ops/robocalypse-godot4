---
name: Damage Numbers (Floating Combat Text)
about: Visuelles Feedback für Schaden durch schwebende Zahlen
title: '[UI] Damage Numbers (Floating Combat Text)'
labels: UI, enhancement, visual-feedback
assignees: ''
---

## 🎯 Ziel
Implementiere schwebende Schadenszahlen über getroffenen Entities für besseres visuelles Feedback und Spielgefühl.

## 📋 Kontext
- **Problem:** Kein visuelles Feedback wie viel Schaden Spieler/Gegner nehmen
- **Impact:** Spieler wissen nicht ob Waffe effektiv ist, ob Critical Hits passieren
- **Inspiration:** Diablo, Borderlands, Path of Exile (Floating Combat Text)

## ✅ Akzeptanzkriterien
- [ ] Zahlen erscheinen über getroffenen Entities (Player, Enemies, Drones)
- [ ] Farb-Kodierung:
  - Weiß: Normaler Schaden (Player → Enemy)
  - Gelb/Gold: Critical Hit
  - Rot: Schaden den Player nimmt
  - Grün: Heilung
  - Cyan: Drone Schaden
- [ ] Animation: Float nach oben + Fade Out (1-1.5 Sekunden)
- [ ] Font: Bold, gut lesbar bei schnellem Combat
- [ ] Performance: Pooling für Label-Nodes (keine FPS-Drops)
- [ ] Optional: Größere Zahlen für größeren Schaden

## 🤖 Claude Sonnet AI Prompt

```markdown
You are Claude Sonnet 4 acting as a Godot 4 UI/VFX developer. Implement floating damage numbers system for robocalypse-godot4.

CONTEXT:
- Repository: reid15halo-ops/robocalypse-godot4
- Branch: work-version
- No visual feedback currently when entities take damage
- Need floating combat text (FCT) system for better game feel

REQUIREMENTS:

1. CREATE DamageNumber SCENE (res://scenes/ui/DamageNumber.tscn):
   ```
   Node2D (DamageNumber)
   └── Label
       - Text: "125"
       - Font: Bold, Size 24
       - Modulate: Color based on type
       - Outline: Black outline for visibility
   ```

2. CREATE DamageNumberManager AUTOLOAD (res://scripts/DamageNumberManager.gd):
   ```gdscript
   extends Node
   class_name DamageNumberManager
   
   const DamageNumber = preload("res://scenes/ui/DamageNumber.tscn")
   var number_pool: Array[Node2D] = []
   var pool_size: int = 50
   
   func _ready():
       _initialize_pool()
   
   func _initialize_pool():
       for i in pool_size:
           var num = DamageNumber.instantiate()
           num.hide()
           add_child(num)
           number_pool.append(num)
   
   func show_damage(position: Vector2, amount: int, type: DamageType):
       var num = _get_from_pool()
       if not num: return
       
       num.global_position = position
       num.get_node("Label").text = str(amount)
       num.get_node("Label").modulate = _get_color(type)
       
       # Scale based on damage amount
       var scale_factor = 1.0 + (amount / 1000.0) * 0.5
       num.scale = Vector2.ONE * scale_factor
       
       num.show()
       _animate_number(num)
   
   func _get_color(type: DamageType) -> Color:
       match type:
           DamageType.NORMAL: return Color.WHITE
           DamageType.CRITICAL: return Color.YELLOW
           DamageType.PLAYER_DAMAGE: return Color.RED
           DamageType.HEAL: return Color.GREEN
           DamageType.DRONE: return Color.CYAN
   
   func _animate_number(num: Node2D):
       var tween = create_tween()
       tween.set_parallel(true)
       
       # Float up
       tween.tween_property(num, "global_position", 
           num.global_position + Vector2(randf_range(-20, 20), -80), 1.2)
       
       # Fade out
       tween.tween_property(num, "modulate:a", 0.0, 1.2)
       
       # Scale slightly
       tween.tween_property(num, "scale", num.scale * 0.8, 1.2)
       
       tween.finished.connect(func(): _return_to_pool(num))
   
   enum DamageType { NORMAL, CRITICAL, PLAYER_DAMAGE, HEAL, DRONE }
   ```

3. INTEGRATE WITH DAMAGE SYSTEM:
   In game.gd or wherever damage is dealt:
   ```gdscript
   func _on_enemy_hit(enemy, damage, is_crit):
       enemy.take_damage(damage)
       
       # Show damage number
       var type = DamageNumberManager.DamageType.CRITICAL if is_crit else DamageNumberManager.DamageType.NORMAL
       DamageNumberManager.show_damage(enemy.global_position, damage, type)
   
   func _on_player_hit(damage):
       player.take_damage(damage)
       DamageNumberManager.show_damage(player.global_position, damage, DamageNumberManager.DamageType.PLAYER_DAMAGE)
   ```

4. ADVANCED FEATURES (Optional):
   - Number stacking: "125 + 50 + 75 = 250" for rapid hits
   - Critical hit animation: Bigger scale, sparkle effect
   - DPS meter: Show total damage per second
   - Sound effect: Different pitch based on damage amount

IMPLEMENTATION STEPS:
1. Create DamageNumber.tscn (Label with proper font/outline)
2. Create DamageNumberManager.gd (autoload with pooling)
3. Register autoload in project.godot
4. Find damage dealing code in game.gd
5. Add DamageNumberManager.show_damage() calls
6. Test with different damage types
7. Adjust animation timing/colors based on feel

PERFORMANCE:
- Use object pooling (50 pre-instantiated labels)
- Reuse labels instead of instantiate/free
- Limit max active numbers (cull oldest if > 100)

RETURN FORMAT:
Provide DamageNumber.tscn structure, complete DamageNumberManager.gd, and integration code for game.gd.
```

## 📝 Visual Design

```
Normal Hit:    125  (White, medium size)
Critical Hit:  ★250★ (Yellow/Gold, larger, bold)
Player Damage: -50  (Red, shake effect)
Heal:          +30  (Green, glow)
Drone Damage:  75   (Cyan)
```

## 🧪 Testing Checklist
- [ ] Numbers appear on enemy hit
- [ ] Numbers appear on player hit
- [ ] Critical hits show yellow/gold
- [ ] Numbers float upward smoothly
- [ ] Numbers fade out after 1-1.5s
- [ ] No FPS drop with 50+ active numbers
- [ ] Font is readable during fast combat
- [ ] Colors are distinguishable
- [ ] Outline makes numbers visible on any background
- [ ] Pool doesn't exhaust (warnings in console if it does)

## 🔗 Related Issues
- Related: #10 (Drone XP - also uses floating text)
- Enhances: Combat feel for all weapons

## 📚 References
- Godot Docs: Label, Tween, Modulate
- Game Feel: Juice It or Lose It (GDC Talk)
- Similar Games: Check Diablo 3, Borderlands 3 damage numbers
