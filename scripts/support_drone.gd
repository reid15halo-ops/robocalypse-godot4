extends CharacterBody2D

# Drone types
enum DroneType {
	ATTACK,
	SHIELD,
	REPAIR,
	SCANNER
}

# Configuration
@export var drone_type: DroneType = DroneType.ATTACK
@export var orbit_distance: float = 80.0
@export var orbit_speed: float = 2.0

# References
var player: CharacterBody2D = null
var orbit_angle: float = 0.0
@export var max_health: float = 60.0
var current_health: float = 60.0
@export var hp_regen_rate: float = 0.0

# Attack drone properties
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var attack_damage: int = 15
var attack_range: float = 200.0

# Shield drone properties
var shield_strength: int = 10

# Repair drone properties
var repair_rate: float = 1.0
var repair_timer: float = 0.0


func _ready() -> void:
	# Set collision
	collision_layer = 0
	collision_mask = 0

	current_health = max_health

	# Get player reference
	player = GameManager.get_player()

	# Random starting angle
	orbit_angle = randf() * TAU

	# Set visual appearance based on type
	_update_visual_for_type()


func _physics_process(delta: float) -> void:
	if not player or GameManager.is_game_over:
		return

	if hp_regen_rate > 0.0 and current_health < max_health:
		current_health = min(current_health + hp_regen_rate * delta, max_health)

	# Orbit around player
	orbit_angle += orbit_speed * delta
	var orbit_pos = player.global_position + Vector2(
		cos(orbit_angle) * orbit_distance,
		sin(orbit_angle) * orbit_distance
	)
	global_position = orbit_pos

	# Drone-specific behavior
	match drone_type:
		DroneType.ATTACK:
			_attack_behavior(delta)
		DroneType.SHIELD:
			_shield_behavior(delta)
		DroneType.REPAIR:
			_repair_behavior(delta)
		DroneType.SCANNER:
			_scanner_behavior(delta)


func _attack_behavior(delta: float) -> void:
	"""Attack nearby enemies"""
	attack_timer += delta

	if attack_timer >= attack_cooldown:
		attack_timer = 0.0

		# Find nearest enemy
		var nearest_enemy = _find_nearest_enemy()
		if nearest_enemy and global_position.distance_to(nearest_enemy.global_position) <= attack_range:
			if nearest_enemy.has_method("take_damage"):
				nearest_enemy.take_damage(attack_damage)

				# Visual feedback
				modulate = Color(1.5, 0.5, 0.5)
				await get_tree().create_timer(0.1).timeout
				modulate = Color.WHITE


func _shield_behavior(_delta: float) -> void:
	"""Stay close to player for protection"""
	# Shield functionality is passive - handled in player take_damage
	pass


func _repair_behavior(delta: float) -> void:
	"""Heal player over time"""
	repair_timer += delta

	if repair_timer >= 1.0:  # Every second
		repair_timer = 0.0
		if player.has_method("heal"):
			player.heal(int(repair_rate))


func _scanner_behavior(_delta: float) -> void:
	"""Reveal hidden items/enemies (visual effect)"""
	# Create pulsing scan ring visual
	_create_scan_pulse()

	# Highlight enemies in range
	_highlight_nearby_enemies()


func _create_scan_pulse() -> void:
	"""Create visual scan ring pulse"""
	# Only create pulse every 2 seconds
	if not has_meta("last_scan_time"):
		set_meta("last_scan_time", Time.get_ticks_msec() / 1000.0)
		return

	var current_time = Time.get_ticks_msec() / 1000.0
	var last_scan = get_meta("last_scan_time")

	if current_time - last_scan < 2.0:
		return

	set_meta("last_scan_time", current_time)

	# Create scan ring
	var scan_ring = ColorRect.new()
	scan_ring.size = Vector2(400, 400)
	scan_ring.position = global_position - scan_ring.size / 2
	scan_ring.color = Color(1.0, 1.0, 0.0, 0.3)
	scan_ring.z_index = 10

	# Add to game scene
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene:
		game_scene.add_child(scan_ring)

		# Expand and fade animation
		var tween = scan_ring.create_tween()
		tween.tween_property(scan_ring, "scale", Vector2(1.5, 1.5), 1.0)
		tween.parallel().tween_property(scan_ring, "modulate:a", 0.0, 1.0)
		tween.tween_callback(scan_ring.queue_free)


func _highlight_nearby_enemies() -> void:
	"""Add yellow outline to enemies in range"""
	const SCAN_RADIUS: float = 300.0

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist <= SCAN_RADIUS:
			# Briefly highlight enemy
			if enemy.has("modulate"):
				var original_color = enemy.modulate
				enemy.modulate = Color(1.5, 1.5, 0.5)  # Yellow tint

				# Restore after 0.5s
				await get_tree().create_timer(0.5).timeout
				if is_instance_valid(enemy):
					enemy.modulate = original_color


func _find_nearest_enemy() -> Node:
	"""Find the nearest enemy"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func destroy() -> void:
	"""Remove the drone"""
	queue_free()


func _update_visual_for_type() -> void:
	"""Update drone color based on type"""
	if not has_node("Visual/Body"):
		return

	var body = $Visual/Body

	match drone_type:
		DroneType.ATTACK:
			body.color = Color(1.0, 0.3, 0.3)  # Red
		DroneType.SHIELD:
			body.color = Color(0.3, 0.5, 1.0)  # Blue
		DroneType.REPAIR:
			body.color = Color(0.3, 1.0, 0.3)  # Green
		DroneType.SCANNER:
			body.color = Color(1.0, 1.0, 0.3)  # Yellow
