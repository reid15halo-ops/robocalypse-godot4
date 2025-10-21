---
name: Hauptmenü mit Settings erstellen
about: Erstelle vollständiges Hauptmenü mit Play, Settings, Credits, Quit
title: '[UI] Hauptmenü mit Settings erstellen'
labels: UI, enhancement, user-experience
assignees: ''
---

## 🎯 Ziel
Erstelle ein vollständiges Hauptmenü mit Navigation zu Game, Settings, Credits und Quit. Spiel startet aktuell direkt ins Gameplay ohne Menü.

## 📋 Kontext
- **Problem:** Kein Hauptmenü, Spiel startet direkt in `res://scenes/game.tscn`
- **Benötigt:** MainMenu.tscn als neue `run/main_scene` in project.godot
- **Settings:** Audio Volume, Language, Controls, Graphics Quality

## ✅ Akzeptanzkriterien
- [ ] MainMenu.tscn mit Buttons: PLAY, SETTINGS, CREDITS, QUIT
- [ ] Settings Screen:
  - Master Volume Slider (0-100%)
  - Music Volume Slider (0-100%)
  - SFX Volume Slider (0-100%)
  - Language Dropdown (EN, DE, ES)
  - Fullscreen Toggle
  - VSync Toggle
- [ ] Credits Screen: Team, Assets, Music, Special Thanks
- [ ] Tutorial/How-to-Play Screen (optional, nice-to-have)
- [ ] Settings persistieren in `user://settings.cfg`
- [ ] Smooth Scene Transitions (Fade In/Out)
- [ ] Keyboard Navigation (Tab, Enter, Escape)
- [ ] Controller Support (optional)

## 🤖 Claude Sonnet AI Prompt

```markdown
You are Claude Sonnet 4 acting as a Godot 4 UI/UX developer. Create a complete main menu system for robocalypse-godot4.

CONTEXT:
- Repository: reid15halo-ops/robocalypse-godot4
- Branch: work-version
- Current state: Game starts directly in game.tscn (no menu)
- Existing systems: LanguageManager (autoload), AudioManager (exists?)

REQUIREMENTS:

1. CREATE MAIN MENU SCENE (res://scenes/MainMenu.tscn):
   - Background: Animated city scene or static logo
   - Title: "ROBOCALYPSE" (large, stylized)
   - Buttons (VBoxContainer, centered):
     * PLAY → Load res://scenes/game.tscn
     * SETTINGS → Show Settings screen
     * CREDITS → Show Credits screen
     * QUIT → quit application
   - Hover effects: Button scale + color change
   - Sound: Button hover/click SFX

2. SETTINGS SCREEN (Control node, initially hidden):
   - Master Volume HSlider (0-100, default 80)
   - Music Volume HSlider (0-100, default 70)
   - SFX Volume HSlider (0-100, default 80)
   - Language OptionButton (EN, DE, ES) → calls LanguageManager.set_language()
   - Fullscreen CheckButton
   - VSync CheckButton
   - BACK button → return to main menu
   - All settings save to user://settings.cfg on change

3. CREDITS SCREEN (RichTextLabel, ScrollContainer):
   ```
   ROBOCALYPSE
   
   Development: [Your Name]
   Art Assets: OpenGameArt, Kenney.nl
   Music: [Composer Name / Freesound]
   Sound Effects: Freesound.org
   Engine: Godot 4.3
   
   Special Thanks: Godot Community
   ```
   - BACK button → return to main menu

4. SCENE TRANSITIONS:
   - Fade effect (ColorRect with AnimationPlayer)
   - Transition time: 0.3 seconds
   - Use: get_tree().change_scene_to_file() with fade

5. SETTINGS PERSISTENCE:
   ```gdscript
   # SettingsManager.gd (new autoload)
   func save_settings():
       var config = ConfigFile.new()
       config.set_value("audio", "master_volume", master_volume)
       config.set_value("audio", "music_volume", music_volume)
       config.set_value("audio", "sfx_volume", sfx_volume)
       config.set_value("video", "fullscreen", fullscreen)
       config.set_value("video", "vsync", vsync)
       config.save("user://settings.cfg")
   
   func load_settings():
       var config = ConfigFile.new()
       if config.load("user://settings.cfg") == OK:
           master_volume = config.get_value("audio", "master_volume", 80)
           # Apply to AudioServer
           AudioServer.set_bus_volume_db(0, linear_to_db(master_volume / 100.0))
   ```

6. UPDATE PROJECT.GODOT:
   - Change: `run/main_scene="res://scenes/MainMenu.tscn"`
   - Add autoload: SettingsManager="*res://scripts/SettingsManager.gd"

IMPLEMENTATION STEPS:
1. Create res://scenes/MainMenu.tscn (UI layout)
2. Create res://scripts/MainMenu.gd (button connections)
3. Create res://scripts/SettingsManager.gd (persistence)
4. Create Settings/Credits screens (sub-controls)
5. Add SceneTransition (Fade effect)
6. Update project.godot main_scene
7. Test: Menu → Settings → Game → Back to Menu

CODE STYLE:
- Use Control nodes (MarginContainer, VBoxContainer)
- Theme: Dark cyberpunk aesthetic (blues, neons)
- Font: Bold for title, readable for buttons
- Responsive: Works at 1280x720 and 1920x1080

ASSETS NEEDED (if not available):
- Background image/animation
- Button hover/click sounds
- Menu background music (ambient, loopable)

RETURN FORMAT:
Provide MainMenu.tscn structure (as text description), MainMenu.gd, SettingsManager.gd, and project.godot changes.
```

## 📝 UI Mockup

```
╔═══════════════════════════════════════╗
║                                       ║
║         🤖 ROBOCALYPSE 🤖            ║
║                                       ║
║            ▶ PLAY                     ║
║              SETTINGS                 ║
║              CREDITS                  ║
║              QUIT                     ║
║                                       ║
║      [Version 0.3.0-alpha]            ║
╚═══════════════════════════════════════╝

Settings Screen:
╔═══════════════════════════════════════╗
║  ⚙️ SETTINGS                          ║
║                                       ║
║  Master Volume  [████████░] 80%      ║
║  Music Volume   [███████░░] 70%      ║
║  SFX Volume     [████████░] 80%      ║
║                                       ║
║  Language       [English ▼]           ║
║  Fullscreen     [✓]                   ║
║  VSync          [✓]                   ║
║                                       ║
║              [BACK]                   ║
╚═══════════════════════════════════════╝
```

## 🧪 Testing Checklist
- [ ] Main menu displays correctly on startup
- [ ] PLAY button loads game scene
- [ ] SETTINGS button shows settings screen
- [ ] CREDITS button shows credits
- [ ] QUIT button exits application
- [ ] Volume sliders affect audio in real-time
- [ ] Language change updates all menu text immediately
- [ ] Fullscreen toggle works
- [ ] VSync toggle works
- [ ] Settings persist after restart
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Scene transitions are smooth (no flicker)
- [ ] No errors in console

## 🔗 Related Issues
- Depends on: LanguageManager (already implemented)
- Related: #14 (Audio System - Menu Music)
- Blocks: Tutorial screen (future enhancement)

## 📚 References
- Godot Docs: UI System, ConfigFile, Scene Management
- UI Design: Game Menu Best Practices
- Similar Games: Check popular indie game menus
