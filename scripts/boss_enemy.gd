extends CharacterBody2D

var wall_velocity: Vector2 = Vector2.ZERO

# Movement
@export var speed: float = 140.0  # Base speed before phase modifiers

# Health
@export var max_health: int = 6000  # Drastically increased survivability
var current_health: int = 6000
@export var hp_regen_rate: float = 0.0

# Phase handling
var phase: int = 1
var special_attack_cooldown: float = 4.5
var special_attack_timer: float = 0.0

const PHASE_SPEEDS := [140.0, 160.0, 185.0, 210.0]
const PHASE_COOLDOWNS := [4.5, 3.5, 2.8, 2.2]
const PHASE_MINION_COOLDOWNS := [6.0, 5.0, 4.0, 2.5]

var ability_pools: Dictionary = {
	1: ["laser_burst", "orbital_strike"],
	2: ["laser_burst", "orbital_strike", "shockwave_burst", "drone_swarm"],
	3: ["rapid_barrage", "plasma_wall", "gravity_well", "drone_swarm"],
	4: ["obliteration_beam", "gravity_well", "shield_overdrive", "plasma_wall"]
}

# Navigation
var player: CharacterBody2D = null

# Score value
@export var score_value: int = 100

# Minion spawning
var minion_spawn_cooldown: float = 6.0
var minion_spawn_timer: float = 0.0
var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
var enemy_projectile_scene: PackedScene = preload("res://scenes/EnemyProjectile.tscn")

# Visual
var sprite: AnimatedSprite2D = null
var visual_node: Node2D = null
var use_sprites: bool = true  # Sprites now available!

# Defensive systems
var shield_active: bool = false
var shield_value: float = 0.0
const SHIELD_MAX: float = 900.0
const SHIELD_DURATION: float = 7.0
var shield_timer: float = 0.0
var shield_visual: Node2D = null

# Gravity well effect
var gravity_well_timer: float = 0.0
var gravity_well_duration: float = 0.0
var gravity_well_position: Vector2 = Vector2.ZERO
var gravity_well_strength: float = 450.0
var gravity_damage_timer: float = 0.0
var gravity_well_visual: Node2D = null

# Plasma wall tracking
var plasma_walls: Array[Dictionary] = []

func _get_arena_rect() -> Rect2:
	var game_scene: Node = get_tree().get_first_node_in_group("game_scene")
	if game_scene and game_scene.has_node("MapGenerator"):
		var generator: Node = game_scene.get_node("MapGenerator")
		if generator and generator.has_method("get_arena_bounds"):
			return generator.get_arena_bounds()
	return Rect2(Vector2.ZERO, Vector2(1792, 1792))


func _ready() -> void:
	# Set collision layer and mask
	collision_layer = 2  # Layer 2 (Enemy)
	collision_mask = 14  # Spec: collide with enemy/wall layers

	# Add to enemies group
	add_to_group("enemies")
	add_to_group("bosses")

	# Initialize health
	current_health = max_health

	# Get player reference
	player = GameManager.get_player()

	_set_phase_stats()

	# Create visual
	_create_boss_visual()

	# Play boss spawn sound
	AudioManager.play_boss_spawn_sound()


func _set_phase_stats() -> void:
	var idx: int = clamp(phase - 1, 0, PHASE_SPEEDS.size() - 1)
	speed = PHASE_SPEEDS[idx]
	special_attack_cooldown = PHASE_COOLDOWNS[idx]
	minion_spawn_cooldown = PHASE_MINION_COOLDOWNS[idx]
	special_attack_timer = 0.0
	minion_spawn_timer = 0.0
	_apply_phase_color()


func _apply_phase_color() -> void:
	match phase:
		1:
			modulate = Color(1.0, 1.0, 1.0)
		2:
			modulate = Color(1.2, 0.55, 0.55)
		3:
			modulate = Color(1.6, 0.35, 0.35)
		4:
			modulate = Color(2.0, 0.25, 0.25)


func _physics_process(delta: float) -> void:
	# Refresh player reference if needed
	if not player:
		player = GameManager.get_player()

	if not player or GameManager.is_game_over:
		return

	if hp_regen_rate > 0.0 and current_health < max_health:
		current_health = min(current_health + hp_regen_rate * delta, max_health)
		_update_health_bar()

	# Update timers
	special_attack_timer += delta
	minion_spawn_timer += delta

	# Check phase transitions
	_update_phase()

	# Movement - chase player (with null check)
	if not is_instance_valid(player):
		return

	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

	_update_active_effects(delta)

	# Special attacks
	if special_attack_timer >= special_attack_cooldown:
		special_attack_timer = 0.0
		_perform_special_attack()

	# Spawn minions
	if minion_spawn_timer >= minion_spawn_cooldown:
		minion_spawn_timer = 0.0
		_spawn_minions()


func _update_active_effects(delta: float) -> void:
	# Shield decay
	if shield_active:
		shield_timer -= delta
		if shield_timer <= 0.0:
			_deactivate_shield()
		else:
			shield_value = max(0.0, shield_value - (SHIELD_MAX / SHIELD_DURATION) * 0.2 * delta)

	# Gravity well pull
	if gravity_well_timer > 0.0:
		gravity_well_timer -= delta
		gravity_damage_timer += delta
		if player and is_instance_valid(player):
			var to_well: Vector2 = gravity_well_position - player.global_position
			var distance: float = to_well.length()
			if distance > 0.1:
				var pull: Vector2 = to_well.normalized() * gravity_well_strength * delta
				if player.has_variable("external_velocity"):
					player.external_velocity += pull
			if distance <= 120.0 and gravity_damage_timer >= 0.5:
				gravity_damage_timer = 0.0
				if player.has_method("take_damage"):
					player.take_damage(35)
		if gravity_well_timer <= 0.0:
			gravity_well_duration = 0.0
			if gravity_well_visual and is_instance_valid(gravity_well_visual):
				gravity_well_visual.queue_free()
				gravity_well_visual = null
	else:
		if gravity_well_visual and is_instance_valid(gravity_well_visual):
			gravity_well_visual.queue_free()
			gravity_well_visual = null

	# Plasma wall management
	if plasma_walls.size() > 0:
		for i in range(plasma_walls.size() - 1, -1, -1):
			var wall_entry: Dictionary = plasma_walls[i]
			var node: Node2D = wall_entry.get("node")
			if not is_instance_valid(node):
				plasma_walls.remove_at(i)
				continue

			wall_velocity = wall_entry.get("velocity", Vector2.ZERO)
			var lifespan: float = wall_entry.get("lifespan", 0.0) - delta
			var damage_timer: float = wall_entry.get("damage_timer", 0.0) + delta
			node.global_position += wall_velocity * delta

			if player and is_instance_valid(player) and damage_timer >= 0.4:
				if player.global_position.distance_to(node.global_position) <= wall_entry.get("damage_radius", 140.0):
					if player.has_method("take_damage"):
						player.take_damage(30 + 10 * (phase - 1))
				damage_timer = 0.0

			if lifespan <= 0.0:
				node.queue_free()
				plasma_walls.remove_at(i)
			else:
				wall_entry["lifespan"] = lifespan
				wall_entry["damage_timer"] = damage_timer
				plasma_walls[i] = wall_entry


func _update_phase() -> void:
	var health_percent: float = float(current_health) / float(max_health)
	var target_phase: int = 1

	if health_percent <= 0.20:
		target_phase = 4
	elif health_percent <= 0.45:
		target_phase = 3
	elif health_percent <= 0.75:
		target_phase = 2

	if target_phase != phase:
		phase = target_phase
		_set_phase_stats()
		AudioManager.play_boss_rage_sound()
		print("Boss shifted to phase ", phase)


func _perform_special_attack() -> void:
	var pool: Array = ability_pools.get(phase, ability_pools.get(ability_pools.keys().max(), []))
	if pool.is_empty():
		return

	var ability_name: String = pool[randi() % pool.size()]

	match ability_name:
		"laser_burst":
			await _laser_burst()
		"orbital_strike":
			await _orbital_strike()
		"shockwave_burst":
			await _shockwave_burst()
		"drone_swarm":
			await _drone_swarm()
		"rapid_barrage":
			await _rapid_barrage()
		"plasma_wall":
			await _plasma_wall()
		"gravity_well":
			await _gravity_well()
		"obliteration_beam":
			await _obliteration_beam()
		"shield_overdrive":
			_shield_overdrive()
		_:
			await _laser_burst()


func _laser_burst() -> void:
	if is_queued_for_deletion():
		return

	var original_modulate: Color = modulate
	modulate = Color(2.0, 2.0, 0.6)
	await get_tree().create_timer(0.15).timeout

	var projectile_count: int = 12
	for i in range(projectile_count):
		var angle: float = TAU * float(i) / float(projectile_count)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var projectile: Node2D = enemy_projectile_scene.instantiate()
		projectile.global_position = global_position + direction * 48.0
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction)
		projectile.speed = 420.0 + 40.0 * phase
		projectile.damage = 30 + phase * 12
		get_parent().add_child(projectile)

	if player and is_instance_valid(player) and global_position.distance_to(player.global_position) <= 160.0:
		if player.has_method("take_damage"):
			player.take_damage(45 + phase * 10)

	await get_tree().create_timer(0.1).timeout
	modulate = original_modulate


func _orbital_strike() -> void:
	if not player or not is_instance_valid(player) or is_queued_for_deletion():
		return

	var base_pos: Vector2 = player.global_position
	var markers: Array[Node2D] = []
	for i in range(4):
		var angle: float = randf_range(0.0, TAU)
		var radius: float = randf_range(150.0, 260.0)
		var marker: Node2D = Node2D.new()
		marker.global_position = base_pos + Vector2(cos(angle), sin(angle)) * radius
		var ring: Polygon2D = Polygon2D.new()
		ring.polygon = _circle_points(70.0)
		ring.color = Color(1.0, 0.4, 0.1, 0.35)
		marker.add_child(ring)
		get_parent().add_child(marker)
		markers.append(marker)
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(ring, "scale", Vector2(1.4, 1.4), 0.8)
		tween.tween_property(ring, "modulate:a", 0.0, 0.8)

	await get_tree().create_timer(0.9).timeout

	for marker in markers:
		if not is_instance_valid(marker):
			continue
		var explosion: Polygon2D = Polygon2D.new()
		explosion.polygon = _circle_points(100.0)
		explosion.color = Color(1.0, 0.2, 0.1, 0.6)
		marker.add_child(explosion)
		if player and is_instance_valid(player) and player.global_position.distance_to(marker.global_position) <= 120.0:
			if player.has_method("take_damage"):
				player.take_damage(65 + phase * 10)
		get_tree().process_frame
		if is_instance_valid(marker):
			marker.queue_free()


func _shockwave_burst() -> void:
	for pulse in range(2):
		if is_queued_for_deletion():
			return
		var shock_node: Node2D = Node2D.new()
		shock_node.global_position = global_position
		get_parent().add_child(shock_node)

		var ring: Polygon2D = Polygon2D.new()
		ring.polygon = _circle_points(60.0)
		ring.color = Color(0.3, 0.6, 1.0, 0.45)
		shock_node.add_child(ring)

		var max_radius: float = 280.0 + pulse * 90.0
		var tween: Tween = get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector2(max_radius / 60.0, max_radius / 60.0), 0.6)
		tween.tween_property(ring, "modulate:a", 0.0, 0.6)

		await get_tree().create_timer(0.35).timeout

		if player and is_instance_valid(player) and global_position.distance_to(player.global_position) <= max_radius:
			if player.has_method("take_damage"):
				player.take_damage(60 + phase * 15)

		await get_tree().create_timer(0.25).timeout
		if is_instance_valid(shock_node):
			shock_node.queue_free()


func _drone_swarm() -> void:
	var count: int = 4 + phase
	var radius: float = 220.0
	for i in range(count):
		var angle: float = TAU * float(i) / float(count)
		var minion: Node2D = enemy_scene.instantiate()
		minion.global_position = global_position + Vector2(cos(angle), sin(angle)) * radius
		get_parent().add_child(minion)
	await get_tree().create_timer(0.3).timeout


func _rapid_barrage() -> void:
	var volleys: int = 5 + phase
	for i in range(volleys):
		if is_queued_for_deletion():
			return
		if player and is_instance_valid(player):
			var direction: Vector2 = (player.global_position - global_position).normalized()
			if direction.length() < 0.1:
				direction = Vector2.RIGHT
			direction = direction.rotated(randf_range(-0.3, 0.3))
			var projectile: Node2D = enemy_projectile_scene.instantiate()
			projectile.global_position = global_position + direction * 36.0
			if projectile.has_method("set_direction"):
				projectile.set_direction(direction)
			projectile.speed = 520.0 + phase * 50.0
			projectile.damage = 35 + phase * 12
			get_parent().add_child(projectile)
		await get_tree().create_timer(0.18).timeout


func _plasma_wall() -> void:
	return
	var arena: Rect2 = _get_arena_rect()
	var horizontal: bool = randf() < 0.5
	var wall_node: Node2D = Node2D.new()
	wall_node.z_index = 6
	var polygon: Polygon2D = Polygon2D.new()

	var width: float
	var height: float
	if horizontal:
		width = arena.size.x * 0.9
		height = 160.0
	else:
		width = 160.0
		height = arena.size.y * 0.9
	var half_w: float = width / 2.0
	var half_h: float = height / 2.0
	polygon.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	polygon.color = Color(0.6, 0.9, 1.2, 0.45)
	wall_node.add_child(polygon)

	var start_pos: Vector2 = Vector2.ZERO
	wall_velocity = Vector2.ZERO
	if horizontal:
		var from_top: bool = randf() < 0.5
		if from_top:
			start_pos = Vector2(arena.position.x + arena.size.x / 2.0, arena.position.y - half_h - 60.0)
			wall_velocity = Vector2(0.0, 160.0)
		else:
			start_pos = Vector2(arena.position.x + arena.size.x / 2.0, arena.position.y + arena.size.y + half_h + 60.0)
			wall_velocity = Vector2(0.0, -160.0)
	else:
		var from_left: bool = randf() < 0.5
		if from_left:
			start_pos = Vector2(arena.position.x - half_w - 60.0, arena.position.y + arena.size.y / 2.0)
			wall_velocity = Vector2(160.0, 0.0)
		else:
			start_pos = Vector2(arena.position.x + arena.size.x + half_w + 60.0, arena.position.y + arena.size.y / 2.0)
			wall_velocity = Vector2(-160.0, 0.0)

	wall_node.global_position = start_pos
	get_parent().add_child(wall_node)

	plasma_walls.append({
		"node": wall_node,
		"velocity": wall_velocity,
		"lifespan": 5.0,
		"damage_timer": 0.0,
		"damage_radius": max(width, height) * 0.5
	})


func _gravity_well() -> void:
	if not player or not is_instance_valid(player):
		return

	gravity_well_position = player.global_position
	gravity_well_timer = 4.5
	gravity_well_duration = gravity_well_timer
	gravity_damage_timer = 0.0

	if gravity_well_visual and is_instance_valid(gravity_well_visual):
		gravity_well_visual.queue_free()

	gravity_well_visual = Node2D.new()
	gravity_well_visual.z_index = 7
	var core: Polygon2D = Polygon2D.new()
	core.polygon = _circle_points(70.0)
	core.color = Color(0.25, 0.7, 1.2, 0.55)
	gravity_well_visual.add_child(core)
	gravity_well_visual.global_position = gravity_well_position
	get_parent().add_child(gravity_well_visual)

	var tween: Tween = get_tree().create_tween().set_loops()
	tween.tween_property(core, "rotation", TAU, 1.5)
	tween.tween_property(core, "scale", Vector2(1.2, 1.2), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(core, "scale", Vector2(1.0, 1.0), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await get_tree().create_timer(0.1).timeout


func _obliteration_beam() -> void:
	if not player or not is_instance_valid(player):
		return

	var direction: Vector2 = (player.global_position - global_position).normalized()
	if direction.length() < 0.1:
		direction = Vector2.RIGHT

	var beam: Line2D = Line2D.new()
	beam.width = 22.0
	beam.default_color = Color(1.0, 0.35, 0.1, 0.85)
	beam.add_point(Vector2.ZERO)
	beam.add_point(direction * 900.0)
	add_child(beam)

	for _i in range(4):
		await get_tree().create_timer(0.2).timeout
		if not player or not is_instance_valid(player):
			continue
		var to_player: Vector2 = player.global_position - global_position
		var projection: float = to_player.dot(direction)
		if projection < 0.0 or projection > 900.0:
			continue
		var closest_point: Vector2 = global_position + direction * projection
		if closest_point.distance_to(player.global_position) <= 120.0:
			if player.has_method("take_damage"):
				player.take_damage(120)

	if is_instance_valid(beam):
		beam.queue_free()


func _shield_overdrive() -> void:
	shield_active = true
	shield_value = SHIELD_MAX
	shield_timer = SHIELD_DURATION

	if shield_visual and is_instance_valid(shield_visual):
		shield_visual.queue_free()

	shield_visual = Node2D.new()
	var ring: Polygon2D = Polygon2D.new()
	ring.polygon = _circle_points(100.0)
	ring.color = Color(0.2, 1.0, 1.5, 0.45)
	shield_visual.add_child(ring)
	shield_visual.position = Vector2.ZERO
	add_child(shield_visual)

	var tween: Tween = get_tree().create_tween().set_loops()
	tween.tween_property(ring, "rotation", TAU, 2.0)


func _spawn_minions() -> void:
	var minion_count: int = 3 + phase
	for i in range(minion_count):
		var minion: Node2D = enemy_scene.instantiate()
		var angle: float = randf_range(0.0, TAU)
		var distance: float = randf_range(120.0, 240.0)
		minion.global_position = global_position + Vector2(cos(angle), sin(angle)) * distance
		get_parent().add_child(minion)


func take_damage(damage: int) -> void:
	if damage <= 0:
		return

	if shield_active and shield_value > 0.0:
		var absorbed: float = min(float(damage), shield_value)
		shield_value -= absorbed
		damage -= int(absorbed)
		_flash_shield_hit()
		if shield_value <= 0.0:
			_deactivate_shield()

	if damage <= 0:
		return

	current_health -= damage
	_update_health_bar()
	_flash_damage()

	if current_health <= 0:
		die()


func _flash_damage() -> void:
	modulate = Color(1.6, 0.6, 0.6)
	await get_tree().create_timer(0.1).timeout
	if is_queued_for_deletion():
		return
	_apply_phase_color()


func _flash_shield_hit() -> void:
	if shield_visual and is_instance_valid(shield_visual):
		var ring: Polygon2D = shield_visual.get_child(0) as Polygon2D
		if ring and ring is CanvasItem:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(ring, "modulate", Color(0.8, 1.4, 1.6, 0.7), 0.1)
			tween.tween_property(ring, "modulate", Color(0.2, 1.0, 1.5, 0.45), 0.2)


func _deactivate_shield() -> void:
	if not shield_active:
		return
	shield_active = false
	shield_value = 0.0
	shield_timer = 0.0
	if shield_visual and is_instance_valid(shield_visual):
		shield_visual.queue_free()
	shield_visual = null
	_apply_phase_color()


func _clear_plasma_walls() -> void:
	for entry in plasma_walls:
		var node: Node = entry.get("node")
		if node and is_instance_valid(node):
			node.queue_free()
	plasma_walls.clear()


func _update_health_bar() -> void:
	"""Update boss health bar visual"""
	if not has_node("HealthBar"):
		return

	var health_bar: Control = $HealthBar
	var health_percent: float = float(current_health) / float(max_health)
	health_bar.size.x = 60.0 * health_percent  # 60 = max width


func die() -> void:
	"""Handle boss death"""
	if is_queued_for_deletion():
		return

	_deactivate_shield()
	_clear_plasma_walls()
	if gravity_well_visual and is_instance_valid(gravity_well_visual):
		gravity_well_visual.queue_free()
		gravity_well_visual = null

	# Add big score bonus
	GameManager.add_score(score_value)

	# Award scrap (50 per boss - increased from 20)
	var scrap_amount: int = int(50 * MetaProgression.get_scrap_multiplier())
	_award_scrap(scrap_amount)

	# Spawn multiple rewards (could be items/powerups)
	print("Boss defeated! Major rewards!")

	# Remove from scene
	queue_free()


func _award_scrap(amount: int) -> void:
	"""Award scrap to game scene"""
	var game_scene: Node = get_tree().get_first_node_in_group("game_scene")
	if not game_scene:
		return
	if game_scene.has_method("register_kill"):
		game_scene.register_kill()
	if amount > 0 and game_scene.has_method("spawn_scrap_pickups"):
		game_scene.spawn_scrap_pickups(global_position, amount)


func _create_boss_visual() -> void:
	"""Create impressive boss visual with multi-layered design"""
	if use_sprites:
		_create_sprite_visual()
	else:
		_create_colorrect_visual()


func _circle_points(radius: float, segments: int = 24) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(segments):
		var angle: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts


func _create_sprite_visual() -> void:
	"""Create sprite visual for boss"""
	var sprite_path: String = "res://assets/sprites/boss/boss_mech.tres"

	if not ResourceLoader.exists(sprite_path):
		# Fallback to ColorRect
		use_sprites = false
		_create_colorrect_visual()
		return

	sprite = AnimatedSprite2D.new()
	sprite.z_index = 1
	sprite.centered = true
	sprite.scale = Vector2(0.15, 0.15)  # Scale down from 2048px to ~300px (boss size)
	add_child(sprite)

	sprite.sprite_frames = load(sprite_path)
	sprite.play("idle")


func _create_colorrect_visual() -> void:
	"""Create ColorRect fallback visual"""
	var visual: Node2D = Node2D.new()
	visual.name = "Visual"
	visual_node = visual
	add_child(visual)

	var size: float = 128.0  # Large boss size

	# Main body - massive red rectangle
	var body: ColorRect = ColorRect.new()
	body.size = Vector2(size, size)
	body.position = -body.size / 2
	body.color = Color(0.8, 0.1, 0.1, 1.0)  # Dark red
	visual.add_child(body)

	# Black armor plates overlay
	var armor_color: Color = Color(0.1, 0.1, 0.1, 0.9)

	# Top armor plate
	var armor_top: ColorRect = ColorRect.new()
	armor_top.size = Vector2(size * 0.9, 16)
	armor_top.position = Vector2(-size * 0.45, -size * 0.45)
	armor_top.color = armor_color
	visual.add_child(armor_top)

	# Bottom armor plate
	var armor_bottom: ColorRect = ColorRect.new()
	armor_bottom.size = Vector2(size * 0.9, 16)
	armor_bottom.position = Vector2(-size * 0.45, size * 0.35)
	armor_bottom.color = armor_color
	visual.add_child(armor_bottom)

	# Left armor plate
	var armor_left: ColorRect = ColorRect.new()
	armor_left.size = Vector2(16, size * 0.9)
	armor_left.position = Vector2(-size * 0.45, -size * 0.45)
	armor_left.color = armor_color
	visual.add_child(armor_left)

	# Right armor plate
	var armor_right: ColorRect = ColorRect.new()
	armor_right.size = Vector2(16, size * 0.9)
	armor_right.position = Vector2(size * 0.35, -size * 0.45)
	armor_right.color = armor_color
	visual.add_child(armor_right)

	# 4 weapon arms (extending outward)
	var arm_length: float = 60.0
	var arm_thickness: float = 12.0

	# Top arm
	var arm_top: ColorRect = ColorRect.new()
	arm_top.size = Vector2(arm_thickness, arm_length)
	arm_top.position = Vector2(-arm_thickness / 2, -size * 0.5 - arm_length)
	arm_top.color = Color(0.2, 0.2, 0.2)
	visual.add_child(arm_top)

	# Bottom arm
	var arm_bottom: ColorRect = ColorRect.new()
	arm_bottom.size = Vector2(arm_thickness, arm_length)
	arm_bottom.position = Vector2(-arm_thickness / 2, size * 0.5)
	arm_bottom.color = Color(0.2, 0.2, 0.2)
	visual.add_child(arm_bottom)

	# Left arm
	var arm_left: ColorRect = ColorRect.new()
	arm_left.size = Vector2(arm_length, arm_thickness)
	arm_left.position = Vector2(-size * 0.5 - arm_length, -arm_thickness / 2)
	arm_left.color = Color(0.2, 0.2, 0.2)
	visual.add_child(arm_left)

	# Right arm
	var arm_right: ColorRect = ColorRect.new()
	arm_right.size = Vector2(arm_length, arm_thickness)
	arm_right.position = Vector2(size * 0.5, -arm_thickness / 2)
	arm_right.color = Color(0.2, 0.2, 0.2)
	visual.add_child(arm_right)

	# Glowing red eyes
	var eye_left: ColorRect = ColorRect.new()
	eye_left.size = Vector2(20, 20)
	eye_left.position = Vector2(-30, -20)
	eye_left.color = Color(1.0, 0.0, 0.0, 1.0)
	eye_left.name = "EyeLeft"
	visual.add_child(eye_left)

	var eye_right: ColorRect = ColorRect.new()
	eye_right.size = Vector2(20, 20)
	eye_right.position = Vector2(10, -20)
	eye_right.color = Color(1.0, 0.0, 0.0, 1.0)
	eye_right.name = "EyeRight"
	visual.add_child(eye_right)

	# Pulsing glow effect on eyes
	var tween: Tween = create_tween().set_loops()
	tween.set_parallel(true)
	tween.tween_property(eye_left, "modulate:a", 0.5, 0.8)
	tween.tween_property(eye_right, "modulate:a", 0.5, 0.8)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(eye_left, "modulate:a", 1.0, 0.8)
	tween.tween_property(eye_right, "modulate:a", 1.0, 0.8)

	# Core reactor (center glow)
	var core: ColorRect = ColorRect.new()
	core.size = Vector2(32, 32)
	core.position = -core.size / 2
	core.color = Color(1.0, 0.3, 0.0, 0.8)  # Orange glow
	core.name = "Core"
	visual.add_child(core)

	# Pulsing core
	var core_tween: Tween = create_tween().set_loops()
	core_tween.tween_property(core, "scale", Vector2(1.2, 1.2), 0.5)
	core_tween.tween_property(core, "scale", Vector2(0.8, 0.8), 0.5)
