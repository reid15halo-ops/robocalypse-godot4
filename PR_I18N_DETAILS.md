# Pull Request: i18n: Localization setup (DE/EN/ES), HUD uses tr() (#2)

## Overview
This PR implements basic localization (internationalization) support for the Robocalypse Godot 4 project, enabling German, English, and Spanish language support with runtime language switching.

## Changes Summary

### 1. Translation Files
**File:** `locale/strings.csv`
- Created translation CSV with 24 translation keys
- Columns: key, en, de, es
- Keys include:
  - HUD: HP, SHIELD, SCORE, WAVE, TIME, SCRAP
  - Menus: PAUSE, RESUME, GAME_OVER, FINAL_SCORE, ROUTE_SELECTION
  - Drone UI: LEVEL, XP, CONTROLLING_DRONE, PRESS_E_CONTROL
  - Notifications: PRESS_ANY_KEY, HP_LOW, SHIELD_BROKEN
  - Format strings: WAVE_FMT, TIME_FMT, FINAL_SCORE_FMT, LEVEL_FMT, XP_FMT

### 2. UIStrings Constants
**File:** `scripts/UIStrings.gd`
- Completely refactored to provide string constants
- All translation keys available as constants (e.g., `UIStrings.HP`)
- Prevents typos and provides IDE autocomplete
- Removed old manual translation system

### 3. LanguageManager Autoload
**File:** `scripts/LanguageManager.gd`
- New singleton for language management
- Functions:
  - `_ready()`: Loads saved language from `user://settings.cfg`
  - `set_language(locale: String)`: Changes language and persists to config
  - `get_current_language()`: Returns active locale
  - `cycle_language()`: Cycles through EN → DE → ES (for testing)
- Supports: English (en), German (de), Spanish (es)

### 4. Game UI Integration
**File:** `scripts/game.gd`
- Replaced all hardcoded UI strings with `tr(UIStrings.CONSTANT)` calls
- Updated functions:
  - `_update_score_label()`: "Score: X" → `tr(UIStrings.SCORE) + ": " + X`
  - `_update_wave_label()`: Uses `tr(UIStrings.WAVE_FMT).format({"n": wave})`
  - `_update_wave_timer()`: Uses `tr(UIStrings.TIME_FMT).format({"t": time})`
  - `_update_scrap_label()`: "Scrap: X" → `tr(UIStrings.SCRAP) + ": " + X`
  - `_update_drone_ui()`: All drone labels now localized
  - Game over screen: Uses `tr(UIStrings.FINAL_SCORE_FMT).format({"score": X})`
- Added `_refresh_ui_labels()`: Refreshes all labels after language change
- Added language cycle check in `_process()`: Pressing L key cycles languages

### 5. Project Configuration
**File:** `project.godot`
- Added `LanguageManager` to autoload section
- Added `[internationalization]` section:
  - Registered translation files: `locale/strings.{en,de,es}.translation`
  - Note: Godot auto-generates .translation files from .csv on first editor load
- Added `cycle_language` input action (L key)

## How to Test

1. **Open in Godot Editor**
   - Godot will automatically import `locale/strings.csv` and generate `.translation` files
   - These files are binary and don't need to be committed

2. **In-Game Language Switching**
   - Press `L` key during gameplay to cycle through languages
   - Language preference persists across game sessions
   - UI labels update immediately

3. **Manual Language Setting**
   - In code: `LanguageManager.set_language("de")` for German
   - In code: `LanguageManager.set_language("en")` for English
   - In code: `LanguageManager.set_language("es")` for Spanish

4. **Verify Translations**
   - Start game and check HUD displays
   - Press L to cycle and verify all labels update
   - Check: HP, Shield, Score, Wave, Time, Scrap labels
   - Trigger game over and check final score message
   - If drone exists, check drone UI labels

## Acceptance Criteria ✅

- [x] Translation CSV exists with DE/EN/ES entries for all required keys
- [x] Project settings include translations and autoload registration
- [x] tr() is used for all HUD strings (HP, Shield, Wave, Score, Time, Scrap, etc.)
- [x] Language can be switched via LanguageManager.set_language()
- [x] Language preference persists across game sessions
- [x] No hardcoded HUD text remains in affected lines (835, 981-1003, 1117-1135, 1161)
- [x] Format strings work for dynamic values (Wave {n}, Time {t}s, etc.)

## Font Considerations

⚠️ **Note:** The current default font may not include full coverage for German umlauts (ä, ö, ü, ß) or Spanish accents (á, é, í, ó, ú, ñ). 

**Recommendation:** 
- Test with German/Spanish text in-game
- If characters display as boxes/missing, add a DynamicFont with proper Unicode coverage
- Suggested fonts: Noto Sans, Roboto, or any font with Latin Extended support
- This should be addressed in a follow-up issue if needed

## Files Changed

- `locale/strings.csv` (new)
- `scripts/UIStrings.gd` (refactored)
- `scripts/LanguageManager.gd` (new)
- `scripts/game.gd` (refactored)
- `project.godot` (configuration)

## Commits

1. `feat(i18n): add translation CSV and UIStrings constants`
2. `feat(i18n): add LanguageManager autoload singleton`
3. `refactor(ui): replace hardcoded HUD strings with tr()`
4. `chore(project): register translations and LanguageManager autoload`

## Related Issues

Closes #2 - Lokalisierung einrichten und Basisschlüssel registrieren

## Future Enhancements

- Add language selection UI in main menu/settings
- Expand translations to include:
  - Weapon names and descriptions
  - Enemy names
  - Ability/skill descriptions
  - Tutorial/help text
  - Menu screens (Main Menu, Settings, etc.)
- Add more languages (French, Italian, Portuguese, etc.)
- Implement pluralization rules for languages that need them
- Add context-aware translations where needed
