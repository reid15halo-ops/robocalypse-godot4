extends Node

# Constants
const LASER_BURST_MODULATE_R: float = 2.0
const LASER_BURST_MODULATE_G: float = 2.0
const LASER_BURST_MODULATE_B: float = 0.6
const LASER_BURST_TIMER: float = 0.15
const LASER_BURST_PROJECTILE_COUNT: int = 12
const LASER_BURST_PROJECTILE_SPAWN_RADIUS: float = 48.0
const LASER_BURST_PROJECTILE_BASE_SPEED: float = 420.0
const LASER_BURST_PROJECTILE_SPEED_PER_PHASE: float = 40.0
const LASER_BURST_PROJECTILE_BASE_DAMAGE: int = 30
const LASER_BURST_PROJECTILE_DAMAGE_PER_PHASE: int = 12
const LASER_BURST_PLAYER_DAMAGE_DISTANCE: float = 160.0
const LASER_BURST_PLAYER_BASE_DAMAGE: int = 45
const LASER_BURST_PLAYER_DAMAGE_PER_PHASE: int = 10
const LASER_BURST_MODULATE_RESET_TIMER: float = 0.1

const ORBITAL_STRIKE_MARKER_COUNT: int = 4
const ORBITAL_STRIKE_MIN_RADIUS: float = 150.0
const ORBITAL_STRIKE_MAX_RADIUS: float = 260.0
const ORBITAL_STRIKE_RING_RADIUS: float = 70.0
const ORBITAL_STRIKE_RING_COLOR_R: float = 1.0
const ORBITAL_STRIKE_RING_COLOR_G: float = 0.4
const ORBITAL_STRIKE_RING_COLOR_B: float = 0.1
const ORBITAL_STRIKE_RING_COLOR_A: float = 0.35
const ORBITAL_STRIKE_RING_SCALE: float = 1.4
const ORBITAL_STRIKE_RING_TWEEN_DURATION: float = 0.8
const ORBITAL_STRIKE_TIMER: float = 0.9
const ORBITAL_STRIKE_EXPLOSION_RADIUS: float = 100.0
const ORBITAL_STRIKE_EXPLOSION_COLOR_R: float = 1.0
const ORBITAL_STRIKE_EXPLOSION_COLOR_G: float = 0.2
const ORBITAL_STRIKE_EXPLOSION_COLOR_B: float = 0.1
const ORBITAL_STRIKE_EXPLOSION_COLOR_A: float = 0.6
const ORBITAL_STRIKE_PLAYER_DAMAGE_DISTANCE: float = 120.0
const ORBITAL_STRIKE_PLAYER_BASE_DAMAGE: int = 65
const ORBITAL_STRIKE_PLAYER_DAMAGE_PER_PHASE: int = 10

const SHOCKWAVE_BURST_PULSE_COUNT: int = 2
const SHOCKWAVE_BURST_RING_RADIUS: float = 60.0
const SHOCKWAVE_BURST_RING_COLOR_R: float = 0.3
const SHOCKWAVE_BURST_RING_COLOR_G: float = 0.6
const SHOCKWAVE_BURST_RING_COLOR_B: float = 1.0
const SHOCKWAVE_BURST_RING_COLOR_A: float = 0.45
const SHOCKWAVE_BURST_MAX_RADIUS_BASE: float = 280.0
const SHOCKWAVE_BURST_MAX_RADIUS_PER_PULSE: float = 90.0
const SHOCKWAVE_BURST_TWEEN_DURATION: float = 0.6
const SHOCKWAVE_BURST_TIMER: float = 0.35
const SHOCKWAVE_BURST_PLAYER_BASE_DAMAGE: int = 60
const SHOCKWAVE_BURST_PLAYER_DAMAGE_PER_PHASE: int = 15
const SHOCKWAVE_BURST_NODE_CLEANUP_TIMER: float = 0.25

const DRONE_SWARM_COUNT_BASE: int = 4
const DRONE_SWARM_RADIUS: float = 220.0
const DRONE_SWARM_TIMER: float = 0.3

const RAPID_BARRAGE_VOLLEYS_BASE: int = 5
const RAPID_BARRAGE_ROTATION_RANGE: float = 0.3
const RAPID_BARRAGE_PROJECTILE_SPAWN_RADIUS: float = 36.0
const RAPID_BARRAGE_PROJECTILE_BASE_SPEED: float = 520.0
const RAPID_BARRAGE_PROJECTILE_SPEED_PER_PHASE: float = 50.0
const RAPID_BARRAGE_PROJECTILE_BASE_DAMAGE: int = 35
const RAPID_BARRAGE_PROJECTILE_DAMAGE_PER_PHASE: int = 12
const RAPID_BARRAGE_TIMER: float = 0.18

const PLASMA_WALL_Z_INDEX: int = 6
const PLASMA_WALL_ARENA_WIDTH_MULTIPLIER: float = 0.9
const PLASMA_WALL_HEIGHT: float = 160.0
const PLASMA_WALL_WIDTH: float = 160.0
const PLASMA_WALL_COLOR_R: float = 0.6
const PLASMA_WALL_COLOR_G: float = 0.9
const PLASMA_WALL_COLOR_B: float = 1.2
const PLASMA_WALL_COLOR_A: float = 0.45
const PLASMA_WALL_SPAWN_OFFSET: float = 60.0
const PLASMA_WALL_VELOCITY: float = 160.0
const PLASMA_WALL_LIFESPAN: float = 5.0
const PLASMA_WALL_DAMAGE_RADIUS_MULTIPLIER: float = 0.5

const GRAVITY_WELL_TIMER_DURATION: float = 4.5
const GRAVITY_WELL_Z_INDEX: int = 7
const GRAVITY_WELL_CORE_RADIUS: float = 70.0
const GRAVITY_WELL_CORE_COLOR_R: float = 0.25
const GRAVITY_WELL_CORE_COLOR_G: float = 0.7
const GRAVITY_WELL_CORE_COLOR_B: float = 1.2
const GRAVITY_WELL_CORE_COLOR_A: float = 0.55
const GRAVITY_WELL_TWEEN_ROTATION_DURATION: float = 1.5
const GRAVITY_WELL_TWEEN_SCALE_DURATION: float = 0.7
const GRAVITY_WELL_TIMER: float = 0.1

const OBLITERATION_BEAM_WIDTH: float = 22.0
const OBLITERATION_BEAM_LENGTH: float = 900.0
const OBLITERATION_BEAM_COLOR_R: float = 1.0
const OBLITERATION_BEAM_COLOR_G: float = 0.35
const OBLITERATION_BEAM_COLOR_B: float = 0.1
const OBLITERATION_BEAM_COLOR_A: float = 0.85
const OBLITERATION_BEAM_PULSE_COUNT: int = 4
const OBLITERATION_BEAM_PULSE_TIMER: float = 0.2
const OBLITERATION_BEAM_PLAYER_DAMAGE_DISTANCE: float = 120.0
const OBLITERATION_BEAM_PLAYER_DAMAGE: int = 120

const SHIELD_OVERDRIVE_RING_RADIUS: float = 100.0
const SHIELD_OVERDRIVE_RING_COLOR_R: float = 0.2
const SHIELD_OVERDRIVE_RING_COLOR_G: float = 1.0
const SHIELD_OVERDRIVE_RING_COLOR_B: float = 1.5
const SHIELD_OVERDRIVE_RING_COLOR_A: float = 0.45
const SHIELD_OVERDRIVE_TWEEN_ROTATION_DURATION: float = 2.0

var boss: CharacterBody2D

func _init(boss_node: CharacterBody2D):
	boss = boss_node

func _laser_burst() -> void:
	if boss.is_queued_for_deletion():
		return

	var original_modulate: Color = boss.modulate
	boss.modulate = Color(LASER_BURST_MODULATE_R, LASER_BURST_MODULATE_G, LASER_BURST_MODULATE_B)
	await boss.get_tree().create_timer(LASER_BURST_TIMER).timeout

	var projectile_count: int = LASER_BURST_PROJECTILE_COUNT
	for i in range(projectile_count):
		var angle: float = TAU * float(i) / float(projectile_count)
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var projectile: Node2D = boss.enemy_projectile_scene.instantiate()
		projectile.global_position = boss.global_position + direction * LASER_BURST_PROJECTILE_SPAWN_RADIUS
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction)
		projectile.speed = LASER_BURST_PROJECTILE_BASE_SPEED + LASER_BURST_PROJECTILE_SPEED_PER_PHASE * boss.state_machine.phase
		projectile.damage = LASER_BURST_PROJECTILE_BASE_DAMAGE + boss.state_machine.phase * LASER_BURST_PROJECTILE_DAMAGE_PER_PHASE
		boss.get_parent().add_child(projectile)

	if boss.player and boss.is_instance_valid(boss.player) and boss.global_position.distance_to(boss.player.global_position) <= LASER_BURST_PLAYER_DAMAGE_DISTANCE:
		if boss.player.has_method("take_damage"):
			boss.player.take_damage(LASER_BURST_PLAYER_BASE_DAMAGE + boss.state_machine.phase * LASER_BURST_PLAYER_DAMAGE_PER_PHASE)

	await boss.get_tree().create_timer(LASER_BURST_MODULATE_RESET_TIMER).timeout
	boss.modulate = original_modulate


func _orbital_strike() -> void:
	if not boss.player or not boss.is_instance_valid(boss.player) or boss.is_queued_for_deletion():
		return

	var base_pos: Vector2 = boss.player.global_position
	var markers: Array[Node2D] = []
	for i in range(ORBITAL_STRIKE_MARKER_COUNT):
		var angle: float = randf_range(0.0, TAU)
		var radius: float = randf_range(ORBITAL_STRIKE_MIN_RADIUS, ORBITAL_STRIKE_MAX_RADIUS)
		var marker: Node2D = Node2D.new()
		marker.global_position = base_pos + Vector2(cos(angle), sin(angle)) * radius
		var ring: Polygon2D = Polygon2D.new()
		ring.polygon = boss.visuals._circle_points(ORBITAL_STRIKE_RING_RADIUS)
		ring.color = Color(ORBITAL_STRIKE_RING_COLOR_R, ORBITAL_STRIKE_RING_COLOR_G, ORBITAL_STRIKE_RING_COLOR_B, ORBITAL_STRIKE_RING_COLOR_A)
		marker.add_child(ring)
		boss.get_parent().add_child(marker)
		markers.append(marker)
		var tween: Tween = boss.get_tree().create_tween()
		tween.tween_property(ring, "scale", Vector2(ORBITAL_STRIKE_RING_SCALE, ORBITAL_STRIKE_RING_SCALE), ORBITAL_STRIKE_RING_TWEEN_DURATION)
		tween.tween_property(ring, "modulate:a", 0.0, ORBITAL_STRIKE_RING_TWEEN_DURATION)

	await boss.get_tree().create_timer(ORBITAL_STRIKE_TIMER).timeout

	for marker in markers:
		if not boss.is_instance_valid(marker):
			continue
		var explosion: Polygon2D = Polygon2D.new()
		explosion.polygon = boss.visuals._circle_points(ORBITAL_STRIKE_EXPLOSION_RADIUS)
		explosion.color = Color(ORBITAL_STRIKE_EXPLOSION_COLOR_R, ORBITAL_STRIKE_EXPLOSION_COLOR_G, ORBITAL_STRIKE_EXPLOSION_COLOR_B, ORBITAL_STRIKE_EXPLOSION_COLOR_A)
		marker.add_child(explosion)
		if boss.player and boss.is_instance_valid(boss.player) and boss.player.global_position.distance_to(marker.global_position) <= ORBITAL_STRIKE_PLAYER_DAMAGE_DISTANCE:
			if boss.player.has_method("take_damage"):
				boss.player.take_damage(ORBITAL_STRIKE_PLAYER_BASE_DAMAGE + boss.state_machine.phase * ORBITAL_STRIKE_PLAYER_DAMAGE_PER_PHASE)
		boss.get_tree().process_frame
		if boss.is_instance_valid(marker):
			marker.queue_free()


func _shockwave_burst() -> void:
	for pulse in range(SHOCKWAVE_BURST_PULSE_COUNT):
		if boss.is_queued_for_deletion():
			return
		var shock_node: Node2D = Node2D.new()
		shock_node.global_position = boss.global_position
		boss.get_parent().add_child(shock_node)

		var ring: Polygon2D = Polygon2D.new()
		ring.polygon = boss.visuals._circle_points(SHOCKWAVE_BURST_RING_RADIUS)
		ring.color = Color(SHOCKWAVE_BURST_RING_COLOR_R, SHOCKWAVE_BURST_RING_COLOR_G, SHOCKWAVE_BURST_RING_COLOR_B, SHOCKWAVE_BURST_RING_COLOR_A)
		shock_node.add_child(ring)

		var max_radius: float = SHOCKWAVE_BURST_MAX_RADIUS_BASE + pulse * SHOCKWAVE_BURST_MAX_RADIUS_PER_PULSE
		var tween: Tween = boss.get_tree().create_tween()
		tween.set_parallel(true)
		tween.tween_property(ring, "scale", Vector2(max_radius / SHOCKWAVE_BURST_RING_RADIUS, max_radius / SHOCKWAVE_BURST_RING_RADIUS), SHOCKWAVE_BURST_TWEEN_DURATION)
		tween.tween_property(ring, "modulate:a", 0.0, SHOCKWAVE_BURST_TWEEN_DURATION)

		await boss.get_tree().create_timer(SHOCKWAVE_BURST_TIMER).timeout

		if boss.player and boss.is_instance_valid(boss.player) and boss.global_position.distance_to(boss.player.global_position) <= max_radius:
			if boss.player.has_method("take_damage"):
				boss.player.take_damage(SHOCKWAVE_BURST_PLAYER_BASE_DAMAGE + boss.state_machine.phase * SHOCKWAVE_BURST_PLAYER_DAMAGE_PER_PHASE)

		await boss.get_tree().create_timer(SHOCKWAVE_BURST_NODE_CLEANUP_TIMER).timeout
		if boss.is_instance_valid(shock_node):
			shock_node.queue_free()


func _drone_swarm() -> void:
	var count: int = DRONE_SWARM_COUNT_BASE + boss.state_machine.phase
	var radius: float = DRONE_SWARM_RADIUS
	for i in range(count):
		var angle: float = TAU * float(i) / float(count)
		var minion: Node2D = boss.enemy_scene.instantiate()
		minion.global_position = boss.global_position + Vector2(cos(angle), sin(angle)) * radius
		boss.get_parent().add_child(minion)
	await boss.get_tree().create_timer(DRONE_SWARM_TIMER).timeout


func _rapid_barrage() -> void:
	var volleys: int = RAPID_BARRAGE_VOLLEYS_BASE + boss.state_machine.phase
	for i in range(volleys):
		if boss.is_queued_for_deletion():
			return
		if boss.player and boss.is_instance_valid(boss.player):
			var direction: Vector2 = (boss.player.global_position - boss.global_position).normalized()
			if direction.length() < 0.1:
				direction = Vector2.RIGHT
			direction = direction.rotated(randf_range(-RAPID_BARRAGE_ROTATION_RANGE, RAPID_BARRAGE_ROTATION_RANGE))
			var projectile: Node2D = boss.enemy_projectile_scene.instantiate()
			projectile.global_position = boss.global_position + direction * RAPID_BARRAGE_PROJECTILE_SPAWN_RADIUS
			if projectile.has_method("set_direction"):
				projectile.set_direction(direction)
			projectile.speed = RAPID_BARRAGE_PROJECTILE_BASE_SPEED + boss.state_machine.phase * RAPID_BARRAGE_PROJECTILE_SPEED_PER_PHASE
			projectile.damage = RAPID_BARRAGE_PROJECTILE_BASE_DAMAGE + boss.state_machine.phase * RAPID_BARRAGE_PROJECTILE_DAMAGE_PER_PHASE
			boss.get_parent().add_child(projectile)
		await boss.get_tree().create_timer(RAPID_BARRAGE_TIMER).timeout


func _plasma_wall() -> void:
	return
	var arena: Rect2 = boss._get_arena_rect()
	var horizontal: bool = randf() < 0.5
	var wall_node: Node2D = Node2D.new()
	wall_node.z_index = PLASMA_WALL_Z_INDEX
	var polygon: Polygon2D = Polygon2D.new()

	var width: float
	var height: float
	if horizontal:
		width = arena.size.x * PLASMA_WALL_ARENA_WIDTH_MULTIPLIER
		height = PLASMA_WALL_HEIGHT
	else:
		width = PLASMA_WALL_WIDTH
		height = arena.size.y * PLASMA_WALL_ARENA_WIDTH_MULTIPLIER
	var half_w: float = width / 2.0
	var half_h: float = height / 2.0
	polygon.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h)
	])
	polygon.color = Color(PLASMA_WALL_COLOR_R, PLASMA_WALL_COLOR_G, PLASMA_WALL_COLOR_B, PLASMA_WALL_COLOR_A)
	wall_node.add_child(polygon)

	var start_pos: Vector2 = Vector2.ZERO
	if horizontal:
		var from_top: bool = randf() < 0.5
		if from_top:
			start_pos = Vector2(arena.position.x + arena.size.x / 2.0, arena.position.y - half_h - PLASMA_WALL_SPAWN_OFFSET)
		else:
			start_pos = Vector2(arena.position.x + arena.size.x / 2.0, arena.position.y + arena.size.y + half_h + PLASMA_WALL_SPAWN_OFFSET)
	else:
		var from_left: bool = randf() < 0.5
		if from_left:
			start_pos = Vector2(arena.position.x - half_w - PLASMA_WALL_SPAWN_OFFSET, arena.position.y + arena.size.y / 2.0)
		else:
			start_pos = Vector2(arena.position.x + arena.size.x + half_w + PLASMA_WALL_SPAWN_OFFSET, arena.position.y + arena.size.y / 2.0)

	wall_node.global_position = start_pos
	boss.get_parent().add_child(wall_node)

	boss.plasma_walls.append({
		"node": wall_node,
		"lifespan": PLASMA_WALL_LIFESPAN,
		"damage_timer": 0.0,
		"damage_radius": max(width, height) * PLASMA_WALL_DAMAGE_RADIUS_MULTIPLIER
	})


func _gravity_well() -> void:
	if not boss.player or not boss.is_instance_valid(boss.player):
		return

	boss.gravity_well_position = boss.player.global_position
	boss.gravity_well_timer = GRAVITY_WELL_TIMER_DURATION
	boss.gravity_well_duration = boss.gravity_well_timer
	boss.gravity_damage_timer = 0.0

	if boss.gravity_well_visual and boss.is_instance_valid(boss.gravity_well_visual):
		boss.gravity_well_visual.queue_free()

	boss.gravity_well_visual = Node2D.new()
	boss.gravity_well_visual.z_index = GRAVITY_WELL_Z_INDEX
	var core: Polygon2D = Polygon2D.new()
	core.polygon = boss.visuals._circle_points(GRAVITY_WELL_CORE_RADIUS)
	core.color = Color(GRAVITY_WELL_CORE_COLOR_R, GRAVITY_WELL_CORE_COLOR_G, GRAVITY_WELL_CORE_COLOR_B, GRAVITY_WELL_CORE_COLOR_A)
	boss.gravity_well_visual.add_child(core)
	boss.gravity_well_visual.global_position = boss.gravity_well_position
	boss.get_parent().add_child(boss.gravity_well_visual)

	var tween: Tween = boss.get_tree().create_tween().set_loops()
	tween.tween_property(core, "rotation", TAU, GRAVITY_WELL_TWEEN_ROTATION_DURATION)
	tween.tween_property(core, "scale", Vector2(1.2, 1.2), GRAVITY_WELL_TWEEN_SCALE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(core, "scale", Vector2(1.0, 1.0), GRAVITY_WELL_TWEEN_SCALE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await boss.get_tree().create_timer(GRAVITY_WELL_TIMER).timeout


func _obliteration_beam() -> void:
	if not boss.player or not boss.is_instance_valid(boss.player):
		return

	var direction: Vector2 = (boss.player.global_position - boss.global_position).normalized()
	if direction.length() < 0.1:
		direction = Vector2.RIGHT

	var beam: Line2D = Line2D.new()
	beam.width = OBLITERATION_BEAM_WIDTH
	beam.default_color = Color(OBLITERATION_BEAM_COLOR_R, OBLITERATION_BEAM_COLOR_G, OBLITERATION_BEAM_COLOR_B, OBLITERATION_BEAM_COLOR_A)
	beam.add_point(Vector2.ZERO)
	beam.add_point(direction * OBLITERATION_BEAM_LENGTH)
	boss.add_child(beam)

	for _i in range(OBLITERATION_BEAM_PULSE_COUNT):
		await boss.get_tree().create_timer(OBLITERATION_BEAM_PULSE_TIMER).timeout
		if not boss.player or not boss.is_instance_valid(boss.player):
			continue
		var to_player: Vector2 = boss.player.global_position - boss.global_position
		var projection: float = to_player.dot(direction)
		if projection < 0.0 or projection > OBLITERATION_BEAM_LENGTH:
			continue
		var closest_point: Vector2 = boss.global_position + direction * projection
		if closest_point.distance_to(boss.player.global_position) <= OBLITERATION_BEAM_PLAYER_DAMAGE_DISTANCE:
			if boss.player.has_method("take_damage"):
				boss.player.take_damage(OBLITERATION_BEAM_PLAYER_DAMAGE)

	if boss.is_instance_valid(beam):
		beam.queue_free()


func _shield_overdrive() -> void:
	boss.shield_active = true
	boss.shield_value = boss.SHIELD_MAX
	boss.shield_timer = boss.SHIELD_DURATION

	if boss.shield_visual and boss.is_instance_valid(boss.shield_visual):
		boss.shield_visual.queue_free()

	boss.shield_visual = Node2D.new()
	var ring: Polygon2D = Polygon2D.new()
	ring.polygon = boss.visuals._circle_points(SHIELD_OVERDRIVE_RING_RADIUS)
	ring.color = Color(SHIELD_OVERDRIVE_RING_COLOR_R, SHIELD_OVERDRIVE_RING_COLOR_G, SHIELD_OVERDRIVE_RING_COLOR_B, SHIELD_OVERDRIVE_RING_COLOR_A)
	boss.shield_visual.add_child(ring)
	boss.shield_visual.position = Vector2.ZERO
	boss.add_child(boss.shield_visual)

	var tween: Tween = boss.get_tree().create_tween().set_loops()
	tween.tween_property(ring, "rotation", TAU, SHIELD_OVERDRIVE_TWEEN_ROTATION_DURATION)