# GitHub Issues - Implementation Guide

## 📋 Übersicht

Dieses Repository enthält detaillierte Issue-Templates für zukünftige Features und Optimierungen. Jedes Template enthält einen kompletten **Claude Sonnet AI Prompt** für die bestmögliche Implementierung.

## 🎯 Verfügbare Issues

### Kritische Features (🔴 Priorität: Hoch)
| Issue | Titel | Labels | Aufwand |
|-------|-------|--------|---------|
| #7 | Boss-Gegner Spawn-Logik | `enhancement`, `gameplay`, `critical` | 1-2 Tage |
| #9 | Hauptmenü mit Settings | `UI`, `enhancement`, `user-experience` | 2-3 Tage |

### Wichtige Features (🟡 Priorität: Mittel)
| Issue | Titel | Labels | Aufwand |
|-------|-------|--------|---------|
| #8 | Object Pooling | `optimization`, `performance` | 1-2 Tage |
| #10 | Drone XP-System | `gameplay`, `drone`, `enhancement` | 1 Tag |

## 🚀 Issues auf GitHub erstellen

### Option 1: Manuell über GitHub Web Interface

1. Gehe zu: https://github.com/reid15halo-ops/robocalypse-godot4/issues/new/choose
2. Wähle ein Issue-Template aus (z.B. `issue_07_boss_spawn.md`)
3. GitHub lädt automatisch den Titel, Body und Labels
4. Klicke "Submit new issue"
5. Wiederhole für alle Templates

### Option 2: Mit GitHub CLI (empfohlen)

```powershell
# GitHub CLI installieren (falls noch nicht vorhanden)
winget install --id GitHub.cli

# Login
gh auth login

# Issues automatisch erstellen
cd "C:\Users\122798\OneDrive\Documents\Marzola Programme\robocalypse-godot4"

# Issue #7: Boss Spawn
gh issue create --template issue_07_boss_spawn.md --repo reid15halo-ops/robocalypse-godot4

# Issue #8: Object Pooling
gh issue create --template issue_08_object_pooling.md --repo reid15halo-ops/robocalypse-godot4

# Issue #9: Hauptmenü
gh issue create --template issue_09_main_menu.md --repo reid15halo-ops/robocalypse-godot4

# Issue #10: Drone XP
gh issue create --template issue_10_drone_xp.md --repo reid15halo-ops/robocalypse-godot4
```

### Option 3: Batch-Erstellung (alle auf einmal)

Öffne PowerShell und führe aus:

```powershell
cd "C:\Users\122798\OneDrive\Documents\Marzola Programme\robocalypse-godot4"

$templates = @(
    "issue_07_boss_spawn",
    "issue_08_object_pooling",
    "issue_09_main_menu",
    "issue_10_drone_xp"
)

foreach ($template in $templates) {
    gh issue create --template "$template.md" --repo reid15halo-ops/robocalypse-godot4
    Write-Host "✅ Created issue from $template" -ForegroundColor Green
}
```

## 🤖 Claude Sonnet AI verwenden

Jedes Issue-Template enthält einen vollständigen **Claude Sonnet AI Prompt** im Abschnitt `## 🤖 Claude Sonnet AI Prompt`.

### So verwendest du den Prompt:

1. **Kopiere den kompletten Prompt-Block** (alles innerhalb der ````markdown ... ````)
2. **Öffne Claude.ai** oder deine Claude-Integration
3. **Füge den Prompt ein** und sende ihn
4. Claude wird:
   - Den Code analysieren
   - Die Implementierung vornehmen
   - Vollständige Code-Änderungen bereitstellen
   - Tests vorschlagen

### Beispiel-Workflow:

```bash
# 1. Issue auf GitHub öffnen
https://github.com/reid15halo-ops/robocalypse-godot4/issues/7

# 2. Claude Prompt kopieren aus Issue-Beschreibung

# 3. Branch erstellen
git checkout work-version
git pull origin work-version
git checkout -b feature/boss-spawn-logic

# 4. Claude Prompt in Claude.ai einfügen

# 5. Code-Änderungen von Claude übernehmen

# 6. Testen und committen
git add .
git commit -m "feat(gameplay): implement boss spawn logic

- Boss spawns every 5th wave
- Boss has 5x HP, 2x Damage, 0.7x Speed
- Boss defeat grants 100 scrap + 500 XP
- Visual/Audio feedback on boss arrival

Closes #7"

# 7. Push und PR erstellen
git push -u origin feature/boss-spawn-logic
gh pr create --base work-version --title "feat: Boss spawn logic (#7)"
```

## 📊 Issue-Priorisierung

### Sprint 1 (diese Woche)
- [x] #2: Lokalisierung ✅ Erledigt
- [ ] #7: Boss Spawn Logic (🔴 Kritisch)
- [ ] #9: Hauptmenü

### Sprint 2 (nächste Woche)
- [ ] #10: Drone XP-System
- [ ] #8: Object Pooling

## 🔄 Workflow für jedes Issue

```
1. Issue lesen
   ↓
2. Branch erstellen (feature/issue-name)
   ↓
3. Claude Prompt verwenden
   ↓
4. Code implementieren
   ↓
5. Tests durchführen (Checklist)
   ↓
6. Commit mit "Closes #X"
   ↓
7. PR erstellen
   ↓
8. Review & Merge
```

## 📝 Template-Struktur

Jedes Issue-Template enthält:

- **🎯 Ziel:** Was soll erreicht werden?
- **📋 Kontext:** Wo im Code, was ist das Problem?
- **✅ Akzeptanzkriterien:** Wann ist das Issue erledigt?
- **🤖 Claude Sonnet AI Prompt:** Kompletter Prompt für Claude
- **📝 Implementation Notes:** Code-Beispiele, Formeln
- **🧪 Testing Checklist:** Was muss getestet werden?
- **🔗 Related Issues:** Abhängigkeiten
- **📚 References:** Godot Docs, Game Design Patterns

## 🎨 Best Practices

### Commit Messages
```
feat(scope): kurze Beschreibung

- Detail 1
- Detail 2
- Detail 3

Closes #X
```

### Branch Names
```
feature/issue-name     # Neue Features
fix/bug-description    # Bug Fixes
refactor/system-name   # Code Refactoring
docs/update-readme     # Dokumentation
```

### PR Titles
```
feat: Boss spawn logic (#7)
fix: Drone XP calculation (#10)
refactor: Object pooling system (#8)
```

## 🆘 Hilfe & Support

- **GitHub Issues:** https://github.com/reid15halo-ops/robocalypse-godot4/issues
- **Godot Docs:** https://docs.godotengine.org/en/stable/
- **Claude AI:** https://claude.ai
- **Discord:** [Your Discord Server]

## 📚 Weitere Ressourcen

- [Godot 4 Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
- [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Game Design Patterns](https://gameprogrammingpatterns.com/)

---

**Erstellt am:** 21. Oktober 2025  
**Letzte Aktualisierung:** 21. Oktober 2025  
**Version:** 1.0
