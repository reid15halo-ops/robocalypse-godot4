---
name: Boss-Gegner Spawn-Logik implementieren
about: Boss-Scene ist geladen aber wird nicht gespawnt
title: '[GAMEPLAY] Boss-Gegner Spawn-Logik implementieren'
labels: enhancement, gameplay, critical
assignees: ''
---

## 🎯 Ziel
Boss-Gegner werden aktuell nicht gespawnt, obwohl die Scene geladen ist. Implementiere vollständige Boss Spawn-Logik mit erhöhten Stats und besonderen Rewards.

## 📋 Kontext
- **Datei:** `scripts/game.gd:11`
- **Code:** `var boss_scene = preload("res://scenes/BossEnemy.tscn")`
- **Problem:** Boss wird nirgendwo instanziiert oder gespawnt

## ✅ Akzeptanzkriterien
- [ ] Boss spawnt automatisch nach jeder 5. Welle (Wave 5, 10, 15, etc.)
- [ ] Boss hat 5x HP, 2x Damage, 0.7x Speed verglichen mit normalen Enemies
- [ ] Boss-Defeat gewährt 100 Scrap + 500 XP Bonus
- [ ] Visual Feedback: Screen Shake, Warning UI "BOSS INCOMING!"
- [ ] Audio: Boss Spawn Sound, Boss Battle Music Track
- [ ] Boss Drop: Guaranteed High-Tier Upgrade oder Health Pack

## 🤖 Claude Sonnet AI Prompt

```markdown
You are Claude Sonnet 4 acting as a senior Godot 4 game developer. Implement boss spawning logic for the robocalypse-godot4 project.

CONTEXT:
- Repository: reid15halo-ops/robocalypse-godot4
- Branch: work-version
- File: scripts/game.gd
- Boss scene already exists: res://scenes/BossEnemy.tscn (preloaded at line 11)
- Wave system exists but no boss spawn logic

REQUIREMENTS:
1. Spawn boss automatically every 5th wave (wave % 5 == 0)
2. Boss stats: HP = normal_enemy_hp * 5, Damage = normal_damage * 2, Speed = normal_speed * 0.7
3. Boss defeat rewards: +100 Scrap, +500 XP
4. UI warning 5 seconds before boss spawn: "⚠️ BOSS INCOMING!"
5. Screen shake effect on boss arrival
6. Boss battle music track (add AudioManager.play_boss_music())
7. Guaranteed rare drop on defeat

IMPLEMENTATION STEPS:
1. Find wave_completed() or start_wave() function in game.gd
2. Add check: if current_wave % 5 == 0: _spawn_boss()
3. Implement _spawn_boss() method:
   - Get valid spawn position from MapGenerator
   - Instantiate boss_scene
   - Scale stats (hp *= 5, damage *= 2, speed *= 0.7)
   - Connect boss signals (died, damaged)
   - Show UI warning
4. Add boss defeat handler: _on_boss_defeated()
   - Award bonus scrap/xp
   - Spawn guaranteed drop
   - Trigger victory screen/next wave
5. Test: Run game, reach wave 5, verify boss spawns correctly

CODE STYLE:
- Use GDScript typed syntax
- Add docstrings: """Spawn boss enemy for milestone waves"""
- Use signals for boss events
- Follow existing code patterns in game.gd

RETURN FORMAT:
Provide complete code changes using replace_string_in_file tool with proper context (5 lines before/after).
```

## 📝 Implementation Notes

### Boss Stats Scaling
```gdscript
func _spawn_boss() -> void:
	"""Spawn boss enemy at milestone waves (5, 10, 15, etc.)"""
	var spawn_pos = MapGenerator.get_random_street_spawn_point()
	var boss = boss_scene.instantiate()
	boss.position = spawn_pos
	
	# Scale stats
	boss.max_hp = base_enemy_hp * 5
	boss.hp = boss.max_hp
	boss.damage = base_enemy_damage * 2
	boss.speed = base_enemy_speed * 0.7
	
	# Connect signals
	boss.died.connect(_on_boss_defeated)
	
	# UI + Audio
	_show_boss_warning()
	AudioManager.play_boss_music()
	_trigger_screen_shake(0.5, 10.0)
	
	add_child(boss)
```

### Boss Warning UI
```gdscript
func _show_boss_warning() -> void:
	"""Show warning UI 5 seconds before boss arrival"""
	var warning_label = Label.new()
	warning_label.text = "⚠️ BOSS INCOMING!"
	warning_label.add_theme_font_size_override("font_size", 48)
	warning_label.modulate = Color.RED
	# Add tween animation: pulse + fade
	# Auto-remove after 5 seconds
```

## 🧪 Testing Checklist
- [ ] Boss spawns at wave 5
- [ ] Boss has correct HP (5x normal)
- [ ] Boss deals correct damage (2x normal)
- [ ] Boss moves slower (0.7x speed)
- [ ] Warning UI shows before spawn
- [ ] Boss music plays during fight
- [ ] Screen shakes on boss arrival
- [ ] Boss drops 100 scrap on defeat
- [ ] Boss grants 500 XP on defeat
- [ ] Rare item drops guaranteed

## 🔗 Related Issues
- Depends on: #14 (Audio System - Boss Music)
- Blocks: #16 (Roguelike Upgrades - Boss Drops)

## 📚 References
- Godot Docs: Signals & Node Management
- Game Design: Boss Scaling Formulas
- Similar Games: Vampire Survivors, Brotato (Boss Mechanics)
