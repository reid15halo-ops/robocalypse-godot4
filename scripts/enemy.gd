extends CharacterBody2D

# Movement
@export var min_speed: float = 110.0
@export var max_speed: float = 165.0
var current_speed: float = 100.0

# Health
@export var max_health: int = 100
var current_health: int = 100
@export var hp_regen_rate: float = 0.0

# Navigation
var player: CharacterBody2D = null
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var last_target_pos: Vector2 = Vector2.INF # Für Caching
const PATH_UPDATE_THRESHOLD_SQ: float = 10000.0 # 100*100
var stuck_timer: float = 0.0
const STUCK_TIME_THRESHOLD: float = 5.0 # 5 Sekunden

# Score value
@export var score_value: int = 10




# Attack timers and behavior
var attack_cooldown: float = 0.0
var dash_cooldown: float = 0.0
var preferred_distance: float = 0.0  # For sniper keeping distance

# Visual properties
@export var enemy_color: Color = Color(1.0, 0.2, 0.2)  # Red by default
@export var enemy_size: float = 1.0  # Scale multiplier
@export var has_pulse_animation: bool = true
@export var has_rotation_animation: bool = true

# Visual nodes
var visual_node: Node2D = null
var sprite: AnimatedSprite2D = null
var use_sprites: bool = true  # Sprites are now available!

var is_stunned: bool = false
var stun_timer: float = 0.0
var _pre_stun_speed: float = 0.0

func _ready() -> void:
	# Set collision layer and mask
	collision_layer = 2  # Layer 2 (Enemy)
	collision_mask = 14  # Interact with Enemies (2) + Walls (4) + Walls layer? per spec

	# Add to enemies group
	add_to_group("enemies")

	# Apply area difficulty scaling
	var area_multiplier = MapSystem.get_difficulty_multiplier()
	max_health = int(max_health * area_multiplier)
	min_speed = min_speed * sqrt(area_multiplier)  # Speed scales slower
	max_speed = max_speed * sqrt(area_multiplier)
	score_value = int(score_value * area_multiplier)

	# Randomize speed
	current_speed = randf_range(min_speed, max_speed)

	# Initialize health
	current_health = max_health

	# Get player reference
	player = GameManager.get_player()

	# Setup navigation
	_setup_navigation()

	# Create visual representation
	_create_visual()


	# Start animations
	if has_pulse_animation:
		_start_pulse_animation()
	if has_rotation_animation:
		_start_rotation_animation()


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	# Handle stun timer
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

	# Regenerate health if this unit supports it
	if hp_regen_rate > 0.0 and current_health < max_health:
		current_health = min(current_health + hp_regen_rate * delta, max_health)

	# Update cooldowns
	if attack_cooldown > 0:
		attack_cooldown -= delta
	if dash_cooldown > 0:
		dash_cooldown -= delta

	# Execute behavior based on enemy type
	if player != null and not GameManager.is_game_over:
		# Check enemy type and execute appropriate behavior
		if get_meta("is_kamikaze", false):
			_kamikaze_behavior()
		elif get_meta("is_sniper", false):
			_sniper_behavior()
		elif enemy_color.b > 0.9 and enemy_color.g > 0.7:  # Cyan - Fast Drone
			_fast_drone_behavior()
		elif enemy_color.r > 0.5 and enemy_color.g > 0.2 and enemy_color.g < 0.4 and enemy_color.b < 0.3:  # Brown - Heavy Drone
			_heavy_drone_behavior()
		else:
			# Standard drone - simple chase
			_standard_behavior()

	# --- KORRIGIERTE NAVIGATIONSBASIERTE BEWEGUNG (HOTFIX) ---
	if not nav_agent or not is_instance_valid(nav_agent):
		# Fallback, wenn kein Navigationsagent vorhanden ist
		velocity = velocity.move_toward(Vector2.ZERO, current_speed * delta)
	elif nav_agent.is_navigation_finished():
		# Ziel erreicht, anhalten
		nav_agent.set_velocity(Vector2.ZERO)
	else:
		# Berechne die gewünschte Geschwindigkeit und übergib sie an den Agenten
		var direction = (nav_agent.get_next_path_position() - global_position).normalized()
		var desired_velocity = direction * current_speed
		nav_agent.set_velocity(desired_velocity)
	# --- ENDE KORREKTUR ---

	# Stuck-Check
	_check_if_stuck(delta)

	# Die finale 'velocity' wird durch das 'velocity_computed'-Signal des Agenten gesetzt.
	move_and_slide()




func apply_stun(duration: float) -> void:
	"""Temporarily stop movement and actions"""
	if duration <= 0.0:
		return
	is_stunned = true
	stun_timer = max(stun_timer, duration)
	_pre_stun_speed = current_speed
	current_speed = 0.0
	velocity = Vector2.ZERO


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

	# Visual feedback (separate coroutine)
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

	# Award scrap (10 per enemy - increased from 5)
	var scrap_amount = int(10 * MetaProgression.get_scrap_multiplier())
	_award_scrap(scrap_amount)

	# IMPORTANT: Check if enemy is pooled
	# Pooled enemies should NOT be freed - they return to the pool immediately
	if get_meta("is_pooled", false):
		# Deactivate and hide immediately
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
		set_physics_process(false)
		global_position = Vector2(-10000, -10000)  # Move offscreen

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

	# Visual explosion effect using ExplosionEffect scene
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

	print("Kamikaze explosion! Damage: ", explosion_damage, " Radius: ", explosion_radius)


func _award_scrap(amount: int) -> void:
	"""Award scrap to game scene"""
	# Send signal to game scene
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if not game_scene:
		return
	if game_scene.has_method("register_kill"):
		game_scene.register_kill()
	if amount > 0 and game_scene.has_method("spawn_scrap_pickups"):
		game_scene.spawn_scrap_pickups(global_position, amount)


# ============================================================================
# NAVIGATION (NEU)
# ============================================================================

func _setup_navigation():
	if not nav_agent:
		push_warning("Enemy: NavigationAgent2D node not found!")
		return
	
	# Performance-Optimierungen
	nav_agent.path_postprocessing = NavigationAgent2D.PATH_POSTPROCESSING_EDGECENTERED
	nav_agent.set_max_speed(max_speed) # Wichtig für Avoidance-Berechnungen
	
	# Debug-Visualisierung (kann für Release deaktiviert werden)
	nav_agent.debug_enabled = true 
	
	# Warten, bis der Agent auf dem Navigationsserver aktiv ist
	await get_tree().physics_frame
	
	# Verbinde das 'velocity_computed'-Signal für die Vermeidung
	if nav_agent.avoidance_enabled:
		nav_agent.velocity_computed.connect(func(safe_velocity):
			velocity = safe_velocity
		)

func _update_navigation_target(target_pos: Vector2):
	if not nav_agent: return
	
	# Caching: Pfad nur neu berechnen, wenn sich das Ziel signifikant bewegt hat
	if target_pos.distance_squared_to(last_target_pos) > PATH_UPDATE_THRESHOLD_SQ:
		nav_agent.target_position = target_pos
		last_target_pos = target_pos


func _get_navigation_direction(target_position: Vector2) -> Vector2:
	# Diese Funktion wird jetzt durch den NavigationAgent gesteuert.
	# Wir setzen das Ziel und der Agent berechnet den Pfad.
	_update_navigation_target(target_position)
	
	if nav_agent.is_navigation_finished():
		return Vector2.ZERO
		
	return (nav_agent.get_next_path_position() - global_position).normalized()


# ============================================================================
# EDGE CASE HANDLING (NEU)
# ============================================================================

func _check_if_stuck(delta: float):
	"""Prüft, ob der Gegner feststeckt und löst das Problem."""
	if velocity.length_squared() < 1.0: # Wenn sich der Gegner kaum bewegt
		stuck_timer += delta
	else:
		stuck_timer = 0.0 # Timer zurücksetzen, wenn Bewegung stattfindet

	if stuck_timer > STUCK_TIME_THRESHOLD:
		print("Enemy ist festgesteckt. Versuche, das Problem zu lösen...")
		_handle_stuck_enemy()
		stuck_timer = 0.0 # Timer zurücksetzen, um Endlosschleifen zu vermeiden

func _handle_stuck_enemy():
	"""Versucht, einen feststeckenden Gegner zu befreien."""
	# Option 1: Teleportiere zu einem nahen, gültigen Navigationspunkt
	var current_map = get_world_2d().navigation_map
	var nearby_point = NavigationServer2D.map_get_closest_point(current_map, global_position)
	
	if global_position.distance_to(nearby_point) > 5.0: # Nur teleportieren, wenn der Punkt nicht der aktuelle ist
		global_position = nearby_point
		print("Stuck-Lösung: Gegner zu nächstem Nav-Punkt teleportiert.")
		return

	# Option 2: Wenn Teleport nicht hilft, Ziel kurzzeitig ändern (z.B. weglaufen)
	if player:
		var away_from_player = (global_position - player.global_position).normalized() * 150
		_update_navigation_target(global_position + away_from_player)
		print("Stuck-Lösung: Gegner versucht, sich kurzzeitig vom Spieler wegzubewegen.")
		
		# Nach kurzer Zeit wieder das ursprüngliche Ziel anvisieren
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(player):
			_update_navigation_target(player.global_position)


# ============================================================================
# ENEMY BEHAVIOR FUNCTIONS
# ============================================================================



func _standard_behavior() -> void:
	"""Standard drone - intelligent chase with tactics"""
	# Use smart target selection
	var target = _find_best_target()
	if not target or not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	# Predict target position
	var predicted_pos = _predict_target_position(target, 0.3)

	# Check if should flank
	var target_pos = predicted_pos
	if _should_use_flanking():
		target_pos = _get_flanking_position()

	# Navigate intelligently
	var direction = _get_navigation_direction(target_pos)
	# velocity wird jetzt durch den NavigationAgent gesetzt



func _fast_drone_behavior() -> void:
	"""Fast drone - chase with periodic dash attacks"""
	var distance = global_position.distance_to(player.global_position)

	# Dash attack every 3 seconds when in range
	if dash_cooldown <= 0 and distance < 360.0:
		_dash_attack()
		dash_cooldown = 3.0
	else:
		# Normal chase
		var direction = _get_navigation_direction(player.global_position)
		# velocity wird jetzt durch den NavigationAgent gesetzt



func _dash_attack() -> void:
	"""Dash towards player at high speed"""
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * current_speed * 2.5  # 2.5x speed boost

	# Visual feedback - cyan trail effect
	modulate = Color(0.5, 1.5, 2.0)
	await get_tree().create_timer(0.5).timeout
	if is_queued_for_deletion():
		return
	modulate = Color.WHITE


func _heavy_drone_behavior() -> void:
	"""Heavy drone - slow movement with projectile attacks"""
	var distance = global_position.distance_to(player.global_position)

	# Shoot projectile every 2 seconds when in range
	if attack_cooldown <= 0 and distance < 480.0:
		_shoot_projectile()
		attack_cooldown = 2.0

	# Slow chase
	var direction = _get_navigation_direction(player.global_position)
	# velocity wird jetzt durch den NavigationAgent gesetzt



func _shoot_projectile() -> void:
	"""Shoot projectile at player"""
	var projectile_scene = load("res://scenes/EnemyProjectile.tscn")
	if not projectile_scene:
		print("Warning: EnemyProjectile.tscn not found!")
		return

	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position

	# Set collision layers for projectiles
	if projectile is Area2D or projectile is CharacterBody2D:
		projectile.collision_layer = 8  # Projectile layer
		projectile.collision_mask = 4   # Hit Walls only

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


func _sniper_behavior() -> void:
	"""Sniper drone - keep distance and shoot laser"""
	if not nav_agent or not is_instance_valid(player): return

	var distance = global_position.distance_to(player.global_position)
	var direction = _get_navigation_direction(player.global_position)

	# Maintain distance between 360-600 pixels
	if distance < 360.0:
		# Too close - back away
		nav_agent.target_position = global_position - direction * 100
	elif distance > 600.0:
		# Too far - move closer
		nav_agent.target_position = player.global_position
	else:
		# Perfect distance - strafe around player
		var perpendicular = Vector2(-direction.y, direction.x)
		nav_agent.target_position = global_position + perpendicular * 100


	# Shoot laser every 3 seconds
	if attack_cooldown <= 0:
		_shoot_laser()
		attack_cooldown = 3.0


func _shoot_laser() -> void:
	"""Shoot laser at player with warning line"""
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


func _kamikaze_behavior() -> void:
	"""Kamikaze drone - accelerate when close to player"""
	if not nav_agent or not is_instance_valid(player): return

	var distance = global_position.distance_to(player.global_position)
	var direction = _get_navigation_direction(player.global_position)

	# Check for contact - explode immediately!
	if distance < 48.0:  # Contact range
		die()  # This triggers _kamikaze_explode() in die() function
		return

	# Accelerate when within 180 pixels
	if distance < 180.0:
		# Beschleunige in Richtung des nächsten Navigationspunktes
		var move_direction = (nav_agent.get_next_path_position() - global_position).normalized()
		var desired_velocity = move_direction * current_speed * 2.0 # Double speed
		nav_agent.set_velocity(desired_velocity)
		
		# Increase danger core pulse speed
		if visual_node:
			var danger_core = visual_node.get_node_or_null("DangerCore")
			if danger_core:
				danger_core.modulate = Color(2.0, 0.0, 0.0, 1.0)
	else:
		# Normale Geschwindigkeit wird durch _physics_process gehandhabt
		pass



func _create_visual() -> void:
	"""Create visual representation of enemy"""
	if use_sprites:
		_create_sprite_visual()
	else:
		_create_colorrect_visual()


func _create_sprite_visual() -> void:
	"""Create AnimatedSprite2D visual (when assets available)"""
	sprite = AnimatedSprite2D.new()
	sprite.z_index = 1
	sprite.centered = true
	add_child(sprite)

	# Try to load sprite frames based on enemy type
	var sprite_path = _get_sprite_path_for_enemy()
	if ResourceLoader.exists(sprite_path):
		sprite.sprite_frames = load(sprite_path)
		sprite.play("hover")
	else:
		# Fallback to ColorRect if sprite not found
		sprite.queue_free()
		sprite = null
		use_sprites = false
		_create_colorrect_visual()
		return

	# Apply size multiplier (sprites are already 40x40)
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
	"""Create enhanced ColorRect visual with multi-node composition"""
	# Create container for all visual elements
	visual_node = Node2D.new()
	visual_node.name = "Visual"
	add_child(visual_node)

	# Determine enemy type and create appropriate visuals
	if get_meta("is_kamikaze", false):
		_create_kamikaze_visual()
	elif get_meta("is_sniper", false):
		_create_sniper_visual()
	elif enemy_color.r > 0.9 and enemy_color.g < 0.3:  # Red - Standard
		_create_standard_drone_visual()
	elif enemy_color.b > 0.9 and enemy_color.g > 0.7:  # Cyan - Fast
		_create_fast_drone_visual()
	elif enemy_color.r > 0.5 and enemy_color.b < 0.3:  # Brown - Heavy
		_create_heavy_drone_visual()
	else:
		# Fallback: simple rect
		_create_simple_visual()


func _create_standard_drone_visual() -> void:
	"""Red standard drone - circular with propellers"""
	var size = 40 * enemy_size

	# Main body - circle approximation with ColorRect
	var body = ColorRect.new()
	body.size = Vector2(size, size)
	body.position = -body.size / 2
	body.color = enemy_color
	visual_node.add_child(body)

	# Core glow
	var core = ColorRect.new()
	core.size = Vector2(size * 0.4, size * 0.4)
	core.position = -core.size / 2
	core.color = Color(1.0, 1.0, 0.5, 0.6)  # Yellow glow
	visual_node.add_child(core)

	# 4 propellers
	var prop_size = Vector2(8 * enemy_size, 8 * enemy_size)
	var prop_dist = size * 0.6
	for i in 4:
		var angle = (PI / 2.0) * i
		var prop = ColorRect.new()
		prop.size = prop_size
		prop.position = Vector2(cos(angle), sin(angle)) * prop_dist - prop_size / 2
		prop.color = Color(0.3, 0.3, 0.3)
		visual_node.add_child(prop)


func _create_fast_drone_visual() -> void:
	"""Cyan fast drone - triangular with thrusters"""
	var size = 40 * enemy_size

	# Main body - triangle approximation with 3 rects
	var body = ColorRect.new()
	body.size = Vector2(size * 0.8, size * 1.2)
	body.position = Vector2(-size * 0.4, -size * 0.6)
	body.color = enemy_color
	visual_node.add_child(body)

	# Thruster glow left
	var thruster_l = ColorRect.new()
	thruster_l.size = Vector2(6 * enemy_size, 20 * enemy_size)
	thruster_l.position = Vector2(-size * 0.5, -10 * enemy_size)
	thruster_l.color = Color(0.5, 1.0, 1.0, 0.7)
	visual_node.add_child(thruster_l)

	# Thruster glow right
	var thruster_r = ColorRect.new()
	thruster_r.size = Vector2(6 * enemy_size, 20 * enemy_size)
	thruster_r.position = Vector2(size * 0.3, -10 * enemy_size)
	thruster_r.color = Color(0.5, 1.0, 1.0, 0.7)
	visual_node.add_child(thruster_r)


func _create_heavy_drone_visual() -> void:
	"""Brown heavy drone - thick rectangular with armor plates"""
	var size = 60 * enemy_size

	# Main body
	var body = ColorRect.new()
	body.size = Vector2(size, size)
	body.position = -body.size / 2
	body.color = enemy_color
	visual_node.add_child(body)

	# Armor plates (darker gray overlay)
	var armor_color = Color(0.3, 0.3, 0.3, 0.8)

	# Top armor
	var armor_top = ColorRect.new()
	armor_top.size = Vector2(size * 0.8, 8 * enemy_size)
	armor_top.position = Vector2(-size * 0.4, -size * 0.45)
	armor_top.color = armor_color
	visual_node.add_child(armor_top)

	# Bottom armor
	var armor_bottom = ColorRect.new()
	armor_bottom.size = Vector2(size * 0.8, 8 * enemy_size)
	armor_bottom.position = Vector2(-size * 0.4, size * 0.35)
	armor_bottom.color = armor_color
	visual_node.add_child(armor_bottom)

	# Left armor
	var armor_left = ColorRect.new()
	armor_left.size = Vector2(8 * enemy_size, size * 0.6)
	armor_left.position = Vector2(-size * 0.45, -size * 0.3)
	armor_left.color = armor_color
	visual_node.add_child(armor_left)

	# Right armor
	var armor_right = ColorRect.new()
	armor_right.size = Vector2(8 * enemy_size, size * 0.6)
	armor_right.position = Vector2(size * 0.35, -size * 0.3)
	armor_right.color = armor_color
	visual_node.add_child(armor_right)


func _create_kamikaze_visual() -> void:
	"""Orange kamikaze drone - octagon with warning stripes"""
	var size = 40 * enemy_size

	# Main body - octagon approximation
	var body = ColorRect.new()
	body.size = Vector2(size, size)
	body.position = -body.size / 2
	body.color = enemy_color
	visual_node.add_child(body)

	# Warning stripes (yellow)
	var stripe1 = ColorRect.new()
	stripe1.size = Vector2(size * 0.8, 4 * enemy_size)
	stripe1.position = Vector2(-size * 0.4, -10 * enemy_size)
	stripe1.color = Color(1.0, 1.0, 0.0, 0.9)
	visual_node.add_child(stripe1)

	var stripe2 = ColorRect.new()
	stripe2.size = Vector2(size * 0.8, 4 * enemy_size)
	stripe2.position = Vector2(-size * 0.4, 6 * enemy_size)
	stripe2.color = Color(1.0, 1.0, 0.0, 0.9)
	visual_node.add_child(stripe2)

	# Pulsing danger core
	var danger_core = ColorRect.new()
	danger_core.size = Vector2(16 * enemy_size, 16 * enemy_size)
	danger_core.position = -danger_core.size / 2
	danger_core.color = Color(1.0, 0.0, 0.0, 0.8)
	danger_core.name = "DangerCore"
	visual_node.add_child(danger_core)

	# Make danger core pulse faster
	var tween = create_tween().set_loops()
	tween.tween_property(danger_core, "modulate:a", 1.0, 0.3)
	tween.tween_property(danger_core, "modulate:a", 0.3, 0.3)


func _create_sniper_visual() -> void:
	"""Green sniper drone - rectangular with long cannon"""
	var size = 40 * enemy_size

	# Main body
	var body = ColorRect.new()
	body.size = Vector2(size, size * 0.8)
	body.position = Vector2(-size * 0.5, -size * 0.4)
	body.color = enemy_color
	visual_node.add_child(body)

	# Long barrel/cannon
	var cannon = ColorRect.new()
	cannon.size = Vector2(size * 1.2, 6 * enemy_size)
	cannon.position = Vector2(size * 0.5, -3 * enemy_size)
	cannon.color = Color(0.15, 0.15, 0.15)
	visual_node.add_child(cannon)

	# Scanner circle (animated)
	var scanner = ColorRect.new()
	scanner.size = Vector2(size * 1.5, 2 * enemy_size)
	scanner.position = Vector2(-size * 0.25, -1 * enemy_size)
	scanner.color = Color(0.0, 1.0, 0.0, 0.3)
	scanner.name = "Scanner"
	visual_node.add_child(scanner)

	# Animate scanner pulse
	var tween = create_tween().set_loops()
	tween.tween_property(scanner, "modulate:a", 0.1, 1.0)
	tween.tween_property(scanner, "modulate:a", 0.6, 1.0)


func _create_simple_visual() -> void:
	"""Fallback simple visual"""
	var body = ColorRect.new()
	body.size = Vector2(40, 40) * enemy_size
	body.position = -body.size / 2
	body.color = enemy_color
	visual_node.add_child(body)


func _get_sprite_path_for_enemy() -> String:
	"""Get sprite resource path based on enemy metadata"""
	# Check for specific enemy type metadata
	if get_meta("is_kamikaze", false):
		return "res://assets/sprites/enemies/drone_kamikaze.tres"

	if get_meta("is_sniper", false):
		return "res://assets/sprites/enemies/drone_sniper.tres"

	# Determine by color/properties
	var r = enemy_color.r
	var g = enemy_color.g
	var b = enemy_color.b

	if r > 0.9 and g < 0.3 and b < 0.3:
		return "res://assets/sprites/enemies/drone_standard.tres"  # Red - Standard
	elif r < 0.3 and g > 0.7 and b > 0.9:
		return "res://assets/sprites/enemies/drone_fast.tres"  # Cyan - Fast
	elif r > 0.5 and g > 0.2 and g < 0.4 and b < 0.3:
		return "res://assets/sprites/enemies/drone_heavy.tres"  # Brown - Heavy
	elif r > 0.9 and g > 0.5 and b < 0.3:
		return "res://assets/sprites/enemies/drone_kamikaze.tres"  # Orange - Kamikaze
	elif r < 0.3 and g > 0.7 and b < 0.4:
		return "res://assets/sprites/enemies/drone_sniper.tres"  # Green - Sniper

	# Default
	return "res://assets/sprites/enemies/drone_standard.tres"


func _start_pulse_animation() -> void:
	"""Start pulsing scale animation"""
	if use_sprites and sprite:
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.5)
		tween.tween_property(sprite, "scale", Vector2(0.9, 0.9), 0.5)
	elif visual_node:
		# Pulse the entire visual container
		var tween = create_tween().set_loops()
		tween.tween_property(visual_node, "scale", Vector2(1.1, 1.1), 0.5)
		tween.tween_property(visual_node, "scale", Vector2(0.9, 0.9), 0.5)


func _start_rotation_animation() -> void:
	"""Start continuous rotation"""
	if use_sprites and sprite:
		var tween = create_tween().set_loops()
		tween.tween_property(sprite, "rotation", TAU, 2.0)
	elif visual_node:
		# Rotate the entire visual container
		var tween = create_tween().set_loops()
		tween.tween_property(visual_node, "rotation", TAU, 2.0)

func _get_navigation_direction(target_position: Vector2) -> Vector2:
	# Diese Funktion wird jetzt durch den NavigationAgent gesteuert.
	# Wir setzen das Ziel und der Agent berechnet den Pfad.
	_update_navigation_target(target_position)
	
	if nav_agent.is_navigation_finished():
		return Vector2.ZERO
		
	return (nav_agent.get_next_path_position() - global_position).normalized()


func _apply_wall_avoidance(delta: float) -> void:
	pass # Ersetzt durch NavigationAgent2D


# ============================================================================
# ADVANCED AI SYSTEMS
# ============================================================================

func _apply_separation_force(delta: float) -> void:
	pass # Ersetzt durch NavigationAgent2D Avoidance



func _find_best_target() -> CharacterBody2D:
	"""Advanced target selection with threat assessment"""
	var player_target = GameManager.get_player()
	if not player_target or not is_instance_valid(player_target):
		return null

	# Simple case: Only player exists
	var potential_targets = [player_target]

	# Check for player drones/pets
	var all_targets = get_tree().get_nodes_in_group("player_controlled")
	for target in all_targets:
		if is_instance_valid(target) and target != player_target:
			potential_targets.append(target)

	# If only one target, return it
	if potential_targets.size() == 1:
		return player_target

	# Score each target based on distance, threat, and health
	var best_target = player_target
	var best_score = -INF

	for target in potential_targets:
		if not is_instance_valid(target):
			continue

		var target_node = target as Node2D
		if target_node == null:
			continue

		var distance = global_position.distance_to(target_node.global_position)
		var score = 0.0

		# Closer targets score higher
		score += max(0, 500.0 - distance) / 5.0

		# Low health targets score higher (if we can see health)
		if "current_health" in target and "max_health" in target:
			var health_percent = float(target.current_health) / float(target.max_health)
			score += (1.0 - health_percent) * 50.0

		# Attacking targets score higher
		if "melee_timer" in target:
			var melee_time = target.get("melee_timer")
			if melee_time != null and melee_time < 0.1:
				score += 30.0

		if score > best_score:
			best_score = score
			best_target = target

	return best_target


func _predict_target_position(target: Node2D, prediction_time: float = 0.3) -> Vector2:
	"""Predict where target will be based on their velocity"""
	if not target or not is_instance_valid(target):
		return global_position

	var target_pos = target.global_position

	# If target has velocity, predict future position
	if "velocity" in target:
		var target_velocity = target.get("velocity")
		if target_velocity != null and target_velocity is Vector2:
			if target_velocity.length() > 10.0:
				target_pos += target_velocity * prediction_time

	return target_pos


func _should_use_flanking() -> bool:
	"""Determine if enemy should try to flank the player"""
	# Flanking behavior for smart enemies
	if randf() > 0.7:  # 30% chance to flank
		return true

	# Flank if player is surrounded by allies
	var allies_near_player = 0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == self:
			continue

		if player and is_instance_valid(player):
			var dist = enemy.global_position.distance_to(player.global_position)
			if dist < 150.0:
				allies_near_player += 1

	return allies_near_player >= 3


func _get_flanking_position() -> Vector2:
	"""Get a flanking position around the player"""
	if not player or not is_instance_valid(player):
		return global_position

	# Random angle offset for flanking
	var angle_offset = randf_range(-PI/2, PI/2)
	var to_player = (player.global_position - global_position).normalized()
	var flank_dir = to_player.rotated(angle_offset)
	var flank_distance = randf_range(100.0, 200.0)

	return player.global_position + flank_dir * flank_distance
