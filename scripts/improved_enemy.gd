extends CharacterBody2D

## ImprovedDrone - Advanced AI with State Machine and Navigation
## Kompatibel mit dem bestehenden Enemy Pooling System

# ============================================================================
# SIGNALS
# ============================================================================

# No custom signals needed - uses standard enemy behavior

# ============================================================================
# EXPORTS
# ============================================================================

# Movement
@export var min_speed: float = 100.0
@export var max_speed: float = 150.0
@export var acceleration: float = 400.0
@export var deceleration: float = 600.0
var current_speed: float = 100.0

# AI Behavior
@export var aggro_range: float = 600.0
@export var attack_range: float = 200.0
@export var patrol_radius: float = 300.0

# Health
@export var max_health: int = 100
var current_health: int = 100
@export var hp_regen_rate: float = 0.0

# Score value
@export var score_value: int = 10

# Visual properties
@export var enemy_color: Color = Color(1.0, 0.2, 0.2)
@export var enemy_size: float = 1.0
@export var has_pulse_animation: bool = true
@export var has_rotation_animation: bool = true

# ============================================================================
# STATE MACHINE
# ============================================================================

enum DroneState {
	IDLE,
	PATROLLING,
	CHASING,
	ATTACKING,
	WALL_AVOIDING
}

var current_state: DroneState = DroneState.IDLE
var previous_state: DroneState = DroneState.IDLE
var state_timer: float = 0.0

# ============================================================================
# INTERNAL VARIABLES
# ============================================================================

# Navigation
var player: CharacterBody2D = null
var nav_agent: NavigationAgent2D = null
var raycasts: Dictionary = {}  # "forward", "left45", "right45", "left90", "right90"
var wall_avoidance_direction: Vector2 = Vector2.ZERO

# Attack timers
var attack_cooldown: float = 0.0
var dash_cooldown: float = 0.0
var preferred_distance: float = 0.0  # For sniper

# Patrol
var patrol_center: Vector2 = Vector2.ZERO
var patrol_target: Vector2 = Vector2.ZERO
var patrol_wait_timer: float = 0.0

# Strafing
var strafe_direction: int = 1  # 1 = clockwise, -1 = counterclockwise
var strafe_timer: float = 0.0

# Visual nodes
var visual_node: Node2D = null
var sprite: AnimatedSprite2D = null
var use_sprites: bool = true

var is_stunned: bool = false
var stun_timer: float = 0.0
var _pre_stun_speed: float = 0.0

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	# Set collision layer and mask
	collision_layer = 2  # Layer 2 (Enemy)
	collision_mask = 14  # Updated collision mask spec

	# Add to enemies group
	add_to_group("enemies")

	# Apply area difficulty scaling
	var area_multiplier = MapSystem.get_difficulty_multiplier()
	max_health = int(max_health * area_multiplier)
	min_speed = min_speed * sqrt(area_multiplier)
	max_speed = max_speed * sqrt(area_multiplier)
	score_value = int(score_value * area_multiplier)

	# Randomize speed
	current_speed = randf_range(min_speed, max_speed)

	# Initialize health
	current_health = max_health

	# Get player reference
	player = GameManager.get_player()

	# Setup NavigationAgent2D
	nav_agent = get_node_or_null("NavigationAgent2D")
	if nav_agent:
		nav_agent.path_desired_distance = 10.0
		nav_agent.target_desired_distance = 10.0
		nav_agent.avoidance_enabled = true

	# Setup RayCasts
	_setup_raycasts()

	# Create visual representation
	_create_visual()

	# Start animations
	if has_pulse_animation:
		_start_pulse_animation()
	if has_rotation_animation:
		_start_rotation_animation()

	# Initialize patrol
	patrol_center = global_position
	_generate_new_patrol_target()

	# Randomize strafe direction
	strafe_direction = 1 if randf() > 0.5 else -1


func _setup_raycasts() -> void:
	"""Setup RayCast2D nodes for wall detection"""
	var ray_names = ["RayForward", "RayLeft45", "RayRight45", "RayLeft90", "RayRight90"]

	for ray_name in ray_names:
		var ray = get_node_or_null(ray_name)
		if ray:
			raycasts[ray_name.to_lower().replace("ray", "")] = ray
		else:
			# RayCast not found - wall avoidance will be disabled
			print("Warning: ", ray_name, " not found in ImprovedEnemy scene")


# ============================================================================
# MAIN LOOP
# ============================================================================

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	if is_stunned:
		stun_timer -= delta
		velocity = Vector2.ZERO
		if stun_timer <= 0.0:
			is_stunned = false
			current_speed = max(_pre_stun_speed, min_speed)
		else:
			return

	# Get player reference if not set
	if player == null:
		player = GameManager.get_player()

	# Don't process if game over
	if GameManager.is_game_over:
		return

	if hp_regen_rate > 0.0 and current_health < max_health:
		current_health = min(current_health + hp_regen_rate * delta, max_health)

	# Update cooldowns
	if attack_cooldown > 0:
		attack_cooldown -= delta
	if dash_cooldown > 0:
		dash_cooldown -= delta

	# Update state machine
	update_state(delta)

	# Handle movement based on state
	handle_movement(delta)

	# Apply movement
	move_and_slide()


func apply_stun(duration: float) -> void:
	if duration <= 0.0:
		return
	is_stunned = true
	stun_timer = max(stun_timer, duration)
	_pre_stun_speed = current_speed
	current_speed = 0.0
	velocity = Vector2.ZERO


# ============================================================================
# STATE MACHINE
# ============================================================================

func update_state(delta: float) -> void:
	"""Update AI state based on context"""
	if player == null or not is_instance_valid(player):
		current_state = DroneState.IDLE
		return

	state_timer += delta
	var dist_to_player = global_position.distance_to(player.global_position)

	# Wall avoidance has highest priority
	if _detect_walls() and current_state != DroneState.WALL_AVOIDING:
		previous_state = current_state
		current_state = DroneState.WALL_AVOIDING
		state_timer = 0.0
		return

	# State transitions
	match current_state:
		DroneState.IDLE:
			if dist_to_player < aggro_range:
				current_state = DroneState.CHASING
				state_timer = 0.0
			elif state_timer > 2.0:
				# Start patrolling after being idle for 2s
				current_state = DroneState.PATROLLING
				state_timer = 0.0

		DroneState.PATROLLING:
			if dist_to_player < aggro_range:
				current_state = DroneState.CHASING
				state_timer = 0.0
			elif global_position.distance_to(patrol_target) < 50.0:
				# Reached patrol point
				patrol_wait_timer = randf_range(1.0, 3.0)
				_generate_new_patrol_target()

		DroneState.CHASING:
			if dist_to_player < attack_range:
				current_state = DroneState.ATTACKING
				state_timer = 0.0
			elif dist_to_player > aggro_range * 1.5:
				current_state = DroneState.IDLE
				state_timer = 0.0

		DroneState.ATTACKING:
			# Execute type-specific attacks
			_execute_attack_behavior(delta)

			# Transition back to chasing if too far
			if dist_to_player > attack_range * 1.5:
				current_state = DroneState.CHASING
				state_timer = 0.0

		DroneState.WALL_AVOIDING:
			# Return to previous state after avoiding wall
			if not _detect_walls() and state_timer > 0.5:
				current_state = previous_state
				state_timer = 0.0


func handle_movement(delta: float) -> void:
	"""Calculate and apply movement based on current state"""
	var target_velocity = Vector2.ZERO

	match current_state:
		DroneState.IDLE:
			# Decelerate to stop
			target_velocity = Vector2.ZERO

		DroneState.PATROLLING:
			if patrol_wait_timer > 0:
				patrol_wait_timer -= delta
				target_velocity = Vector2.ZERO
			else:
				target_velocity = get_navigation_velocity(patrol_target)

		DroneState.CHASING:
			# Chase player using navigation
			target_velocity = get_navigation_velocity(player.global_position)

			# Type-specific chase modifiers
			if get_meta("is_kamikaze", false):
				var dist = global_position.distance_to(player.global_position)
				if dist < 150.0:
					# Accelerate when close
					target_velocity *= 2.0

			elif get_meta("is_sniper", false):
				# Maintain distance
				var dist = global_position.distance_to(player.global_position)
				if dist < 300.0:
					# Too close - back away
					target_velocity = -target_velocity * 0.5
				elif dist > 500.0:
					# Too far - approach slowly
					target_velocity *= 0.5

		DroneState.ATTACKING:
			# Circular strafing around player
			target_velocity = _calculate_strafe_velocity()

		DroneState.WALL_AVOIDING:
			# Avoid walls using raycasts
			target_velocity = calculate_wall_avoidance() * current_speed

	# Smooth acceleration/deceleration
	if target_velocity.length() > velocity.length():
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(target_velocity, deceleration * delta)

	# Clamp velocity to max speed
	if velocity.length() > current_speed:
		velocity = velocity.normalized() * current_speed


# ============================================================================
# NAVIGATION & AVOIDANCE
# ============================================================================

func get_navigation_velocity(target_pos: Vector2) -> Vector2:
	"""Get velocity towards target using NavigationAgent2D"""
	if nav_agent == null or not is_instance_valid(nav_agent):
		# Fallback: direct movement
		return (target_pos - global_position).normalized() * current_speed

	nav_agent.target_position = target_pos

	if nav_agent.is_navigation_finished():
		return Vector2.ZERO

	var next_pos = nav_agent.get_next_path_position()
	return (next_pos - global_position).normalized() * current_speed


func calculate_wall_avoidance() -> Vector2:
	"""Calculate avoidance direction based on raycast collisions"""
	var avoidance = Vector2.ZERO

	for ray_name in raycasts:
		var ray = raycasts[ray_name]
		if not is_instance_valid(ray):
			continue

		if ray.is_colliding():
			# Get ray direction in global space
			var ray_dir = ray.target_position.rotated(rotation).normalized()

			# Weight avoidance by proximity
			var collision_point = ray.get_collision_point()
			var distance = global_position.distance_to(collision_point)
			var weight = 1.0 - (distance / 100.0)  # Closer = stronger avoidance

			# Add weighted avoidance away from wall
			avoidance -= ray_dir * weight

	# Normalize and return
	if avoidance.length() > 0:
		return avoidance.normalized()
	return Vector2.ZERO


func _detect_walls() -> bool:
	"""Check if any raycast detects a wall"""
	for ray in raycasts.values():
		if is_instance_valid(ray) and ray.is_colliding():
			return true
	return false


func _calculate_strafe_velocity() -> Vector2:
	"""Calculate circular strafing velocity around player"""
	if player == null or not is_instance_valid(player):
		return Vector2.ZERO

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	# Perpendicular vector for strafing
	var perpendicular = Vector2(-to_player.y, to_player.x).normalized()

	# Switch strafe direction periodically
	strafe_timer += get_physics_process_delta_time()
	if strafe_timer > 2.0:
		strafe_direction *= -1
		strafe_timer = 0.0

	# Combine strafing with distance correction
	var strafe_velocity = perpendicular * strafe_direction * current_speed * 0.7

	# Move closer if too far, back away if too close
	var ideal_distance = attack_range * 0.8
	if distance > ideal_distance:
		strafe_velocity += to_player.normalized() * current_speed * 0.3
	elif distance < ideal_distance * 0.5:
		strafe_velocity -= to_player.normalized() * current_speed * 0.3

	return strafe_velocity


# ============================================================================
# PATROL SYSTEM
# ============================================================================

func _generate_new_patrol_target() -> void:
	"""Generate random patrol point around patrol center"""
	var angle = randf() * TAU
	var distance = randf() * patrol_radius
	patrol_target = patrol_center + Vector2(cos(angle), sin(angle)) * distance


# ============================================================================
# ATTACK BEHAVIORS
# ============================================================================

func _execute_attack_behavior(delta: float) -> void:
	"""Execute type-specific attack patterns"""
	# Fast Drone - Dash attacks
	if enemy_color.b > 0.9 and enemy_color.g > 0.7:  # Cyan
		if dash_cooldown <= 0 and state_timer > 1.0:
			_dash_attack()
			dash_cooldown = 3.0

	# Heavy Drone - Projectile attacks
	elif enemy_color.r > 0.5 and enemy_color.g > 0.2 and enemy_color.g < 0.4:  # Brown
		if attack_cooldown <= 0:
			_shoot_projectile()
			attack_cooldown = 2.0

	# Sniper - Laser attacks
	elif get_meta("is_sniper", false):
		if attack_cooldown <= 0 and state_timer > 0.5:
			_shoot_laser()
			attack_cooldown = 3.0

	# Kamikaze - Explode on contact
	elif get_meta("is_kamikaze", false):
		var distance = global_position.distance_to(player.global_position)
		if distance < 40.0:
			die()


func _dash_attack() -> void:
	"""Dash towards player at high speed"""
	if player == null or not is_instance_valid(player):
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * current_speed * 2.5  # 2.5x speed boost

	# Visual feedback - cyan trail effect
	modulate = Color(0.5, 1.5, 2.0)
	await get_tree().create_timer(0.5).timeout
	if is_queued_for_deletion():
		return
	modulate = Color.WHITE


func _shoot_projectile() -> void:
	"""Shoot projectile at player"""
	if player == null or not is_instance_valid(player):
		return

	var projectile_scene = load("res://scenes/EnemyProjectile.tscn")
	if not projectile_scene:
		print("Warning: EnemyProjectile.tscn not found!")
		return

	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position

	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)

	get_parent().add_child(projectile)

	# Visual muzzle flash
	modulate = Color(1.5, 1.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_queued_for_deletion():
		return
	modulate = Color.WHITE


func _shoot_laser() -> void:
	"""Shoot laser at player with warning line"""
	if player == null or not is_instance_valid(player):
		return

	# Create warning line
	var warning_line = Line2D.new()
	warning_line.add_point(Vector2.ZERO)
	warning_line.add_point(player.global_position - global_position)
	warning_line.default_color = Color(1.0, 0.0, 0.0, 0.5)
	warning_line.width = 3.0
	warning_line.z_index = 100
	add_child(warning_line)

	# Wait 0.5s then shoot
	await get_tree().create_timer(0.5).timeout

	if is_queued_for_deletion() or not is_instance_valid(player):
		return

	# Remove warning line
	if is_instance_valid(warning_line):
		warning_line.queue_free()

	# Create laser beam
	var laser_line = Line2D.new()
	laser_line.add_point(Vector2.ZERO)
	laser_line.add_point(player.global_position - global_position)
	laser_line.default_color = Color(0.0, 1.0, 0.0, 1.0)
	laser_line.width = 5.0
	laser_line.z_index = 100
	add_child(laser_line)

	# Check if laser hits player
	var distance = global_position.distance_to(player.global_position)
	if distance < get_meta("attack_range", 400.0):
		if player.has_method("take_damage"):
			player.take_damage(60)  # High damage

	# Remove laser after 0.1s
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(laser_line):
		laser_line.queue_free()


# ============================================================================
# DAMAGE & DEATH
# ============================================================================

func take_damage(damage: int) -> void:
	"""Take damage from player attacks"""
	current_health -= damage

	# Update miniboss health bar if this is a miniboss
	if get_meta("is_miniboss", false):
		var game_scene = get_tree().get_first_node_in_group("game_scene")
		if game_scene:
			var miniboss_spawner = game_scene.get_node_or_null("MinibossSpawner")
			if miniboss_spawner and miniboss_spawner.has_method("update_health_bar"):
				miniboss_spawner.update_health_bar()

	# Visual feedback
	_flash_damage()

	# Check for death
	if current_health <= 0:
		die()


func _flash_damage() -> void:
	"""Visual damage feedback"""
	modulate = Color(1.5, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	if is_queued_for_deletion():
		return
	modulate = Color.WHITE


func die() -> void:
	"""Handle enemy death"""
	if is_queued_for_deletion():
		return

	# Check if kamikaze - explode on death
	if get_meta("is_kamikaze", false):
		_kamikaze_explode()

	# Play death sound
	AudioManager.play_enemy_death_sound()

	# Add score
	GameManager.add_score(score_value)

	# Award scrap
	var scrap_amount = int(10 * MetaProgression.get_scrap_multiplier())
	_award_scrap(scrap_amount)

	# IMPORTANT: Check if enemy is pooled
	if get_meta("is_pooled", false):
		# Deactivate and hide immediately
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		set_physics_process(false)
		global_position = Vector2(-10000, -10000)

		# Notify game scene to return to pool
		var game_scene = get_tree().get_first_node_in_group("game_scene")
		if game_scene and game_scene.has_method("_return_enemy_to_pool"):
			game_scene.call("_return_enemy_to_pool", self)
		return

	# Non-pooled enemies get freed normally
	queue_free()


func _kamikaze_explode() -> void:
	"""Explode and damage nearby entities"""
	var explosion_damage = get_meta("explosion_damage", 80)
	var explosion_radius = get_meta("explosion_radius", 150.0)

	# Visual explosion effect
	var explosion_scene = load("res://scenes/ExplosionEffect.tscn")
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	explosion.explosion_radius = explosion_radius
	explosion.explosion_color = Color(1.0, 0.5, 0.0, 0.7)
	get_parent().add_child(explosion)

	# Damage player if in range
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= explosion_radius:
			if player.has_method("take_damage"):
				player.take_damage(explosion_damage)

	# Play explosion sound
	AudioManager.play_explosion_sound()


func _award_scrap(amount: int) -> void:
	"""Award scrap to game scene"""
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if not game_scene:
		return
	if game_scene.has_method("register_kill"):
		game_scene.register_kill()
	if amount > 0 and game_scene.has_method("spawn_scrap_pickups"):
		game_scene.spawn_scrap_pickups(global_position, amount)


# ============================================================================
# VISUAL SYSTEM (Copy from original enemy.gd)
# ============================================================================

func _create_visual() -> void:
	"""Create visual representation of enemy"""
	if use_sprites:
		_create_sprite_visual()
	else:
		_create_colorrect_visual()


func _create_sprite_visual() -> void:
	"""Create AnimatedSprite2D visual"""
	sprite = AnimatedSprite2D.new()
	sprite.z_index = 1
	sprite.centered = true
	add_child(sprite)

	var sprite_path = _get_sprite_path_for_enemy()
	if ResourceLoader.exists(sprite_path):
		sprite.sprite_frames = load(sprite_path)
		sprite.play("hover")
	else:
		sprite.queue_free()
		sprite = null
		use_sprites = false
		_create_colorrect_visual()
		return

	sprite.scale = Vector2(enemy_size, enemy_size)


func _get_sprite_path_for_enemy() -> String:
	"""Get correct sprite path based on drone type metadata"""
	var drone_type = get_meta("drone_type", "standard")

	match drone_type:
		"kamikaze":
			return "res://assets/anim/drone_kamikaze.tres"
		"sniper":
			return "res://assets/anim/drone_sniper.tres"
		"fast":
			return "res://assets/anim/drone_fast.tres"
		"heavy":
			return "res://assets/anim/drone_heavy.tres"
		_:
			return "res://assets/anim/drone_standard.tres"


func _create_colorrect_visual() -> void:
	"""Create ColorRect visual"""
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	add_child(visual_node)

	# Simple rect fallback
	var body = ColorRect.new()
	body.size = Vector2(40, 40) * enemy_size
	body.position = -body.size / 2
	body.color = enemy_color
	visual_node.add_child(body)


func _get_sprite_path_for_enemy() -> String:
	"""Get sprite path based on enemy type"""
	if get_meta("is_kamikaze", false):
		return "res://assets/sprites/enemies/drone_kamikaze.tres"
	if get_meta("is_sniper", false):
		return "res://assets/sprites/enemies/drone_sniper.tres"

	return "res://assets/sprites/enemies/drone_standard.tres"


func _start_pulse_animation() -> void:
	"""Start pulsing animation"""
	if use_sprites and sprite:
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "scale", Vector2(1.1, 1.1) * enemy_size, 0.5)
		tween.tween_property(sprite, "scale", Vector2(0.9, 0.9) * enemy_size, 0.5)
	elif visual_node:
		var tween = create_tween().set_loops()
		tween.tween_property(visual_node, "scale", Vector2(1.1, 1.1), 0.5)
		tween.tween_property(visual_node, "scale", Vector2(0.9, 0.9), 0.5)


func _start_rotation_animation() -> void:
	"""Start rotation animation"""
	if use_sprites and sprite:
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "rotation", TAU, 2.0)
	elif visual_node:
		var tween = create_tween().set_loops()
		tween.tween_property(visual_node, "rotation", TAU, 2.0)
