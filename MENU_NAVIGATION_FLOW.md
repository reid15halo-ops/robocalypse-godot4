# Menu Navigation Flow

```
┌─────────────────────────────────────────┐
│                                         │
│         🤖 ROBOCALYPSE 🤖              │
│                                         │
│            ▶ PLAY                       │
│              Character Select           │
│              Meta Upgrades              │
│              SETTINGS                   │
│              CREDITS                    │
│              QUIT                       │
│                                         │
│      [Version 0.3.0-alpha]              │
└─────────────────────────────────────────┘
         │  │  │  │  │  │
         │  │  │  │  │  └──── Exit Application
         │  │  │  │  │
         │  │  │  │  └───────► Credits Screen
         │  │  │  │                 │
         │  │  │  │                 └─[Back]─┐
         │  │  │  │                           │
         │  │  │  └──────────► Settings       │
         │  │  │                   │          │
         │  │  │                   │          │
         │  │  │     ┌─────────────┴──────┐   │
         │  │  │     │                    │   │
         │  │  │     ▼                    │   │
         │  │  │  ⚙️ SETTINGS             │   │
         │  │  │                          │   │
         │  │  │  Master Volume  [████]   │   │
         │  │  │  Music Volume   [███]    │   │
         │  │  │  SFX Volume     [████]   │   │
         │  │  │                          │   │
         │  │  │  Language   [English▼]   │   │
         │  │  │  Fullscreen [✓]          │   │
         │  │  │  VSync      [✓]          │   │
         │  │  │                          │   │
         │  │  │        [BACK]────────────┼───┘
         │  │  │                          │
         │  │  └──────────► Meta Upgrades │
         │  │                  Shop       │
         │  │                             │
         │  └──────────────► Character    │
         │                   Selection    │
         │                                │
         └──────────────────► Game Scene  │
                                          │
         ┌────────────────────────────────┘
         ▼
    Main Menu
```

## Settings Persistence Flow

```
┌──────────────┐
│  User opens  │
│   Settings   │
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│ SettingsManager      │
│ loads from:          │
│ user://settings.cfg  │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ UI displays current  │
│ settings values      │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ User changes a       │
│ setting (slider,     │
│ dropdown, toggle)    │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ SettingsManager      │
│ applies change to    │
│ audio/video system   │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ SettingsManager      │
│ saves immediately to │
│ user://settings.cfg  │
└──────────────────────┘
```

## Translation System Flow

```
┌─────────────────┐
│ User selects    │
│ language in     │
│ settings        │
└────────┬────────┘
         │
         ▼
┌────────────────────────┐
│ SettingsManager        │
│ calls                  │
│ LanguageManager        │
│ .set_language()        │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ TranslationServer      │
│ changes locale         │
│ (en, de, es)           │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Settings UI calls      │
│ _update_translations() │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ All tr() calls get     │
│ new translations from  │
│ strings.csv            │
└────────────────────────┘
```

## Autoload Dependencies

```
┌──────────────────┐
│   Game Startup   │
└────────┬─────────┘
         │
         ├─────► LanguageManager (loads saved language)
         │
         ├─────► SettingsManager (loads all settings)
         │          │
         │          ├──► AudioManager (set volumes)
         │          ├──► MusicManager (set volume)
         │          └──► DisplayServer (fullscreen, vsync)
         │
         └─────► SceneTransition (ready for use)
```

## File Structure

```
robocalypse-godot4/
├── scenes/
│   ├── MainMenu.tscn         ← Entry point (project.godot main_scene)
│   ├── Settings.tscn         ← Settings menu
│   ├── Credits.tscn          ← Credits screen (NEW)
│   ├── SceneTransition.tscn  ← Fade effects (NEW)
│   ├── Game.tscn             ← Main game
│   ├── CharacterSelect.tscn  ← Character selection
│   └── MetaUpgradeShop.tscn  ← Meta upgrades
│
├── scripts/
│   ├── main_menu.gd          ← Main menu logic
│   ├── settings.gd           ← Settings UI logic
│   ├── credits.gd            ← Credits logic (NEW)
│   ├── SceneTransition.gd    ← Transition logic (NEW)
│   ├── SettingsManager.gd    ← Settings persistence (NEW)
│   ├── LanguageManager.gd    ← Language system
│   ├── audio_manager.gd      ← Audio/SFX
│   └── music_manager.gd      ← Music
│
├── locale/
│   └── strings.csv           ← Translations (updated)
│
└── project.godot             ← Autoloads configured
```

## Keyboard Navigation

```
Main Menu:
  Tab       → Focus next button
  Shift+Tab → Focus previous button
  Enter     → Activate focused button
  Escape    → Quit application

Settings:
  Tab       → Focus next control
  Shift+Tab → Focus previous control
  ←/→       → Adjust slider
  Space     → Toggle checkbox
  Enter     → Open dropdown
  Escape    → Back to main menu

Credits:
  Escape    → Back to main menu
  Scroll    → Scroll content
```
