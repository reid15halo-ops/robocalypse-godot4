# Robocalypse - Godot 4 Game Project

## Projektübersicht
Robocalypse ist ein 2D Top-Down Survival-Shooter, entwickelt mit Godot 4. Der Spieler muss gegen Wellen von feindlichen Robotern überleben.

## Architektur

### Szenen-Struktur
- **MainMenu.tscn** - Hauptmenü mit Start/Quit Buttons
- **Game.tscn** - Hauptspielszene mit Spielfeld, UI und Spawning-System
- **Player.tscn** - Spieler-Charaktermodell mit Bewegung und Gesundheitssystem
- **Enemy.tscn** - Gegnermodell mit KI-Navigation

### Scripts
- **GameManager.gd** - Singleton (Autoload) für globalen Zustand und Score-Verwaltung
- **player.gd** - Spieler-Logik mit Bewegung (200px/s) und Gesundheit (100 HP)
- **enemy.gd** - Gegner-KI mit Verfolgungslogik (100-150px/s)
- **game.gd** - Spiel-Logik mit Enemy-Spawning und UI-Updates
- **main_menu.gd** - Menü-Navigation

## Wichtige Systeme

### Bewegungssystem
- **Input-Maps**: WASD + Pfeiltasten für Bewegung, ESC für Pause
- **Physics**: CharacterBody2D mit `move_and_slide()` (Godot 4)
- **Geschwindigkeit**: Player 200px/s, Enemy 100-150px/s variabel

### Gesundheitssystem
- Player startet mit 100 HP
- Kollision mit Enemy verursacht Schaden
- Health Bar UI zeigt aktuelle Gesundheit
- Bei 0 HP: Game Over

### Enemy-Spawning
- Periodisches Spawning alle X Sekunden
- Spawn-Position an Bildschirmrändern
- Schwierigkeit erhöht sich über Zeit

### Kollisions-Layer
1. **Layer 1**: Player
2. **Layer 2**: Enemy
3. **Layer 3**: Boundary (Spielfeldgrenzen)

## Godot 4 Spezifika
- Signal-Verbindungen: `.connect(callable)` Syntax
- CharacterBody2D statt KinematicBody2D
- `move_and_slide()` ohne Parameter (velocity als Property)
- Modern signal declaration: `signal signal_name`

## Development Commands
```bash
# Godot Editor öffnen
godot project.godot

# Spiel direkt ausführen
godot --path . scenes/MainMenu.tscn
```

## Nächste Schritte
- [ ] Audio-System hinzufügen (Sound-Effekte, Musik)
- [ ] Power-Ups implementieren
- [ ] Waffen-System erweitern
- [ ] High-Score Persistenz
- [ ] Partikel-Effekte
