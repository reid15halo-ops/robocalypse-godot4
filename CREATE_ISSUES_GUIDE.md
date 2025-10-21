# 🚀 GitHub Issues Erstellen - Schnellanleitung

Da GitHub CLI nicht installiert ist, folge dieser Schritt-für-Schritt-Anleitung zum manuellen Erstellen der Issues.

## ✅ Issue-Templates bereit zum Erstellen

| # | Titel | Priorität | Aufwand |
|---|-------|-----------|---------|
| #7 | Boss-Gegner Spawn-Logik | 🔴 Kritisch | 1-2 Tage |
| #8 | Object Pooling | 🟡 Mittel | 1-2 Tage |
| #9 | Hauptmenü mit Settings | 🔴 Kritisch | 2-3 Tage |
| #10 | Drone XP-System | 🟡 Mittel | 1 Tag |
| #11 | Damage Numbers | 🟢 Nice-to-Have | 1 Tag |
| #12 | Achievement System | 🟡 Mittel | 2 Tage |
| #14 | Audio System | 🔴 Kritisch | 2-3 Tage |

**Total: 7 Issues | Geschätzter Aufwand: 10-14 Tage**

---

## 📋 Methode 1: Manuell über GitHub (Einfach)

### Schritt 1: Repository öffnen
```
https://github.com/reid15halo-ops/robocalypse-godot4/issues
```

### Schritt 2: "New Issue" klicken

### Schritt 3: Issue-Details einfügen

Für **jedes der 7 Issues**:

1. **Titel** kopieren aus Template (z.B. "[GAMEPLAY] Boss-Gegner Spawn-Logik implementieren")
2. **Body** kopieren (gesamter Inhalt des .md Files)
3. **Labels** hinzufügen:
   - Issue #7: `enhancement`, `gameplay`, `critical`
   - Issue #8: `optimization`, `performance`, `enhancement`
   - Issue #9: `UI`, `enhancement`, `user-experience`
   - Issue #10: `gameplay`, `drone`, `enhancement`
   - Issue #11: `UI`, `enhancement`, `visual-feedback`
   - Issue #12: `meta-progression`, `enhancement`, `gamification`
   - Issue #14: `audio`, `enhancement`, `polish`, `critical`
4. **Submit new issue**

---

## ⚡ Methode 2: Schnell-Links (Öffnet Issue-Formular)

Klicke auf diese Links um Issues direkt zu erstellen:

### Issue #7: Boss Spawn
```
https://github.com/reid15halo-ops/robocalypse-godot4/issues/new?title=[GAMEPLAY]%20Boss-Gegner%20Spawn-Logik%20implementieren&labels=enhancement,gameplay,critical
```
**Dann kopiere Body aus:** `.github/ISSUE_TEMPLATE/issue_07_boss_spawn.md`

### Issue #8: Object Pooling
```
https://github.com/reid15halo-ops/robocalypse-godot4/issues/new?title=[OPTIMIZATION]%20Object%20Pooling%20für%20Performance-Optimierung&labels=optimization,performance,enhancement
```
**Dann kopiere Body aus:** `.github/ISSUE_TEMPLATE/issue_08_object_pooling.md`

### Issue #9: Hauptmenü
```
https://github.com/reid15halo-ops/robocalypse-godot4/issues/new?title=[UI]%20Hauptmenü%20mit%20Settings%20erstellen&labels=UI,enhancement,user-experience
```
**Dann kopiere Body aus:** `.github/ISSUE_TEMPLATE/issue_09_main_menu.md`

### Issue #10: Drone XP
```
https://github.com/reid15halo-ops/robocalypse-godot4/issues/new?title=[GAMEPLAY]%20Drone%20XP-System%20vervollständigen&labels=gameplay,drone,enhancement
```
**Dann kopiere Body aus:** `.github/ISSUE_TEMPLATE/issue_10_drone_xp.md`

### Issue #11: Damage Numbers
```
https://github.com/reid15halo-ops/robocalypse-godot4/issues/new?title=[UI]%20Damage%20Numbers%20(Floating%20Combat%20Text)&labels=UI,enhancement,visual-feedback
```
**Dann kopiere Body aus:** `.github/ISSUE_TEMPLATE/issue_11_damage_numbers.md`

### Issue #12: Achievements
```
https://github.com/reid15halo-ops/robocalypse-godot4/issues/new?title=[PROGRESSION]%20Achievement%20System%20implementieren&labels=meta-progression,enhancement,gamification
```
**Dann kopiere Body aus:** `.github/ISSUE_TEMPLATE/issue_12_achievements.md`

### Issue #14: Audio System
```
https://github.com/reid15halo-ops/robocalypse-godot4/issues/new?title=[AUDIO]%20Audio%20System%20vervollständigen&labels=audio,enhancement,polish,critical
```
**Dann kopiere Body aus:** `.github/ISSUE_TEMPLATE/issue_14_audio_system.md`

---

## 🤖 GitHub CLI Installation (Für zukünftige Automatisierung)

Wenn du später Issues automatisch erstellen möchtest:

### Installation
```powershell
winget install --id GitHub.cli
```

### Login
```powershell
gh auth login
```

### Issues automatisch erstellen
```powershell
cd "C:\Users\122798\OneDrive\Documents\Marzola Programme\robocalypse-godot4"

# Alle Issues auf einmal erstellen
.\create_github_issues.ps1
```

---

## 📊 Priorisierte Reihenfolge

### **Sprint 1: Core Gameplay** (Diese/Nächste Woche)
1. ✅ Issue #2: Lokalisierung (bereits erledigt)
2. 🔴 **Issue #7: Boss Spawn** (Kritisch für Gameplay)
3. 🔴 **Issue #14: Audio System** (Kritisch für Spielgefühl)
4. 🔴 **Issue #9: Hauptmenü** (Kritisch für Release)

### **Sprint 2: Features & Polish** (Übernächste Woche)
5. 🟡 **Issue #10: Drone XP** (Wichtig für Progression)
6. 🟡 **Issue #12: Achievements** (Wichtig für Replay-Value)
7. 🟢 **Issue #11: Damage Numbers** (Nice-to-Have, schnell umsetzbar)

### **Sprint 3: Performance** (Optional, später)
8. 🟡 **Issue #8: Object Pooling** (Wichtig bei Performance-Problemen)

---

## 🎯 Nach dem Erstellen der Issues

### 1. Milestone erstellen (Optional)
```
Milestone: "Version 0.4 - Core Features Complete"
Due Date: [Ihr Wunschdatum]
Issues: #7, #8, #9, #10, #11, #12, #14
```

### 2. Project Board erstellen (Optional)
```
Columns:
- 📋 Backlog (alle neuen Issues)
- 🔥 In Progress (aktuell bearbeitet)
- ✅ Done (fertiggestellt)
```

### 3. Issue #7 starten
```bash
# Branch erstellen
git checkout work-version
git pull origin work-version
git checkout -b feature/boss-spawn-logic

# Claude Prompt aus Issue #7 kopieren
# Code implementieren
# Testen mit Checklist
# Commit + Push + PR
```

---

## 🔄 Workflow für jedes Issue

```
1. Issue auf GitHub öffnen
   ↓
2. Issue lesen & verstehen
   ↓
3. Branch erstellen: git checkout -b feature/issue-name
   ↓
4. Claude Prompt aus Issue kopieren → Claude.ai
   ↓
5. Code von Claude implementieren
   ↓
6. Testing Checklist abarbeiten
   ↓
7. git commit -m "feat(scope): description

   Closes #X"
   ↓
8. git push -u origin feature/issue-name
   ↓
9. PR erstellen auf GitHub
   ↓
10. Review & Merge
```

---

## 📚 Hilfreiche Ressourcen

### Dokumentation
- **Issue Templates:** `.github/ISSUE_TEMPLATE/README.md`
- **Claude Prompts:** In jedem Issue unter "🤖 Claude Sonnet AI Prompt"
- **Testing Checklists:** In jedem Issue unter "🧪 Testing Checklist"

### Tools
- **Claude AI:** https://claude.ai
- **Godot Docs:** https://docs.godotengine.org/en/stable/
- **GitHub Issues:** https://github.com/reid15halo-ops/robocalypse-godot4/issues

---

## ✅ Checkliste: Issues erstellt?

- [ ] Issue #7: Boss Spawn
- [ ] Issue #8: Object Pooling
- [ ] Issue #9: Hauptmenü
- [ ] Issue #10: Drone XP
- [ ] Issue #11: Damage Numbers
- [ ] Issue #12: Achievements
- [ ] Issue #14: Audio System

**Nach dem Erstellen:**
- [ ] Milestone "Version 0.4" erstellt (optional)
- [ ] Project Board erstellt (optional)
- [ ] Issue #7 als erstes angefangen

---

**Geschätzter Zeit-Aufwand zum Erstellen:** 15-20 Minuten für alle 7 Issues

**Viel Erfolg! 🚀**
