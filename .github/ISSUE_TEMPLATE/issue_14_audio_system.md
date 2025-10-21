---
name: Audio System vervollständigen
about: Implementiere vollständiges Audio System mit Music und SFX
title: '[AUDIO] Audio System vervollständigen'
labels: audio, enhancement, polish, critical
assignees: ''
---

## 🎯 Ziel
Implementiere vollständiges Audio-System mit Hintergrundmusik, Sound Effects, Volume-Steuerung und dynamischen Audio-Übergängen für bessere Immersion.

## 📋 Kontext
- **Problem:** Spiel hat keine Musik oder Sound Effects
- **Impact:** Fehlende Immersion, kein Audio-Feedback für Actions
- **Kritisch:** Audio ist essentiell für professionelles Spielgefühl

## ✅ Akzeptanzkriterien
- [ ] Background Music System mit 3-5 Tracks (Menü, Combat, Boss)
- [ ] Sound Effects für alle wichtigen Events (min. 20 SFX)
- [ ] Volume-Steuerung: Master, Music, SFX (0-100%)
- [ ] Smooth Cross-Fade zwischen Music Tracks (2-3 Sekunden)
- [ ] Audio persistiert in `user://settings.cfg`
- [ ] Audio Pool für häufige Sounds (Performance)

## 🎵 Required Audio Assets

### Music Tracks (3-5 Tracks)
1. **Menu Music** - Ambient, loopbar, ruhig
2. **Combat Music** - Energisch, Elektronisch, 120-140 BPM
3. **Boss Music** - Intensiv, Episch, build-up
4. **Wave Break Music** - Entspannt, kurze Pause-Atmosphäre
5. **Game Over Music** - Düster, melancholisch

### Sound Effects (20+ SFX)

#### Player Sounds
- Shoot (Player Weapon) - Pew/Laser
- Player Hit - Grunt/Impact
- Player Death - Explosion/Scream
- Player Level Up - Chime/PowerUp
- Dash/Dodge - Whoosh

#### Enemy Sounds
- Enemy Spawn - Portal/Teleport
- Enemy Hit - Thud/Clang
- Enemy Death - Explosion (varied by type)
- Boss Spawn - Deep Roar/Warning
- Boss Death - Epic Explosion

#### UI Sounds
- Button Hover - Subtle Beep
- Button Click - Click/Confirm
- Menu Open/Close - Swoosh
- Achievement Unlock - Fanfare
- Level Up - Chime
- Warning - Alert Beep

#### Gameplay Sounds
- Item Pickup (Scrap) - Coin/Bling
- Health Pickup - PowerUp
- Drone Command - Beep/Chirp
- Drone Attack - Laser
- Wave Start - Alarm/Horn
- Wave Complete - Victory Jingle
- Portal Open - Warp

## 🤖 Claude Sonnet AI Prompt

```markdown
You are Claude Sonnet 4 acting as a Godot 4 audio systems developer. Implement complete audio system for robocalypse-godot4.

CONTEXT:
- Repository: reid15halo-ops/robocalypse-godot4
- Branch: work-version
- Currently no music or sound effects
- Need professional audio system with volume control and cross-fading

REQUIREMENTS:

1. ENHANCE AudioManager AUTOLOAD (res://scripts/AudioManager.gd):
   ```gdscript
   extends Node
   class_name AudioManager
   
   # Music Players
   var music_players: Array[AudioStreamPlayer] = []
   var current_music_player: AudioStreamPlayer
   var next_music_player: AudioStreamPlayer
   
   # SFX Pool
   var sfx_pool: Array[AudioStreamPlayer] = []
   const SFX_POOL_SIZE = 20
   
   # Music Tracks
   var music_tracks = {
       "menu": preload("res://sounds/music/menu_ambient.ogg"),
       "combat": preload("res://sounds/music/combat_electronic.ogg"),
       "boss": preload("res://sounds/music/boss_epic.ogg"),
       "game_over": preload("res://sounds/music/game_over.ogg")
   }
   
   # SFX Library
   var sfx_library = {
       "player_shoot": preload("res://sounds/sfx/player_shoot.wav"),
       "player_hit": preload("res://sounds/sfx/player_hit.wav"),
       "player_death": preload("res://sounds/sfx/player_death.wav"),
       "enemy_hit": preload("res://sounds/sfx/enemy_hit.wav"),
       "enemy_death": preload("res://sounds/sfx/enemy_death.wav"),
       "boss_spawn": preload("res://sounds/sfx/boss_spawn.wav"),
       "button_click": preload("res://sounds/sfx/ui_click.wav"),
       "achievement": preload("res://sounds/sfx/achievement.wav"),
       "pickup": preload("res://sounds/sfx/pickup.wav"),
       "wave_start": preload("res://sounds/sfx/wave_start.wav"),
       "wave_complete": preload("res://sounds/sfx/wave_complete.wav")
       # ... add all 20+ sounds
   }
   
   # Volume Settings
   var master_volume: float = 0.8
   var music_volume: float = 0.7
   var sfx_volume: float = 0.8
   
   func _ready():
       _initialize_music_players()
       _initialize_sfx_pool()
       _load_volume_settings()
   
   func _initialize_music_players():
       for i in 2:  # Two players for cross-fade
           var player = AudioStreamPlayer.new()
           player.bus = "Music"
           add_child(player)
           music_players.append(player)
       
       current_music_player = music_players[0]
       next_music_player = music_players[1]
   
   func _initialize_sfx_pool():
       for i in SFX_POOL_SIZE:
           var player = AudioStreamPlayer.new()
           player.bus = "SFX"
           add_child(player)
           sfx_pool.append(player)
   
   func play_music(track_name: String, fade_time: float = 2.0):
       if not music_tracks.has(track_name):
           push_error("Music track not found: " + track_name)
           return
       
       # Setup next player
       next_music_player.stream = music_tracks[track_name]
       next_music_player.volume_db = linear_to_db(0.0)
       next_music_player.play()
       
       # Cross-fade
       var tween = create_tween()
       tween.set_parallel(true)
       
       # Fade out current
       tween.tween_property(current_music_player, "volume_db", 
           linear_to_db(0.0), fade_time)
       
       # Fade in next
       tween.tween_property(next_music_player, "volume_db",
           linear_to_db(music_volume), fade_time)
       
       tween.finished.connect(func():
           current_music_player.stop()
           var temp = current_music_player
           current_music_player = next_music_player
           next_music_player = temp
       )
   
   func play_sfx(sfx_name: String, volume_multiplier: float = 1.0, pitch: float = 1.0):
       if not sfx_library.has(sfx_name):
           push_error("SFX not found: " + sfx_name)
           return
       
       var player = _get_available_sfx_player()
       if not player: return
       
       player.stream = sfx_library[sfx_name]
       player.volume_db = linear_to_db(sfx_volume * volume_multiplier)
       player.pitch_scale = pitch
       player.play()
   
   func _get_available_sfx_player() -> AudioStreamPlayer:
       for player in sfx_pool:
           if not player.playing:
               return player
       return null  # Pool exhausted
   
   func set_master_volume(volume: float):
       master_volume = clamp(volume, 0.0, 1.0)
       AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
       _save_volume_settings()
   
   func set_music_volume(volume: float):
       music_volume = clamp(volume, 0.0, 1.0)
       var music_bus = AudioServer.get_bus_index("Music")
       AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
       _save_volume_settings()
   
   func set_sfx_volume(volume: float):
       sfx_volume = clamp(volume, 0.0, 1.0)
       var sfx_bus = AudioServer.get_bus_index("SFX")
       AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
       _save_volume_settings()
   
   func _save_volume_settings():
       var config = ConfigFile.new()
       config.load("user://settings.cfg")
       config.set_value("audio", "master_volume", master_volume)
       config.set_value("audio", "music_volume", music_volume)
       config.set_value("audio", "sfx_volume", sfx_volume)
       config.save("user://settings.cfg")
   
   func _load_volume_settings():
       var config = ConfigFile.new()
       if config.load("user://settings.cfg") == OK:
           master_volume = config.get_value("audio", "master_volume", 0.8)
           music_volume = config.get_value("audio", "music_volume", 0.7)
           sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
           set_master_volume(master_volume)
           set_music_volume(music_volume)
           set_sfx_volume(sfx_volume)
   ```

2. SETUP AUDIO BUSES (Project > Project Settings > Audio):
   ```
   Master (0)
   ├── Music (1)
   └── SFX (2)
   ```

3. INTEGRATE IN GAME:
   ```gdscript
   # In game.gd
   
   func _ready():
       AudioManager.play_music("combat")
   
   func _on_player_shoot():
       AudioManager.play_sfx("player_shoot")
   
   func _on_enemy_hit(enemy):
       AudioManager.play_sfx("enemy_hit", 1.0, randf_range(0.9, 1.1))  # Varied pitch
   
   func _on_boss_spawn():
       AudioManager.play_music("boss", 3.0)  # 3s cross-fade
       AudioManager.play_sfx("boss_spawn")
   
   func _on_wave_complete():
       AudioManager.play_sfx("wave_complete")
   
   func _on_game_over():
       AudioManager.play_music("game_over")
       AudioManager.play_sfx("player_death")
   ```

4. FREE AUDIO RESOURCES:
   - **Music:** Incompetech.com (Kevin MacLeod), Purple Planet Music, Bensound
   - **SFX:** Freesound.org, OpenGameArt.org, Zapsplat (free tier)
   - **Tools:** Audacity (editing), LMMS (music), Bfxr (8-bit SFX generator)

IMPLEMENTATION STEPS:
1. Create audio folder structure (sounds/music/, sounds/sfx/)
2. Download/create placeholder audio files (use Bfxr for quick SFX)
3. Enhance AudioManager.gd with music/sfx management
4. Setup Audio Buses in Project Settings
5. Integrate play_music/play_sfx calls throughout game.gd
6. Test volume sliders in settings menu
7. Test cross-fade between music tracks
8. Profile: Ensure no audio stuttering

RETURN FORMAT:
Provide complete enhanced AudioManager.gd and integration examples for game.gd.
```

## 📝 Audio Bus Structure

```
Master (0 dB)
├── Music (-6 dB)
│   ├── Menu Music
│   ├── Combat Music
│   └── Boss Music
└── SFX (0 dB)
    ├── Player Sounds
    ├── Enemy Sounds
    └── UI Sounds
```

## 🧪 Testing Checklist
- [ ] Menu music plays on game start
- [ ] Combat music plays during gameplay
- [ ] Boss music plays when boss spawns
- [ ] Music cross-fades smoothly (no gaps/overlaps)
- [ ] All SFX play correctly (shoot, hit, death, etc.)
- [ ] Volume sliders affect audio in real-time
- [ ] Audio settings persist after restart
- [ ] No audio stuttering or clicks
- [ ] SFX pool doesn't run out during intense combat
- [ ] Varied pitch on repeated sounds (enemy hits)

## 🎨 Free Audio Resources

### Music
- **Incompetech:** https://incompetech.com (Creative Commons)
- **Purple Planet:** https://www.purple-planet.com (Free for games)
- **Bensound:** https://www.bensound.com (Free tier)

### SFX
- **Freesound:** https://freesound.org (Community, CC licenses)
- **OpenGameArt:** https://opengameart.org/art-search-advanced?keys=&field_art_type_tid%5B%5D=13
- **Bfxr:** https://www.bfxr.net (Generate retro SFX)
- **Zapsplat:** https://www.zapsplat.com (Free tier)

## 🔗 Related Issues
- Blocks: #7 (Boss Spawn - needs boss music)
- Blocks: #12 (Achievements - needs unlock sound)
- Required by: #9 (Main Menu - needs menu music)

## 📚 References
- Godot Docs: AudioStreamPlayer, AudioServer, Audio Buses
- Game Audio: Best Practices (GDC Talks)
- Mixing: Music vs SFX balance (-6 dB for music is common)
