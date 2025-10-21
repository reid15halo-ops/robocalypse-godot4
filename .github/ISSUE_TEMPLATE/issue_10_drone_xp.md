---
name: Drone XP-System vervollständigen
about: Vervollständige Drone Level-Up Mechanik mit XP-Formel und Stats-Boost
title: '[GAMEPLAY] Drone XP-System vervollständigen'
labels: gameplay, drone, enhancement
assignees: ''
---

## 🎯 Ziel
Drone sammelt XP aber `xp_needed` Berechnung fehlt. Level-Ups haben keine sichtbaren Effekte. Implementiere vollständiges XP-System mit Stats-Boost und Visual Feedback.

## 📋 Kontext
- **Datei:** `scripts/game.gd:1500-1550` (drone_stats)
- **Problem:** `xp_needed` wird nicht berechnet, Level-Up hat keine Auswirkungen
- **Status:** Drone XP wird gesammelt, aber UI zeigt `XP: 750/0` (xp_needed = 0)

## ✅ Akzeptanzkriterien
- [ ] XP-Formel: `xp_needed = 100 * (level ^ 1.5)` (exponentielles Wachstum)
- [ ] Level-Up Stats-Boost:
  - HP: +10% des base_hp
  - Damage: +5% des base_damage
  - Speed: +3% (optional, Drohnen sollten nicht zu schnell werden)
  - Fire Rate: -5% Cooldown (schnelleres Schießen)
- [ ] Visual Feedback:
  - Particle Effect (Gold/Blue Burst) bei Level-Up
  - Screen Flash (kurz)
  - Floating Text: "LEVEL UP!"
- [ ] Audio: Level-Up Sound Effect
- [ ] UI: Progress Bar animiert smooth: `[███████░░░] XP: 750/1000`
- [ ] Max Level: 10 (danach nur noch Prestige XP, keine Stats mehr)

## 🤖 Claude Sonnet AI Prompt

```markdown
You are Claude Sonnet 4 acting as a Godot 4 gameplay systems developer. Complete the Drone XP and leveling system for robocalypse-godot4.

CONTEXT:
- Repository: reid15halo-ops/robocalypse-godot4
- Branch: work-version
- File: scripts/game.gd (drone stats around line 1500-1550)
- Current issue: Drone collects XP but xp_needed is 0, level-ups don't boost stats

REQUIREMENTS:

1. XP FORMULA:
   ```gdscript
   func _calculate_xp_needed(level: int) -> int:
       """Calculate XP required for next level (exponential curve)"""
       return int(100 * pow(level, 1.5))
   ```
   Example progression:
   - Level 1→2: 100 XP
   - Level 2→3: 282 XP
   - Level 3→4: 519 XP
   - Level 4→5: 800 XP
   - Level 5→6: 1118 XP

2. DRONE STATS STRUCTURE:
   ```gdscript
   var drone_stats = {
       "exists": false,
       "level": 1,
       "xp": 0,
       "xp_needed": 100,
       "hp": 100,
       "max_hp": 100,
       "base_hp": 100,        # NEW: Store base values
       "damage": 10,
       "base_damage": 10,     # NEW
       "speed": 200,
       "base_speed": 200,     # NEW
       "fire_rate": 0.5,      # Shots per second
       "base_fire_rate": 0.5  # NEW
   }
   ```

3. LEVEL-UP FUNCTION:
   ```gdscript
   func _drone_level_up() -> void:
       """Handle drone leveling up"""
       drone_stats.level += 1
       
       # Stats boost (cumulative)
       drone_stats.max_hp = drone_stats.base_hp * (1.0 + (drone_stats.level - 1) * 0.10)
       drone_stats.hp = drone_stats.max_hp  # Heal on level up
       drone_stats.damage = drone_stats.base_damage * (1.0 + (drone_stats.level - 1) * 0.05)
       drone_stats.fire_rate = drone_stats.base_fire_rate / (1.0 + (drone_stats.level - 1) * 0.05)
       
       # Reset XP for next level
       drone_stats.xp = 0
       drone_stats.xp_needed = _calculate_xp_needed(drone_stats.level)
       
       # Feedback
       _show_level_up_effects()
       AudioManager.play_sfx("drone_level_up")
       
       # Max level check
       if drone_stats.level >= 10:
           print("Drone reached max level!")
   ```

4. XP GAIN (on enemy kill by drone):
   ```gdscript
   func _on_drone_kill(enemy) -> void:
       var xp_gained = enemy.xp_value  # Different enemies give different XP
       drone_stats.xp += xp_gained
       
       # Show floating XP text
       _show_floating_text(enemy.global_position, "+%d XP" % xp_gained, Color.CYAN)
       
       # Check for level up
       while drone_stats.xp >= drone_stats.xp_needed and drone_stats.level < 10:
           _drone_level_up()
   ```

5. VISUAL EFFECTS:
   ```gdscript
   func _show_level_up_effects() -> void:
       """Visual feedback for drone level up"""
       # Particle burst
       var particles = CPUParticles2D.new()
       particles.position = drone_controller.global_position
       particles.emitting = true
       particles.one_shot = true
       particles.amount = 50
       particles.lifetime = 1.0
       particles.color = Color.GOLD
       add_child(particles)
       
       # Floating text "LEVEL UP!"
       _show_floating_text(drone_controller.global_position, "LEVEL UP!", Color.GOLD)
       
       # Screen flash
       _trigger_screen_flash(Color(1, 1, 1, 0.3), 0.2)
   ```

6. UI UPDATE:
   ```gdscript
   func _update_drone_ui() -> void:
       # ...existing code...
       
       # XP Bar (smooth animation with Tween)
       var xp_percent = float(drone_stats.xp) / float(drone_stats.xp_needed)
       var tween = create_tween()
       tween.tween_property(drone_xp_bar, "value", xp_percent, 0.3)
       
       # XP Label with formatting
       drone_xp_label.text = tr(UIStrings.XP_FMT).format({
           "current": drone_stats.xp,
           "needed": drone_stats.xp_needed
       })
   ```

IMPLEMENTATION STEPS:
1. Find drone_stats dictionary in game.gd
2. Add base_hp, base_damage, base_fire_rate fields
3. Implement _calculate_xp_needed(level) function
4. Implement _drone_level_up() function with stats scaling
5. Connect enemy death signal to _on_drone_kill()
6. Implement _show_level_up_effects() visual feedback
7. Update _update_drone_ui() with smooth XP bar animation
8. Add max level cap (10)
9. Test: Spawn enemies, let drone kill them, verify level ups work

RETURN FORMAT:
Provide complete code sections with proper context (5 lines before/after) for replace_string_in_file tool.
```

## 📝 Stats Progression Table

| Level | XP Needed | HP | Damage | Fire Rate |
|-------|-----------|-----|--------|-----------|
| 1 | 100 | 100 | 10 | 0.50s |
| 2 | 282 | 110 | 10.5 | 0.48s |
| 3 | 519 | 120 | 11.0 | 0.45s |
| 4 | 800 | 130 | 11.5 | 0.43s |
| 5 | 1118 | 140 | 12.0 | 0.40s |
| 10 | 3162 | 190 | 14.5 | 0.33s |

## 🧪 Testing Checklist
- [ ] XP bar shows correct progress (e.g., 500/1000)
- [ ] XP bar animates smoothly when XP is gained
- [ ] Drone levels up when XP reaches xp_needed
- [ ] Stats increase correctly on level up
- [ ] Particle effect shows on level up
- [ ] "LEVEL UP!" floating text appears
- [ ] Level-up sound plays
- [ ] HP is fully restored on level up
- [ ] Max level 10 is enforced (no further level ups)
- [ ] UI updates immediately after level up

## 🔗 Related Issues
- Related: #11 (Damage Numbers - also uses floating text)
- Depends on: #14 (Audio System - Level-Up Sound)

## 📚 References
- Game Design: RPG Leveling Curves (exponential vs linear)
- Godot Docs: Tweens for smooth animations
- Similar Games: Tower Defense drone upgrade systems
