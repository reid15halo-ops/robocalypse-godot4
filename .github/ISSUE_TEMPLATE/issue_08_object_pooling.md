---
name: Object Pooling für Performance
about: Implementiere Object Pooling für Enemies und Projectiles
title: '[OPTIMIZATION] Object Pooling für Performance-Optimierung'
labels: optimization, performance, enhancement
assignees: ''
---

## 🎯 Ziel
Reduziere Garbage Collection Spikes durch Object Pooling für häufig instanziierte Objekte (Enemies, Projectiles).

## 📋 Kontext
- **Problem:** Ständiges `instantiate()` und `queue_free()` verursacht GC-Spikes
- **Impact:** FPS-Drops bei 50+ Enemies oder vielen Projectiles
- **Dateien:** `scripts/game.gd:450-500` (spawn_enemy), Projectile Spawn Logic

## ✅ Akzeptanzkriterien
- [ ] EnemyPool verwaltet 50-100 pre-instantiated enemies
- [ ] ProjectilePool für Player/Enemy Bullets
- [ ] Pool wächst dynamisch bei Bedarf (max 200)
- [ ] Performance: Stabile 60 FPS bei 100+ aktiven Enemies
- [ ] Memory: Max 100MB RAM für Pools
- [ ] API: `pool.get_instance()`, `pool.return_instance(obj)`

## 🤖 Claude Sonnet AI Prompt

```markdown
You are Claude Sonnet 4 acting as a Godot 4 performance optimization expert. Implement object pooling system for robocalypse-godot4.

CONTEXT:
- Repository: reid15halo-ops/robocalypse-godot4
- Branch: work-version
- Current problem: Frequent instantiate()/queue_free() causes GC spikes and FPS drops
- Target objects: Enemies (5 types), Projectiles (Player bullets, Enemy bullets)

REQUIREMENTS:
1. Create ObjectPool base class (res://scripts/ObjectPool.gd):
   - Properties: pool (Array), scene (PackedScene), initial_size, max_size
   - Methods: get_instance(), return_instance(obj), _grow_pool()
   
2. Create EnemyPool singleton (autoload):
   - Manages pools for each enemy type (Standard, Fast, Heavy, Sniper, Kamikaze)
   - Pre-instantiate 20 of each type on _ready()
   - Grow dynamically up to 50 per type

3. Create ProjectilePool singleton (autoload):
   - Separate pools for Player bullets vs Enemy bullets
   - Pre-instantiate 100 player bullets, 50 enemy bullets
   - Very fast get/return (bullets spawn frequently)

4. Refactor game.gd spawn logic:
   - Replace: `var enemy = enemy_scene.instantiate()`
   - With: `var enemy = EnemyPool.get_instance(enemy_type)`
   - On enemy death: `EnemyPool.return_instance(enemy)` instead of `queue_free()`

5. Pooled object lifecycle:
   - get_instance(): Show node, reset position/stats, enable collision
   - return_instance(): Hide node, disable collision, reset state

IMPLEMENTATION STEPS:
1. Create ObjectPool.gd base class
2. Create EnemyPool.gd (extends Node, autoload)
3. Create ProjectilePool.gd (extends Node, autoload)
4. Register autoloads in project.godot
5. Refactor game.gd: Replace instantiate/free calls
6. Add pool monitoring (debug UI: "Pool: 45/50 active")
7. Profile before/after: Measure FPS, GC time, memory usage

CODE EXAMPLE:
```gdscript
# ObjectPool.gd
class_name ObjectPool extends Node

var pool: Array[Node] = []
var scene: PackedScene
var initial_size: int = 20
var max_size: int = 100
var active_count: int = 0

func _ready() -> void:
    for i in initial_size:
        _create_instance()

func get_instance() -> Node:
    if pool.is_empty():
        if active_count < max_size:
            return _create_instance()
        else:
            push_warning("Pool exhausted!")
            return null
    
    var obj = pool.pop_back()
    obj.show()
    obj.set_process(true)
    active_count += 1
    return obj

func return_instance(obj: Node) -> void:
    obj.hide()
    obj.set_process(false)
    pool.append(obj)
    active_count -= 1

func _create_instance() -> Node:
    var obj = scene.instantiate()
    obj.hide()
    add_child(obj)
    pool.append(obj)
    return pool.pop_back()
```

TESTING:
- Spawn 100 enemies rapidly → Check FPS stays 60
- Kill all enemies → Check memory doesn't leak
- Debug overlay: Show active/pooled counts

RETURN FORMAT:
Provide complete code for ObjectPool.gd, EnemyPool.gd, ProjectilePool.gd plus refactored game.gd sections.
```

## 📝 Implementation Notes

### Performance Targets
- **Before:** 30-40 FPS @ 100 enemies, GC spikes every 5s
- **After:** 60 FPS @ 100 enemies, minimal GC activity
- **Memory:** +50MB initial (pre-instantiated pools), stable during gameplay

### Pool Sizes
| Object Type | Initial | Max | Reason |
|-------------|---------|-----|--------|
| Enemy (each) | 20 | 50 | 5 types = 100 total |
| Player Bullet | 100 | 200 | High fire rate |
| Enemy Bullet | 50 | 100 | Multiple enemies |

### Debug UI (Optional)
```gdscript
# Show in HUD corner
Label: "Pools: E:45/100 P:80/200 EB:30/100"
```

## 🧪 Testing Checklist
- [ ] Pools pre-instantiate correctly on game start
- [ ] get_instance() returns valid, reset objects
- [ ] return_instance() properly hides and disables objects
- [ ] No memory leaks after 1000+ enemy spawns
- [ ] FPS stable at 60 with 100+ active enemies
- [ ] GC time reduced (use Godot Profiler)
- [ ] Pool grows dynamically when exhausted
- [ ] Pool doesn't exceed max_size limit

## 🔗 Related Issues
- Blocks: #15 (State Machine - easier with pooled objects)
- Related: #17 (Unit Tests - test pool logic)

## 📚 References
- Godot Docs: Node Management, Memory Optimization
- Design Pattern: Object Pool Pattern
- Similar Implementation: Godot Wild Jam Games
