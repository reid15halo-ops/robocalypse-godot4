extends Node

# Signals
signal mode_switched(is_drone_mode: bool)
signal drone_spawned
signal drone_died

# References
var player: CharacterBody2D = null
var drone: CharacterBody2D = null
var game_camera: Camera2D = null

# State
var is_drone_mode: bool = false
var drone_unlocked: bool = false
var drone_scene = preload("res://scenes/ControllableDrone.tscn")

# AI for background character
var ai_target_pos: Vector2 = Vector2.ZERO
var ai_wander_timer: float = 0.0
var ai_wander_interval: float = 3.0


func _ready() -> void:
	# Get player reference
	player = get_parent()
	if not player:
		print("Error: HackerDroneController must be child of Player!")
		return

	# Create camera if needed
	_setup_camera()


func _process(delta: float) -> void:
	# Check for mode switch input
	if Input.is_action_just_pressed("switch_mode") and drone_unlocked and drone:
		toggle_mode()

	# Handle AI movement for background character
	if is_drone_mode and player:
		_handle_player_ai(delta)
	elif not is_drone_mode and drone:
		_handle_drone_ai(delta)


func _setup_camera() -> void:
	"""Setup camera that follows active character"""
	game_camera = Camera2D.new()
	game_camera.enabled = true
	player.add_child(game_camera)


func spawn_drone() -> void:
	"""Spawn the controllable drone"""
	if drone:
		print("Drone already exists!")
		return

	drone = drone_scene.instantiate()
	drone.global_position = player.global_position + Vector2(100, 0)

	# Connect signals
	drone.died.connect(_on_drone_died)
	drone.level_up.connect(_on_drone_level_up)

	# Add to scene
	player.get_parent().add_child(drone)

	drone_unlocked = true
	drone_spawned.emit()

	print("Drone spawned! Press 'E' to switch control.")


func toggle_mode() -> void:
	"""Switch between player and drone control"""
	if not drone or not drone_unlocked:
		return

	is_drone_mode = not is_drone_mode

	if is_drone_mode:
		# Switch to drone control
		drone.is_player_controlled = true
		player.set_meta("ai_controlled", true)  # Use metadata flag instead of disabling physics
		_move_camera_to(drone)
		print("Controlling Drone - Hacker on AI")
	else:
		# Switch back to player control
		drone.is_player_controlled = false
		player.set_meta("ai_controlled", false)
		_move_camera_to(player)
		print("Controlling Hacker - Drone on AI")

	mode_switched.emit(is_drone_mode)


func _move_camera_to(target: Node2D) -> void:
	"""Move camera to target with smooth transition"""
	if not game_camera:
		return

	# Reparent camera
	game_camera.reparent(target)

	# Optional: Tween for smooth transition
	var tween = get_tree().create_tween()
	tween.tween_property(game_camera, "position", Vector2.ZERO, 0.3)


func _handle_player_ai(delta: float) -> void:
	"""Simple AI for player when controlling drone"""
	if not player or not is_instance_valid(player):
		return

	ai_wander_timer += delta

	# Pick new wander position periodically
	if ai_wander_timer >= ai_wander_interval:
		ai_wander_timer = 0.0
		# Wander near drone
		if drone:
			var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
			ai_target_pos = drone.global_position + offset
		else:
			ai_target_pos = player.global_position

	# Move towards target
	var direction = (ai_target_pos - player.global_position).normalized()
	var distance = player.global_position.distance_to(ai_target_pos)

	if distance > 50.0:
		player.velocity = direction * player.speed * 0.5  # Half speed for AI
	else:
		player.velocity = Vector2.ZERO
	# Note: player._physics_process will call move_and_slide()


func _handle_drone_ai(_delta: float) -> void:
	"""Simple AI for drone when controlling player"""
	if not drone or not is_instance_valid(drone):
		return

	# Follow player at distance
	var follow_distance = 150.0
	var direction = (player.global_position - drone.global_position).normalized()
	var distance = drone.global_position.distance_to(player.global_position)

	if distance > follow_distance:
		drone.velocity = direction * drone.current_speed * 0.6
		drone.move_and_slide()
	else:
		drone.velocity = Vector2.ZERO


func _on_drone_died() -> void:
	"""Handle drone death"""
	var was_in_drone_mode = is_drone_mode

	# If we were controlling the drone, this is CATASTROPHIC
	if was_in_drone_mode:
		print("DRONE DESTROYED! All progress lost!")

		# Reset ALL drone progress
		if drone and is_instance_valid(drone):
			drone.reset_progress()

		# Switch back to player
		is_drone_mode = false
		player.set_meta("ai_controlled", false)
		_move_camera_to(player)

		# Respawn drone at level 1
		if drone:
			drone.queue_free()
			drone = null

		# Wait a bit before allowing respawn
		await get_tree().create_timer(2.0).timeout
		spawn_drone()

	else:
		# Just respawn without penalty
		print("Drone died in background - respawning...")
		if drone:
			drone.queue_free()
			drone = null

		await get_tree().create_timer(3.0).timeout
		spawn_drone()

	drone_died.emit()


func _on_drone_level_up(new_level: int) -> void:
	"""Drone leveled up"""
	print("Drone reached level ", new_level, "!")
	# Could show UI notification here


func apply_drone_upgrade(upgrade_data: Dictionary) -> void:
	"""Apply upgrade to drone"""
	if drone and is_instance_valid(drone):
		drone.apply_upgrade(upgrade_data)
		print("Applied drone upgrade: ", upgrade_data.name)


func get_drone_stats() -> Dictionary:
	"""Get current drone stats for UI"""
	if not drone or not is_instance_valid(drone):
		return {
			"exists": false
		}

	return {
		"exists": true,
		"level": drone.current_level,
		"hp": drone.current_health,
		"max_hp": drone.max_health,
		"xp": drone.current_xp,
		"xp_needed": drone._get_xp_for_next_level(),
		"damage": drone.current_damage,
		"speed": drone.current_speed
	}
