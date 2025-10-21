# Debug-Log System - Anleitung

## Übersicht

Das Debug-Log-System erfasst automatisch alle Fehler, Warnungen und wichtige Events während des Spiels und zeigt sie in einem separaten Fenster an.

## Nutzung

### 1. Spiel starten
- Starte das Spiel normal über Godot (F5 oder "Spiel starten")
- Das Debug-Log-Fenster erscheint **automatisch** oben links

### 2. Debug-Fenster bedienen

**Tastenkombinationen:**
- **F3** = Debug-Fenster ein-/ausblenden

**Buttons im Fenster:**
- **Logs Löschen** = Löscht alle aktuellen Logs
- **In Zwischenablage** = Kopiert alle Logs in die Zwischenablage (für Berichte)
- **Schließen (F3)** = Schließt das Fenster (kann mit F3 wieder geöffnet werden)
- **Auto-Scroll** = Checkbox - Scrollt automatisch zu neuen Logs

### 3. Log-Typen verstehen

Das System unterscheidet vier Log-Typen:

| Typ | Farbe | Bedeutung |
|-----|-------|-----------|
| **INFO** | Grau | Normale Informationen (z.B. "Spiel gestartet") |
| **WARNING** | Gelb | Warnungen (z.B. fehlende Dateien, Performance-Probleme) |
| **ERROR** | Orange-Rot | Fehler (z.B. Null-Referenzen, ungültige Operationen) |
| **CRITICAL** | Rot | Kritische Fehler (z.B. verhinderte Crashes) |

### 4. Fehlerlog exportieren

**So erstellst du einen detaillierten Fehlerbericht:**

1. Spiele bis zum Fehler/Crash
2. Drücke **F3** um das Debug-Fenster zu öffnen
3. Klicke auf **"In Zwischenablage"**
4. Die Logs sind jetzt in deiner Zwischenablage
5. Füge sie hier im Chat ein (Strg+V)

**Alternative:** Log-Datei finden
- Die Logs werden auch automatisch gespeichert in:
  ```
  C:\Users\<DeinName>\AppData\Roaming\Godot\app_userdata\Robocalypse\debug_log.txt
  ```
- Öffne diese Datei mit einem Texteditor und kopiere den Inhalt

### 5. Statistik verstehen

Oben im Debug-Fenster siehst du:
- **Fehler: X** = Anzahl ERROR + CRITICAL Logs (wird rot bei Fehlern)
- **Warnungen: X** = Anzahl WARNING Logs (gelb)
- **Info: X** = Anzahl INFO Logs (grau)

### 6. Automatische Fehlererfassung

Das System erfasst automatisch:
- ✅ GDScript-Fehler (push_error)
- ✅ Warnungen (push_warning)
- ✅ Null-Reference-Fehler
- ✅ Ungültige Methodenaufrufe
- ✅ Crashes und kritische Zustände
- ✅ Performance-Probleme

### 7. Beispiel: Fehler melden

**Gutes Beispiel:**
```
Kopiere den kompletten Log-Output:

=== ROBOCALYPSE FEHLERLOG ===
Exportiert: 2025-01-17 23:45:12
Gesamt Fehler: 3 | Warnungen: 1 | Info: 5
=====================================

[23:42:15] [INFO] Spiel gestartet - Wave 1
[23:42:18] [INFO] Wave 2 gestartet
[23:42:25] [ERROR] NULL REFERENCE: enemy.gd:245 - player ist null
[23:42:25] [CRITICAL] CRASH PREVENTED: laser_bullet.gd:163 - Ungültige Chain-Target
[23:42:30] [WARNING] Performance: 45 FPS (unter 60)
```

Dieser Log zeigt:
- Spiel lief bis Wave 2
- Bei 23:42:25 gab es einen Fehler mit einem null-player
- Gleichzeitig verhinderte das System einen Laser-Chain-Crash
- Performance-Warnung bei 45 FPS

## Troubleshooting

### Fenster erscheint nicht
1. Drücke **F3**
2. Prüfe ob `DebugLogger` als Autoload konfiguriert ist (in project.godot)

### Keine Logs erscheinen
1. Prüfe ob das Spiel läuft
2. Drücke F3 mehrmals um Fenster zu togglen
3. Prüfe die Log-Datei (siehe Punkt 4 oben)

### Fenster zu klein/groß
- Das Fenster ist fest positioniert bei (20, 20) mit Größe 800x500
- Zum Ändern: Bearbeite `DebugLogWindow.tscn` im Godot-Editor

## Für Entwickler: Eigene Logs hinzufügen

Du kannst das System auch in deinem Code nutzen:

```gdscript
# Info-Log
DebugLogger.log_info("Spieler hat Level-Up erreicht")

# Warnung
DebugLogger.log_warning("Zu viele Gegner spawned (Performance-Risiko)")

# Fehler
DebugLogger.log_error("Konnte Item nicht laden: " + item_id)

# Kritischer Fehler
DebugLogger.log_critical("Spieler-Referenz verloren - Spiel instabil")
```

## Technische Details

**Dateien:**
- `scripts/debug_logger.gd` = Logger-Singleton
- `scripts/debug_log_window.gd` = UI-Script
- `scenes/DebugLogWindow.tscn` = UI-Szene
- `scripts/error_catcher.gd` = Error-Catcher (optional)

**Limits:**
- Max. 500 Logs im Speicher
- Älteste Logs werden automatisch gelöscht
- Log-Datei hat kein Limit

**Performance:**
- Minimaler Overhead (~0.1ms pro Log)
- Auto-Save in Datei (asynchron)
- Kein Impact auf Gameplay

## Bekannte Einschränkungen

- Godot's interne Engine-Fehler werden nicht alle erfasst
- C++-Crashes können nicht abgefangen werden
- Sehr schnelle Logs (>1000/s) können UI verlangsamen

## Support

Bei Problemen mit dem Debug-System:
1. Prüfe ob alle Dateien vorhanden sind
2. Prüfe Godot-Console (Output-Tab im Editor)
3. Erstelle einen Fehlerbericht mit Log-Export
