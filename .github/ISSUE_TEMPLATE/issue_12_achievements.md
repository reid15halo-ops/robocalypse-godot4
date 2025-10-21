---
name: Achievement System implementieren
about: Meta-Progression durch Achievements für Langzeit-Motivation
title: '[PROGRESSION] Achievement System implementieren'
labels: meta-progression, enhancement, gamification
assignees: ''
---

## 🎯 Ziel
Implementiere ein vollständiges Achievement-System mit mindestens 15 Achievements, Toast-Notifications und persistenter Speicherung.

## 📋 Kontext
- **Problem:** Keine Langzeit-Ziele für Spieler nach ersten Runs
- **Impact:** Weniger Replay-Value, keine Milestone-Celebrations
- **Inspiration:** Steam Achievements, Xbox Achievements

## ✅ Akzeptanzkriterien
- [ ] Mindestens 15 Achievements definiert
- [ ] Achievements persistieren in `user://achievements.json`
- [ ] Toast-Notification bei Unlock (Sound + Visual)
- [ ] Achievement-Screen im Hauptmenü (Liste aller Achievements)
- [ ] Progress-Tracking für mehrstufige Achievements
- [ ] Statistiken: "3/15 Unlocked (20%)"

## 🎖️ Achievement-Liste (Mindestens 15)

### Combat Achievements
1. **"First Blood"** - Töte deinen ersten Gegner
2. **"Sharpshooter"** - Erreiche 90% Trefferquote in einer Welle
3. **"Centurion"** - Töte 100 Gegner (Total)
4. **"Exterminator"** - Töte 1000 Gegner (Total)
5. **"Overkill"** - Töte 10+ Gegner in 10 Sekunden

### Survival Achievements  
6. **"Survivor"** - Überlebe 10 Wellen
7. **"Marathon Runner"** - Überlebe 25 Wellen
8. **"Untouchable"** - Absolviere eine Welle ohne Schaden
9. **"Perfect Run"** - Überlebe 10 Wellen ohne zu sterben

### Boss Achievements
10. **"Boss Slayer"** - Besiege deinen ersten Boss
11. **"Boss Hunter"** - Besiege 5 Bosse (Total)

### Collection Achievements
12. **"Collector"** - Sammle 1000 Scrap (Total)
13. **"Treasure Hunter"** - Sammle 10000 Scrap (Total)

### Drone Achievements
14. **"Drone Master"** - Bringe Drone auf Level 5
15. **"Drone Commander"** - Drone tötet 100 Gegner

### Speed/Skill Achievements
16. **"Speed Demon"** - Beende eine Welle in unter 30 Sekunden
17. **"Glass Cannon"** - Besiege Boss nur mit 10% HP

## 🤖 Claude Sonnet AI Prompt

```markdown
You are Claude Sonnet 4 acting as a Godot 4 systems developer. Implement a complete achievement system for robocalypse-godot4.

CONTEXT:
- Repository: reid15halo-ops/robocalypse-godot4
- Branch: work-version
- Need meta-progression system for player retention
- Achievements provide goals beyond basic gameplay

REQUIREMENTS:

1. CREATE AchievementData RESOURCE (res://resources/AchievementData.gd):
   ```gdscript
   extends Resource
   class_name AchievementData
   
   @export var id: String = ""
   @export var title: String = ""
   @export var description: String = ""
   @export var icon: Texture2D
   @export var unlock_condition: String = ""  # e.g., "kills >= 100"
   @export var is_hidden: bool = false
   @export var points: int = 10
   
   var unlocked: bool = false
   var progress: int = 0
   var max_progress: int = 1
   var unlock_time: String = ""
   ```

2. CREATE AchievementManager AUTOLOAD (res://scripts/AchievementManager.gd):
   ```gdscript
   extends Node
   class_name AchievementManager
   
   signal achievement_unlocked(achievement: AchievementData)
   
   var achievements: Dictionary = {}
   const SAVE_PATH = "user://achievements.json"
   
   func _ready():
       _initialize_achievements()
       load_achievements()
   
   func _initialize_achievements():
       # Define all achievements
       _add_achievement("first_blood", "First Blood", "Kill your first enemy", 1)
       _add_achievement("centurion", "Centurion", "Kill 100 enemies", 100)
       _add_achievement("survivor", "Survivor", "Survive 10 waves", 10)
       # ... add all 15+ achievements
   
   func _add_achievement(id: String, title: String, desc: String, max_progress: int = 1):
       var ach = AchievementData.new()
       ach.id = id
       ach.title = title
       ach.description = desc
       ach.max_progress = max_progress
       achievements[id] = ach
   
   func check_achievement(id: String, current_value: int = 1):
       if not achievements.has(id): return
       var ach = achievements[id]
       if ach.unlocked: return
       
       ach.progress = current_value
       
       if ach.progress >= ach.max_progress:
           _unlock_achievement(ach)
   
   func _unlock_achievement(ach: AchievementData):
       ach.unlocked = true
       ach.unlock_time = Time.get_datetime_string_from_system()
       achievement_unlocked.emit(ach)
       _show_toast_notification(ach)
       _save_achievements()
       print("🎖️ Achievement Unlocked: ", ach.title)
   
   func _show_toast_notification(ach: AchievementData):
       # Create toast UI
       var toast = preload("res://scenes/ui/AchievementToast.tscn").instantiate()
       toast.setup(ach)
       get_tree().root.add_child(toast)
   
   func _save_achievements():
       var data = {}
       for id in achievements:
           var ach = achievements[id]
           data[id] = {
               "unlocked": ach.unlocked,
               "progress": ach.progress,
               "unlock_time": ach.unlock_time
           }
       
       var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
       file.store_string(JSON.stringify(data, "\t"))
       file.close()
   
   func load_achievements():
       if not FileAccess.file_exists(SAVE_PATH): return
       
       var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
       var json = JSON.parse_string(file.get_as_text())
       file.close()
       
       for id in json:
           if achievements.has(id):
               achievements[id].unlocked = json[id].unlocked
               achievements[id].progress = json[id].progress
               achievements[id].unlock_time = json[id].unlock_time
   
   func get_unlock_percentage() -> float:
       var unlocked_count = 0
       for ach in achievements.values():
           if ach.unlocked: unlocked_count += 1
       return (float(unlocked_count) / achievements.size()) * 100.0
   ```

3. CREATE ACHIEVEMENT TOAST (res://scenes/ui/AchievementToast.tscn):
   ```
   Control (AchievementToast)
   └── PanelContainer
       └── HBoxContainer
           ├── TextureRect (Icon)
           └── VBoxContainer
               ├── Label (Title: "Achievement Unlocked!")
               └── Label (Achievement Name)
   ```

4. INTEGRATE WITH GAME EVENTS:
   ```gdscript
   # In game.gd
   
   func _on_enemy_killed(enemy):
       total_kills += 1
       AchievementManager.check_achievement("first_blood", 1)
       AchievementManager.check_achievement("centurion", total_kills)
       AchievementManager.check_achievement("exterminator", total_kills)
       
       # Check for rapid kills
       _check_overkill()
   
   func _on_wave_completed(wave):
       AchievementManager.check_achievement("survivor", wave)
       AchievementManager.check_achievement("marathon_runner", wave)
       
       if damage_taken_this_wave == 0:
           AchievementManager.check_achievement("untouchable", 1)
   
   func _on_boss_defeated():
       boss_kills += 1
       AchievementManager.check_achievement("boss_slayer", 1)
       AchievementManager.check_achievement("boss_hunter", boss_kills)
   ```

5. CREATE ACHIEVEMENTS SCREEN (in Main Menu):
   - ScrollContainer with all achievements
   - Show: Icon, Title, Description, Progress
   - Locked achievements show "???" or silhouette
   - Statistics: "X/15 Unlocked (Y%)"

IMPLEMENTATION STEPS:
1. Create AchievementData resource script
2. Create AchievementManager autoload
3. Define all 15+ achievements in _initialize_achievements()
4. Create AchievementToast scene (popup notification)
5. Create Achievements screen in main menu
6. Integrate check_achievement() calls throughout game.gd
7. Test each achievement triggers correctly
8. Add achievement icons (use placeholder if needed)

RETURN FORMAT:
Provide complete AchievementManager.gd, integration points in game.gd, and toast UI structure.
```

## 📝 Achievement Toast Design

```
╔═══════════════════════════════╗
║ 🎖️ ACHIEVEMENT UNLOCKED!     ║
║                               ║
║ [Icon]  Centurion             ║
║         Kill 100 enemies      ║
║                               ║
║         +10 Points            ║
╚═══════════════════════════════╝
```

## 🧪 Testing Checklist
- [ ] All 15+ achievements defined correctly
- [ ] Achievements save to JSON file
- [ ] Achievements load on game start
- [ ] Toast notification shows on unlock
- [ ] Sound plays on unlock
- [ ] Achievement screen displays all achievements
- [ ] Locked achievements show placeholder
- [ ] Progress tracking works (e.g., 50/100 kills)
- [ ] Percentage calculated correctly
- [ ] No duplicate unlocks (check once unlocked)
- [ ] Hidden achievements stay hidden until unlocked

## 🔗 Related Issues
- Enhances: Overall meta-progression
- Future: Steam Achievement integration (#19)

## 📚 References
- Godot Docs: FileAccess, JSON, Signals
- Achievement Design: Best Practices (Gamasutra)
- Similar Games: Check indie game achievement systems
